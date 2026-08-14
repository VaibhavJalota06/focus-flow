import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:focus_flow/features/navigation/main_navigation_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Integration flow: MainNavigation renders and supports tab switching', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainNavigationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Today screen is initial view
    expect(find.text('Daily Dashboard'), findsOneWidget);

    // Tap Tasks Tab
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(find.text('All Tasks'), findsWidgets);

    // Tap Calendar Tab
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('Calendar Schedule'), findsOneWidget);

    // Tap Focus Tab
    await tester.tap(find.text('Focus'));
    await tester.pumpAndSettle();
    expect(find.text('Focus Mode'), findsWidgets);

    // Tap Analytics Tab
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Analytics & Streaks'), findsOneWidget);
  });
}
