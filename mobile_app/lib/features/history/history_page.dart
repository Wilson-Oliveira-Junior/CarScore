import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  final List<Map<String, Object>> _parts = [
    {
      'name': 'Pastilha de freio dianteira',
      'vehicle': 'Corolla 2020',
      'price': 420.0,
      'store': 'AutoPecas Centro',
      'updatedAt': '30/03/2026 16:50',
    },
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _addPart() async {
    final nameCtrl = TextEditingController();
    final vehicleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final storeCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova peca monitorada'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome da peca'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: vehicleCtrl,
                decoration: const InputDecoration(labelText: 'Veiculo alvo'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Preco atual (R\$)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: storeCtrl,
                decoration: const InputDecoration(labelText: 'Loja / fornecedor'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final parsedPrice = double.tryParse(priceCtrl.text.replaceAll(',', '.'));
    if (nameCtrl.text.trim().isEmpty ||
        vehicleCtrl.text.trim().isEmpty ||
        parsedPrice == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome, veiculo e preco valido.')),
      );
      return;
    }

    String two(int v) => v.toString().padLeft(2, '0');
    final now = DateTime.now();
    final updatedAt =
        '${two(now.day)}/${two(now.month)}/${now.year} ${two(now.hour)}:${two(now.minute)}';

    setState(() {
      _parts.insert(0, {
        'name': nameCtrl.text.trim(),
        'vehicle': vehicleCtrl.text.trim(),
        'price': parsedPrice,
        'store': storeCtrl.text.trim().isEmpty ? 'Nao informado' : storeCtrl.text.trim(),
        'updatedAt': updatedAt,
      });
    });
  }

  Widget _carsTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Erro ao carregar historico'),
              subtitle: Text(_error!),
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Sem analises salvas'),
              subtitle: Text('Faça uma analise na aba Analise para preencher este historico.'),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final label = item['label'].toString();
        final prettyLabel = label.replaceAll('_', ' ');
        final score = item['finalScore'];
        final monthly = item['monthlyTotal'];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _labelColor(label).withValues(alpha: 0.15),
              foregroundColor: _labelColor(label),
              child: Text('$score'),
            ),
            title: Text('${item['vehicleLabel']} (${item['year']})'),
            subtitle: Text('Custo mensal: R\$ ${(monthly as num).toStringAsFixed(2)}'),
            trailing: Chip(
              label: Text(prettyLabel),
              backgroundColor: _labelColor(label).withValues(alpha: 0.15),
            ),
          ),
        );
      },
    );
  }

  Widget _partsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monitor de pecas',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Acompanhe preco de pecas criticas para negociar melhor na compra e planejar manutencao.',
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _addPart,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar peca'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_parts.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.build_outlined),
              title: Text('Sem pecas monitoradas'),
              subtitle: Text('Adicione itens como filtro, pneu, bateria e freios.'),
            ),
          ),
        ..._parts.map(
          (part) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.build_outlined)),
              title: Text(part['name'] as String),
              subtitle: Text(
                '${part['vehicle']} • ${part['store']}\nAtualizado em ${part['updatedAt']}',
              ),
              isThreeLine: true,
              trailing: Text(
                'R\$ ${(part['price'] as double).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.history(limit: 30);
      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _labelColor(String label) {
    switch (label) {
      case 'compra_saudavel':
        return Colors.green;
      case 'viavel_com_atencao':
        return Colors.orange;
      case 'alto_custo_para_perfil':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historico'),
          actions: [
            IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.directions_car), text: 'Carros'),
              Tab(icon: Icon(Icons.build_outlined), text: 'Pecas'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: TabBarView(
            children: [
              _carsTab(),
              _partsTab(),
            ],
          ),
        ),
      ),
    );
  }
}
