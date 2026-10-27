import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_health_food/main.dart';
import 'package:smart_health_food/screens/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Provide an in-memory SharedPreferences implementation for testing.
    SharedPreferences.setMockInitialValues({});

    await Supabase.initialize(
      url: kSupabaseUrl,
      anonKey: kSupabaseAnonKey,
    );
  });

  testWidgets('app boots and shows login when unauthenticated', (tester) async {
    await tester.pumpWidget(const SmartHealthFoodApp());
    await tester.pump();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
