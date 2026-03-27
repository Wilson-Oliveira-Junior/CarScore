import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ApiClient _api = ApiClient();

  double _price = 0.40;
  double _fuel = 0.25;
  double _maintenance = 0.20;
  double _adequacy = 0.15;

  bool _loading = true;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final w = await _api.getWeights();
      setState(() {
        _price = w['price']!;
        _fuel = w['fuel']!;
        _maintenance = w['maintenance']!;
        _adequacy = w['adequacy']!;
      });
    } catch (e) {
      setState(() => _message = 'Erro ao carregar pesos: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final saved = await _api.updateWeights({
        'price': _price,
        'fuel': _fuel,
        'maintenance': _maintenance,
        'adequacy': _adequacy,
      });
      setState(() {
        _price = saved['price']!;
        _fuel = saved['fuel']!;
        _maintenance = saved['maintenance']!;
        _adequacy = saved['adequacy']!;
        _message = 'Pesos atualizados com sucesso.';
      });
    } catch (e) {
      setState(() => _message = 'Erro ao salvar pesos: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  Widget _weightSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(value.toStringAsFixed(2)),
          ],
        ),
        Slider(
          min: 0,
          max: 1,
          divisions: 100,
          value: value,
          onChanged: _saving ? null : onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sum = _price + _fuel + _maintenance + _adequacy;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pesos do score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text('A API normaliza os pesos para somar 1.0.'),
                        const SizedBox(height: 16),
                        _weightSlider(
                          label: 'Preço',
                          value: _price,
                          onChanged: (v) => setState(() => _price = v),
                        ),
                        _weightSlider(
                          label: 'Combustível',
                          value: _fuel,
                          onChanged: (v) => setState(() => _fuel = v),
                        ),
                        _weightSlider(
                          label: 'Manutenção',
                          value: _maintenance,
                          onChanged: (v) => setState(() => _maintenance = v),
                        ),
                        _weightSlider(
                          label: 'Adequação',
                          value: _adequacy,
                          onChanged: (v) => setState(() => _adequacy = v),
                        ),
                        const SizedBox(height: 8),
                        Text('Soma atual: ${sum.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Salvar pesos'),
                          ),
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: 8),
                          Text(_message!),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Impacto'),
                    subtitle: Text('As novas análises usarão os pesos atualizados imediatamente no backend.'),
                  ),
                ),
              ],
            ),
    );
  }
}
