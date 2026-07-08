import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:driver/main.dart';

/// In-memory stand-in for the PKCE token storage so tests don't hit the
/// shared_preferences plugin channel (unavailable under `flutter test`).
class _InMemoryGotrueAsyncStorage extends GotrueAsyncStorage {
  final _store = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _store[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _store[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async => _store.remove(key);
}

void main() {
  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _InMemoryGotrueAsyncStorage(),
      ),
    );
  });

  testWidgets('DriverApp shows the login screen when signed out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DriverApp());
    await tester.pump();

    expect(find.text('Driver App'), findsWidgets);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
