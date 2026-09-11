import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_info.dart';
import '../services/prefs.dart';
import '../theme.dart';

/// Classic card-memory game: find all 8 emoji pairs in as few moves as
/// possible. Best score (fewest moves) is persisted.
class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
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

  final _random = Random();

  @override
  void initState() {
    super.initState();
    _best = Prefs.bestScore('memory_match');
    _start();
  }

  @override
  void dispose() {
    _flipBackTimer?.cancel();
    super.dispose();
  }

  void _start() {
    _flipBackTimer?.cancel();
    final deck = [..._symbols, ..._symbols]..shuffle(_random);
    setState(() {
      _cards = deck;
      _matched = {};
      _revealed.clear();
      _firstIndex = null;
      _moves = 0;
      _busy = false;
    });
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
    await Prefs.saveBestScore('memory_match', _moves);
    if (!mounted) return;
    final newBest = _moves;
    setState(() => _best = newBest);
    if (mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'You matched them all!',
            style: TextStyle(color: AppColors.text, fontSize: 17),
          ),
          content: Text(
            'Finished in $_moves moves.',
            style: const TextStyle(color: AppColors.subtext, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _start();
              },
              child: const Text(
                'Play again',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Memory Match',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                _statChip('Moves', '$_moves'),
                const SizedBox(width: 10),
                _statChip('Best', _best == 0 ? '—' : '$_best'),
                const Spacer(),
                FloatingActionButton.small(
                  heroTag: 'memRestart',
                  backgroundColor: AppColors.card,
                  foregroundColor: AppColors.accent,
                  onPressed: _start,
                  tooltip: 'Shuffle',
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
      body: Row(
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
      body: AnimatedSwitcher(
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
