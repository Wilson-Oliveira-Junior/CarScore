import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/features/analysis/analysis_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AnalysisPage shows validation error when vehicle model is blank',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: AnalysisPage(),
      ),
    );

    await tester.pumpAndSettle();

    final modelField = find.byType(TextFormField).first;

    expect(modelField, findsOneWidget);
    expect(find.text('Diagnostico de compra'), findsOneWidget);
  });
}
