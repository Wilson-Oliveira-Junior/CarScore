import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({
    super.key,
    required this.result,
    required this.vehicleLabel,
    required this.year,
    required this.imageUrl,
    required this.askedPrice,
    required this.kmPerLiter,
    required this.updatedAt,
    this.fuelType,
    this.fipeReferencePrice,
  });

  final Map<String, dynamic> result;
  final String vehicleLabel;
  final int year;
  final String imageUrl;
  final double askedPrice;
  final double kmPerLiter;
  final String updatedAt;
  final String? fuelType;
  final double? fipeReferencePrice;

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

  Widget _thermometer(BuildContext context, int score) {
    final pct = score.clamp(0, 100).toDouble() / 100.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final markerX = (width - 24) * pct;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Termometro de qualidade da compra',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFD7263D),
                        Color(0xFFF4A261),
                        Color(0xFF2A9D8F),
                        Color(0xFF2E7D32),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: markerX,
                  top: -6,
                  child: Container(
                    width: 24,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _scoreColor(score), width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$score',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _scoreColor(score),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Risco alto', style: TextStyle(fontSize: 12)),
                Text('Compra saudavel', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        );
      },
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
        child: ListView(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => Container(
                  height: 180,
                  color: const Color(0xFFE8EEF2),
                  alignment: Alignment.center,
                  child: const Icon(Icons.directions_car, size: 64),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$vehicleLabel ($year)',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Atualizado em $updatedAt',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(label.toString().replaceAll('_', ' ')),
                  backgroundColor: _labelColor(label).withValues(alpha: 0.18),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _thermometer(context, finalScore as int),
            const SizedBox(height: 14),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resumo financeiro',
                        style:
                            TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Preco pedido: R\$ ${askedPrice.toStringAsFixed(2)}'),
                    if (fipeReferencePrice != null)
                      Text(
                        'Referencia FIPE: R\$ ${fipeReferencePrice!.toStringAsFixed(2)}',
                      ),
                    Text('Consumo informado: ${kmPerLiter.toStringAsFixed(1)} km/l'),
                    if (fuelType != null)
                      Text('Combustivel: $fuelType'),
                    const Divider(height: 20),
                    Text(
                        'Custo combustivel (mensal): R\$ ${fuelMonthly.toStringAsFixed(2)}'),
                    Text('Custo total (mensal): R\$ ${monthlyTotal.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Pilares', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _pillarRow('Preço', (pillars['priceScore'] ?? 0) as int, explanations['price']!),
            _pillarRow('Combustível', (pillars['fuelScore'] ?? 0) as int, explanations['fuel']!),
            _pillarRow('Manutenção', (pillars['maintenanceScore'] ?? 0) as int, explanations['maintenance']!),
            _pillarRow('Adequação', (pillars['adequacyScore'] ?? 0) as int, explanations['adequacy']!),
            const SizedBox(height: 12),
            const Text('Pesos usados no calculo', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(weights.toString()),
            const SizedBox(height: 10),
            const Text(
              'Fontes e atualizacao',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              fipeReferencePrice != null
                  ? 'Preco: FIPE em tempo real • Consumo: Inmetro/PBE • Analise gerada em $updatedAt'
                  : 'Preco: heuristico (sem FIPE no momento) • Consumo: valor informado • Analise gerada em $updatedAt',
            ),
            const SizedBox(height: 16),
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
