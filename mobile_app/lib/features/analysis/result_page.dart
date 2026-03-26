import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key, required this.result});

  final Map<String, dynamic> result;

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

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  Widget _pillarRow(String name, int score, String explanation) {
    final color = _scoreColor(score);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('$score', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 100.0,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(explanation, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pillars = result['pillars'] as Map<String, dynamic>? ?? {};
    final weights = result['weights'] as Map<String, dynamic>? ?? {};
    final finalScore = result['finalScore'] ?? 0;
    final label = result['label'] ?? '';
    final fuelMonthly = result['fuelMonthly'] ?? 0;
    final monthlyTotal = result['monthlyTotal'] ?? 0;

    final explanations = {
      'price': 'Compara o preço pedido com uma referência de mercado. Preços abaixo da referência aumentam o score.',
      'fuel': 'Estimativa do gasto mensal com combustível. Menor gasto = melhor score.',
      'maintenance': 'Estimativa de manutenção mensal. Menor manutenção = melhor score.',
      'adequacy': 'Adequação ao perfil (km/mês e eficiência).',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado da Análise')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Score: $finalScore', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Chip(label: Text(label.toString().replaceAll('_', ' ')), backgroundColor: _labelColor(label)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Custo combustível (mensal): R\$ ${fuelMonthly.toStringAsFixed(2)}'),
            Text('Custo total (mensal): R\$ ${monthlyTotal.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            const Text('Pilares', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _pillarRow('Preço', (pillars['priceScore'] ?? 0) as int, explanations['price']!),
            _pillarRow('Combustível', (pillars['fuelScore'] ?? 0) as int, explanations['fuel']!),
            _pillarRow('Manutenção', (pillars['maintenanceScore'] ?? 0) as int, explanations['maintenance']!),
            _pillarRow('Adequação', (pillars['adequacyScore'] ?? 0) as int, explanations['adequacy']!),
            const SizedBox(height: 12),
            const Text('Pesos', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(weights.toString()),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}
