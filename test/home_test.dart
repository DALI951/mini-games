import 'package:flutter_test/flutter_test.dart';
import 'package:minigames/main.dart';
import 'package:minigames/services/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Prefs.debugReset();
    await Prefs.init();
  });

  testWidgets('hub renders all ten games', (tester) async {
    await tester.pumpWidget(const MiniGamesApp());
    await tester.pump();

    expect(find.text('MiniGames'), findsOneWidget);
    expect(find.text('Tic Tac Toe'), findsOneWidget);
    expect(find.text('Memory Match'), findsOneWidget);
    expect(find.text('Simon Says'), findsOneWidget);
    expect(find.text('Snake'), findsOneWidget);
    expect(find.text('2048'), findsOneWidget);
    expect(find.text('Rock Paper Scissors'), findsOneWidget);
    expect(find.text('Connect Four'), findsOneWidget);
    expect(find.text('Color Rush'), findsOneWidget);
    expect(find.text('Word Unscramble'), findsOneWidget);
    expect(find.text('Higher or Lower'), findsOneWidget);
  });

  testWidgets('tapping a game card opens that game', (tester) async {
    await tester.pumpWidget(const MiniGamesApp());
    await tester.pump();

    await tester.tap(find.text('Tic Tac Toe'));
    await tester.pumpAndSettle();

    expect(find.text('X to move'), findsOneWidget);
  });

  testWidgets('back from a game returns to the hub', (tester) async {
    await tester.pumpWidget(const MiniGamesApp());
    await tester.pump();

    await tester.tap(find.text('Memory Match'));
    await tester.pumpAndSettle();
    expect(find.text('Moves'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Pick a game'), findsOneWidget);
  });
}
