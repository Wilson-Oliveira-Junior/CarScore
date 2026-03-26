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
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
