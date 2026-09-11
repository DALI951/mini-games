import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_info.dart';
import '../services/prefs.dart';
import '../theme.dart';
import '../widgets/result_screen.dart';

/// Classic 3-in-a-row. Single: vs a perfect-ish AI. Two players: hotseat,
/// driven by the global Players setting (Settings → Game mode).
class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  static const _lines = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  late List<String?> _board;
  late bool _xTurn;
  late bool _vsAi;
  late int _xWins;
  late int _oWins;
  late int _draws;
  String? _winner;
  Timer? _aiTimer;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    super.dispose();
  }

  void _reset() {
    _aiTimer?.cancel();
    setState(() {
      _board = List<String?>.filled(9, null);
      _xTurn = true;
      _vsAi = !Prefs.twoPlayer;
      _winner = null;
      _xWins = 0;
      _oWins = 0;
      _draws = 0;
    });
  }

  void _newRound() {
    _aiTimer?.cancel();
    setState(() {
      _board = List<String?>.filled(9, null);
      _xTurn = true;
      _winner = null;
    });
  }

  String? _checkWinner(List<String?> b) {
    for (final line in _lines) {
      final a = b[line[0]];
      if (a != null && a == b[line[1]] && a == b[line[2]]) return a;
    }
    return null;
  }

  bool get _full => !_board.contains(null);

  bool get _gameOver => _winner != null || _full;

  void _place(int index) {
    if (_gameOver || _board[index] != null) return;
    if (_vsAi && !_xTurn) return;

    final mark = _xTurn ? 'X' : 'O';
    setState(() {
      _board[index] = mark;
      _xTurn = !_xTurn;
    });
    if (Prefs.haptics) HapticFeedback.lightImpact();

    _afterMove();
  }

  void _afterMove() {
    final winner = _checkWinner(_board);
    if (winner != null) {
      setState(() {
        _winner = winner;
        if (winner == 'X') {
          _xWins++;
        } else {
          _oWins++;
        }
      });
      return;
    }
    if (_full) {
      setState(() => _draws++);
      return;
    }
    if (_vsAi && !_xTurn) {
      _aiTimer = Timer(const Duration(milliseconds: 400), _aiMove);
    }
  }

  // Minimax with a slight preference for the center on an empty board.
  void _aiMove() {
    if (!mounted || _gameOver) return;
    final index = _bestAiMove(_board);
    if (index == null) return;
    setState(() {
      _board[index] = 'O';
      _xTurn = true;
    });
    _afterMove();
  }

  int _score(List<String?> b, int depth) {
    final w = _checkWinner(b);
    if (w == 'X') return 10 - depth;
    if (w == 'O') return depth - 10;
    return 0;
  }

  int _minimax(List<String?> b, int depth, bool maximizing) {
    final s = _score(b, depth);
    if (s != 0) return s;
    if (!b.contains(null)) return 0;

    if (maximizing) {
      var best = -1000;
      for (var i = 0; i < 9; i++) {
        if (b[i] == null) {
          b[i] = 'X';
          best = _max(best, _minimax(b, depth + 1, false));
          b[i] = null;
        }
      }
      return best;
    } else {
      var best = 1000;
      for (var i = 0; i < 9; i++) {
        if (b[i] == null) {
          b[i] = 'O';
          best = _min(best, _minimax(b, depth + 1, true));
          b[i] = null;
        }
      }
      return best;
    }
  }

  int? _bestAiMove(List<String?> b) {
    if (!b.contains(null)) return null;
    if (b[4] == null) return 4;
    var bestScore = 1000;
    var bestMove = 0;
    for (var i = 0; i < 9; i++) {
      if (b[i] == null) {
        b[i] = 'O';
        final s = _minimax(b, 0, true);
        b[i] = null;
        if (s < bestScore) {
          bestScore = s;
          bestMove = i;
        }
      }
    }
    return bestMove;
  }

  int _max(int a, int b) => a > b ? a : b;
  int _min(int a, int b) => a < b ? a : b;

  String get _statusText {
    if (_winner != null) {
      return _winner == 'X' ? 'X wins!' : 'O wins!';
    }
    if (_full) return "It's a draw.";
    return _xTurn ? 'X to move' : 'O to move';
  }

  @override
  Widget build(BuildContext context) {
    final over = _gameOver;
    final resultTitle = _winner == null
        ? "It's a draw!"
        : _vsAi
        ? (_winner == 'X' ? 'You win!' : 'You lose')
        : '${_winner == 'X' ? 'X' : 'O'} wins!';

    return GameScaffold(
      title: 'Tic Tac Toe',
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _scoreChip('X', _xWins, AppColors.accent),
                        const SizedBox(width: 10),
                        _scoreChip('O', _oWins, AppColors.subtext),
                        const SizedBox(width: 10),
                        _scoreChip('=', _draws, AppColors.subtext),
                        const Spacer(),
                        FloatingActionButton.small(
                          heroTag: 'tttNew',
                          backgroundColor: AppColors.card,
                          foregroundColor: AppColors.accent,
                          onPressed: over ? _reset : _newRound,
                          tooltip: 'Restart',
                          child: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _statusText,
                      style: TextStyle(
                        color: _winner != null
                            ? AppColors.accent
                            : AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [for (var i = 0; i < 9; i++) _tile(i)],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (over && _winner != null && Prefs.showResultScreens)
            ResultOverlay(
              type: _winner == 'X'
                  ? ResultType.win
                  : _winner == 'O'
                  ? ResultType.lose
                  : ResultType.draw,
              title: resultTitle,
              subtitle: 'X: $_xWins · O: $_oWins · Draws: $_draws',
              onPrimary: _newRound,
              secondaryLabel: 'New match',
              onSecondary: _reset,
            ),
          if (over && _winner == null && Prefs.showResultScreens)
            ResultOverlay(
              type: ResultType.draw,
              title: "It's a draw!",
              subtitle: 'X: $_xWins · O: $_oWins · Draws: $_draws',
              onPrimary: _newRound,
              secondaryLabel: 'New match',
              onSecondary: _reset,
            ),
        ],
      ),
    );
  }

  Widget _scoreChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(int index) {
    final mark = _board[index];
    final highlight =
        _winner != null &&
        _winner == mark &&
        _lines.any(
          (l) => l.contains(index) && l.every((i) => _board[i] == _winner),
        );
    return InkWell(
      key: ValueKey('ttt-$index'),
      onTap: () => _place(index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.accent.withValues(alpha: 0.16)
              : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight
                ? AppColors.accent.withValues(alpha: 0.6)
                : AppColors.cardBorder,
          ),
        ),
        alignment: Alignment.center,
        child: mark == null
            ? null
            : Text(
                mark,
                style: TextStyle(
                  color: mark == 'X' ? AppColors.accent : AppColors.subtext,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
