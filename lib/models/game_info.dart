import 'package:flutter/material.dart';

import '../games/color_rush.dart';
import '../games/connect_four.dart';
import '../games/game_2048.dart';
import '../games/higher_lower.dart';
import '../games/mastermind.dart';
import '../games/memory_match.dart';
import '../games/rps.dart';
import '../games/simon_says.dart';
import '../games/snake.dart';
import '../games/stickman_duel.dart';
import '../games/hangman.dart';
import '../games/tower_of_hanoi.dart';
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
    required this.tutorial,
    this.supportsBot = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  /// Short "how to play" text shown on the pre-game intro panel.
  final String tutorial;

  /// Whether the game can be played vs a bot (as opposed to solo only).
  final bool supportsBot;
}

final List<GameInfo> kGames = [
  GameInfo(
    id: 'tic_tac_toe',
    title: 'Tic Tac Toe',
    subtitle: 'Beat the bot or a friend',
    icon: Icons.grid_3x3,
    color: AppColors.gameRed,
    builder: _ttt,
    tutorial: 'Get three in a row — across, down or diagonal — before the '
        'opponent does. Tap an empty square to play. First to win a round '
        'takes the match; a full board with no winner is a draw.',
    supportsBot: true,
  ),
  GameInfo(
    id: 'memory_match',
    title: 'Memory Match',
    subtitle: 'Flip cards, find pairs',
    icon: Icons.style,
    color: AppColors.gameAmber,
    builder: _memory,
    tutorial: 'Cards are face down. Tap two to flip them — if they match '
        'they stay up aren our you score a point. Fewer flips is better. '
        'Match boosts best-score players, pass-and-play: each player digs '
        'for pairs on their own turn.',
  ),
  GameInfo(
    id: 'simon_says',
    title: 'Simon Says',
    subtitle: 'Repeat the light sequence',
    icon: Icons.tonality,
    color: AppColors.gameGreen,
    builder: _simon,
    tutorial: 'Watch the pads light up in a sequence. Repeat it back in the '
        'same order by tapping the pads. Each correct repeat adds one more '
        'step. One wrong tap ends your run.',
  ),
  GameInfo(
    id: 'snake',
    title: 'Snake',
    subtitle: "Eat, grow, don't crash",
    icon: Icons.linear_scale,
    color: AppColors.gameBlue,
    builder: _snake,
    tutorial: 'Swipe to steer the snake. Eat the red food to grow and score. '
        'Don\'t hit the walls or your own tail — that ends the game. It '
        'speeds up as you eat.',
  ),
  GameInfo(
    id: 'game_2048',
    title: '2048',
    subtitle: 'Merge tiles to 2048',
    icon: Icons.apps,
    color: AppColors.gameViolet,
    builder: _game2048,
    tutorial: 'Swipe to slide every tile at once. Tiles with the same number '
        'merge into their double. Reach the 2048 tile to win — you can keep '
        'merging past it with the board fills.',
  ),
  GameInfo(
    id: 'rps',
    title: 'Rock Paper Scissors',
    subtitle: 'First to 3 wins the match',
    icon: Icons.back_hand,
    color: AppColors.gameRed,
    builder: _rps,
    tutorial: 'Pick rock, paper or scissors. Rock beats scissors, scissors '
        'beats paper, paper beats rock. First to 3 round-wins takes the '
        'match. Ties replays the round.',
    supportsBot: true,
  ),
  GameInfo(
    id: 'connect_four',
    title: 'Connect Four',
    subtitle: 'Drop discs, get four',
    icon: Icons.circle,
    color: AppColors.gameAmber,
    builder: _connectFour,
    tutorial: 'Drop discs into columns — they fall to the lowest empty slot. '
        'Get four of your colour in a row (any direction) to win a round. '
        'First player to win a round wins the match; a draw resets the '
        'score.',
    supportsBot: true,
  ),
  GameInfo(
    id: 'color_rush',
    title: 'Color Rush',
    subtitle: 'Stroop test — tap the ink',
    icon: Icons.palette,
    color: AppColors.gameGreen,
    builder: _colorRush,
    tutorial: 'A word names a colour, but the letters are painted another '
        'colour. Tap the colour of the INK, not the word. Answer as many as '
        'you can before time runs out.',
  ),
  GameInfo(
    id: 'word_unscramble',
    title: 'Word Unscramble',
    subtitle: 'Unscramble, pick the answer',
    icon: Icons.abc,
    color: AppColors.gameBlue,
    builder: _wordUnscramble,
    tutorial: 'Letters are scrambled into a word — reorder them to spell it. '
        'Pick the correct answer, or type it in. You get a limited number of '
        'lives; wrong guesses cost one.',
  ),
  GameInfo(
    id: 'tower_of_hanoi',
    title: 'Tower of Hanoi',
    subtitle: 'Stack them all',
    icon: Icons.terrain,
    color: AppColors.gameViolet,
    builder: _hanoi,
    tutorial: 'Move the whole tower from the left peg to the right peg, one '
        'disk at a time. You may only drop a disk on an empty peg or on a '
        'bigger disk — never on a smaller one. Fewer moves means a better '
        'run.',
    supportsBot: false,
  ),
  GameInfo(
    id: 'higher_lower',
    title: 'Higher or Lower',
    subtitle: 'Guess big or small',
    icon: Icons.swap_vert,
    color: AppColors.gameViolet,
    builder: _higherLower,
    tutorial: 'Two numbers — is the next one higher or lower than the '
        'current? Expert guessing on every card earns a bigger streak. '
        'Hit your goal streak to beat the level.',
  ),
  GameInfo(
    id: 'stickman_duel',
    title: 'Stickman Fight',
    subtitle: 'Blades, bows and bombs',
    icon: Icons.sports_mma,
    color: AppColors.gameRed,
    builder: _stickman,
    tutorial: 'Pick a weapon, then knock your rival off the bridge into the '
        'spikes below. Each fall scores a round — first to 3 wins the match. '
        'P1 uses the left controls, P2 the right. Bombs can bite the thrower.',
    supportsBot: true,
  ),
  GameInfo(
    id: 'mastermind',
    title: 'Mastermind',
    subtitle: 'Crack the secret code',
    icon: Icons.color_lens,
    color: AppColors.gameViolet,
    builder: _mastermind,
    tutorial: 'A code is hidden as a row of coloured pegs. Guess the row: '
        'black pegs mean right colour in the right spot, white mean right '
        'colour in the wrong spot. Crack it before the tries run out.',
    supportsBot: true,
  ),
];

/// Private widget-builder aliases so the registry stays readable.
Widget _ttt(BuildContext context) => const TicTacToeScreen();
Widget _memory(BuildContext context) => const MemoryScreen();
Widget _simon(BuildContext context) => const SimonScreen();
Widget _snake(BuildContext context) => const SnakeScreen();
Widget _game2048(BuildContext context) => const Game2048Screen();
Widget _rps(BuildContext context) => const RpsScreen();
Widget _connectFour(BuildContext context) => const ConnectFourScreen();
Widget _colorRush(BuildContext context) => const ColorRushScreen();
Widget _wordUnscramble(BuildContext context) => const WordUnscrambleScreen();
Widget _hanoi(BuildContext context) => const TowerOfHanoiScreen();
Widget _higherLower(BuildContext context) => const HigherLowerScreen();
Widget _stickman(BuildContext context) => const StickmanDuelScreen();
Widget _mastermind(BuildContext context) => const MastermindScreen();
