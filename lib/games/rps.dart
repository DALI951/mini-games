import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_info.dart';
import '../services/prefs.dart';
import '../theme.dart';
import '../widgets/result_screen.dart';
import '../widgets/game_scaffold.dart';

enum _Shape { rock, paper, scissors }

extension _ShapeX on _Shape {
  String get emoji => switch (this) {
    _Shape.rock => '✊',
    _Shape.paper => '✋',
    _Shape.scissors => '✌️',
  };

  String get label => switch (this) {
    _Shape.rock => 'Rock',
    _Shape.paper => 'Paper',
    _Shape.scissors => 'Scissors',
  };
}

/// Rock Paper Scissors — first to 3 round wins.
/// Single: vs the AI. Two players: P1 picks, then P2 picks, then reveal.
class RpsScreen extends StatefulWidget {
  const RpsScreen({super.key});

  @override
  State<RpsScreen> createState() => _RpsScreenState();
}

class _RpsScreenState extends State<RpsScreen> {
  /// Effective two-player flag for rps (per-game override wins).
  bool get twoPlayer => Prefs.effectiveTwoPlayer('rps');

  static const _target = 3;

  late bool _twoPlayer;
  int _p1 = 0;
  int _p2 = 0;
  _Shape? _pick1;
  _Shape? _pick2;
  _Shape? _aiPick;
  String? _roundResult;
  int _rounds = 0;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _twoPlayer = this.twoPlayer;
  }

  void _resetMatch() {
    setState(() {
      _p1 = 0;
      _p2 = 0;
      _pick1 = null;
      _pick2 = null;
      _aiPick = null;
      _roundResult = null;
      _rounds = 0;
    });
  }

  void _pick(_Shape shape) {
    if (Prefs.haptics) HapticFeedback.lightImpact();

    if (_twoPlayer) {
      if (_pick1 == null) {
        setState(() => _pick1 = shape);
        return;
      }
      if (_pick2 != null) return;
      setState(() => _pick2 = shape);
      _resolve(_pick1!, shape);
    } else {
      if (_pick1 != null && _roundResult != null) return;
      _pick1 = shape;
      _aiPick = _Shape.values[_random.nextInt(3)];
      _resolve(shape, _aiPick!);
    }
  }

  void _resolve(_Shape a, _Shape b) {
    final result = _roundWinner(a, b);
    setState(() {
      _rounds++;
      if (result == 1) {
        _p1++;
        _roundResult = _twoPlayer
            ? 'Player 1 takes the round'
            : 'You win this round!';
      } else if (result == 2) {
        _p2++;
        _roundResult = _twoPlayer
            ? 'Player 2 takes the round'
            : 'The bot takes this round';
      } else {
        _roundResult = 'Draw — no point';
      }
    });
  }

  int _roundWinner(_Shape a, _Shape b) {
    if (a == b) return 0;
    final beats = {
      _Shape.rock: _Shape.scissors,
      _Shape.scissors: _Shape.paper,
      _Shape.paper: _Shape.rock,
    };
    return beats[a] == b ? 1 : 2;
  }

  bool get _matchOver => _p1 >= _target || _p2 >= _target;

  void _nextRound() {
    setState(() {
      _pick1 = null;
      _pick2 = null;
      _aiPick = null;
      _roundResult = null;
    });
  }

  String get _status {
    if (_pick1 == null) {
      return _twoPlayer ? 'Player 1 — pick a shape' : 'Pick your shape';
    }
    if (_twoPlayer && _pick2 == null && !_matchOver) {
      return 'Player 2 — pick a shape';
    }
    if (_roundResult != null && !_matchOver) {
      final pf = _twoPlayer
          ? 'P1: $_p1  ·  P2: $_p2'
          : 'You: $_p1  ·  Bot: $_p2';
      return '$_roundResult   ·   $pf';
    }
    return _roundResult ?? 'Pick your shape';
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Rock Paper Scissors',
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(
                  children: [
                    _chip(_twoPlayer ? 'P1' : 'You', '$_p1', AppColors.accent),
                    const SizedBox(width: 10),
                    _chip(_twoPlayer ? 'P2' : 'Bot', '$_p2', AppColors.subtext),
                    const Spacer(),
                    FloatingActionButton.small(
                      heroTag: 'rpsReset',
                      backgroundColor: AppColors.card,
                      foregroundColor: AppColors.accent,
                      onPressed: _resetMatch,
                      tooltip: 'Restart match',
                      child: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              Text(
                _status,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'First to $_target wins',
                style: const TextStyle(color: AppColors.subtext, fontSize: 12),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_pick1 != null && !_matchOver)
                        Text(
                          _revealLine,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.subtext,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final shape in _Shape.values) ...[
                            _shapeButton(shape),
                            if (shape != _Shape.values.last)
                              const SizedBox(width: 16),
                          ],
                        ],
                      ),
                      if (_roundResult != null && !_matchOver) ...[
                        const SizedBox(height: 18),
                        ghostButton('Next round', _nextRound),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_matchOver && Prefs.showResultScreens)
            ResultOverlay(
              type: _p1 > _p2 ? ResultType.win : ResultType.lose,
              title: _twoPlayer
                  ? (_p1 > _p2 ? 'Player 1 wins!' : 'Player 2 wins!')
                  : (_p1 > _p2 ? 'You win!' : 'You lose'),
              subtitle: 'P1: $_p1  ·  P2: $_p2',
              onPrimary: _resetMatch,
              secondaryLabel: 'Exit',
              onSecondary: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  String get _revealLine {
    if (_twoPlayer) {
      return 'P1 ${_pick1!.emoji}  vs  P2 ${_pick2?.emoji ?? '…'}';
    }
    return 'You ${_pick1!.emoji}  vs  Bot ${_aiPick?.emoji ?? '…'}';
  }

  Widget _shapeButton(_Shape shape) {
    final disabled =
        _matchOver ||
        (_pick1 != null && _pick2 != null && _roundResult != null) ||
        (_twoPlayer && _pick2 != null);
    return InkWell(
      onTap: disabled ? null : () => _pick(shape),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Text(shape.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 4),
            Text(
              shape.label,
              style: const TextStyle(color: AppColors.subtext, fontSize: 11),
            ),
          ],
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
