import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minigames/games/color_rush.dart';
import 'package:minigames/games/connect_four.dart';
import 'package:minigames/games/higher_lower.dart';
import 'package:minigames/games/rps.dart';
import 'package:minigames/games/word_unscramble.dart';
import 'package:minigames/services/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Prefs.debugReset();
    await Prefs.init();
  });

  testWidgets('rock paper scissors renders and plays a round vs bot', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RpsScreen()));
    await tester.pump();

    expect(find.text('Rock Paper Scissors'), findsOneWidget);
    expect(find.text('✊'), findsOneWidget);

    await tester.tap(find.text('✊'));
    await tester.pump();

    // A round resolves right away (you / bot / draw) with a score line.
    expect(find.textContaining('You:'), findsOneWidget);
  });

  testWidgets('connect four two-player turns alternate', (tester) async {
    await Prefs.setTwoPlayer(true);
    await tester.pumpWidget(const MaterialApp(home: ConnectFourScreen()));
    await tester.pump();

    expect(find.text('Connect Four'), findsOneWidget);
    expect(find.text('Player 1 — your turn'), findsOneWidget);

    // Tap the drop arrow for column 0.
    await tester.tap(find.byKey(const ValueKey('cf-drop-0')));
    await tester.pump();
    expect(find.text('Player 2 — your turn'), findsOneWidget);
  });

  testWidgets('color rush renders and starts a solo round', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ColorRushScreen()));
    await tester.pump();

    expect(find.text('Color Rush'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump();

    // Counting down while running.
    expect(find.textContaining('s left'), findsOneWidget);

    // Stop the periodic timer so the test can finish.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('word unscramble renders options', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WordUnscrambleScreen()));
    await tester.pump();

    expect(find.text('Word Unscramble'), findsOneWidget);
    // 4 answer options are rendered.
    expect(find.byType(InkWell), findsNWidgets(4));
  });

  testWidgets('higher or lower renders and accepts a guess', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HigherLowerScreen()));
    await tester.pump();

    expect(find.text('Higher or Lower'), findsOneWidget);
    expect(find.text('Higher'), findsOneWidget);
    expect(find.text('Lower'), findsOneWidget);

    await tester.tap(find.text('Higher'));
    await tester.pump();

    // Reveal + Next button appear.
    expect(find.text('Next'), findsOneWidget);
  });
}
