import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import 'analysis_page.dart';

/// Tela de busca cascata: Marca → Modelo → Ano → pré-preenche formulário.
class VehicleSearchPage extends StatefulWidget {
  const VehicleSearchPage({super.key});

  @override
  State<VehicleSearchPage> createState() => _VehicleSearchPageState();
}

class _VehicleSearchPageState extends State<VehicleSearchPage> {
  final ApiClient _api = ApiClient();

  String _vehicleImageUrl() {
    final brand = _selectedBrand?.name ?? '';
    final model = _selectedModel?.name ?? 'car';
    final q = Uri.encodeComponent('$brand $model');
    return 'https://source.unsplash.com/featured/900x500/?$q,car';
  }

  // Dados carregados
  List<FipeBrand> _brands = [];
  List<FipeModel> _models = [];
  List<FipeYear> _years = [];

  // Seleção atual
  FipeBrand? _selectedBrand;
  FipeModel? _selectedModel;
  FipeYear? _selectedYear;

  FipePrice? _fipePrice;
  VehicleConsumption? _consumption;

  bool _loadingBrands = false;
  bool _loadingModels = false;
  bool _loadingYears = false;
  bool _loadingPrice = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    setState(() { _loadingBrands = true; _error = null; });
    try {
      final brands = await _api.getBrands();
      setState(() { _brands = brands; });
    } catch (e) {
      setState(() { _error = 'Erro ao carregar marcas: $e'; });
    } finally {
      setState(() { _loadingBrands = false; });
    }
  }

  Future<void> _onBrandSelected(FipeBrand brand) async {
    setState(() {
      _selectedBrand = brand;
      _selectedModel = null;
      _selectedYear = null;
      _fipePrice = null;
      _consumption = null;
      _models = [];
      _years = [];
      _loadingModels = true;
      _error = null;
    });
    try {
      final models = await _api.getModels(brand.code);
      setState(() { _models = models; });
    } catch (e) {
      setState(() { _error = 'Erro ao carregar modelos: $e'; });
    } finally {
      setState(() { _loadingModels = false; });
    }
  }

  Future<void> _onModelSelected(FipeModel model) async {
    setState(() {
      _selectedModel = model;
      _selectedYear = null;
      _fipePrice = null;
      _consumption = null;
      _years = [];
      _loadingYears = true;
      _error = null;
    });
    try {
      final years = await _api.getYears(_selectedBrand!.code, model.code);
      setState(() { _years = years; });
    } catch (e) {
      setState(() { _error = 'Erro ao carregar anos: $e'; });
    } finally {
      setState(() { _loadingYears = false; });
    }
  }

  Future<void> _onYearSelected(FipeYear year) async {
    setState(() {
      _selectedYear = year;
      _fipePrice = null;
      _consumption = null;
      _loadingPrice = true;
      _error = null;
    });
    try {
      final price = await _api.getFipePrice(
          _selectedBrand!.code, _selectedModel!.code, year.code);
      setState(() { _fipePrice = price; });

      // Tenta buscar consumo Inmetro em paralelo (sem bloquear)
      final yearNum = int.tryParse(year.code.split('-').first) ?? price.yearModel;
      final consumption = await _api.getConsumption(
          _selectedBrand!.name, _selectedModel!.name, yearNum);
      setState(() { _consumption = consumption; });
    } catch (e) {
      setState(() { _error = 'Erro ao buscar dados: $e'; });
    } finally {
      setState(() { _loadingPrice = false; });
    }
  }

  void _proceed() {
    final price = _fipePrice;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AnalysisPage(
        prefill: AnalysisPrefill(
          vehicleLabel: '${_selectedBrand?.name ?? ''} ${_selectedModel?.name ?? ''}'.trim(),
          year: price?.yearModel ?? int.tryParse(_selectedYear?.code.split('-').first ?? '') ?? 2020,
          fipeReferencePrice: price?.referencePrice,
          suggestedKmPerLiter: _consumption?.averageKmL,
          fuelType: _consumption?.fuel,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar veículo')),
      body: _loadingBrands
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),

                // Marca
                _buildDropdown<FipeBrand>(
                  label: 'Marca',
                  value: _selectedBrand,
                  items: _brands,
                  itemLabel: (b) => b.name,
                  onChanged: _onBrandSelected,
                  loading: _loadingBrands,
                ),
                const SizedBox(height: 12),

                // Modelo
                if (_selectedBrand != null)
                  _buildDropdown<FipeModel>(
                    label: 'Modelo',
                    value: _selectedModel,
                    items: _models,
                    itemLabel: (m) => m.name,
                    onChanged: _onModelSelected,
                    loading: _loadingModels,
                  ),
                if (_selectedBrand != null) const SizedBox(height: 12),

                // Ano
                if (_selectedModel != null)
                  _buildDropdown<FipeYear>(
                    label: 'Ano',
                    value: _selectedYear,
                    items: _years,
                    itemLabel: (y) => y.name,
                    onChanged: _onYearSelected,
                    loading: _loadingYears,
                  ),
                if (_selectedModel != null) const SizedBox(height: 16),

                if (_selectedModel != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      _vehicleImageUrl(),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stack) => Container(
                        height: 150,
                        color: const Color(0xFFE7EEF4),
                        alignment: Alignment.center,
                        child: const Icon(Icons.directions_car, size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Preview FIPE
                if (_loadingPrice)
                  const Center(child: CircularProgressIndicator()),

                if (_fipePrice != null) ...[
                  _InfoCard(
                    icon: Icons.sell_outlined,
                    title: 'Referência FIPE',
                    value: _fipePrice!.referencePriceFormatted ??
                        'R\$ ${_fipePrice!.referencePrice.toStringAsFixed(2)}',
                    subtitle: [
                      _fipePrice!.fuel,
                      if (_fipePrice!.referenceMonth != null)
                        _fipePrice!.referenceMonth!,
                      'Fonte: ${_fipePrice!.sourceName}',
                    ].join(' • '),
                    badgeLabel: _fipePrice!.sourceName,
                    badgeColor: _badgeColor(_fipePrice!.source),
                  ),
                  if (_fipePrice!.isFallback)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        _fipePrice!.source == 'local'
                            ? 'Valor vindo da base local estimada. Use como referência operacional.'
                            : 'Valor vindo do provedor secundário Parallelum/FIPE.' ,
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                ],

                if (_consumption != null) ...[
                  _InfoCard(
                    icon: Icons.local_gas_station_outlined,
                    title: 'Consumo Inmetro (referência)',
                    value: '${_consumption!.averageKmL} km/l (média)',
                    subtitle: 'Urbano: ${_consumption!.urbanKmL} • Estrada: ${_consumption!.roadKmL}',
                  ),
                  const SizedBox(height: 16),
                ],

                if (_fipePrice != null)
                  FilledButton.icon(
                    onPressed: _proceed,
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Analisar este veículo'),
                  ),
              ],
            ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T) onChanged,
    required bool loading,
  }) {
    if (loading) {
      return InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: const SizedBox(height: 20, child: LinearProgressIndicator()),
      );
    }
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      isExpanded: true,
      items: items.map((item) => DropdownMenuItem<T>(
        value: item,
        child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }

  Color _badgeColor(String source) {
    switch (source) {
      case 'parallelum':
        return const Color(0xFF0E7490);
      case 'local':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF2563EB);
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.badgeLabel,
    this.badgeColor,
  });
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final String? badgeLabel;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Row(
          children: [
            Expanded(
              child: Text(title, style: theme.textTheme.labelMedium),
            ),
            if (badgeLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (badgeColor ?? theme.colorScheme.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeLabel!,
                  style: TextStyle(
                    color: badgeColor ?? theme.colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
