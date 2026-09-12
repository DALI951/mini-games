import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_info.dart';
import '../services/prefs.dart';
import '../theme.dart';
import '../widgets/result_screen.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/two_player.dart';

/// Simon Says: watch the light sequence, then repeat it. One step longer
/// every round; a wrong tap ends the run.
/// Two players: pass-and-play — each player runs once, higher score wins.
class SimonScreen extends StatefulWidget {
  const SimonScreen({super.key});

  @override
  State<SimonScreen> createState() => _SimonScreenState();
}

class _SimonScreenState extends State<SimonScreen> {
  /// Effective two-player flag for simon_says (per-game override wins).
  bool get twoPlayer => Prefs.effectiveTwoPlayer('simon_says');

  static const _colors = [
    Color(0xFF7F1D1D), // red (dim)
    Color(0xFF064E3B), // green (dim)
    Color(0xFF1E3A8A), // blue (dim)
    Color(0xFF78350F), // yellow/amber (dim)
  ];
  static const _colorsLit = [
    Color(0xFFDC2626),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
  ];

  late List<int> _sequence;
  int _playerStep = 0;
  int _score = 0;
  int _best = 0;
  bool _playerTurn = false;
  bool _busy = false;
  int _lit = -1;
  int _runId = 0; // cancels stale async gaps on restart/dispose
  bool _over = false;
  late final TwoPlayerSession _session;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _best = Prefs.bestScore('simon_says');
    _session = TwoPlayerSession(enabled: this.twoPlayer);
    _sequence = [];
  }

  @override
  void dispose() {
    _runId++;
    super.dispose();
  }

  Future<void> _start() async {
    _runId++;
    final id = _runId;
    setState(() {
      _sequence = [];
      _score = 0;
      _playerTurn = false;
      _busy = true;
      _lit = -1;
      _over = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || id != _runId) return;
    _nextRound();
  }

  Future<void> _nextRound() async {
    final id = _runId;
    setState(() {
      _sequence.add(_random.nextInt(4));
      _playerTurn = false;
      _busy = true;
    });
    await _showSequence(id);
    if (!mounted || id != _runId) return;
    setState(() {
      _playerTurn = true;
      _busy = false;
      _playerStep = 0;
    });
  }

  Future<void> _showSequence(int id) async {
    for (final pad in _sequence) {
      if (!mounted || id != _runId) return;
      setState(() => _lit = -1);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted || id != _runId) return;
      setState(() => _lit = pad);
      await Future<void>.delayed(const Duration(milliseconds: 380));
    }
    if (!mounted || id != _runId) return;
    setState(() => _lit = -1);
  }

  void _tapPad(int pad) {
    if (!_playerTurn) return;
    if (Prefs.haptics) HapticFeedback.lightImpact();
    setState(() => _lit = pad);
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (mounted && _lit == pad) setState(() => _lit = -1);
    });

    if (pad != _sequence[_playerStep]) {
      _gameOver();
      return;
    }
    _playerStep++;
    if (_playerStep >= _sequence.length) {
      setState(() => _score = _sequence.length);
      _advance();
    }
  }

  void _advance() {
    final id = _runId;
    Future<void>.delayed(const Duration(milliseconds: 400), () async {
      if (!mounted || id != _runId) return;
      await _nextRound();
    });
  }

  Future<void> _gameOver() async {
    _runId++;
    final id = _runId;
    final runScore = _score;
    setState(() {
      _playerTurn = false;
      _busy = true;
      _lit = -1;
    });

    if (_session.isTwoPlayer) {
      final next = _session.finishRound(runScore);
      if (next == 0) {
        setState(() => _over = true);
        return;
      }
      if (!mounted || id != _runId) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Player ${_session.currentPlayer} — your turn!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      await _start();
      return;
    }

    await Prefs.saveBestScore('simon_says', runScore);
    if (!mounted || id != _runId) return;
    final newBest = Prefs.bestScore('simon_says');
    setState(() {
      _best = newBest;
      _over = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTwo = _session.isTwoPlayer;
    final who = isTwo && !_session.finished ? _session.currentPlayer : null;
    final statusText = _playerTurn
        ? (who != null
              ? 'Player $who — repeat the sequence'
              : 'Your turn — repeat the sequence')
        : _busy
        ? 'Watch…'
        : who != null
        ? 'Player $who — tap start'
        : 'Tap start to play';

    return GameScaffold(
      title: 'Simon Says',
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    _statChip('Score', '$_score'),
                    const SizedBox(width: 10),
                    if (isTwo)
                      _statChip(
                        'Match',
                        '${_session.scoreA} vs ${_session.scoreB}',
                      )
                    else
                      _statChip('Best', _best == 0 ? '—' : '$_best'),
                    const Spacer(),
                    FloatingActionButton.small(
                      heroTag: 'simonStart',
                      backgroundColor: AppColors.card,
                      foregroundColor: AppColors.accent,
                      onPressed: isTwo ? _resetMatch : _start,
                      tooltip: _sequence.isEmpty ? 'Start' : 'Restart',
                      child: Icon(
                        _sequence.isEmpty ? Icons.play_arrow : Icons.refresh,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                statusText,
                style: const TextStyle(
                  color: AppColors.subtext,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [for (var i = 0; i < 4; i++) _pad(i)],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_over && Prefs.showResultScreens)
            ResultOverlay(
              type: isTwo ? _session.resultType : ResultType.lose,
              title: isTwo
                  ? _session.winnerTitle
                  : (_score > 0 ? 'Score $_score' : 'Oops!'),
              subtitle: isTwo
                  ? _session.matchSubtitle
                  : 'The sequence got you${_score > 0 ? " after $_score steps" : ""}',
              onPrimary: _resetMatch,
              secondaryLabel: 'Home',
              onSecondary: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  void _resetMatch() {
    _session.reset();
    _start();
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

  Widget _pad(int index) {
    final isLit = _lit == index;
    return GestureDetector(
      onTap: () => _tapPad(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: isLit ? _colorsLit[index] : _colors[index],
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isLit
                ? _colorsLit[index].withValues(alpha: 0.8)
                : AppColors.cardBorder,
          ),
          boxShadow: isLit
              ? [
                  BoxShadow(
                    color: _colorsLit[index].withValues(alpha: 0.4),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
