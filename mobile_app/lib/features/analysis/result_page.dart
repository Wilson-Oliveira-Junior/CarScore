import 'package:flutter/material.dart';
import 'parts_detail_page.dart';

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

  String _statusText(String label) {
    switch (label) {
      case 'compra_saudavel':
        return 'Compra saudavel';
      case 'viavel_com_atencao':
        return 'Compra com ressalvas';
      case 'alto_custo_para_perfil':
        return 'Atencao ao custo total';
      default:
        return 'Nao recomendado';
    }
  }

  String _statusBadge(String label) {
    switch (label) {
      case 'compra_saudavel':
        return '✅ Compra saudavel';
      case 'viavel_com_atencao':
        return '⚠️ Compra com ressalvas';
      case 'alto_custo_para_perfil':
        return '⚠️ Atencao ao custo';
      default:
        return '❌ Nao recomendado';
    }
  }

  List<String> _negativeDrivers({
    required int priceScore,
    required int fuelScore,
    required int maintenanceScore,
    required int partsScore,
    required double fuelMonthly,
    required bool partsFallbackUsed,
    required int marketQuotesUsed,
    double? fipeDiffPct,
  }) {
    final issues = <String>[];
    if (fipeDiffPct != null && fipeDiffPct > 8) {
      issues.add('Preco acima da referencia FIPE (+${fipeDiffPct.toStringAsFixed(1)}%).');
    } else if (priceScore < 45) {
      issues.add('Preco acima da media esperada para o que entrega.');
    }
    if (fuelScore < 45 || fuelMonthly > 700) {
      issues.add('Custo de combustivel elevado para seu perfil de uso.');
    }
    if (maintenanceScore < 45) {
      issues.add('Manutencao mensal estimada acima do ideal.');
    }
    if (partsScore < 55) {
      issues.add('Pecas com custo acima da categoria (faixa estimada).');
    }
    if (partsFallbackUsed || marketQuotesUsed < 20) {
      issues.add('Confianca da cotacao de pecas limitada no momento.');
    }
    return issues;
  }

  List<String> _positiveDrivers({
    required int priceScore,
    required int fuelScore,
    required int maintenanceScore,
    required int adequacyScore,
    required int partsScore,
    required bool partsFallbackUsed,
    required int marketQuotesUsed,
    double? fipeDiffPct,
  }) {
    final positives = <String>[];
    if (fipeDiffPct != null && fipeDiffPct < -5) {
      positives.add('Preco abaixo da referencia FIPE (${fipeDiffPct.toStringAsFixed(1)}%).');
    } else if (priceScore >= 70) {
      positives.add('Preco competitivo frente ao mercado.');
    }
    if (fuelScore >= 70) {
      positives.add('Custo de combustivel favoravel para o uso informado.');
    }
    if (maintenanceScore >= 70) {
      positives.add('Manutencao previsivel para o perfil de uso.');
    }
    if (partsScore >= 70) {
      positives.add('Boa disponibilidade/custo de pecas em faixa estimada.');
    }
    if (!partsFallbackUsed && marketQuotesUsed >= 40) {
      positives.add('Boa confianca de cotacao de pecas pela amostra coletada.');
    }
    if (adequacyScore >= 70) {
      positives.add('Boa adequacao ao seu perfil de rodagem.');
    }
    return positives;
  }

  ({String label, Color color}) _partsConfidence({
    required int marketQuotesUsed,
    required bool fallbackUsed,
  }) {
    if (fallbackUsed || marketQuotesUsed < 20) {
      return (label: 'Confianca baixa', color: Colors.red);
    }
    if (marketQuotesUsed < 40) {
      return (label: 'Confianca media', color: Colors.orange);
    }
    return (label: 'Confianca alta', color: Colors.green);
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
    final hasCombined = result['car'] is Map<String, dynamic>;
    final carResult = hasCombined
      ? Map<String, dynamic>.from(result['car'] as Map)
      : result;
    final partsResult = hasCombined
      ? Map<String, dynamic>.from(result['parts'] as Map? ?? const <String, dynamic>{})
      : null;
    final combinedResult = hasCombined
      ? Map<String, dynamic>.from(result['combined'] as Map? ?? const <String, dynamic>{})
      : null;

    final pillars = carResult['pillars'] as Map<String, dynamic>? ?? {};
    final weights = carResult['weights'] as Map<String, dynamic>? ?? {};
    final partsSource = partsResult?['source'] as String? ?? 'N/A';
    final partsSourceLabel = partsSource == 'mercadolivre_blended_v1'
        ? 'Mercado Livre + fallback local'
        : partsSource == 'local_seed_v1'
            ? 'Base local de peças'
            : partsSource;
    final finalScore =
      (combinedResult != null ? combinedResult['score'] : carResult['finalScore']) ?? 0;
    final label =
      (combinedResult != null ? combinedResult['label'] : carResult['label']) ?? '';
    final fuelMonthly = (carResult['fuelMonthly'] as num? ?? 0).toDouble();
    final monthlyTotal = (carResult['monthlyTotal'] as num? ?? 0).toDouble();
    final carScore = ((carResult['finalScore'] as num?) ?? 0).toInt();
    final partsScore = ((partsResult?['partsScore'] as num?) ?? 0).toInt();
    final priceScore = ((pillars['priceScore'] as num?) ?? 0).toInt();
    final fuelScore = ((pillars['fuelScore'] as num?) ?? 0).toInt();
    final maintenanceScore = ((pillars['maintenanceScore'] as num?) ?? 0).toInt();
    final adequacyScore = ((pillars['adequacyScore'] as num?) ?? 0).toInt();
    final sourceDetails = Map<String, dynamic>.from(partsResult?['sourceDetails'] as Map? ?? const {});
    final marketQuotesUsed = (sourceDetails['marketQuotesUsed'] as num? ?? 0).toInt();
    final partsFallbackUsed = sourceDetails['fallbackUsed'] == true;
    final confidence = _partsConfidence(
      marketQuotesUsed: marketQuotesUsed,
      fallbackUsed: partsFallbackUsed,
    );

    final referencePrice = fipeReferencePrice ??
        ((carResult['meta'] as Map<String, dynamic>?)?['referencePrice'] as num?)?.toDouble();
    final fipeDiffPct = referencePrice != null && referencePrice > 0
        ? ((askedPrice - referencePrice) / referencePrice) * 100
        : null;

    final negatives = _negativeDrivers(
      priceScore: priceScore,
      fuelScore: fuelScore,
      maintenanceScore: maintenanceScore,
      partsScore: partsScore,
      fuelMonthly: fuelMonthly,
      partsFallbackUsed: partsFallbackUsed,
      marketQuotesUsed: marketQuotesUsed,
      fipeDiffPct: fipeDiffPct,
    );
    final positives = _positiveDrivers(
      priceScore: priceScore,
      fuelScore: fuelScore,
      maintenanceScore: maintenanceScore,
      adequacyScore: adequacyScore,
      partsScore: partsScore,
      partsFallbackUsed: partsFallbackUsed,
      marketQuotesUsed: marketQuotesUsed,
      fipeDiffPct: fipeDiffPct,
    );

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

            Card(
              color: _labelColor(label).withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: ${(finalScore as num).toInt()} / 100',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _statusBadge(label.toString()),
                      style: TextStyle(
                        color: _labelColor(label.toString()),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Veredito: ${_statusText(label.toString())}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Diagnostico rapido',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (negatives.isEmpty)
                      const Text('Sem alertas criticos no momento.')
                    else
                      ...negatives.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('↓ $item'),
                          )),
                    const SizedBox(height: 8),
                    if (positives.isNotEmpty)
                      ...positives.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('↑ $item'),
                          )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Como os dados foram usados',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Preço: referência FIPE ${referencePrice != null ? 'disponível' : 'não disponível'}.'),
                    Text('Pecas: $partsSourceLabel.'),
                    Text('Confiança de peças: ${confidence.label}.'),
                    if (combinedResult != null)
                      Text(
                        'Peso combinado: ${(combinedResult['weights']?['car'] * 100).toInt()}% carro / ${(combinedResult['weights']?['parts'] * 100).toInt()}% peças.',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            _thermometer(context, finalScore as int),
            const SizedBox(height: 14),

            if (combinedResult != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Score combinado (decisao final)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text('Carro: $carScore'),
                      Text('Pecas: $partsScore'),
                      const SizedBox(height: 4),
                      Text(
                        'Pesos: carro ${(combinedResult['weights']?['car'] ?? 0).toString()} | pecas ${(combinedResult['weights']?['parts'] ?? 0).toString()}',
                      ),
                    ],
                  ),
                ),
              ),
            if (combinedResult != null) const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resumo financeiro e referencia',
                        style:
                            TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Preco pedido: R\$ ${askedPrice.toStringAsFixed(2)}'),
                    if (referencePrice != null)
                      Text(
                        'Referencia FIPE: R\$ ${referencePrice.toStringAsFixed(2)}',
                      ),
                    if (fipeDiffPct != null)
                      Text(
                        'Diferenca vs FIPE: ${fipeDiffPct >= 0 ? '+' : ''}${fipeDiffPct.toStringAsFixed(1)}%',
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
            const Text('Breakdown tecnico (detalhado)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _pillarRow('Preço', (pillars['priceScore'] ?? 0) as int, explanations['price']!),
            _pillarRow('Combustível', (pillars['fuelScore'] ?? 0) as int, explanations['fuel']!),
            _pillarRow('Manutenção', (pillars['maintenanceScore'] ?? 0) as int, explanations['maintenance']!),
            _pillarRow('Adequação', (pillars['adequacyScore'] ?? 0) as int, explanations['adequacy']!),
            if (partsResult != null) const SizedBox(height: 12),
            if (partsResult != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Risco de pecas',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Score de pecas: $partsScore'),
                      Text(
                        'Faixa estimada de custo anual: R\$ ${((partsResult['annualPartsCost'] as num?) ?? 0).toStringAsFixed(2)}',
                      ),
                      Text(
                        'Faixa estimada de custo mensal: R\$ ${((partsResult['monthlyPartsCost'] as num?) ?? 0).toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 4),
                      Text('Label: ${partsResult['label'] ?? '-'}'),
                      if (partsResult['source'] != null)
                        Text('Fonte de preco: ${partsResult['source']}'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('Confianca da cotacao: '),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: confidence.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              confidence.label,
                              style: TextStyle(
                                color: confidence.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text('Amostra usada: $marketQuotesUsed cotacoes.'),
                      const SizedBox(height: 4),
                      const Text(
                        'Valores de pecas sao referencias estimadas e podem variar por regiao, fornecedor e disponibilidade.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      if ((partsResult['outlierParts'] as List<dynamic>? ?? []).isNotEmpty)
                        Text(
                          'Pecas fora da curva: ${(partsResult['outlierParts'] as List<dynamic>).join(', ')}',
                        ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PartsDetailPage(
                                partsResult: partsResult,
                                vehicleLabel: vehicleLabel,
                                year: year,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.tune_outlined),
                        label: const Text('Ver detalhe de pecas'),
                      ),
                    ],
                  ),
                ),
              ),
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
