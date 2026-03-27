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

  @override
  void initState() {
    super.initState();
    _load();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.error_outline),
                          title: const Text('Erro ao carregar histórico'),
                          subtitle: Text(_error!),
                        ),
                      ),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(16),
                        children: const [
                          Card(
                            child: ListTile(
                              leading: Icon(Icons.info_outline),
                              title: Text('Sem análises salvas'),
                              subtitle: Text('Faça uma análise na aba Análise para preencher este histórico.'),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
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
                      ),
      ),
    );
  }
}
