import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessfr/features/analysis/geographic_king_safety_screen.dart';
import 'package:chessfr/features/analysis/widgets/carlsbad_matrix_visualizer.dart';

void main() {
  testWidgets('GeographicKingSafetyScreen builds and displays key components', (WidgetTester tester) async {
    // Set larger screen size for widget test
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;

    // Reset screen size on teardown
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Build the widget
    await tester.pumpWidget(
      const MaterialApp(
        home: GeographicKingSafetyScreen(),
      ),
    );

    // Verify Title and Subtitle are present
    expect(find.text('GEOGRAPHIC KING SAFETY MATRIX'), findsOneWidget);
    expect(find.text('Carlsbad Tabiya Field Analysis Unit'), findsOneWidget);

    // Verify visualizer widget is rendered
    expect(find.byType(CarlsbadMatrixVisualizer), findsOneWidget);

    // Verify Research sidebar contact info
    expect(find.text('Dawn Jones'), findsOneWidget);
    expect(find.text('Carlsbad Field Station Manager'), findsOneWidget);

    // Verify all modality action buttons are present
    expect(find.text('Modality A: Fortress'), findsOneWidget);
    expect(find.text('Modality B: Bait Hook'), findsOneWidget);
    expect(find.text('Modality C: Evacuation'), findsOneWidget);

    // Tap Modality B and pump a single frame to process state change without looping forever
    await tester.tap(find.text('Modality B: Bait Hook'));
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Modality C and pump a single frame
    await tester.tap(find.text('Modality C: Evacuation'));
    await tester.pump(const Duration(milliseconds: 100));
  });
}
