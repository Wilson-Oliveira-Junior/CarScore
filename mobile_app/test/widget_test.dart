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

    await tester.pumpWidget(MaterialApp(home: ResultPage(result: result)));

    expect(find.text('Score: 68'), findsOneWidget);
    expect(find.text('Preço'), findsOneWidget);
    expect(find.text('Combustível'), findsOneWidget);
    expect(find.text('Manutenção'), findsOneWidget);
    expect(find.text('Adequação'), findsOneWidget);
  });
}
