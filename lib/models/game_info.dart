import 'package:flutter/material.dart';

import '../games/game_2048.dart';
import '../games/memory_match.dart';
import '../games/simon_says.dart';
import '../games/snake.dart';
import '../games/tic_tac_toe.dart';
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
];

Widget _ttt(BuildContext context) => const TicTacToeScreen();
Widget _memory(BuildContext context) => const MemoryScreen();
Widget _simon(BuildContext context) => const SimonScreen();
Widget _snake(BuildContext context) => const SnakeScreen();
Widget _game2048(BuildContext context) => const Game2048Screen();

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
