import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minigames/screens/settings.dart';
import 'package:minigames/services/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Prefs.debugReset();
    await Prefs.init();
  });

  testWidgets('settings screen renders core sections', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pump();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('HIGH SCORES'), findsOneWidget);
    expect(find.text('UPDATES'), findsOneWidget);
    expect(find.text('Check for updates'), findsOneWidget);
    expect(find.text('Haptics'), findsOneWidget);
  });

  testWidgets('haptics toggle flips', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pump();

    final toggle = find.byType(Switch);
    expect(toggle, findsOneWidget);

    await tester.tap(toggle);
    await tester.pump();
    expect(tester.widget<Switch>(toggle).value, isFalse);
  });
}
