import 'package:flutter/material.dart';

class PartsDetailPage extends StatelessWidget {
  const PartsDetailPage({
    super.key,
    required this.partsResult,
    required this.vehicleLabel,
    required this.year,
  });

  final Map<String, dynamic> partsResult;
  final String vehicleLabel;
  final int year;

  Color _confidenceColor(String confidence) {
    switch (confidence) {
      case 'Confianca alta':
        return Colors.green;
      case 'Confianca media':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _resolveConfidence({
    required int quotes,
    required bool fallback,
  }) {
    if (fallback || quotes < 20) return 'Confianca baixa';
    if (quotes < 40) return 'Confianca media';
    return 'Confianca alta';
  }

  @override
  Widget build(BuildContext context) {
    final basket = (partsResult['basket'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final sourceDetails = Map<String, dynamic>.from(
      partsResult['sourceDetails'] as Map? ?? const <String, dynamic>{},
    );
    final quotes = (sourceDetails['marketQuotesUsed'] as num? ?? 0).toInt();
    final fallback = sourceDetails['fallbackUsed'] == true;
    final confidence = _resolveConfidence(quotes: quotes, fallback: fallback);
    final confidenceColor = _confidenceColor(confidence);

    final annual = (partsResult['annualPartsCost'] as num? ?? 0).toDouble();
    final monthly = (partsResult['monthlyPartsCost'] as num? ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe de pecas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$vehicleLabel ($year)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text('Custo anual estimado: R\$ ${annual.toStringAsFixed(2)}'),
                  Text('Custo mensal estimado: R\$ ${monthly.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Confianca da cotacao: '),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: confidenceColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          confidence,
                          style: TextStyle(
                            color: confidenceColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text('Amostra usada: $quotes cotacoes'),
                  const SizedBox(height: 6),
                  const Text(
                    'Valores de pecas sao faixas estimadas e podem variar por regiao, fornecedor e disponibilidade.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Comparativo por faixa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (basket.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Sem dados de pecas para detalhar'),
              ),
            )
          else
            ...basket.map((item) {
              final label = (item['label'] ?? '-').toString();
              final min = (item['minPrice'] as num? ?? 0).toDouble();
              final avg = (item['avgPrice'] as num? ?? 0).toDouble();
              final max = (item['maxPrice'] as num? ?? 0).toDouble();
              final annualCost = (item['annualCostEstimate'] as num? ?? 0).toDouble();

              final range = (max - min).abs();
              final progress = range > 0 ? ((avg - min) / range).clamp(0.0, 1.0) : 0.5;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('Min: R\$ ${min.toStringAsFixed(2)}'),
                      Text('Medio: R\$ ${avg.toStringAsFixed(2)}'),
                      Text('Max: R\$ ${max.toStringAsFixed(2)}'),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Impacto anual estimado: R\$ ${annualCost.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
