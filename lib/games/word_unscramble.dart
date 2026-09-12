import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_info.dart';
import '../services/prefs.dart';
import '../theme.dart';
import '../widgets/result_screen.dart';
import '../widgets/game_scaffold.dart';

const _pairs = <List<String>>[
  ['FLUTTER', 'DART'],
  ['PYTHON', 'SNAKE'],
  ['CREATE', 'MOD'],
  ['MINECRAFT', 'CRAFT'],
  ['TUNISIA', 'CARTHAGE'],
  ['GITHUB', 'REPOS'],
  ['PIXELS', 'GRAPHIC'],
  ['BENAROUS', 'SUBURB'],
  ['RAMADAN', 'FASTING'],
  ['SCOOTER', 'WHEELS'],
];

/// Word Unscramble — unscramble the word, pick the answer below.
/// Single: 3 wrong answers and it's game over.
/// Two players: first to 5 correct answers wins (miss = turn passes).
class WordUnscrambleScreen extends StatefulWidget {
  const WordUnscrambleScreen({super.key});

  @override
  State<WordUnscrambleScreen> createState() => _WordUnscrambleScreenState();
}

class _WordUnscrambleScreenState extends State<WordUnscrambleScreen> {
  /// Effective two-player flag for word_unscramble (per-game override wins).
  bool get twoPlayer => Prefs.effectiveTwoPlayer('word_unscramble');

  late bool _twoPlayer;
  static final _random = Random();

  int _pairIdx = _random.nextInt(_pairs.length);
  late String _scrambled;
  final List<String> _options = [];
  int _lives = 3;
  int _score = 0;

  // Two-player state: first to 5.
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
    _nextQuestion(skipPairReset: true);
  }

  void _nextQuestion({bool skipPairReset = false}) {
    if (!skipPairReset) {
      _pairIdx = _random.nextInt(_pairs.length);
    }
    final word = _pairs[_pairIdx][0];
    final correct = _pairs[_pairIdx][1];
    _scrambled = _shuffleWord(word);
    final wrongs = _pairs
        .map((p) => p[1])
        .where((a) => a != correct)
        .take(3)
        .toList();
    _options
      ..clear()
      ..addAll([correct, ...wrongs])
      ..shuffle(_random);
    _answered = false;
  }

  String _shuffleWord(String w) {
    var chars = w.split('')..shuffle(_random);
    if (chars.join() == w) {
      chars = w.split('')..shuffle(_random);
    }
    return chars.join();
  }

  void _resetGame() {
    setState(() {
      _over = false;
      _overTitle = '';
      _lives = 3;
      _score = 0;
      _p1 = 0;
      _p2 = 0;
      _turn = 1;
      _nextQuestion(skipPairReset: true);
    });
  }

  void _answer(String choice) {
    if (_answered || _over) return;
    final correct = _pairs[_pairIdx][1];
    final isRight = choice == correct;
    if (Prefs.haptics) {
      if (isRight) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }

    setState(() {
      _answered = true;
      if (isRight) {
        if (_twoPlayer) {
          if (_turn == 1) {
            _p1++;
            if (_p1 >= 5) {
              _over = true;
              _overTitle = 'Player 1 wins!';
            }
          } else {
            _p2++;
            if (_p2 >= 5) {
              _over = true;
              _overTitle = 'Player 2 wins!';
            }
          }
        } else {
          _score++;
        }
      } else {
        if (_twoPlayer) {
          // Miss = turn passes to the other player.
          _turn = _turn == 1 ? 2 : 1;
        } else {
          _lives--;
          if (_lives <= 0) {
            _over = true;
            _overTitle = 'Out of lives!';
          }
        }
      }
    });

    if (_over) return;

    if (isRight) {
      _nextQuestion();
      return;
    }

    // Wrong answer: show the correct word briefly, then continue.
    if (_twoPlayer) {
      final next = _turn;
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted || _over) return;
        setState(_nextQuestion);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Miss! Player $next — your turn'),
            duration: const Duration(seconds: 2),
          ),
        );
      });
    } else {
      if (_lives <= 0) return;
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted || _over) return;
        setState(_nextQuestion);
      });
    }
  }

  String get _status {
    if (_twoPlayer) {
      return _over
          ? _overTitle
          : 'P1: $_p1 · P2: $_p2 — Player $_turn, first to 5';
    }
    if (_over) return _overTitle;
    return 'Lives: $_lives · Solved: $_score';
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Word Unscramble',
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
                      _chip('Solved', '$_score', AppColors.accent),
                      const SizedBox(width: 10),
                      _chip('Lives', '$_lives', AppColors.subtext),
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
              const SizedBox(height: 26),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Unscramble the word',
                        style: TextStyle(
                          color: AppColors.subtext,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _scrambled,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: 280,
                        child: Column(
                          children: [
                            for (var k = 0; k < _options.length; k++) ...[
                              _optionButton(_options[k]),
                              if (k < _options.length - 1)
                                const SizedBox(height: 10),
                            ],
                          ],
                        ),
                      ),
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
                  : 'Words solved: $_score',
              onPrimary: _resetGame,
              secondaryLabel: 'Home',
              onSecondary: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  Widget _optionButton(String choice) {
    final correct = _pairs[_pairIdx][1];
    final isCorrect = _answered && choice == correct;
    final isWrong = _answered && choice != correct;
    Color border = AppColors.cardBorder;
    if (isCorrect) border = AppColors.accent;
    if (isWrong) border = AppColors.subtext;

    return InkWell(
      onTap: _answered || _over ? null : () => _answer(choice),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: border,
            width: isCorrect || isWrong ? 2 : 1,
          ),
        ),
        child: Text(
          choice,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isCorrect
                ? AppColors.accent
                : isWrong
                ? Colors.white70
                : AppColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
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
