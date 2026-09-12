import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_info.dart';
import '../services/prefs.dart';
import '../theme.dart';
import '../widgets/result_screen.dart';

/// Connect Four — drop discs, get 4 in a row.
/// Single: vs the AI (minimax, depth 4). Two players: same screen,
/// alternating turns.
class ConnectFourScreen extends StatefulWidget {
  const ConnectFourScreen({super.key});

  @override
  State<ConnectFourScreen> createState() => _ConnectFourScreenState();
}

class _ConnectFourScreenState extends State<ConnectFourScreen> {
  static const rows = 6;
  static const cols = 7;

  late bool _twoPlayer;
  late List<List<int?>> _board; // [row][col]; null empty, 1 P1, 2 P2/AI
  late bool _turn; // true = player 1
  int? _winner;
  int _p1Wins = 0;
  int _p2Wins = 0;
  int _draws = 0;

  @override
  void initState() {
    super.initState();
    _twoPlayer = this.twoPlayer;
    _board = List.generate(rows, (_) => List<int?>.filled(cols, null));
    _turn = true;
  }

  void _newGame() {
    setState(() {
      _board = List.generate(rows, (_) => List<int?>.filled(cols, null));
      _turn = true;
      _winner = null;
    });
  }

  void _resetMatch() {
    setState(() {
      _board = List.generate(rows, (_) => List<int?>.filled(cols, null));
      _turn = true;
      _winner = null;
      _p1Wins = 0;
      _p2Wins = 0;
      _draws = 0;
    });
  }

  int? _columnFloor(int col) {
    for (var r = rows - 1; r >= 0; r--) {
      if (_board[r][col] == null) return r;
    }
    return null;
  }

  void _drop(int col, {bool fromAi = false}) {
    if (_winner != null) return;
    // In single-player mode, ignore human taps when it's the AI's turn.
    if (!fromAi && !_twoPlayer && !_turn) return;
    final me = _turn ? 1 : 2;

    final floor = _columnFloor(col);
    if (floor == null) return;

    if (Prefs.haptics) HapticFeedback.lightImpact();
    setState(() {
      _board[floor][col] = me;
      _turn = !_turn;
    });

    final win = _checkWin(me);
    if (win != null) {
      setState(() {
        _winner = me;
        _turn = true;
        if (me == 1) {
          _p1Wins++;
        } else {
          _p2Wins++;
        }
      });
      return;
    }
    if (_boardFull) {
      setState(() {
        _winner = 0; // draw
        _draws++;
      });
      return;
    }

    if (!_twoPlayer && !_turn) {
      Future<void>.delayed(const Duration(milliseconds: 350), _aiMove);
    }
  }

  bool get _boardFull => _board.every((row) => row.every((c) => c != null));

  void _aiMove() {
    if (!mounted || _winner != null) return;
    if (_turn) return; // user already moved again
    final col = _bestAiMove(_board, depth: 4);
    if (col < 0) return;
    _drop(col, fromAi: true);
  }

  // ---- AI: minimax with alpha-beta on a window-based heuristic ----

  int? _checkWin(int mark) {
    const dirs = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (_board[r][c] != mark) continue;
        for (final d in dirs) {
          var count = 1;
          var rr = r + d[0];
          var cc = c + d[1];
          while (rr >= 0 &&
              rr < rows &&
              cc >= 0 &&
              cc < cols &&
              _board[rr][cc] == mark) {
            count++;
            rr += d[0];
            cc += d[1];
          }
          if (count >= 4) return mark;
        }
      }
    }
    return null;
  }

  int? _winAt(List<List<int?>> board, int mark) {
    final saved = _board;
    _board = board;
    final result = _checkWin(mark);
    _board = saved;
    return result;
  }

  List<int> _validCols(List<List<int?>> board) {
    final cols2 = <int>[];
    for (var c = 0; c < cols; c++) {
      if (board[0][c] == null) cols2.add(c);
    }
    // Prefer middle columns for stronger play.
    cols2.sort((a, b) => (cols / 2 - a).abs().compareTo((cols / 2 - b).abs()));
    return cols2;
  }

  // Score a 4-cell window from the AI's perspective.
  int _windowScore(List<int?> w, int ai) {
    var aiCount = 0;
    var plCount = 0;
    for (final v in w) {
      if (v == ai) {
        aiCount++;
      } else if (v != null) {
        plCount++;
      }
    }
    if (aiCount > 0 && plCount > 0) return 0;
    if (aiCount == 4) return 100000;
    if (aiCount == 3) return 60;
    if (aiCount == 2) return 8;
    if (plCount == 4) return -100000;
    if (plCount == 3) return -70;
    if (plCount == 2) return -10;
    return 0;
  }

  int _evaluate(List<List<int?>> board, int ai) {
    var score = 0;
    // Horizontal.
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c <= cols - 4; c++) {
        score += _windowScore([
          board[r][c],
          board[r][c + 1],
          board[r][c + 2],
          board[r][c + 3],
        ], ai);
      }
    }
    // Vertical.
    for (var c = 0; c < cols; c++) {
      for (var r = 0; r <= rows - 4; r++) {
        score += _windowScore([
          board[r][c],
          board[r + 1][c],
          board[r + 2][c],
          board[r + 3][c],
        ], ai);
      }
    }
    // Diagonals.
    for (var r = 0; r <= rows - 4; r++) {
      for (var c = 0; c <= cols - 4; c++) {
        score += _windowScore([
          board[r][c],
          board[r + 1][c + 1],
          board[r + 2][c + 2],
          board[r + 3][c + 3],
        ], ai);
      }
    }
    for (var r = 3; r < rows; r++) {
      for (var c = 0; c <= cols - 4; c++) {
        score += _windowScore([
          board[r][c],
          board[r - 1][c + 1],
          board[r - 2][c + 2],
          board[r - 3][c + 3],
        ], ai);
      }
    }
    return score;
  }

  int _simulate(List<List<int?>> board, int col, int mark) {
    final b = board.map((row) => List<int?>.from(row)).toList();
    for (var r = rows - 1; r >= 0; r--) {
      if (b[r][col] == null) {
        b[r][col] = mark;
        break;
      }
    }
    return _hasWin(b, mark) ? mark : 0;
  }

  bool _hasWin(List<List<int?>> board, int mark) {
    final saved = _board;
    _board = board;
    final w = _checkWin(mark);
    _board = saved;
    return w != null;
  }

  int _search(
    List<List<int?>> board,
    int depth,
    int alpha,
    int beta,
    bool maximizing,
    int ai,
  ) {
    if (depth == 0) return _evaluate(board, ai);
    final cols2 = _validCols(board);
    if (cols2.isEmpty) return 0;

    if (maximizing) {
      var best = -1 << 30;
      for (final c in cols2) {
        final win = _simulate(board, c, ai);
        if (win == ai) return 100000 + depth;
        final b = board.map((row) => List<int?>.from(row)).toList();
        for (var r = rows - 1; r >= 0; r--) {
          if (b[r][c] == null) {
            b[r][c] = ai;
            break;
          }
        }
        best = max(best, _search(b, depth - 1, alpha, beta, false, ai));
        alpha = max(alpha, best);
        if (beta <= alpha) break;
      }
      return best;
    } else {
      var best = 1 << 30;
      for (final c in cols2) {
        final win = _simulate(board, c, 3 - ai);
        if (win != 0) return -100000 - depth;
        final b = board.map((row) => List<int?>.from(row)).toList();
        for (var r = rows - 1; r >= 0; r--) {
          if (b[r][c] == null) {
            b[r][c] = 3 - ai;
            break;
          }
        }
        best = min(best, _search(b, depth - 1, alpha, beta, true, ai));
        beta = min(beta, best);
        if (beta <= alpha) break;
      }
      return best;
    }
  }

  int _bestAiMove(List<List<int?>> board, {int depth = 4}) {
    var bestCol = -1;
    var bestScore = -1 << 30;
    for (final c in _validCols(board)) {
      final win = _simulate(board, c, 2);
      if (win == 2) return c;
      final b = board.map((row) => List<int?>.from(row)).toList();
      for (var r = rows - 1; r >= 0; r--) {
        if (b[r][c] == null) {
          b[r][c] = 2;
          break;
        }
      }
      final score = _search(b, depth - 1, -1 << 30, 1 << 30, false, 2);
      if (score > bestScore) {
        bestScore = score;
        bestCol = c;
      }
    }
    return bestCol;
  }

  String get _status {
    if (_winner != null) {
      if (_winner == 0) return "It's a draw.";
      final w = _winner == 1;
      return _twoPlayer
          ? (w ? 'Player 1 wins!' : 'Player 2 wins!')
          : (w ? 'You win!' : 'You lose');
    }
    if (_twoPlayer) {
      return _turn ? 'Player 1 — your turn' : 'Player 2 — your turn';
    }
    return _turn ? 'Your turn' : 'Bot thinking…';
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Connect Four',
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(
                  children: [
                    _chip('Red', '$_p1Wins', AppColors.accent),
                    const SizedBox(width: 10),
                    _chip('Gray', '$_p2Wins', AppColors.subtext),
                    const SizedBox(width: 10),
                    _chip('=', '$_draws', AppColors.subtext),
                    const Spacer(),
                    FloatingActionButton.small(
                      heroTag: 'cfNew',
                      backgroundColor: AppColors.card,
                      foregroundColor: AppColors.accent,
                      onPressed: _newGame,
                      tooltip: 'New game',
                      child: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              Text(
                _status,
                style: TextStyle(
                  color: _winner == 0 ? AppColors.text : AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (var c = 0; c < cols; c++)
                            Expanded(
                              child: InkWell(
                                key: ValueKey('cf-drop-$c'),
                                onTap: () => _drop(c),
                                child: SizedBox(
                                  height: 42,
                                  child: Icon(
                                    Icons.arrow_drop_down_circle_outlined,
                                    color: AppColors.subtext.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: cols,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (var r = 0; r < rows; r++)
                              for (var c = 0; c < cols; c++) _cell(r, c),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_winner != null && Prefs.showResultScreens)
            ResultOverlay(
              type: _winner == 1
                  ? ResultType.win
                  : _winner == 2
                  ? ResultType.lose
                  : ResultType.draw,
              title: _status,
              subtitle: _twoPlayer
                  ? 'Red: $_p1Wins · Gray: $_p2Wins'
                  : (_winner == 1
                        ? 'You beat the bot!'
                        : 'Best of luck next time'),
              onPrimary: _newGame,
              secondaryLabel: 'Restart match',
              onSecondary: _resetMatch,
            ),
        ],
      ),
    );
  }

  Widget _cell(int r, int c) {
    final v = _board[r][c];
    final color = v == 1
        ? AppColors.accent
        : v == 2
        ? AppColors.subtext
        : null;
    return Padding(
      padding: const EdgeInsets.all(3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color ?? AppColors.card.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String value, Color color) {
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
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
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
}
