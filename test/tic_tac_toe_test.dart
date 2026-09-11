import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minigames/games/tic_tac_toe.dart';
import 'package:minigames/services/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Prefs.debugReset();
    await Prefs.init();
  });

  testWidgets('two players can take turns', (tester) async {
    await Prefs.setTwoPlayer(true);
    await tester.pumpWidget(const MaterialApp(home: TicTacToeScreen()));
    await tester.pump();
    await tester.pump();

    // X plays center.
    await tester.tap(find.byKey(const ValueKey('ttt-4')));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ttt-4')),
        matching: find.text('X'),
      ),
      findsOneWidget,
    );
    expect(find.text('O to move'), findsOneWidget);

    // O plays a corner.
    await tester.tap(find.byKey(const ValueKey('ttt-0')));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ttt-0')),
        matching: find.text('O'),
      ),
      findsOneWidget,
    );
    expect(find.text('X to move'), findsOneWidget);
  });

  testWidgets('a winning line is detected', (tester) async {
    await Prefs.setTwoPlayer(true);
    await tester.pumpWidget(const MaterialApp(home: TicTacToeScreen()));
    await tester.pump();
    await tester.pump();

    // X takes the top row while O blocks elsewhere: cells 0,3,1,4,2.
    await tester.tap(find.byKey(const ValueKey('ttt-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('ttt-3')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('ttt-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('ttt-4')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('ttt-2')));
    await tester.pump();

    // Result overlay appears (result screens on by default): status line
    // says "X wins!" and the drawer shows its own copy + action buttons.
    expect(find.text('X wins!'), findsNWidgets(2));
    expect(find.text('Play again'), findsOneWidget);
  });

  testWidgets('vs AI mode makes the bot play', (tester) async {
    await Prefs.setTwoPlayer(false);
    await tester.pumpWidget(const MaterialApp(home: TicTacToeScreen()));
    await tester.pump();
    await tester.pump();

    // Default mode is vs AI; X plays center, then the bot should answer.
    await tester.tap(find.byKey(const ValueKey('ttt-4')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(Text), findsWidgets);
    expect(find.widgetWithText(InkWell, 'O'), findsOneWidget);
    expect(find.text('X to move'), findsOneWidget);
  });

  testWidgets('result overlay is hidden when disabled in settings', (
    tester,
  ) async {
    await Prefs.setShowResultScreens(false);
    await Prefs.setTwoPlayer(true);
    await tester.pumpWidget(const MaterialApp(home: TicTacToeScreen()));
    await tester.pump();
    await tester.pump();

    // X takes the top row: cells 0,3,1,4,2.
    await tester.tap(find.byKey(const ValueKey('ttt-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('ttt-3')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('ttt-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('ttt-4')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('ttt-2')));
    await tester.pump();

    expect(find.text('Play again'), findsNothing);
    expect(find.text('X wins!'), findsOneWidget);
  });
}
