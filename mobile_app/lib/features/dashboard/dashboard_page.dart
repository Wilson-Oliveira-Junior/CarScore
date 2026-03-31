import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../analysis/vehicle_search_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  static const _recentFiltersKey = 'dashboard_recent_filters_v1';

  final _api = ApiClient();
  final _regionCtrl = TextEditingController(text: 'Sao Paulo');
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();
  final _maxKmCtrl = TextEditingController();
  final _minYearCtrl = TextEditingController();

  final Set<String> _selectedProviders = {'mercadolivre'};

  List<MarketplaceOffer> _offers = [];
  List<OfferProviderHealth> _providersHealth = [];
  List<_RecentFilterPreset> _recentFilters = [];
  bool _loading = false;
  bool _loadingHealth = false;
  bool _showFilters = false;
  String? _error;
  String? _selectedId;
  _OfferSort _sortBy = _OfferSort.bestOpportunity;
  late final AnimationController _skeletonController;

  // Offsets de latitude/longitude para espalhar hotspots ao redor do centro.
  static const _mapOffsets = [
    [0.022, -0.018],
    [0.018, 0.016],
    [0.006, 0.029],
    [-0.007, -0.012],
    [-0.015, 0.017],
    [-0.021, -0.006],
    [0.011, -0.031],
    [0.000, 0.000],
  ];

  @override
  void initState() {
    super.initState();
    _skeletonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _loadRecentFilters();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _skeletonController.dispose();
    _regionCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _maxPriceCtrl.dispose();
    _maxKmCtrl.dispose();
    _minYearCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecentFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_recentFiltersKey) ?? [];
    final parsed = <_RecentFilterPreset>[];
    for (final item in raw) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        parsed.add(_RecentFilterPreset.fromJson(map));
      } catch (_) {
        // Skip invalid persisted item.
      }
    }
    if (!mounted) return;
    setState(() {
      _recentFilters = parsed;
    });
  }

  Future<void> _saveCurrentFilterPreset() async {
    final preset = _RecentFilterPreset(
      region: _regionCtrl.text.trim(),
      brand: _brandCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      maxPrice: _maxPriceCtrl.text.trim(),
      maxKm: _maxKmCtrl.text.trim(),
      minYear: _minYearCtrl.text.trim(),
      providers: _selectedProviders.toList()..sort(),
      savedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
    );

    // Keep only meaningful entries.
    if (!preset.hasUsefulFilters) return;

    final deduped = <_RecentFilterPreset>[preset];
    for (final item in _recentFilters) {
      if (item.signature == preset.signature) continue;
      deduped.add(item);
      if (deduped.length >= 6) break;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _recentFiltersKey,
      deduped.map((e) => jsonEncode(e.toJson())).toList(),
    );

    if (!mounted) return;
    setState(() {
      _recentFilters = deduped;
    });
  }

  Future<void> _applyRecentFilter(_RecentFilterPreset preset) async {
    setState(() {
      _regionCtrl.text = preset.region;
      _brandCtrl.text = preset.brand;
      _modelCtrl.text = preset.model;
      _maxPriceCtrl.text = preset.maxPrice;
      _maxKmCtrl.text = preset.maxKm;
      _minYearCtrl.text = preset.minYear;
      _selectedProviders
        ..clear()
        ..addAll(preset.providers.isEmpty ? {'mercadolivre'} : preset.providers);
      _showFilters = true;
    });
    await _loadOffers();
  }

  bool get _isGlobalFallbackActive {
    if (_selectedProviders.every((id) => id == 'local')) return false;
    final anyLocalOffer = _offers.any((offer) => offer.source == 'local');
    if (anyLocalOffer) return true;
    if (_providersHealth.isEmpty) return false;

    final healthyExternal = _providersHealth.any(
      (item) =>
          _selectedProviders.contains(item.id) &&
          item.id != 'local' &&
          item.healthy,
    );
    return !healthyExternal;
  }

  double? _parseMoney(String value) {
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  int? _parseInt(String value) {
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadOffers(),
      _loadProvidersHealth(),
    ]);
  }

  Future<void> _loadProvidersHealth() async {
    setState(() {
      _loadingHealth = true;
    });
    try {
      final health = await _api.getOffersProvidersHealth();
      if (!mounted) return;
      setState(() {
        _providersHealth = health;
        _loadingHealth = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _providersHealth = [];
        _loadingHealth = false;
      });
    }
  }

  List<MarketplaceOffer> _sortOffers(List<MarketplaceOffer> offers) {
    final sorted = [...offers];
    sorted.sort((a, b) {
      switch (_sortBy) {
        case _OfferSort.bestOpportunity:
          final quality = b.qualityScore.compareTo(a.qualityScore);
          if (quality != 0) return quality;
          return a.price.compareTo(b.price);
        case _OfferSort.lowestPrice:
          return a.price.compareTo(b.price);
        case _OfferSort.lowestKm:
          if (a.km == 0 && b.km == 0) return 0;
          if (a.km == 0) return 1;
          if (b.km == 0) return -1;
          return a.km.compareTo(b.km);
        case _OfferSort.newest:
          return b.year.compareTo(a.year);
      }
    });
    return sorted;
  }

  Future<void> _loadOffers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final region =
          _regionCtrl.text.trim().isEmpty ? 'Sao Paulo' : _regionCtrl.text.trim();
      final offers = await _api.getOffers(
        region: region,
        limit: 12,
        brand: _brandCtrl.text,
        model: _modelCtrl.text,
        maxPrice: _parseMoney(_maxPriceCtrl.text),
        maxKm: _parseInt(_maxKmCtrl.text),
        minYear: _parseInt(_minYearCtrl.text),
        providers: _selectedProviders.toList(),
      );
      final sorted = _sortOffers(offers);
      if (!mounted) return;
      setState(() {
        _offers = sorted;
        _selectedId = sorted.isNotEmpty ? sorted.first.id : null;
        _loading = false;
      });
      await _saveCurrentFilterPreset();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao carregar ofertas. Verifique o backend.';
        _loading = false;
      });
    }
  }

  Color _dealColor(MarketplaceOffer offer) {
    if (offer.fipeDiff >= 4000) return const Color(0xFF197B47);
    if (offer.fipeDiff >= 1500) return const Color(0xFF2A9D8F);
    if (offer.fipeDiff >= 0) return const Color(0xFFE09F3E);
    return const Color(0xFFC44536);
  }

  String _dealLabel(MarketplaceOffer offer) {
    if (offer.fipeDiff >= 4000) return 'Melhor oportunidade';
    if (offer.fipeDiff >= 1500) return 'Boa compra';
    if (offer.fipeDiff >= 0) return 'Na FIPE';
    return 'Acima da FIPE';
  }

  String _money(num value) {
    final isNeg = value < 0;
    final abs = isNeg ? -value : value;
    final str = abs.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return '${isNeg ? '-' : ''}R\$ $buf';
  }

  MarketplaceOffer? get _selected {
    if (_offers.isEmpty) return null;
    if (_selectedId == null) return _offers.first;
    return _offers.cast<MarketplaceOffer?>().firstWhere(
          (o) => o?.id == _selectedId,
          orElse: () => _offers.first,
        );
  }

  Future<void> _openListing(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nao foi possivel abrir o link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CarScore'),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar ofertas',
              onPressed: _loadDashboardData,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildGlobalFallbackBanner(),
            const SizedBox(height: 10),
            _buildSearchHeader(),
            const SizedBox(height: 16),
            _buildProvidersHealthPanel(),
            const SizedBox(height: 12),
            _buildActiveFiltersBar(),
            const SizedBox(height: 12),
            _buildMapHotspots(),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _loading
                  ? Container(
                      key: const ValueKey('selected-loading'),
                      child: _buildSelectedSkeleton(),
                    )
                  : _selected != null
                      ? Container(
                          key: ValueKey('selected-${_selected!.id}'),
                          child: _buildSelectedCard(_selected!),
                        )
                      : const SizedBox.shrink(key: ValueKey('selected-empty')),
            ),
            const SizedBox(height: 8),
            _buildListHeader(),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _buildOffersSection(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalFallbackBanner() {
    final fallback = _isGlobalFallbackActive;
    final color = fallback ? const Color(0xFFB26A00) : const Color(0xFF197B47);
    final title = fallback ? 'Modo fallback ativo' : 'Modo normal ativo';
    final subtitle = fallback
        ? 'Fontes externas degradadas. Exibindo dados de contingencia quando necessario.'
        : 'Fontes principais saudaveis e ativas para consulta em tempo real.';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            fallback ? Icons.sync_problem_rounded : Icons.verified_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersSection() {
    if (_loading) {
      return Column(
        key: const ValueKey('offers-loading'),
        children: List.generate(4, (_) => _buildOfferSkeleton()),
      );
    }
    if (_error != null) {
      return Container(key: const ValueKey('offers-error'), child: _buildError());
    }
    if (_offers.isEmpty) {
      return Container(key: const ValueKey('offers-empty'), child: _buildEmpty());
    }
    return Column(
      key: ValueKey('offers-${_offers.length}-${_sortBy.name}'),
      children: _offers.map((offer) => _buildOfferCard(offer)).toList(),
    );
  }

  // ── Header com busca ─────────────────────────────────────────────────────

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2239), Color(0xFF124E78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mapa de oportunidades',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ofertas reais do Mercado Livre comparadas com a tabela FIPE.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _regionCtrl,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _loadOffers(),
                  decoration: InputDecoration(
                    labelText: 'Cidade ou estado',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.location_on_outlined,
                        color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white12,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _loading ? null : _loadOffers,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search),
                label: const Text('Buscar'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF197B47),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() {
                  _showFilters = !_showFilters;
                }),
                icon: Icon(
                  _showFilters ? Icons.tune : Icons.tune_outlined,
                  color: Colors.white,
                ),
                label: Text(
                  _showFilters ? 'Ocultar filtros' : 'Mais filtros',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const Spacer(),
              if (_brandCtrl.text.isNotEmpty ||
                  _modelCtrl.text.isNotEmpty ||
                  _maxPriceCtrl.text.isNotEmpty ||
                  _maxKmCtrl.text.isNotEmpty ||
                  _minYearCtrl.text.isNotEmpty ||
                  _selectedProviders.length != 1 ||
                  !_selectedProviders.contains('mercadolivre'))
                TextButton(
                  onPressed: () {
                    setState(() {
                      _brandCtrl.clear();
                      _modelCtrl.clear();
                      _maxPriceCtrl.clear();
                      _maxKmCtrl.clear();
                      _minYearCtrl.clear();
                      _selectedProviders
                        ..clear()
                        ..add('mercadolivre');
                    });
                    _loadOffers();
                  },
                  child: const Text(
                    'Limpar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
          if (_showFilters) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _brandCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _filterDecoration('Marca', Icons.directions_car),
                    onSubmitted: (_) => _loadOffers(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _modelCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _filterDecoration('Modelo', Icons.badge_outlined),
                    onSubmitted: (_) => _loadOffers(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _maxPriceCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _filterDecoration('Preco max.', Icons.sell_outlined),
                    onSubmitted: (_) => _loadOffers(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _maxKmCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _filterDecoration('Km max.', Icons.speed_outlined),
                    onSubmitted: (_) => _loadOffers(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minYearCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _filterDecoration('Ano min.', Icons.calendar_month),
                    onSubmitted: (_) => _loadOffers(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Fontes de dados',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _providerChip('mercadolivre', 'Mercado Livre', true),
                _providerChip('local', 'Base local', true),
                _providerChip('webmotors', 'Webmotors (stub)', false),
                _providerChip('olx', 'OLX (stub)', false),
              ],
            ),
            if (_recentFilters.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Buscas recentes',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove(_recentFiltersKey);
                      if (!mounted) return;
                      setState(() {
                        _recentFilters = [];
                      });
                    },
                    child: const Text(
                      'Limpar recentes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentFilters.take(5).map((preset) {
                  return ActionChip(
                    onPressed: () => _applyRecentFilter(preset),
                    backgroundColor: Colors.white12,
                    side: const BorderSide(color: Colors.white24),
                    labelStyle: const TextStyle(color: Colors.white),
                    avatar: const Icon(Icons.history, size: 16, color: Colors.white70),
                    label: Text(preset.shortLabel),
                  );
                }).toList(),
              ),
            ],
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const VehicleSearchPage())),
              icon: const Icon(Icons.manage_search),
              label: const Text('Buscar veiculo especifico na FIPE'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvidersHealthPanel() {
    if (_loadingHealth) {
      return _skeletonBox(height: 78, radius: 14);
    }
    if (_providersHealth.isEmpty) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Status das fontes indisponivel'),
          subtitle: const Text('Nao foi possivel consultar a saude dos providers.'),
          trailing: TextButton(
            onPressed: _loadProvidersHealth,
            child: const Text('Tentar'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status das fontes',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Como ler: verde = operando normal; vermelho = fonte degradada.\n'
              'Se fontes externas falharem, o app ativa fallback automatico (base local).',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _providersHealth.map((item) {
                final healthy = item.healthy;
                final color = healthy
                    ? const Color(0xFF197B47)
                    : const Color(0xFFC44536);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        healthy ? Icons.check_circle : Icons.warning_amber,
                        color: color,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${item.name} • ${item.latencyMs} ms',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersBar() {
    final chips = <Widget>[
      _chipInfo('Ordenar: ${_sortBy.label}', const Color(0xFF124E78)),
      if (_regionCtrl.text.trim().isNotEmpty)
        _chipInfo('Regiao: ${_regionCtrl.text.trim()}', const Color(0xFF4C6A92)),
      if (_brandCtrl.text.trim().isNotEmpty)
        _chipInfo('Marca: ${_brandCtrl.text.trim()}', const Color(0xFF2A9D8F)),
      if (_modelCtrl.text.trim().isNotEmpty)
        _chipInfo('Modelo: ${_modelCtrl.text.trim()}', const Color(0xFF2A9D8F)),
      if (_maxPriceCtrl.text.trim().isNotEmpty)
        _chipInfo('Ate ${_money(_parseMoney(_maxPriceCtrl.text) ?? 0)}', const Color(0xFFE09F3E)),
      if (_maxKmCtrl.text.trim().isNotEmpty)
        _chipInfo('Ate ${_maxKmCtrl.text.trim()} km', const Color(0xFF6E7E85)),
      if (_minYearCtrl.text.trim().isNotEmpty)
        _chipInfo('Ano >= ${_minYearCtrl.text.trim()}', const Color(0xFF6E7E85)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Visao de resultados',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            DropdownButton<_OfferSort>(
              value: _sortBy,
              underline: const SizedBox.shrink(),
              items: _OfferSort.values
                  .map(
                    (value) => DropdownMenuItem<_OfferSort>(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _sortBy = value;
                  _offers = _sortOffers(_offers);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }

  Widget _chipInfo(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }

  InputDecoration _filterDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white12,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white),
      ),
    );
  }

  Widget _providerChip(String id, String label, bool enabled) {
    final selected = _selectedProviders.contains(id);
    return FilterChip(
      selected: selected,
      onSelected: enabled
          ? (value) {
              setState(() {
                if (value) {
                  _selectedProviders.add(id);
                } else {
                  _selectedProviders.remove(id);
                }
                if (_selectedProviders.isEmpty) {
                  _selectedProviders.add('mercadolivre');
                }
              });
            }
          : null,
      label: Text(label),
      selectedColor: const Color(0xFF197B47).withValues(alpha: 0.25),
      backgroundColor: Colors.white10,
      labelStyle: TextStyle(
        color: enabled ? Colors.white : Colors.white54,
        fontSize: 12,
      ),
      side: BorderSide(
        color: enabled ? Colors.white38 : Colors.white24,
      ),
    );
  }

  // ── Mapa com hotspots ────────────────────────────────────────────────────

  Widget _buildMapHotspots() {
    final center = _mapCenterForRegion(_regionCtrl.text);
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFE8F0F5),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 11.4,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.carscore.mobile_app',
                  ),
                  if (!_loading)
                    MarkerLayer(
                      markers: _buildMapMarkers(center),
                    ),
                ],
              ),
            ),
          ),

          // Contagem badge
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.store, size: 14, color: Color(0xFF124E78)),
                  const SizedBox(width: 6),
                  Text(
                    _loading
                        ? 'Carregando...'
                        : _offers.isEmpty
                            ? 'Nenhuma oferta'
                            : '${_offers.length} ofertas encontradas',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Mapa real (OpenStreetMap)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Badge de fonte (Mercado Livre / Base local)
          Positioned(
            bottom: 10,
            right: 10,
            child: _buildSourceBadge(
              _offers.isNotEmpty ? _offers.first.sourceName : 'Mercado Livre',
              _offers.isNotEmpty ? _offers.first.source : 'mercadolivre',
            ),
          ),

          // Hotspots sobre o mapa
          if (_loading)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 84),
                width: 220,
                height: 86,
                child: Column(
                  children: [
                    _skeletonBox(height: 26, radius: 999),
                    const SizedBox(height: 10),
                    _skeletonBox(height: 16, width: 160, radius: 999),
                  ],
                ),
              ),
            )
          else if (_offers.isEmpty)
            const Center(
              child: Text(
                'Sem pinos para os filtros atuais',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSourceBadge(String label, String source) {
    final color = source == 'mercadolivre'
        ? const Color(0xFF3483FA)
        : const Color(0xFF6E7E85);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.store, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  List<Marker> _buildMapMarkers(LatLng center) {
    final result = <Marker>[];
    final count = _offers.length.clamp(0, _mapOffsets.length);
    for (var i = 0; i < count; i++) {
      final offer = _offers[i];
      final offset = _mapOffsets[i];
      final point = LatLng(center.latitude + offset[0], center.longitude + offset[1]);
      final color = _dealColor(offer);
      final isSelected = offer.id == (_selectedId ?? '');

      result.add(
        Marker(
          point: point,
          width: 118,
          height: 42,
          child: GestureDetector(
            onTap: () => setState(() => _selectedId = offer.id),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
                border: isSelected ? Border.all(color: Colors.white, width: 2.2) : null,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isSelected ? 0.6 : 0.34),
                    blurRadius: isSelected ? 14 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                _money(offer.price),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
              ),
            ),
          ),
        ),
      );
    }
    return result;
  }

  LatLng _mapCenterForRegion(String input) {
    final q = input.toLowerCase();
    if (q.contains('sao paulo') || q.contains('sp')) return const LatLng(-23.5505, -46.6333);
    if (q.contains('rio de janeiro') || q.contains('rj')) return const LatLng(-22.9068, -43.1729);
    if (q.contains('belo horizonte') || q.contains('bh') || q.contains('mg')) return const LatLng(-19.9167, -43.9345);
    if (q.contains('curitiba') || q.contains('pr')) return const LatLng(-25.4284, -49.2733);
    if (q.contains('porto alegre') || q.contains('rs')) return const LatLng(-30.0346, -51.2177);
    if (q.contains('salvador') || q.contains('ba')) return const LatLng(-12.9777, -38.5016);
    if (q.contains('recife') || q.contains('pe')) return const LatLng(-8.0476, -34.8770);
    if (q.contains('brasilia') || q.contains('df')) return const LatLng(-15.7939, -47.8828);
    if (q.contains('fortaleza') || q.contains('ce')) return const LatLng(-3.7319, -38.5267);
    if (q.contains('goiania') || q.contains('go')) return const LatLng(-16.6869, -49.2648);
    return const LatLng(-23.5505, -46.6333);
  }

  // ── Card da oferta selecionada ────────────────────────────────────────────

  Widget _buildSelectedCard(MarketplaceOffer offer) {
    final color = _dealColor(offer);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagem do anuncio (thumbnail ML) ou Unsplash
          _buildOfferImage(offer, height: 170),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(offer.title,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (offer.year > 0) offer.year.toString(),
                              if (offer.km > 0) '${_money(offer.km)} km',
                              if (offer.city.isNotEmpty) offer.city,
                            ].join(' • '),
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Chip(
                          label: Text(_dealLabel(offer),
                              style: const TextStyle(fontSize: 11)),
                          backgroundColor:
                              color.withValues(alpha: 0.14),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(height: 4),
                        _buildSourceBadge(
                            offer.sourceName, offer.source),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: (offer.qualityScore.clamp(0, 100)) / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    offer.qualityScore >= 80
                        ? const Color(0xFF197B47)
                        : offer.qualityScore >= 60
                            ? const Color(0xFF2A9D8F)
                            : offer.qualityScore >= 40
                                ? const Color(0xFFE09F3E)
                                : const Color(0xFFC44536),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nota de oportunidade: ${offer.qualityScore}/100 (${_qualityLabel(offer.qualityScore)})',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _InfoMetric(
                        label: 'Preco pedido',
                        value: _money(offer.price),
                        accent: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoMetric(
                        label: 'Ref. FIPE*',
                        value: _money(offer.fipeEstimate),
                        accent: const Color(0xFF4C6A92),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoMetric(
                        label: 'Diferenca FIPE',
                        value:
                            '${offer.fipeDiff >= 0 ? '-' : '+'}${_money(offer.fipeDiff.abs())}',
                        accent: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '* Estimativa FIPE via base local. Para valor oficial, use "Buscar veiculo especifico".',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: offer.listingUrl.isNotEmpty
                            ? () => _openListing(offer.listingUrl)
                            : null,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Ver anuncio'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const VehicleSearchPage())),
                        icon: const Icon(Icons.analytics_outlined, size: 16),
                        label: const Text('Analisar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferImage(MarketplaceOffer offer, {double height = 100}) {
    if (offer.thumbnailUrl.isNotEmpty) {
      return Image.network(
        offer.thumbnailUrl,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _networkCarFallback(offer, height),
      );
    }
    return _networkCarFallback(offer, height);
  }

  Widget _networkCarFallback(MarketplaceOffer offer, double height) {
    final query = Uri.encodeComponent(
      '${offer.brand.isNotEmpty ? offer.brand : "car"} ${offer.model.isNotEmpty ? offer.model : offer.title} carro',
    );
    final curatedUrl = _curatedVehicleImageUrl(offer);
    return Image.network(
      curatedUrl,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Image.network(
        'https://source.unsplash.com/1200x700/?$query',
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: height,
          color: const Color(0xFFF0F4F8),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_car, size: 48, color: Color(0xFF8FA2AF)),
                const SizedBox(height: 8),
                Text(
                  offer.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF607D8B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Lista de ofertas ──────────────────────────────────────────────────────

  Widget _buildListHeader() {
    final belowFipe = _offers.where((o) => o.fipeDiff > 0).length;
    return Row(
      children: [
        const Expanded(
          child: Text('Todas as ofertas',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        if (!_loading && _offers.isNotEmpty)
          Text('$belowFipe abaixo da FIPE',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF197B47))),
      ],
    );
  }

  Widget _buildError() {
    return Card(
      color: const Color(0xFFFFF3F3),
      child: ListTile(
        leading:
            const Icon(Icons.wifi_off_rounded, color: Color(0xFFC44536)),
        title: const Text('Nao foi possivel carregar ofertas'),
        subtitle: const Text(
            'Verifique se o backend esta rodando e tente novamente.'),
        trailing: TextButton(
          onPressed: _loadOffers,
          child: const Text('Tentar'),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.travel_explore_outlined),
        title: Text('Nenhuma oferta para esta regiao'),
        subtitle: Text('Tente outra cidade ou estado.'),
      ),
    );
  }

  Widget _buildOfferCard(MarketplaceOffer offer) {
    final color = _dealColor(offer);
    final isSelected = offer.id == (_selectedId ?? '');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: isSelected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color, width: 2),
            )
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedId = offer.id),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: offer.thumbnailUrl.isNotEmpty
                      ? Image.network(offer.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                          _networkThumbFallback(offer))
                      : _networkThumbFallback(offer),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (offer.city.isNotEmpty)
                          offer.city
                        else
                          offer.region,
                        if (offer.km > 0) '${_money(offer.km)} km',
                        if (offer.year > 0) offer.year.toString(),
                      ].join(' • '),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _miniTag(offer.sourceName,
                            offer.source == 'mercadolivre'
                                ? const Color(0xFF3483FA)
                                : const Color(0xFF6E7E85)),
                        const SizedBox(width: 4),
                        _miniTag(
                            _dealLabel(offer),
                            color),
                        const SizedBox(width: 4),
                        _miniTag(
                          '${offer.qualityScore}/100',
                          const Color(0xFF124E78),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Preco
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(offer.price),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${offer.fipeDiff >= 0 ? '-' : '+'}${_money(offer.fipeDiff.abs())}',
                    style: TextStyle(
                      fontSize: 11,
                      color: offer.fipeDiff >= 0
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'FIPE ${_money(offer.fipeEstimate)}',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(Color color) {
    return Container(
      color: color.withValues(alpha: 0.1),
      child: Icon(Icons.directions_car, color: color),
    );
  }

  Widget _networkThumbFallback(MarketplaceOffer offer) {
    final query = Uri.encodeComponent(
      '${offer.brand.isNotEmpty ? offer.brand : "car"} ${offer.model.isNotEmpty ? offer.model : offer.title} carro',
    );
    final curatedUrl = _curatedVehicleImageUrl(offer);
    return Image.network(
      curatedUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Image.network(
        'https://source.unsplash.com/200x140/?$query',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _avatarFallback(_dealColor(offer)),
      ),
    );
  }

  String _curatedVehicleImageUrl(MarketplaceOffer offer) {
    final text = '${offer.brand} ${offer.model} ${offer.title}'.toLowerCase();

    if (text.contains('tracker')) {
      return 'https://images.unsplash.com/photo-1542282088-fe8426682b8f?auto=format&fit=crop&w=1200&q=80';
    }
    if (text.contains('corolla') || text.contains('civic') || text.contains('onix')) {
      return 'https://images.unsplash.com/photo-1493238792000-8113da705763?auto=format&fit=crop&w=1200&q=80';
    }
    if (text.contains('hilux') || text.contains('pickup')) {
      return 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=1200&q=80';
    }
    if (text.contains('creta') || text.contains('renegade') || text.contains('t-cross') || text.contains('suv')) {
      return 'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?auto=format&fit=crop&w=1200&q=80';
    }
    return 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=1200&q=80';
  }

  Widget _miniTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _qualityLabel(int score) {
    if (score >= 80) return 'Excelente';
    if (score >= 60) return 'Boa';
    if (score >= 40) return 'Neutra';
    return 'Ruim';
  }

  Widget _buildSelectedSkeleton() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _skeletonBox(height: 170, radius: 0),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _skeletonBox(height: 18, radius: 8),
                const SizedBox(height: 8),
                _skeletonBox(height: 12, width: 240, radius: 8),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _skeletonBox(height: 62, radius: 12)),
                    const SizedBox(width: 8),
                    Expanded(child: _skeletonBox(height: 62, radius: 12)),
                    const SizedBox(width: 8),
                    Expanded(child: _skeletonBox(height: 62, radius: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferSkeleton() {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            _skeletonBox(height: 72, width: 72, radius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonBox(height: 14, radius: 8),
                  const SizedBox(height: 6),
                  _skeletonBox(height: 11, width: 210, radius: 8),
                  const SizedBox(height: 7),
                  _skeletonBox(height: 10, width: 170, radius: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonBox({required double height, double? width, double radius = 12}) {
    return AnimatedBuilder(
      animation: _skeletonController,
      builder: (context, _) {
        final t = _skeletonController.value;
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              colors: [
                Color.lerp(const Color(0xFFE9EEF2), const Color(0xFFF3F6F9), t)!,
                Color.lerp(const Color(0xFFDCE4EA), const Color(0xFFE8EEF3), t)!,
                Color.lerp(const Color(0xFFE9EEF2), const Color(0xFFF3F6F9), t)!,
              ],
              stops: const [0.05, 0.45, 0.95],
              begin: Alignment(-1 + (2 * t), -1),
              end: Alignment(1 + (2 * t), 1),
            ),
          ),
        );
      },
    );
  }
}

class _RecentFilterPreset {
  const _RecentFilterPreset({
    required this.region,
    required this.brand,
    required this.model,
    required this.maxPrice,
    required this.maxKm,
    required this.minYear,
    required this.providers,
    required this.savedAtEpochMs,
  });

  final String region;
  final String brand;
  final String model;
  final String maxPrice;
  final String maxKm;
  final String minYear;
  final List<String> providers;
  final int savedAtEpochMs;

  bool get hasUsefulFilters =>
      region.isNotEmpty ||
      brand.isNotEmpty ||
      model.isNotEmpty ||
      maxPrice.isNotEmpty ||
      maxKm.isNotEmpty ||
      minYear.isNotEmpty ||
      providers.any((item) => item != 'mercadolivre');

  String get signature =>
      '$region|$brand|$model|$maxPrice|$maxKm|$minYear|${providers.join(',')}';

  String get shortLabel {
    final parts = <String>[];
    if (region.isNotEmpty) parts.add(region);
    if (brand.isNotEmpty) parts.add(brand);
    if (model.isNotEmpty) parts.add(model);
    if (minYear.isNotEmpty) parts.add('>= $minYear');
    if (maxPrice.isNotEmpty) parts.add('R\$ $maxPrice');
    if (parts.isEmpty) return 'Busca recente';
    return parts.take(3).join(' • ');
  }

  Map<String, dynamic> toJson() => {
        'region': region,
        'brand': brand,
        'model': model,
        'maxPrice': maxPrice,
        'maxKm': maxKm,
        'minYear': minYear,
        'providers': providers,
        'savedAtEpochMs': savedAtEpochMs,
      };

  factory _RecentFilterPreset.fromJson(Map<String, dynamic> json) {
    final rawProviders = json['providers'] as List<dynamic>? ?? const [];
    return _RecentFilterPreset(
      region: (json['region'] as String? ?? '').trim(),
      brand: (json['brand'] as String? ?? '').trim(),
      model: (json['model'] as String? ?? '').trim(),
      maxPrice: (json['maxPrice'] as String? ?? '').trim(),
      maxKm: (json['maxKm'] as String? ?? '').trim(),
      minYear: (json['minYear'] as String? ?? '').trim(),
      providers: rawProviders.map((item) => '$item').toList(),
      savedAtEpochMs: (json['savedAtEpochMs'] as num? ?? 0).toInt(),
    );
  }
}

enum _OfferSort {
  bestOpportunity('Melhor oportunidade'),
  lowestPrice('Menor preco'),
  lowestKm('Menor km'),
  newest('Mais novo');

  const _OfferSort(this.label);
  final String label;
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _InfoMetric extends StatelessWidget {
  const _InfoMetric(
      {required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}

