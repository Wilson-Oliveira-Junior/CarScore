import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/analysis/result_page.dart';

void main() {
  testWidgets('ResultPage renders pillars and score', (WidgetTester tester) async {
    final result = {
      'fuelMonthly': 120.5,
      'monthlyTotal': 220.5,
      'pillars': {
        'priceScore': 70,
        'fuelScore': 60,
        'maintenanceScore': 80,
        'adequacyScore': 50,
      },
      'weights': {'price': 0.4, 'fuel': 0.25, 'maintenance': 0.2, 'adequacy': 0.15},
      'finalScore': 68,
      'label': 'viavel_com_atencao',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          result: result,
          vehicleLabel: 'Honda Civic',
          year: 2020,
          imageUrl: 'https://example.com/car.jpg',
          askedPrice: 89000,
          kmPerLiter: 12.5,
          updatedAt: '30/03/2026 17:30',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Score: 68 / 100'), findsOneWidget);
    expect(find.text('Diagnostico rapido'), findsOneWidget);
    expect(find.text('Termometro de qualidade da compra', skipOffstage: false), findsOneWidget);
    expect(find.text('Resumo financeiro e referencia', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('Preco pedido', skipOffstage: false), findsOneWidget);
  });
}
