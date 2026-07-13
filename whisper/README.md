# Pipeline quase em tempo real (Teams -> Whisper -> Bullets)

Este projeto implementa um pipeline em 4 partes:

1. Captura audio do sistema (via VB-Cable / Stereo Mix).
2. Salva em blocos curtos (2 a 4 segundos, padrao 3s).
3. Transcreve localmente com faster-whisper.
4. Envia a transcricao para LLM e gera ate 5 bullets rapidos.

## Requisitos

- Windows
- Python 3.10+
- Device de loopback funcionando (VB-Cable ou Stereo Mix)
- Variavel `OPENAI_API_KEY` configurada

## Instalacao

```bash
pip install -r requirements.txt
```

## Passo 1: listar dispositivos

```bash
python realtime_pipeline.py --list-devices
```

Escolha o nome do device de entrada usado para capturar o audio do Teams
(exemplo comum: `CABLE Output`).

## Passo 2: executar pipeline

```bash
python realtime_pipeline.py --device-hint "CABLE Output" --block-seconds 3 --model-size small --compute-type int8
```

## Flags uteis

- `--block-seconds`: 2, 3 ou 4 (latencia x contexto)
- `--model-size`: `tiny`, `base`, `small`, `medium`, `large-v3`
- `--compute-type`: `int8` (CPU), `float16` (GPU), etc.
- `--min-text-len`: ignora trechos curtos (padrao 12)
- `--silence-rms-threshold`: ignora silencio (padrao 0.006)

## Fluxo no Windows (estavel)

1. Instale VB-Cable.
2. No Windows/Teams, roteie a saida de audio para o device virtual.
3. Execute o script ouvindo esse device (`--device-hint`).
4. O script faz blocos curtos, transcreve e imprime bullets no terminal.

## Observacoes de latencia

- Use janelas de 2s para resposta mais rapida.
- `beam_size=1` e `vad_filter=True` ja estao ativos no codigo.
- `tiny/base` reduzem latencia, com perda de precisao.
- O script ignora silencio, transcricoes pequenas e repeticoes exatas.

## Estrutura

- `realtime_pipeline.py`: pipeline completo em threads + filas.
- `requirements.txt`: dependencias.
- `.env.example`: exemplo de variavel de ambiente.
