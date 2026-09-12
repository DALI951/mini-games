import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_info.dart';
import '../services/prefs.dart';
import '../theme.dart';
import '../widgets/result_screen.dart';
import '../widgets/two_player.dart';

const _words = ['RED', 'BLUE', 'GREEN', 'YELLOW'];
const _colors = [
  Color(0xFFDC2626), // red
  Color(0xFF3B82F6), // blue
  Color(0xFF22C55E), // green
  Color(0xFFEAB308), // yellow
];

/// Color Rush — Stroop test. Tap the color the word is PRINTED IN,
/// not what it says. Single: 30 seconds. Two players: pass-and-play,
/// 15 seconds each, higher score wins.
class ColorRushScreen extends StatefulWidget {
  const ColorRushScreen({super.key});

  @override
  State<ColorRushScreen> createState() => _ColorRushScreenState();
}

class _ColorRushScreenState extends State<ColorRushScreen> {
  late bool _twoPlayer;
  late final TwoPlayerSession _session;

  int _wordIdx = 0;
  int _colorIdx = 0;
  int _score = 0;
  int _missed = 0;
  bool _running = false;
  bool _over = false;
  Timer? _timer;
  int _msLeft = 0;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _twoPlayer = this.twoPlayer;
    _session = TwoPlayerSession(enabled: _twoPlayer);
    _newWord();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _newWord() {
    setState(() {
      _wordIdx = _random.nextInt(_words.length);
      // Color never matches the word 3 times in a row.
      do {
        _colorIdx = _random.nextInt(_colors.length);
      } while (_colorIdx == _wordIdx);
    });
  }

  void _start({bool freshMatch = false}) {
    if (freshMatch) _session.reset();
    setState(() {
      _running = true;
      _over = false;
      _score = 0;
      _missed = 0;
      _msLeft = _twoPlayer ? 15000 : 30000;
      _newWord();
    });
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      setState(() => _msLeft -= 100);
      if (_msLeft <= 0) _endTurn();
    });
  }

  void _endTurn() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _running = false;
      _msLeft = 0;
    });

    if (_session.isTwoPlayer) {
      final next = _session.finishRound(_score);
      if (next == 0) {
        // Match over — show result overlay.
        setState(() {
          _over = true;
          _running = false;
        });
      } else {
        setState(() {
          _over = false;
          _running = false;
          _score = 0;
          _missed = 0;
          _newWord();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Round done — Player $next, your turn!'),
              duration: const Duration(seconds: 2),
            ),
          );
          _start();
        }
      }
    } else {
      setState(() => _over = true);
    }
  }

  void _answer(int colorIdx) {
    if (!_running || _over) return;
    if (Prefs.haptics) {
      if (colorIdx == _colorIdx) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }
    setState(() {
      if (colorIdx == _colorIdx) {
        _score++;
      } else {
        _missed++;
      }
    });
    _newWord();
  }

  String get _status {
    if (_over) {
      if (_session.isTwoPlayer) return _session.winnerTitle;
      return 'Time up!';
    }
    final secs = (_msLeft / 1000).ceil();
    final p = _session.currentPlayer;
    return _twoPlayer ? 'Player $p — $secs s' : '$secs s left';
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Color Rush',
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(
                  children: [
                    _chip(
                      'Score',
                      '$_score',
                      _twoPlayer ? 'P${_session.currentPlayer}' : null,
                      AppColors.accent,
                    ),
                    const SizedBox(width: 10),
                    _chip('Missed', '$_missed', null, AppColors.subtext),
                    const Spacer(),
                    FloatingActionButton.small(
                      heroTag: 'crReset',
                      backgroundColor: AppColors.card,
                      foregroundColor: AppColors.accent,
                      onPressed: () => setState(() {
                        _running = false;
                        _over = false;
                        _score = 0;
                        _missed = 0;
                        _session.reset();
                        _msLeft = _twoPlayer ? 15000 : 30000;
                      }),
                      tooltip: 'Restart',
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
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _running ? _msLeft / (_twoPlayer ? 15000 : 30000) : 0,
                backgroundColor: AppColors.card,
                color: AppColors.accent,
                minHeight: 4,
              ),
              const SizedBox(height: 28),
              if (!_running && !_over) ...[
                const Text(
                  'Tap the color the word is PRINTED in,\nnot what it says.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.subtext, fontSize: 14),
                ),
                const SizedBox(height: 18),
                accentButton('Start', () => _start(freshMatch: true)),
                const Spacer(),
              ] else ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _words[_wordIdx],
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: _colors[_colorIdx],
                          ),
                        ),
                        const SizedBox(height: 34),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < 4; i++) ...[
                              _colorButton(i),
                              if (i < 3) const SizedBox(width: 12),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_over && Prefs.showResultScreens)
            ResultOverlay(
              type: _session.isTwoPlayer
                  ? _session.resultType
                  : ResultType.lose,
              title: _session.isTwoPlayer ? _session.winnerTitle : 'Time up!',
              subtitle: _twoPlayer
                  ? _session.matchSubtitle
                  : 'You scored $_score (${_missed} missed)',
              onPrimary: () {
                _start(freshMatch: true);
              },
              secondaryLabel: 'Home',
              onSecondary: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, String? sub, Color color) {
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
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(width: 5),
            Text(
              sub,
              style: const TextStyle(
                color: AppColors.subtext,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _colorButton(int i) {
    final correct = i == _colorIdx;
    return InkWell(
      onTap: () => _answer(i),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _colors[i],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: correct ? Colors.white : _colors[i],
            width: correct ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
