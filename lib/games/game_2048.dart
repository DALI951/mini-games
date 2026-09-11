import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_info.dart';
import '../services/prefs.dart';
import '../theme.dart';

/// 2048: swipe to slide tiles, equal tiles merge into double values.
/// Reach 2048 to win (you can keep going after).
class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  static const int _size = 4;

  late List<List<int?>> _board;
  late int _score;
  int _best = 0;
  bool _won = false;
  bool _over = false;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _best = Prefs.bestScore('game_2048');
    _newGame();
  }

  void _newGame() {
    setState(() {
      _board = List.generate(_size, (_) => List<int?>.filled(_size, null));
      _score = 0;
      _won = false;
      _over = false;
      _spawnTile();
      _spawnTile();
    });
  }

  void _spawnTile() {
    final empty = <Point<int>>[];
    for (var r = 0; r < _size; r++) {
      for (var c = 0; c < _size; c++) {
        if (_board[r][c] == null) empty.add(Point(r, c));
      }
    }
    if (empty.isEmpty) return;
    final cell = empty[_random.nextInt(empty.length)];
    _board[cell.x][cell.y] = _random.nextDouble() < 0.9 ? 2 : 4;
  }

  /// Slides one line (row or column) in the given direction and returns
  /// the points gained.
  int _slide(List<int?> line) {
    final values = line.where((v) => v != null).cast<int>().toList();
    if (values.isEmpty) return 0;

    final out = <int>[];
    var gained = 0;
    var i = 0;
    while (i < values.length) {
      if (i + 1 < values.length && values[i] == values[i + 1]) {
        out.add(values[i] * 2);
        gained += values[i] * 2;
        i += 2;
      } else {
        out.add(values[i]);
        i++;
      }
    }
    while (out.length < _size) {
      out.add(0);
    }
    for (var k = 0; k < _size; k++) {
      line[k] = out[k] == 0 ? null : out[k];
    }
    return gained;
  }

  /// Returns true if the board changed (a move happened).
  bool _move(bool toLeft, bool alongRows) {
    var changed = false;
    var points = 0;

    for (var i = 0; i < _size; i++) {
      final line = <int?>[];
      for (var j = 0; j < _size; j++) {
        final r = alongRows ? i : j;
        final c = alongRows ? j : i;
        line.add(_board[r][c]);
      }

      final before = List<int?>.from(line);
      List<int?> merged;
      if (toLeft) {
        points += _slide(line);
        merged = line;
      } else {
        final rev = line.reversed.toList();
        points += _slide(rev);
        merged = rev.reversed.toList();
      }

      if (!_listsEqual(before, merged)) changed = true;
      for (var j = 0; j < _size; j++) {
        final r = alongRows ? i : j;
        final c = alongRows ? j : i;
        _board[r][c] = merged[j];
      }
    }

    if (changed) {
      setState(() {
        _score += points;
        _spawnTile();
        if (!_won && _board.any((row) => row.contains(2048))) _won = true;
        if (_noMovesLeft()) _over = true;
      });
      if (Prefs.haptics) HapticFeedback.lightImpact();
      if (_won || _over) _persistBest();
    }
    return changed;
  }

  bool _listsEqual(List<int?> a, List<int?> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _noMovesLeft() {
    for (var r = 0; r < _size; r++) {
      for (var c = 0; c < _size; c++) {
        final v = _board[r][c];
        if (v == null) return false;
        if (c + 1 < _size && _board[r][c + 1] == v) return false;
        if (r + 1 < _size && _board[r + 1][c] == v) return false;
      }
    }
    return true;
  }

  Future<void> _persistBest() async {
    await Prefs.saveBestScore('game_2048', _score);
    if (!mounted) return;
    setState(() => _best = Prefs.bestScore('game_2048'));
  }

  void _swipe(Offset velocity) {
    if (_over) {
      _newGame();
      return;
    }
    if (velocity.dx.abs() > velocity.dy.abs()) {
      if (velocity.dx > 0) {
        _move(false, true); // right
      } else {
        _move(true, true); // left
      }
    } else {
      if (velocity.dy > 0) {
        _move(false, false); // down
      } else {
        _move(true, false); // up
      }
    }
  }

  Color _tileColor(int? value) {
    switch (value) {
      case 2:
        return const Color(0xFF23262F);
      case 4:
        return const Color(0xFF2B303C);
      case 8:
        return const Color(0xFF7F1D1D);
      case 16:
        return const Color(0xFF991B1B);
      case 32:
        return const Color(0xFFB91C1C);
      case 64:
        return const Color(0xFFDC2626);
      case 128:
        return const Color(0xFFE11D48);
      case 256:
        return const Color(0xFFD97706);
      case 512:
        return const Color(0xFFEA580C);
      case 1024:
        return const Color(0xFFF97316);
      case 2048:
        return const Color(0xFFF59E0B);
      default:
        return AppColors.card;
    }
  }

  Color _tileTextColor(int? value) {
    if (value != null && value <= 4) return AppColors.text;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: '2048',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                _statChip('Score', '$_score'),
                const SizedBox(width: 10),
                _statChip('Best', _best == 0 ? '—' : '$_best'),
                const Spacer(),
                FloatingActionButton.small(
                  heroTag: 'g2048New',
                  backgroundColor: AppColors.card,
                  foregroundColor: AppColors.accent,
                  onPressed: _newGame,
                  tooltip: 'New game',
                  child: const Icon(Icons.refresh),
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
                  child: GestureDetector(
                    onPanEnd: (details) =>
                        _swipe(details.velocity.pixelsPerSecond),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: GridView.count(
                        crossAxisCount: _size,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (var r = 0; r < _size; r++)
                            for (var c = 0; c < _size; c++) _tile(r, c),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Swipe to move',
            style: TextStyle(color: AppColors.subtext, fontSize: 12),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
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
            style: const TextStyle(color: AppColors.subtext, fontSize: 12),
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

  Widget _tile(int r, int c) {
    final value = _board[r][c];
    return Container(
      decoration: BoxDecoration(
        color: _tileColor(value),
        borderRadius: BorderRadius.circular(10),
        border: value == null ? Border.all(color: AppColors.cardBorder) : null,
      ),
      alignment: Alignment.center,
      child: value == null
          ? null
          : Text(
              '$value',
              style: TextStyle(
                color: _tileTextColor(value),
                fontSize: value >= 1024 ? 18 : 22,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}
