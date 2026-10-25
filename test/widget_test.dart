import 'package:flutter_test/flutter_test.dart';
import 'package:smart_health_food/main.dart';

void main() {
  testWidgets('app boots', (tester) async {
    await tester.pumpWidget(const SmartHealthFoodApp());

    // Smoke test: at least one of the navigation labels should exist.
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
  });
}
