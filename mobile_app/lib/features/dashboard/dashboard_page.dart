import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiClient _api = ApiClient();
  bool _loading = false;
  String _healthText = 'Toque para validar conexão com a API';

  Future<void> _checkHealth() async {
    setState(() => _loading = true);
    try {
      final res = await _api.health();
      setState(() => _healthText = 'API online: ${res['status']} (${res['service']})');
    } catch (e) {
      setState(() => _healthText = 'Erro ao conectar na API: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CarScore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resumo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Use a aba Análise para simular compra de carro usado com score por pilares.'),
                  const SizedBox(height: 8),
                  Text(_healthText),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _checkHealth,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.health_and_safety_outlined),
                    label: const Text('Checar API (/health)'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Próximo passo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text('Abra a aba Análise para preencher os dados do veículo e visualizar o resultado com score 0-100.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
