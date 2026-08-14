import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:focus_flow/features/today/today_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('TodayScreen renders header and empty state cleanly', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TodayScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining("Today's Progress"), findsOneWidget);
    expect(find.textContaining("Streak"), findsOneWidget);
  });
}
