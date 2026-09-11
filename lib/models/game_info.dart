import 'package:flutter/material.dart';

import '../games/color_rush.dart';
import '../games/connect_four.dart';
import '../games/game_2048.dart';
import '../games/higher_lower.dart';
import '../games/memory_match.dart';
import '../games/rps.dart';
import '../games/simon_says.dart';
import '../games/snake.dart';
import '../games/tic_tac_toe.dart';
import '../games/word_unscramble.dart';
import '../theme.dart';

/// Registry of every game in the hub. Adding a new game = adding one entry
/// here (and the game's own screen). The hub grid, settings screen and
/// tests all read from this single source of truth.
class GameInfo {
  const GameInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.builder,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
}

final List<GameInfo> kGames = [
  GameInfo(
    id: 'tic_tac_toe',
    title: 'Tic Tac Toe',
    subtitle: 'Beat the bot or a friend',
    icon: Icons.grid_3x3,
    color: AppColors.gameRed,
    builder: _ttt,
  ),
  GameInfo(
    id: 'memory_match',
    title: 'Memory Match',
    subtitle: 'Flip cards, find pairs',
    icon: Icons.style,
    color: AppColors.gameAmber,
    builder: _memory,
  ),
  GameInfo(
    id: 'simon_says',
    title: 'Simon Says',
    subtitle: 'Repeat the light sequence',
    icon: Icons.tonality,
    color: AppColors.gameGreen,
    builder: _simon,
  ),
  GameInfo(
    id: 'snake',
    title: 'Snake',
    subtitle: "Eat, grow, don't crash",
    icon: Icons.linear_scale,
    color: AppColors.gameBlue,
    builder: _snake,
  ),
  GameInfo(
    id: 'game_2048',
    title: '2048',
    subtitle: 'Merge tiles to 2048',
    icon: Icons.apps,
    color: AppColors.gameViolet,
    builder: _game2048,
  ),
  GameInfo(
    id: 'rps',
    title: 'Rock Paper Scissors',
    subtitle: 'First to 3 wins the match',
    icon: Icons.back_hand,
    color: AppColors.gameRed,
    builder: _rps,
  ),
  GameInfo(
    id: 'connect_four',
    title: 'Connect Four',
    subtitle: 'Drop discs, get four',
    icon: Icons.circle,
    color: AppColors.gameAmber,
    builder: _connectFour,
  ),
  GameInfo(
    id: 'color_rush',
    title: 'Color Rush',
    subtitle: 'Stroop test — tap the ink',
    icon: Icons.palette,
    color: AppColors.gameGreen,
    builder: _colorRush,
  ),
  GameInfo(
    id: 'word_unscramble',
    title: 'Word Unscramble',
    subtitle: 'Unscramble, pick the answer',
    icon: Icons.abc,
    color: AppColors.gameBlue,
    builder: _wordUnscramble,
  ),
  GameInfo(
    id: 'higher_lower',
    title: 'Higher or Lower',
    subtitle: 'Guess big or small',
    icon: Icons.swap_vert,
    color: AppColors.gameViolet,
    builder: _higherLower,
  ),
];

Widget _ttt(BuildContext context) => const TicTacToeScreen();
Widget _memory(BuildContext context) => MemoryScreen();
Widget _simon(BuildContext context) => const SimonScreen();
Widget _snake(BuildContext context) => const SnakeScreen();
Widget _game2048(BuildContext context) => const Game2048Screen();
Widget _rps(BuildContext context) => const RpsScreen();
Widget _connectFour(BuildContext context) => const ConnectFourScreen();
Widget _colorRush(BuildContext context) => const ColorRushScreen();
Widget _wordUnscramble(BuildContext context) => const WordUnscrambleScreen();
Widget _higherLower(BuildContext context) => const HigherLowerScreen();

/// Wraps a game builder with a consistent scaffold (title bar over the
/// dark cinema background).
class GameScaffold extends StatelessWidget {
  const GameScaffold({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
    );
  }
}
