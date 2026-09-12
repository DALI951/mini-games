import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/prefs.dart';
import '../theme.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/result_screen.dart';

/// Mastermind — crack the hidden code.
///
/// Solo / vs Bot: the bot hides a code and you guess it. Two players: P1
/// hides the code (secret), P2 guesses. Feedback: black peg = right colour in
/// the right spot, white peg = right colour in a wrong spot.
class MastermindScreen extends StatefulWidget {
  const MastermindScreen({super.key});

  @override
  State<MastermindScreen> createState() => _MastermindScreenState();
}

class _MastermindScreenState extends State<MastermindScreen> {
  static const List<Color> _palette = [
    AppColors.gameRed,
    AppColors.gameAmber,
    AppColors.gameGreen,
    AppColors.gameBlue,
    AppColors.gameViolet,
    Color(0xFFEC4899), // pink
    Color(0xFF06B6D4), // cyan
    Color(0xFFF59E0B), // orange
  ];

  late bool _two;
  late int _diff;
  late int _cols;
  late int _tries;

  bool _settingCode = false; // true while P1 chooses the secret
  List<int> _secret = [];
  List<int> _guess = [];
  final List<List<int>> _history = [];
  final List<(int, int)> _hFeedback = []; // (black, white)
  bool _won = false;
  bool _over = false;

  @override
  void initState() {
    super.initState();
    _two = Prefs.effectiveTwoPlayer('mastermind');
    _diff = Prefs.difficultyFor('mastermind');
    _cols = _diff == 2 ? 5 : 4;
    _tries = switch (_diff) {
      0 => 12,
      1 => 10,
      _ => 9,
    };
    _secret = _randomCode();
    _settingCode = _two; // two-player: P1 hides first
    _guess = List.filled(_cols, -1);
  }

  List<int> _randomCode() {
    return List<int>.generate(_cols,
        (_) => math.Random().nextInt(_diff == 2 ? 8 : 6));
  }

  void _submit() {
    if (_guess.contains(-1)) return;
    if (_settingCode) {
      // P1 locks the secret in — the guesser takes over
      setState(() {
        _secret = List<int>.from(_guess);
        _guess = List.filled(_cols, -1);
        _settingCode = false;
      });
      return;
    }
    final fb = _feedback(_secret, _guess);
    setState(() {
      _history.add(List<int>.from(_guess));
      _hFeedback.add(fb);
      _guess = List.filled(_cols, -1);
      if (fb.$1 == _cols) {
        _won = true;
        _over = true;
      } else if (_history.length >= _tries) {
        _over = true;
      }
    });
    if (_over) _finish();
  }

  (int, int) _feedback(List<int> secret, List<int> guess) {
    var black = 0;
    for (var i = 0; i < _cols; i++) {
      if (secret[i] == guess[i]) black++;
    }
    var white = 0;
    for (final g in guess.toSet()) {
      final inSecret = secret.where((s) => s == g).length;
      final inGuess = guess.where((s) => s == g).length;
      white += math.min(inSecret, inGuess);
    }
    white -= black;
    return (black, white);
  }

  void _finish() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final title = _two
          ? (_won ? 'Player 2 cracks it!' : "P2 didn't crack it")
          : (_won ? 'Cracked!' : 'Out of tries');
      final subtitle = _won
          ? 'In ${_history.length} of $_tries tries'
          : 'The code was ${_secret.join(' ')}';
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            type: _won ? ResultType.win : ResultType.lose,
            title: title,
            subtitle: subtitle,
            bestScore: _history.length,
            gameId: 'mastermind',
            onReplay: () => Navigator.of(context)
                .pushReplacement(MaterialPageRoute<void>(
                  builder: (_) => const MastermindScreen(),
                )),
            onHub: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Mastermind',
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _statusLine(),
            const SizedBox(height: 10),
            Expanded(
              child: _history.isEmpty
                  ? _hintBox()
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (_, i) =>
                          _guessRow(_history[i], _hFeedback[i]),
                    ),
            ),
            const SizedBox(height: 10),
            _currentRow(),
            const SizedBox(height: 10),
            _paletteRow(),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _over ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gameAmber,
                  disabledBackgroundColor: AppColors.card,
                ),
                child: Text(
                  _settingCode
                      ? 'Lock the code'
                      : (_over ? 'Game over' : 'Check guess'),
                  style: TextStyle(
                    color: _over ? AppColors.subtext : AppColors.bg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusLine() {
    final color = _two ? AppColors.gameBlue : AppColors.gameRed;
    final text = _settingCode
        ? 'P1 — pick a secret code'
        : (_two
            ? 'P2 — crack P1\u2019s code'
            : 'Crack the bot\u2019s code  ·  ${_tries - _history.length} tries left');
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _hintBox() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Text(
        'Black peg = right colour, right spot.\nWhite peg = right colour, wrong spot.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.subtext, fontSize: 13),
      ),
    );
  }

  Widget _currentRow() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _cols; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: InkWell(
                key: ValueKey('mm-slot-$i'),
                onTap: _over ? null : () => _clearSlot(i),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _guess[i] >= 0
                        ? _palette[_guess[i]]
                        : AppColors.bg,
                    border: Border.all(
                        color: AppColors.cardBorder, width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _clearSlot(int i) => setState(() => _guess[i] = -1);

  Widget _paletteRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (i, c) in _palette.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              key: ValueKey('mm-color-$i'),
              onTap: _over ? null : () => _pick(i),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c,
                  border: Border.all(color: AppColors.cardBorder),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _pick(int color) {
    final i = _guess.indexOf(-1);
    if (i == -1) return;
    setState(() => _guess[i] = color);
  }

  Widget _guessRow(List<int> code, (int, int) fb) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          for (final c in code)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _palette[c],
                ),
              ),
            ),
          const Spacer(),
          _feedbackDots(fb.$1, AppColors.text),
          const SizedBox(width: 6),
          _feedbackDots(fb.$2, AppColors.subtext),
        ],
      ),
    );
  }

  Widget _feedbackDots(int n, Color color) {
    return Row(
      children: [
        for (var i = 0; i < n; i++)
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
      ],
    );
  }
}