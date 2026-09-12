import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_info.dart';
import '../services/prefs.dart';
import '../theme.dart';
import '../widgets/result_screen.dart';
import '../widgets/game_scaffold.dart';

const _topics = <String, List<dynamic>>{
  // value lists: [name, value ...] — value decides higher/lower.
  'HEIGHT': [170, 180, 195, 210, 182, 176, 165, 201],
  'AGE': [12, 58, 27, 81, 44, 19, 36, 93],
  'SPEED': [30, 12, 40, 22, 60, 55, 18, 35],
};

/// Higher or Lower — guess if the next value is higher or lower than the
/// current one. Single: 3 strikes ends the game. Two players: first to 10
/// points wins (miss = turn passes).
class HigherLowerScreen extends StatefulWidget {
  const HigherLowerScreen({super.key});

  @override
  State<HigherLowerScreen> createState() => _HigherLowerScreenState();
}

class _HigherLowerScreenState extends State<HigherLowerScreen> {
  /// Effective two-player flag for higher_lower (per-game override wins).
  bool get twoPlayer => Prefs.effectiveTwoPlayer('higher_lower');

  late bool _twoPlayer;
  static final _random = Random();

  late List<dynamic> _values;
  String _topic = '';
  int _idx = 0;
  int _current = 0;
  int? _next;

  int _strikes = 0;
  int _score = 0;

  // Two-player state: first to 10.
  int _p1 = 0;
  int _p2 = 0;
  int _turn = 1;

  bool _answered = false;
  bool _over = false;
  String _overTitle = '';

  @override
  void initState() {
    super.initState();
    _twoPlayer = this.twoPlayer;
    _startGame();
  }

  void _startGame() {
    final keys = _topics.keys.toList();
    _topic = keys[_random.nextInt(keys.length)];
    final list = List<dynamic>.from(_topics[_topic]!)..shuffle(_random);
    _values = list;
    _idx = 0;
    _current = _values[0];
    _next = null;
    _strikes = 0;
    _score = 0;
    _p1 = 0;
    _p2 = 0;
    _turn = 1;
    _answered = false;
    _over = false;
    _overTitle = '';
  }

  void _advance() {
    if (_next != null) {
      setState(() {
        _idx++;
        _current = _next!;
        _next = null;
        _answered = false;
      });
    } else if (_idx + 1 < _values.length) {
      setState(() {
        _idx++;
        _current = _values[_idx];
        _answered = false;
      });
    } else {
      // Deck finished — reshuffle a fresh topic, keep scores.
      final keys = _topics.keys.toList();
      _topic = keys[_random.nextInt(keys.length)];
      final list = List<dynamic>.from(_topics[_topic]!)..shuffle(_random);
      setState(() {
        _values = list;
        _idx = 0;
        _current = _values[0];
        _answered = false;
      });
    }
  }

  void _guess(bool higher) {
    if (_answered || _over) return;
    final idx = _idx + 1;
    if (idx >= _values.length) {
      // Last card — reshuffle instead.
      _advance();
      return;
    }
    final next = _values[idx];
    final isHigher = next > _current;
    final right = higher == isHigher;
    if (Prefs.haptics) {
      if (right) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }

    setState(() {
      _answered = true;
      _next = next;
      if (right) {
        if (_twoPlayer) {
          if (_turn == 1) {
            _p1++;
            if (_p1 >= 10) {
              _over = true;
              _overTitle = 'Player 1 wins!';
            }
          } else {
            _p2++;
            if (_p2 >= 10) {
              _over = true;
              _overTitle = 'Player 2 wins!';
            }
          }
        } else {
          _score++;
        }
      } else {
        if (_twoPlayer) {
          _turn = _turn == 1 ? 2 : 1;
        } else {
          _strikes++;
          if (_strikes >= 3) {
            _over = true;
            _overTitle = '3 strikes — game over';
          }
        }
      }
    });
  }

  void _continueAfterReveal() {
    if (_over) return;
    _advance();
    if (_twoPlayer && _answered) {
      // After a miss the turn already switched; announce if we switched.
      // (announcement handled by status line)
    }
  }

  String get _status {
    if (_twoPlayer) {
      return _over
          ? _overTitle
          : 'P1: $_p1 · P2: $_p2 — Player $_turn, first to 10';
    }
    if (_over) return _overTitle;
    return 'Score $_score · 3 strikes ends it';
  }

  String get _topicQuestion {
    switch (_topic) {
      case 'HEIGHT':
        return 'in cm';
      case 'AGE':
        return 'years old';
      case 'SPEED':
        return 'km/h';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final showReveal = _answered && _next != null && !_over;

    return GameScaffold(
      title: 'Higher or Lower',
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(
                  children: [
                    if (_twoPlayer) ...[
                      _chip('P1', '$_p1', AppColors.accent),
                      const SizedBox(width: 10),
                      _chip('P2', '$_p2', AppColors.subtext),
                    ] else ...[
                      _chip('Score', '$_score', AppColors.accent),
                      const SizedBox(width: 10),
                      _chip('Strikes', '$_strikes', AppColors.subtext),
                    ],
                    const Spacer(),
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
              const SizedBox(height: 28),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_topic  ($_topicQuestion)',
                        style: const TextStyle(
                          color: AppColors.subtext,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          '$_current',
                          key: ValueKey('$_current-$_answered'),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        showReveal ? 'next: $_next' : 'Is the next one…',
                        style: TextStyle(
                          color: showReveal
                              ? AppColors.accent
                              : AppColors.subtext,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _guessButton('Higher', Icons.trending_up, true),
                          const SizedBox(width: 20),
                          _guessButton('Lower', Icons.trending_down, false),
                        ],
                      ),
                      if (showReveal) ...[
                        const SizedBox(height: 22),
                        ghostButton('Next', _continueAfterReveal),
                      ],
                      if (_answered &&
                          _twoPlayer &&
                          !_over &&
                          _next == null) ...[
                        const SizedBox(height: 22),
                        ghostButton('Continue', _continueAfterReveal),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_over && Prefs.showResultScreens)
            ResultOverlay(
              type: _twoPlayer
                  ? (_overTitle.contains('1')
                        ? ResultType.win
                        : ResultType.lose)
                  : ResultType.lose,
              title: _overTitle,
              subtitle: _twoPlayer
                  ? 'P1: $_p1 · P2: $_p2'
                  : 'Guessed right: $_score',
              onPrimary: () => setState(_startGame),
              secondaryLabel: 'Home',
              onSecondary: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  Widget _guessButton(String label, IconData icon, bool higher) {
    return InkWell(
      onTap: _answered || _over ? null : () => _guess(higher),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
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
