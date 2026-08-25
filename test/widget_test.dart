import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pcremote/main.dart';
import 'package:pcremote/providers/app_providers.dart';
import 'package:pcremote/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  testWidgets('PCRemote initial smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();
    final storageService = StorageService(prefs, secureStorage);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
        ],
        child: const PCRemoteApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Check that onboarding screen or pairing screen rendered
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
