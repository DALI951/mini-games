import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_info.dart';
import '../services/prefs.dart';
import '../theme.dart';
import '../widgets/result_screen.dart';
import '../widgets/two_player.dart';

/// Classic snake on a 18x22 grid. Swipe to steer, eat the red food to grow,
/// don't hit walls or yourself. Speeds up as you eat.
/// Two players: pass-and-play — each player gets one run, higher score wins.
class SnakeScreen extends StatefulWidget {
  const SnakeScreen({super.key});

  @override
  State<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends State<SnakeScreen> {
  static const int _cols = 18;
  static const int _rows = 22;

  late List<Offset> _snake; // head first
  late Offset _food;
  late Offset _dir;
  late Offset _pendingDir;
  Timer? _timer;
  late int _score;
  int _best = 0;
  bool _running = false;
  bool _over = false;
  double _speedMs = 340;
  late final TwoPlayerSession _session;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _best = Prefs.bestScore('snake');
    _session = TwoPlayerSession(enabled: this.twoPlayer);
    _reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _snake = [const Offset(4, 10), const Offset(3, 10), const Offset(2, 10)];
      _dir = const Offset(1, 0);
      _pendingDir = const Offset(1, 0);
      _score = 0;
      _over = false;
      _speedMs = 340;
      _spawnFood();
    });
  }

  void _resetMatch() {
    _session.reset();
    _start();
  }

  void _start() {
    _reset();
    setState(() => _running = true);
    _timer = Timer.periodic(
      Duration(milliseconds: _speedMs.round()),
      (_) => _tick(),
    );
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _spawnFood() {
    while (true) {
      final candidate = Offset(
        _random.nextInt(_cols).toDouble(),
        _random.nextInt(_rows).toDouble(),
      );
      if (!_snake.contains(candidate)) {
        _food = candidate;
        return;
      }
    }
  }

  void _tick() {
    if (!_running || _over) return;
    _dir = _pendingDir;
    final head = _snake.first + _dir;

    if (head.dx < 0 || head.dx >= _cols || head.dy < 0 || head.dy >= _rows) {
      _gameOver();
      return;
    }

    final ate = head == _food;
    final next = [head, ..._snake];
    if (!ate) next.removeLast();
    if (next.skip(1).contains(head)) {
      _gameOver();
      return;
    }

    setState(() {
      _snake = next;
      if (ate) {
        _score++;
        _spawnFood();
        _speedMs = max(90, _speedMs - 8);
        _timer!.cancel();
        _timer = Timer.periodic(
          Duration(milliseconds: _speedMs.round()),
          (_) => _tick(),
        );
      }
    });
  }

  Future<void> _gameOver() async {
    _timer?.cancel();
    setState(() {
      _running = false;
      _over = true;
    });
    if (Prefs.haptics) HapticFeedback.heavyImpact();

    if (_session.isTwoPlayer) {
      final next = _session.finishRound(_score);
      if (next == 0) return; // match over — overlay shows the winner
      if (!mounted) return;
      setState(() => _over = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Player ${_session.currentPlayer} — your run!'),
          duration: const Duration(seconds: 2),
        ),
      );
      _start();
      return;
    }

    await Prefs.saveBestScore('snake', _score);
    if (!mounted) return;
    setState(() => _best = Prefs.bestScore('snake'));
  }

  void _steer(Offset newDir) {
    if (!_running || _over) return;
    if (newDir == -_dir && _snake.length > 1) return;
    _pendingDir = newDir;
  }

  @override
  Widget build(BuildContext context) {
    final isTwo = _session.isTwoPlayer;
    return GameScaffold(
      title: 'Snake',
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
                      heroTag: 'snakeStart',
                      backgroundColor: AppColors.card,
                      foregroundColor: AppColors.accent,
                      onPressed: isTwo
                          ? (_running ? _pause : _resetMatch)
                          : (_running ? _pause : _start),
                      tooltip: _running ? 'Pause' : 'Play',
                      child: Icon(_running ? Icons.pause : Icons.play_arrow),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity! > 0) {
                        _steer(const Offset(1, 0));
                      } else if (details.primaryVelocity! < 0) {
                        _steer(const Offset(-1, 0));
                      }
                    },
                    onVerticalDragEnd: (details) {
                      if (details.primaryVelocity! > 0) {
                        _steer(const Offset(0, 1));
                      } else if (details.primaryVelocity! < 0) {
                        _steer(const Offset(0, -1));
                      }
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cell = min(
                          constraints.maxWidth / _cols,
                          constraints.maxHeight / _rows,
                        );
                        return Container(
                          width: cell * _cols,
                          height: cell * _rows,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Stack(
                            children: [
                              for (final seg in _snake)
                                Positioned(
                                  left: seg.dx * cell + 1,
                                  top: seg.dy * cell + 1,
                                  width: cell - 2,
                                  height: cell - 2,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: seg == _snake.first
                                          ? AppColors.accent
                                          : AppColors.accent.withValues(
                                              alpha: 0.55,
                                            ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              Positioned(
                                left: _food.dx * cell + 1,
                                top: _food.dy * cell + 1,
                                width: cell - 2,
                                height: cell - 2,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accent.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isTwo && !_session.finished && !_over
                    ? 'Player ${_session.currentPlayer} — swipe to steer'
                    : 'Swipe to steer',
                style: const TextStyle(color: AppColors.subtext, fontSize: 12),
              ),
              const SizedBox(height: 6),
            ],
          ),
          if (_over && Prefs.showResultScreens)
            ResultOverlay(
              type: isTwo ? _session.resultType : ResultType.lose,
              title: isTwo ? _session.winnerTitle : 'Game over',
              subtitle: isTwo
                  ? _session.matchSubtitle
                  : 'Score $_score · Best $_best',
              onPrimary: isTwo ? _resetMatch : _start,
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
}
