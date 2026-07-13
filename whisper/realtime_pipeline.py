import argparse
import os
import queue
import tempfile
import threading
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import numpy as np
import sounddevice as sd
import soundfile as sf
from faster_whisper import WhisperModel
from openai import OpenAI


@dataclass
class Config:
	sample_rate: int = 16000
	channels: int = 1
	block_seconds: float = 3.0
	min_text_len: int = 12
	silence_rms_threshold: float = 0.006
	model_size: str = "small"
	compute_type: str = "int8"
	device_name_hint: str = "CABLE Output"
	language: str = "pt"
	llm_model: str = "gpt-4.1-mini"
	max_bullets: int = 5
	profile_context: str = (
		"Perfil do candidato: Backend, integracao e automacao. "
		"Stack: Python, PHP, APIs REST, SAP RFC/BAPI. "
		"Foco: impacto de negocio e resolucao pratica."
	)


raw_audio_queue: queue.Queue[np.ndarray] = queue.Queue(maxsize=200)
wav_queue: queue.Queue[Path] = queue.Queue(maxsize=200)
text_queue: queue.Queue[str] = queue.Queue(maxsize=200)


def list_input_devices() -> None:
	devices = sd.query_devices()
	print("\nDispositivos de audio detectados:")
	for idx, dev in enumerate(devices):
		print(
			f"[{idx}] {dev['name']} | IN={dev['max_input_channels']} | OUT={dev['max_output_channels']}"
		)


def find_input_device(name_hint: Optional[str]) -> int:
	devices = sd.query_devices()

	if name_hint:
		lowered = name_hint.lower()
		for idx, dev in enumerate(devices):
			if dev["max_input_channels"] > 0 and lowered in dev["name"].lower():
				return idx

	default_input, _ = sd.default.device
	if default_input is not None and default_input >= 0:
		return int(default_input)

	raise RuntimeError(
		"Nenhum device de entrada valido encontrado. Use --list-devices para mapear o nome correto."
	)


def audio_callback(indata, _frames, _time_info, status):
	if status:
		print(f"[audio status] {status}")
	try:
		raw_audio_queue.put_nowait(indata.copy())
	except queue.Full:
		# Se o processamento atrasar, descartamos frames antigos para manter quase tempo real.
		pass


def rms_energy(chunk: np.ndarray) -> float:
	mono = chunk.squeeze()
	if mono.size == 0:
		return 0.0
	return float(np.sqrt(np.mean(np.square(mono))))


def capture_and_chunk_worker(config: Config, device_index: int) -> None:
	samples_needed = int(config.sample_rate * config.block_seconds)
	chunk_list = []
	current_samples = 0

	with sd.InputStream(
		samplerate=config.sample_rate,
		channels=config.channels,
		dtype="float32",
		device=device_index,
		callback=audio_callback,
		blocksize=1024,
	):
		print("[capture] Capturando audio em blocos curtos...")
		while True:
			data = raw_audio_queue.get()
			chunk_list.append(data)
			current_samples += len(data)

			if current_samples < samples_needed:
				continue

			chunk = np.concatenate(chunk_list, axis=0)
			chunk_list = []
			current_samples = 0

			if rms_energy(chunk) < config.silence_rms_threshold:
				continue

			with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
				wav_path = Path(tmp.name)
			sf.write(str(wav_path), chunk, config.sample_rate)

			try:
				wav_queue.put_nowait(wav_path)
			except queue.Full:
				try:
					wav_path.unlink(missing_ok=True)
				except OSError:
					pass


def transcribe_worker(config: Config, model: WhisperModel) -> None:
	last_text = ""

	while True:
		wav_path = wav_queue.get()
		try:
			segments, _info = model.transcribe(
				str(wav_path),
				language=config.language,
				vad_filter=True,
				beam_size=1,
			)

			text = " ".join(seg.text.strip() for seg in segments).strip()
			normalized = " ".join(text.lower().split())

			if len(normalized) < config.min_text_len:
				continue
			if normalized == last_text:
				continue

			last_text = normalized
			text_queue.put(text)
			print(f"\n[transcricao] {text}")
		except Exception as exc:
			print(f"[erro transcricao] {exc}")
		finally:
			try:
				wav_path.unlink(missing_ok=True)
			except OSError:
				pass


def generate_bullets(client: OpenAI, config: Config, transcribed_text: str) -> str:
	prompt = f"""
Voce e um assistente de entrevista.
Receba o trecho da fala do entrevistador e gere no maximo {config.max_bullets} bullets curtos em portugues.

Regras:
- respostas curtas e objetivas
- focar em contexto, problema, solucao, resultado
- se a pergunta estiver incompleta, inferir o tema mais provavel
- evitar buzzwords exageradas
- linguagem natural de conversa

{config.profile_context}

Trecho:
{transcribed_text}
""".strip()

	response = client.responses.create(model=config.llm_model, input=prompt)
	return response.output_text.strip()


def bullets_worker(config: Config, client: OpenAI) -> None:
	while True:
		text = text_queue.get()
		try:
			bullets = generate_bullets(client, config, text)
			print("\n[sugestao de resposta]")
			print(bullets)
			print("-" * 80)
		except Exception as exc:
			print(f"[erro bullets] {exc}")


def build_arg_parser() -> argparse.ArgumentParser:
	parser = argparse.ArgumentParser(
		description="Pipeline quase em tempo real: audio -> blocos -> whisper -> bullets."
	)
	parser.add_argument(
		"--list-devices",
		action="store_true",
		help="Lista os devices de audio e encerra.",
	)
	parser.add_argument(
		"--device-hint",
		type=str,
		default="CABLE Output",
		help="Parte do nome do dispositivo de entrada (ex.: CABLE Output).",
	)
	parser.add_argument(
		"--block-seconds",
		type=float,
		default=3.0,
		help="Janela em segundos para processamento (2 a 4 recomendado).",
	)
	parser.add_argument(
		"--model-size",
		type=str,
		default="small",
		choices=["tiny", "base", "small", "medium", "large-v3"],
		help="Modelo faster-whisper.",
	)
	parser.add_argument(
		"--compute-type",
		type=str,
		default="int8",
		choices=["int8", "int8_float16", "float16", "float32"],
		help="Tipo de computacao para o modelo.",
	)
	parser.add_argument(
		"--min-text-len",
		type=int,
		default=12,
		help="Ignora transcricoes menores que esse tamanho.",
	)
	parser.add_argument(
		"--silence-rms-threshold",
		type=float,
		default=0.006,
		help="Ignora blocos de audio com energia abaixo desse limiar.",
	)
	return parser


def main() -> None:
	parser = build_arg_parser()
	args = parser.parse_args()

	if args.list_devices:
		list_input_devices()
		return

	api_key = os.environ.get("OPENAI_API_KEY")
	if not api_key:
		raise RuntimeError("Defina OPENAI_API_KEY para gerar bullets no LLM.")

	config = Config(
		block_seconds=args.block_seconds,
		min_text_len=args.min_text_len,
		silence_rms_threshold=args.silence_rms_threshold,
		model_size=args.model_size,
		compute_type=args.compute_type,
		device_name_hint=args.device_hint,
	)

	print("[init] Carregando modelo faster-whisper...")
	model = WhisperModel(config.model_size, device="cpu", compute_type=config.compute_type)

	device_index = find_input_device(config.device_name_hint)
	device_name = sd.query_devices(device_index)["name"]
	print(f"[device] Usando: {device_name}")
	print(
		f"[config] janela={config.block_seconds}s | modelo={config.model_size} | compute={config.compute_type}"
	)

	client = OpenAI(api_key=api_key)

	capture_thread = threading.Thread(
		target=capture_and_chunk_worker,
		args=(config, device_index),
		daemon=True,
	)
	transcribe_thread = threading.Thread(
		target=transcribe_worker,
		args=(config, model),
		daemon=True,
	)
	bullets_thread = threading.Thread(
		target=bullets_worker,
		args=(config, client),
		daemon=True,
	)

	capture_thread.start()
	transcribe_thread.start()
	bullets_thread.start()

	print("[run] Pipeline iniciado. Pressione Ctrl+C para encerrar.")
	try:
		while True:
			time.sleep(1)
	except KeyboardInterrupt:
		print("\n[stop] Encerrado.")


if __name__ == "__main__":
	main()
