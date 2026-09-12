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

/// Classic card-memory game: find all 8 emoji pairs in as few moves as
/// possible. Best score (fewest moves) is persisted.
/// Two players: pass-and-play — each player solves the full deck once;
/// fewer moves wins.
class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  /// Effective two-player flag for memory_match (per-game override wins).
  bool get twoPlayer => Prefs.effectiveTwoPlayer('memory_match');

  static const List<String> _symbols = [
    '🍎',
    '🍌',
    '🍇',
    '🍊',
    '🍓',
    '🍉',
    '🍒',
    '🥝',
  ];

  late List<String> _cards;
  late Set<int> _matched;
  final Set<int> _revealed = {};
  int _moves = 0;
  int? _firstIndex;
  bool _busy = false;
  int _best = 0;
  Timer? _flipBackTimer;
  bool _over = false;
  late final TwoPlayerSession _session;

  final _random = Random();

  @override
  void initState() {
    super.initState();
    _best = Prefs.bestScore('memory_match');
    _session = TwoPlayerSession(enabled: this.twoPlayer, lowerIsBetter: true);
    _startRound();
  }

  @override
  void dispose() {
    _flipBackTimer?.cancel();
    super.dispose();
  }

  void _startRound() {
    _flipBackTimer?.cancel();
    final deck = [..._symbols, ..._symbols]..shuffle(_random);
    setState(() {
      _cards = deck;
      _matched = {};
      _revealed.clear();
      _firstIndex = null;
      _moves = 0;
      _busy = false;
      _over = false;
    });
  }

  void _resetMatch() {
    _session.reset();
    _startRound();
  }

  void _onTap(int index) {
    if (_busy) return;
    if (_matched.contains(index) || _revealed.contains(index)) return;

    setState(() {
      _revealed.add(index);
      _moves++;
    });

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    final first = _firstIndex!;
    _firstIndex = null;
    _busy = true;
    if (_cards[first] == _cards[index]) {
      setState(() {
        _matched.add(first);
        _matched.add(index);
        _busy = false;
      });
      if (Prefs.haptics) HapticFeedback.lightImpact();
      _maybeWon();
    } else {
      _flipBackTimer = Timer(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        setState(() {
          _revealed.remove(first);
          _revealed.remove(index);
          _busy = false;
        });
      });
    }
  }

  Future<void> _maybeWon() async {
    if (_matched.length < _cards.length) return;

    if (_session.isTwoPlayer) {
      final next = _session.finishRound(_moves);
      if (next == 0) {
        // Match over — reveal winner.
        setState(() => _over = true);
        return;
      }
      // Other player's turn.
      setState(() => _over = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Player ${_session.currentPlayer} — your turn! Fewer moves wins.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      _startRound();
      return;
    }

    await Prefs.saveBestScore('memory_match', _moves);
    if (!mounted) return;
    final newBest = _moves;
    setState(() {
      _best = newBest;
      _over = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final who = _session.isTwoPlayer && !_session.finished
        ? 'P${_session.currentPlayer}'
        : null;
    return GameScaffold(
      title: 'Memory Match',
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _statChip('Moves', '$_moves'),
                        const SizedBox(width: 10),
                        if (!_session.isTwoPlayer)
                          _statChip('Best', _best == 0 ? '—' : '$_best'),
                        if (_session.isTwoPlayer)
                          _statChip(
                            'Score',
                            '${_session.scoreA} vs ${_session.scoreB}',
                          ),
                        const Spacer(),
                        FloatingActionButton.small(
                          heroTag: 'memRestart',
                          backgroundColor: AppColors.card,
                          foregroundColor: AppColors.accent,
                          onPressed: _session.isTwoPlayer
                              ? _resetMatch
                              : _startRound,
                          tooltip: 'Shuffle',
                          child: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      who == null
                          ? (_session.isTwoPlayer
                                ? 'Solve the deck with the fewest moves'
                                : 'Find all pairs in few moves')
                          : 'Player $who — your round',
                      style: const TextStyle(
                        color: AppColors.subtext,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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
                      child: GridView.count(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (var i = 0; i < _cards.length; i++) _cardTile(i),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_over && Prefs.showResultScreens)
            ResultOverlay(
              type: _session.isTwoPlayer ? _session.resultType : ResultType.win,
              title: _session.isTwoPlayer
                  ? _session.winnerTitle
                  : 'You matched them all!',
              subtitle: _session.isTwoPlayer
                  ? _session.matchSubtitle
                  : 'Finished in $_moves moves',
              onPrimary: _resetMatch,
              secondaryLabel: 'Home',
              onSecondary: () => Navigator.of(context).pop(),
            ),
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

  Widget _cardTile(int index) {
    final faceUp = _revealed.contains(index) || _matched.contains(index);
    return InkWell(
      onTap: () => _onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: faceUp
            ? Container(
                key: ValueKey('face-$index'),
                decoration: BoxDecoration(
                  color: _matched.contains(index)
                      ? AppColors.accent.withValues(alpha: 0.16)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _matched.contains(index)
                        ? AppColors.accent.withValues(alpha: 0.5)
                        : AppColors.cardBorder,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _cards[index],
                  style: const TextStyle(fontSize: 24),
                ),
              )
            : Container(
                key: ValueKey('back-$index'),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.question_mark,
                  color: AppColors.subtext,
                  size: 20,
                ),
              ),
      ),
    );
  }
}
