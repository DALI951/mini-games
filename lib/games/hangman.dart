import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_info.dart';
import '../services/prefs.dart';
import '../theme.dart';
import '../widgets/result_screen.dart';
import '../widgets/two_player.dart';

/// Hangman: a hidden word, one letter revealed per correct guess. Wrong
/// letters cost a life — run out and the word wins boil. Difficulty changes
/// how many lives you get (Easy = 8, Normal = 5, Hard = 3). Two players:
/// pass-and-play, each player solves the same-ish word pool on their own
/// turn; fewer wrong guesses wins the match (best-of rounds).
class HangmanScreen extends StatefulWidget {
  const HangmanScreen({super.key});

  @override
  State<HangmanScreen> createState() => _HangmanScreenState();
}

class _HangmanScreenState extends State<HangmanScreen> {
  late TwoPlayerSession _session;
  late int _lives;
  late String _word;
  final Set<String> _guessed = {};

  static const _words = [
    'cat', 'dog', 'run', 'sun', 'hat', 'cup', 'fox', 'pen', 'egg', 'key',
    'wave', 'lake', 'tree', 'bird', 'star', 'moon', 'fire', 'wind', 'rain',
    'sand', 'gold', 'mint', 'flag', 'ship', 'lamp', 'book', 'door', 'cake',
  ];

  @override
  void initState() {
    super.initState();
    final diff = Prefs.difficultyFor(Prefs.hangmanId);
    _lives = switch (diff) { 0 => 8, 2 => 3, _ => 5 };
    _newVerb();
    if (Prefs.effectiveTwoPlayer(Prefs.hangmanId)) {
      _session = TwoPlayerSession(enabled: true, lowerIsBetter: true);
    }
    _session = TwoPlayerSession(
      enabled: Prefs.effectiveTwoPlayer(Prefs.hangmanId) == false
          ? false
          : Prefs.effectiveTwoPlayer(Prefs.hangmanId),
    );
  }

  void _newVerb() {
    _word = _words[Random().nextInt(_words.length)];
    _guessed.clear();
    setState(() {});
  }

  int get _wrong => _guessed.where((c) => !_word.contains(c)).length;
  bool get _won => _word.split('').every(_guessed.contains);
  bool get _lost => _wrong >= _lives;

  void _tap(String ch) {
    if (_won || _lost) return;
    setState(() => _guessed.add(ch));
    if (_lost || _won) _endRound();
  }

  void _endRound() {
    if (_session.enabled) {
      final next = _session.finishRound(_wrong);
      if (next == 0) {
        _finishMatch();
      } else {
        setState(_newVerb);
      }
    } else {
      _finishSolo();
    }
  }

  void _finishSolo() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          type: _won ? ResultType.win : ResultType.lose,
          title: _won ? 'Solved!' : 'The word was \"$_word\"',
          subtitle: _won ? 'Wrong guesses: $_wrong' : 'Better luck next time',
          bestScore: _won ? _wrong + 1 : _wrong,
          gameId: Prefs.hangmanId,
          onReplay: _newVerb,
          onHub: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
    );
  }

  void _finishMatch() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          type: _session.resultType,
          title: _session.winnerTitle,
          subtitle: _session.fullSubtitle,
          bestScore: _session.winnerScore,
          gameId: Prefs.hangmanId,
          onReplay: _newVerb,
          onHub: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = gameScaffold('Hangman');
    // simplified: reuse a consistent scaffold via GameScaffold
    return Scaffold(
      appBar: AppBar(title: const Text('Hangman')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              _session.enabled ? 'Player ${_session.currentPlayer}'
                  : 'Guess the word',
              style: const TextStyle(
                color: AppColors.subtext,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              List.generate(_word.length,
                      (_) => _word.characters.first) // placeholder replaced below
                  .join(),
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _word.split('').map((c) => _guessed.contains(c) ? c : '_').join(' '),
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Lives: ${_lives - _wrong}',
              style: const TextStyle(color: AppColors.subtext, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 7,
                children: [
                  for (final c in 'abcdefghijklmnopqrstuvwxyz'.split(''))
                    Padding(
                      padding: const EdgeInsets.all(3),
                      child: FilledButton(
                        onPressed: () => _tap(c),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.card,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          c.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
