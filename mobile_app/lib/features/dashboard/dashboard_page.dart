import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../analysis/vehicle_search_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _api = ApiClient();
  final _regionCtrl = TextEditingController(text: 'Sao Paulo');
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();
  final _maxKmCtrl = TextEditingController();

  List<MarketplaceOffer> _offers = [];
  bool _loading = false;
  bool _showFilters = false;
  String? _error;
  String? _selectedId;

  // Posições fixas no mapa para até 8 hotspots
  static const _hotspotPositions = [
    [0.18, 0.22],
    [0.55, 0.18],
    [0.74, 0.44],
    [0.38, 0.62],
    [0.64, 0.72],
    [0.22, 0.68],
    [0.82, 0.28],
    [0.46, 0.40],
  ];

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  @override
  void dispose() {
    _regionCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _maxPriceCtrl.dispose();
    _maxKmCtrl.dispose();
    super.dispose();
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
      );
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _selectedId = offers.isNotEmpty ? offers.first.id : null;
        _loading = false;
      });
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
              onPressed: _loadOffers,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOffers,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSearchHeader(),
            const SizedBox(height: 16),
            _buildMapHotspots(),
            const SizedBox(height: 16),
            if (_selected != null) _buildSelectedCard(_selected!),
            const SizedBox(height: 8),
            _buildListHeader(),
            const SizedBox(height: 8),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (!_loading && _error != null) _buildError(),
            if (!_loading && _error == null && _offers.isEmpty) _buildEmpty(),
            if (!_loading && _error == null)
              ..._offers.map((offer) => _buildOfferCard(offer)),
            const SizedBox(height: 24),
          ],
        ),
      ),
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
                  _maxKmCtrl.text.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _brandCtrl.clear();
                      _modelCtrl.clear();
                      _maxPriceCtrl.clear();
                      _maxKmCtrl.clear();
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

  // ── Mapa com hotspots ────────────────────────────────────────────────────

  Widget _buildMapHotspots() {
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
              child: CustomPaint(painter: _MapPainter()),
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
          if (!_loading)
            ..._buildHotspotWidgets(),
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

  List<Widget> _buildHotspotWidgets() {
    final result = <Widget>[];
    final count = _offers.length.clamp(0, _hotspotPositions.length);
    for (var i = 0; i < count; i++) {
      final offer = _offers[i];
      final pos = _hotspotPositions[i];
      final color = _dealColor(offer);
      final isSelected = offer.id == (_selectedId ?? '');

      result.add(
        Positioned(
          left: (pos[0] * 290).clamp(4.0, 260.0),
          top: (pos[1] * 248).clamp(36.0, 224.0),
          child: GestureDetector(
            onTap: () => setState(() => _selectedId = offer.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 2.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isSelected ? 0.6 : 0.35),
                    blurRadius: isSelected ? 18 : 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Text(
                _money(offer.price),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11),
              ),
            ),
          ),
        ),
      );
    }
    return result;
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
                        label: 'Diferenca',
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
        errorBuilder: (_, _, _) => _unsplashFallback(offer, height),
      );
    }
    return _unsplashFallback(offer, height);
  }

  Widget _unsplashFallback(MarketplaceOffer offer, double height) {
    final query = Uri.encodeComponent(
        '${offer.brand.isNotEmpty ? offer.brand : "car"} ${offer.model}');
    return Image.network(
      'https://source.unsplash.com/400x${height.round()}/?$query,carro,usado',
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        height: height,
        color: const Color(0xFFF0F4F8),
        child: const Center(
            child: Icon(Icons.directions_car,
                size: 48, color: Color(0xFFB0BEC5))),
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
                              _avatarFallback(color))
                      : _avatarFallback(color),
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

// ── Mapa estilo cartografia ────────────────────────────────────────────────────

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFDDE9F0));

    final road = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    final secondary = Paint()
      ..color = const Color(0xFFBED0DA)
      ..strokeWidth = 2;
    final park = Paint()..color = const Color(0xFFB8D8BA);
    final water = Paint()..color = const Color(0xFFB7DDF2);

    canvas.drawLine(Offset(size.width * 0.08, size.height * 0.22),
        Offset(size.width * 0.92, size.height * 0.18), road);
    canvas.drawLine(Offset(size.width * 0.18, size.height * 0.12),
        Offset(size.width * 0.76, size.height * 0.88), road);
    canvas.drawLine(Offset(size.width * 0.1, size.height * 0.7),
        Offset(size.width * 0.88, size.height * 0.58), road);
    for (var i = 0; i < 6; i++) {
      canvas.drawLine(Offset(0, size.height * (0.15 + i * 0.13)),
          Offset(size.width, size.height * (0.15 + i * 0.13)), secondary);
    }
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.68, size.height * 0.08, 72, 46),
            const Radius.circular(14)),
        park);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.12, size.height * 0.72, 82, 52),
            const Radius.circular(14)),
        park);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.72, size.height * 0.58, 90, 58),
            const Radius.circular(18)),
        water);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
