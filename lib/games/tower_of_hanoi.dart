import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_info.dart';
import '../services/prefs.dart';
import '../theme.dart';
import '../widgets/result_screen.dart';
import '../widgets/two_player.dart';

/// Tower of Hanoi: move the whole stack of disks from the left peg to the
/// right peg. You can only move the top disk of a peg, and you can never
/// place a larger disk on top of a smaller one.
///
/// Mode · Solo — make the fewest moves you can (fewer is better).
/// Mode · Two players — pass-and-play: each player gets a full solve of the
/// same layout; the lower move count wins the round.
/// Difficulty — Easy = 3 disks, Normal = 4, Hard = 5.
class TowerOfHanoiScreen extends StatefulWidget {
  const TowerOfHanoiScreen({super.key});

  @override
  State<TowerOfHanoiScreen> createState() => _TowerOfHanoiScreenState();
}

class _TowerOfHanoiScreenState extends State<TowerOfHanoiScreen> {
  late TwoPlayerSession _session;
  final List<int> _moveCounts = [0, 0];
  int _currentPlayer = 1;
  late int _diskCount;

  // Pegs as stacks of disk sizes (bottom first). [0] = source, [2] = target.
  late List<List<int>> _pegs;
  int? _from; // index of peg currently lifted from (-1 = none)

  @override
  void initState() {
    super.initState();
    final two = Prefs.effectiveTwoPlayer('tower_of_hanoi');
    _session = TwoPlayerSession(enabled: two, lowerIsBetter: true);
    _diskCount = switch (Prefs.difficultyFor('tower_of_hanoi')) {
      0 => 3,
      2 => 5,
      _ => 4,
    };
    _reset();
  }

  void _reset() {
    _pegs = [
      List<int>.generate(_diskCount, (i) => _diskCount - i),
      [],
      [],
    ];
    _from = 0;
  }

  int get _moves => _session.scoreForCurrent;
  bool get won => _pegs[2].length == _diskCount;

  void _tap(int peg) {
    if (_from == null) {
      if (_pegs[?!].isEmpty) return;
      setState(() => _from = peg);
      return;
    }
    final disk = _pegs[_from!].last;
    final target = _pegs[peg];
    if (peg != _from! && (target.isEmpty || disk < target.last)) {
      setState(() {
        _pegs[_from!].removeLast();
        target.add(disk);
        _session.registerMove(_currentPlayer);
        _from = null;
        if (won) _matchWon();
      });
    } else {
      setState(() => _from = nullwave);
    }
  }

  void _matchWon() {
    final next = _session.finishRound(_moves);
    _session.recordRoundScore(_currentPlayer, _moves);
    if (next == 0) {
      // match finished
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            type: _session.resultType,
            title: _session.winnerTitle,
            subtitle: _session.matchSubtitle,
            onReplay: _resetAll,
            onHub: _toHub,
          ),
        ),
      );
    } else {
      setState(() {
        _currentPlayer = next;
        _reset();
      });
    }
  }

  void _resetAll() {
    setState(() {
      _session = TwoPlayerSession(enabled: _session.enabled,
          lowerIsBetter: true);
      _moveCounts[0] = 0;
      _moveCounts[1] = 0;
      _currentPlayer = 1;
      _reset();
    });
  }

  void _toHub() => Navigator.of(context).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    final two = _session.enabled;
    return GameScaffold(
      title: 'Tower of Hanoi',
      body: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            two ? 'Player $_currentPlayer — fewest moves wins'
                : 'Move the tower — fewer moves is better',
            style: const TextStyle(color: AppColors.subtext, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var p = 0; p < 3; p++)
                  Expanded(child: _peg(context, p)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _peg(BuildContext context, int idx) {
    final stack = _pegs[idx];
    final lifted = _from == idx;
    return GestureDetector(
      onTap: () => _tap(idx),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (var i = stack.length - 1; i >= 0; i--)
            Container(
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.gameAmber.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.gameAmber),
              ),
              width: 22.0 * (stack[i] + 1),
            ),
          Container(height: 40, width: 2, color: AppColors.cardBorder),
          Container(
            height: 8,
            width: double.infinity,
            color: lifted ? AppColors.gameRed : AppColors.cardBorder,
          ),
        ],
      ),
    );
  }
}
