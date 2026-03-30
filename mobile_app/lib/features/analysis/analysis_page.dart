import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import 'result_page.dart';
import 'vehicle_search_page.dart';

class AnalysisPrefill {
  final String? vehicleLabel;
  final int? year;
  final double? fipeReferencePrice;
  final double? suggestedKmPerLiter;
  final String? fuelType;

  const AnalysisPrefill({
    this.vehicleLabel,
    this.year,
    this.fipeReferencePrice,
    this.suggestedKmPerLiter,
    this.fuelType,
  });
}

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key, this.prefill});

  final AnalysisPrefill? prefill;

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _vehicleCtrl;
  late final TextEditingController _yearCtrl;
  final _priceCtrl = TextEditingController(text: '15000');
  final _kmMonthCtrl = TextEditingController(text: '800');
  late final TextEditingController _kmLiterCtrl;
  final _fuelPriceCtrl = TextEditingController(text: '5.50');
  final _maintenanceCtrl = TextEditingController(text: '100');

  final ApiClient _api = ApiClient();

  double? _fipeReferencePrice;
  String? _fuelType;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    _vehicleCtrl = TextEditingController(text: p?.vehicleLabel ?? 'Fusca');
    _yearCtrl = TextEditingController(text: (p?.year ?? 2010).toString());
    _kmLiterCtrl =
        TextEditingController(text: (p?.suggestedKmPerLiter ?? 10.0).toStringAsFixed(1));
    _fipeReferencePrice = p?.fipeReferencePrice;
    _fuelType = p?.fuelType;
  }

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

  String _vehicleImageUrl(String label) {
    final q = Uri.encodeComponent(label.trim().isEmpty ? 'car' : label.trim());
    return 'https://source.unsplash.com/featured/900x500/?$q,car';
  }

  String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final payload = <String, dynamic>{
        'vehicleLabel': _vehicleCtrl.text.trim(),
        'year': int.parse(_yearCtrl.text),
        'askingPrice': double.parse(_priceCtrl.text.replaceAll(',', '.')),
        'kmPerMonth': double.parse(_kmMonthCtrl.text.replaceAll(',', '.')),
        'kmPerLiter': double.parse(_kmLiterCtrl.text.replaceAll(',', '.')),
        'fuelPricePerLiter': double.parse(_fuelPriceCtrl.text.replaceAll(',', '.')),
        'maintenanceMonthly': double.parse(_maintenanceCtrl.text.replaceAll(',', '.')),
        if (_fipeReferencePrice != null) 'fipeReferencePrice': _fipeReferencePrice,
      };

      final res = await _api.estimate(payload);
      final result = Map<String, dynamic>.from(res['result'] as Map);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultPage(
            result: result,
            vehicleLabel: _vehicleCtrl.text.trim(),
            year: int.parse(_yearCtrl.text),
            imageUrl: _vehicleImageUrl(_vehicleCtrl.text),
            askedPrice: double.parse(_priceCtrl.text.replaceAll(',', '.')),
            kmPerLiter: double.parse(_kmLiterCtrl.text.replaceAll(',', '.')),
            updatedAt: _formatDateTime(DateTime.now()),
            fuelType: _fuelType,
            fipeReferencePrice: _fipeReferencePrice,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao analisar: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFipe = _fipeReferencePrice != null;
    final hasPrefill = widget.prefill != null;
    final vehicleText = _vehicleCtrl.text.trim().isEmpty ? 'Veiculo' : _vehicleCtrl.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisar veiculo'),
        actions: [
          if (!hasPrefill)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Buscar pela FIPE',
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const VehicleSearchPage()),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF062B45), Color(0xFF0A5B8F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _vehicleImageUrl(vehicleText),
                        width: 88,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stack) => Container(
                          width: 88,
                          height: 70,
                          color: Colors.white24,
                          alignment: Alignment.center,
                          child: const Icon(Icons.directions_car, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Diagnostico de compra',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$vehicleText: score por preco, consumo, manutencao e adequacao.',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_outlined),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dica: começe pela busca FIPE para preencher preco de referencia e consumo automaticamente.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (hasFipe)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_outlined, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Preco FIPE: R\$ ${_fipeReferencePrice!.toStringAsFixed(2)}. O score de preco usara dado real.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_fuelType != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_gas_station_outlined, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Consumo Inmetro pre-preenchido. Combustivel: $_fuelType',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _vehicleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Modelo (ex: Honda Civic)',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) => v == null || v.trim().length < 3 ? 'Informe o modelo' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _yearCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ano',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o ano';
                  final y = int.tryParse(v);
                  if (y == null) return 'Ano invalido';
                  if (y < 1950 || y > DateTime.now().year + 1) return 'Ano fora do intervalo';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceCtrl,
                decoration: InputDecoration(
                  labelText: 'Preco pedido (R\$)',
                  prefixIcon: const Icon(Icons.sell_outlined),
                  helperText: hasFipe
                      ? 'Referencia FIPE: R\$ ${_fipeReferencePrice!.toStringAsFixed(2)}'
                      : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || double.tryParse(v.replaceAll(',', '.')) == null)
                    ? 'Preco invalido'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _kmMonthCtrl,
                decoration: const InputDecoration(
                  labelText: 'Km por mes',
                  prefixIcon: Icon(Icons.route_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || double.tryParse(v.replaceAll(',', '.')) == null)
                    ? 'Valor invalido'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _kmLiterCtrl,
                decoration: InputDecoration(
                  labelText: 'Km por litro',
                  prefixIcon: const Icon(Icons.local_gas_station_outlined),
                  helperText: widget.prefill?.suggestedKmPerLiter != null
                      ? 'Sugestao Inmetro: ${widget.prefill!.suggestedKmPerLiter!.toStringAsFixed(1)} km/l'
                      : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || double.tryParse(v.replaceAll(',', '.')) == null)
                    ? 'Valor invalido'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fuelPriceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Preco do combustivel (R\$/L)',
                  prefixIcon: Icon(Icons.oil_barrel_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || double.tryParse(v.replaceAll(',', '.')) == null)
                    ? 'Valor invalido'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _maintenanceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Manutencao mensal estimada (R\$)',
                  prefixIcon: Icon(Icons.build_circle_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || double.tryParse(v.replaceAll(',', '.')) == null)
                    ? 'Valor invalido'
                    : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(hasPrefill ? 'Gerar score detalhado' : 'Analisar agora'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
