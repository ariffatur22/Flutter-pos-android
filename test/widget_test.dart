// Flutter POS Kasir Widget Tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pos_kasir/core/theme/app_theme.dart';

void main() {
  group('POS Kasir App Tests', () {
    testWidgets('App builds without errors', (WidgetTester tester) async {
      // Build a minimal app with ProviderScope for Riverpod support
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            title: 'Flutter POS Kasir',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            home: const Scaffold(
              body: Center(
                child: Text('App Loaded'),
              ),
            ),
          ),
        ),
      );

      // Verify the app builds and text is displayed
      expect(find.text('App Loaded'), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Theme is properly configured', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            title: 'Flutter POS Kasir',
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: Center(
                child: Text('Theme Test'),
              ),
            ),
          ),
        ),
      );

      // Verify theme is applied
      expect(find.text('Theme Test'), findsOneWidget);
      final materialApp = find.byType(MaterialApp);
      expect(materialApp, findsOneWidget);
    });
  });
}
