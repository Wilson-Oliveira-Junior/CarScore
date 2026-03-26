import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import 'result_page.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleCtrl = TextEditingController(text: 'Fusca');
  final _yearCtrl = TextEditingController(text: '2010');
  final _priceCtrl = TextEditingController(text: '15000');
  final _kmMonthCtrl = TextEditingController(text: '800');
  final _kmLiterCtrl = TextEditingController(text: '10');
  final _fuelPriceCtrl = TextEditingController(text: '5.5');
  final _maintenanceCtrl = TextEditingController(text: '100');

  final ApiClient _api = ApiClient();
  bool _loading = false;

  @override
  void dispose() {
    _vehicleCtrl.dispose();
    _yearCtrl.dispose();
    _priceCtrl.dispose();
    _kmMonthCtrl.dispose();
    _kmLiterCtrl.dispose();
    _fuelPriceCtrl.dispose();
    _maintenanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final payload = {
        'vehicleLabel': _vehicleCtrl.text.trim(),
        'year': int.parse(_yearCtrl.text),
        'askingPrice': double.parse(_priceCtrl.text),
        'kmPerMonth': double.parse(_kmMonthCtrl.text),
        'kmPerLiter': double.parse(_kmLiterCtrl.text),
        'fuelPricePerLiter': double.parse(_fuelPriceCtrl.text),
        'maintenanceMonthly': double.parse(_maintenanceCtrl.text),
      };
      final res = await _api.estimate(payload);
      final result = res['result'] as Map<String, dynamic>;
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultPage(result: result)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analisar veículo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _vehicleCtrl,
                decoration: const InputDecoration(labelText: 'Modelo (ex: Fusca)'),
                validator: (v) => v == null || v.trim().length < 3 ? 'Informe o modelo' : null,
              ),
              TextFormField(
                controller: _yearCtrl,
                decoration: const InputDecoration(labelText: 'Ano'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o ano';
                  final y = int.tryParse(v);
                  if (y == null) return 'Ano inválido';
                  if (y < 1950 || y > DateTime.now().year + 1) return 'Ano fora do intervalo';
                  return null;
                },
              ),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Preço pedido (R\$)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Preço inválido' : null,
              ),
              TextFormField(
                controller: _kmMonthCtrl,
                decoration: const InputDecoration(labelText: 'Km por mês'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Valor inválido' : null,
              ),
              TextFormField(
                controller: _kmLiterCtrl,
                decoration: const InputDecoration(labelText: 'Km por litro'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Valor inválido' : null,
              ),
              TextFormField(
                controller: _fuelPriceCtrl,
                decoration: const InputDecoration(labelText: 'Preço do combustível (R\$/L)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Valor inválido' : null,
              ),
              TextFormField(
                controller: _maintenanceCtrl,
                decoration: const InputDecoration(labelText: 'Manutenção mensal estimada (R\$)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Valor inválido' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator() : const Text('Analisar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
