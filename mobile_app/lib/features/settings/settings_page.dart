import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _kCombinedCarWeight = 'combined_car_weight';
  static const _kCombinedPartsWeight = 'combined_parts_weight';
  static const _kProfileCity = 'profile_city';
  static const _kProfileBudget = 'profile_budget';
  static const _kProfileFuel = 'profile_fuel';
  static const _kNotifyDrops = 'profile_notify_drops';
  static const _kPreferEconomy = 'profile_prefer_economy';
  static const _kIncludePartsHistory = 'profile_include_parts_history';

  final ApiClient _api = ApiClient();

  double _price = 0.40;
  double _fuel = 0.25;
  double _maintenance = 0.20;
  double _adequacy = 0.15;
  double _carWeight = 0.70;
  double _partsWeight = 0.30;

  bool _loading = true;
  bool _saving = false;
  String? _message;

  final _cityCtrl = TextEditingController(text: 'Sao Paulo - SP');
  final _budgetCtrl = TextEditingController(text: '1200');
  final _fuelCtrl = TextEditingController(text: '5.89');

  bool _notifyDrops = true;
  bool _preferEconomy = true;
  bool _includePartsInHistory = true;

  @override
  void dispose() {
    _cityCtrl.dispose();
    _budgetCtrl.dispose();
    _fuelCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _saveProfilePrefs() {
    _saveProfilePrefsAsync();
  }

  Future<void> _saveProfilePrefsAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfileCity, _cityCtrl.text.trim());
      await prefs.setString(_kProfileBudget, _budgetCtrl.text.trim());
      await prefs.setString(_kProfileFuel, _fuelCtrl.text.trim());
      await prefs.setBool(_kNotifyDrops, _notifyDrops);
      await prefs.setBool(_kPreferEconomy, _preferEconomy);
      await prefs.setBool(_kIncludePartsHistory, _includePartsInHistory);
      await prefs.setDouble(_kCombinedCarWeight, _carWeight);
      await prefs.setDouble(_kCombinedPartsWeight, _partsWeight);
      if (!mounted) return;
      setState(() {
        _message = 'Preferencias salvas com sucesso.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Erro ao salvar preferencias: $e';
      });
    }
  }

  Future<void> _loadProfilePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString(_kProfileCity);
    final budget = prefs.getString(_kProfileBudget);
    final fuel = prefs.getString(_kProfileFuel);
    final notifyDrops = prefs.getBool(_kNotifyDrops);
    final preferEconomy = prefs.getBool(_kPreferEconomy);
    final includePartsHistory = prefs.getBool(_kIncludePartsHistory);
    final carWeight = prefs.getDouble(_kCombinedCarWeight);
    final partsWeight = prefs.getDouble(_kCombinedPartsWeight);

    if (!mounted) return;
    setState(() {
      if (city != null && city.isNotEmpty) _cityCtrl.text = city;
      if (budget != null && budget.isNotEmpty) _budgetCtrl.text = budget;
      if (fuel != null && fuel.isNotEmpty) _fuelCtrl.text = fuel;
      if (notifyDrops != null) _notifyDrops = notifyDrops;
      if (preferEconomy != null) _preferEconomy = preferEconomy;
      if (includePartsHistory != null) _includePartsInHistory = includePartsHistory;
      if (carWeight != null) _carWeight = carWeight;
      if (partsWeight != null) _partsWeight = partsWeight;
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await _loadProfilePrefs();
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
    final combinedSum = _carWeight + _partsWeight;

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
                        const Text('Como o score funciona', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text(
                          'Cada slider aumenta ou reduz o impacto de um pilar na nota final. O backend normaliza automaticamente para somar 1.0.',
                        ),
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
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Peso do termometro final (carro + pecas)',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        _weightSlider(
                          label: 'Peso do score do carro',
                          value: _carWeight,
                          onChanged: (v) => setState(() => _carWeight = v),
                        ),
                        _weightSlider(
                          label: 'Peso do score de pecas',
                          value: _partsWeight,
                          onChanged: (v) => setState(() => _partsWeight = v),
                        ),
                        Text('Soma atual (carro+pecas): ${combinedSum.toStringAsFixed(2)}'),
                        const SizedBox(height: 6),
                        const Text(
                          'Esses pesos sao enviados na analise combinada e mudam o termometro de compra.',
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Dica: mantenha Preco alto se a negociacao for prioridade. Aumente Combustivel e Manutencao se foco for custo mensal.',
                        ),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Perfil e personalizacao',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Essas preferencias ajudam voce a analisar com contexto pessoal de regiao, combustivel e meta de gasto mensal.',
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _cityCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Cidade/regiao padrao',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _budgetCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Meta de gasto mensal (R\$)',
                            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _fuelCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Preco padrao do combustivel (R\$/L)',
                            prefixIcon: Icon(Icons.local_gas_station_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _notifyDrops,
                          onChanged: (v) => setState(() => _notifyDrops = v),
                          title: const Text('Alertar quando houver queda de preco'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _preferEconomy,
                          onChanged: (v) => setState(() => _preferEconomy = v),
                          title: const Text('Priorizar economia no score sugerido'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _includePartsInHistory,
                          onChanged: (v) => setState(() => _includePartsInHistory = v),
                          title: const Text('Mostrar historico de pecas junto com carros'),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _saveProfilePrefs,
                            icon: const Icon(Icons.tune),
                            label: const Text('Salvar preferencias'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Impacto no app'),
                    subtitle: Text(
                      'Pesos sao aplicados no backend imediatamente. Preferencias pessoais sao usadas para orientar sua experiencia e comparacoes.',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
