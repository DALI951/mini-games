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
    expect(find.text('GAMEPLAY'), findsOneWidget);
    expect(find.text('Haptics'), findsOneWidget);
    expect(find.text('Result screens'), findsOneWidget);

    // Sections further down need scrolling into view.
    await tester.scrollUntilVisible(
      find.text('UPDATES'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('UPDATES'), findsOneWidget);
    expect(find.text('Check for updates'), findsOneWidget);
  });

  testWidgets('result screens toggle flips and persists', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pump();

    // Switches are: [haptics, resultScreens]. Both on by default.
    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(2));
    expect(tester.widget<Switch>(switches.at(1)).value, isTrue);

    // Tap the Result screens switch (index 1).
    await tester.tap(switches.at(1));
    await tester.pump();
    expect(tester.widget<Switch>(switches.at(1)).value, isFalse);
    expect(Prefs.showResultScreens, isFalse);
  });
}
