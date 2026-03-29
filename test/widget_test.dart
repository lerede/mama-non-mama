import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mama_non_mama/main.dart';

void main() {
  testWidgets('App renders title', (WidgetTester tester) async {
    await tester.pumpWidget(const MamaNonMamaApp());

    expect(find.text("M'ama Non M'ama"), findsOneWidget);
  });

  testWidgets('START button is visible before game starts',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MamaNonMamaApp());

    expect(find.text('INIZIA 🌸'), findsOneWidget);
  });

  testWidgets('FlowerPainter renders without throwing',
      (WidgetTester tester) async {
    final petals = List.generate(
      13,
      (i) => PetalInfo(
        2 * 3.14159 * i / 13,
        windAmplitude: 18,
        windFrequency: 2.2,
        windPhase: 0,
        windDrift: 22,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            size: const Size(300, 400),
            painter: FlowerPainter(petals: petals),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
