import 'package:flutter/material.dart';

import '../models/game_info.dart';
import '../services/prefs.dart';
import '../theme.dart';

/// Full-screen pre-game intro: tutorial, player mode (solo / vs bot / two
/// players), difficulty (Easy / Normal / Hard). The chosen mode + difficulty
/// are saved per game (via [Prefs]) and the game screen is pushed with those
/// applied. Back returns to the hub without starting.
class GameIntroScreen extends StatefulWidget {
  const GameIntroScreen({super.key, required this.game});

  final GameInfo game;

  @override
  State<GameIntroScreen> createState() => _GameIntroScreenState();
}

class _GameIntroScreenState extends State<GameIntroScreen> {
  String? _mode;
  int _difficulty = 1;

  @override
  void initState() {
    super.initState();
    _mode = Prefs.playerModeFor(widget.game.id);
    _difficulty = Prefs.difficultyFor(widget.game.id);
  }

  String get _effectiveMode => _mode ?? Prefs.playersSolo;

  Future<void> _start() async {
    await Prefs.setPlayerModeFor(widget.game.id, _effectiveMode);
    await Prefs.setDifficultyFor(widget.game.id, _difficulty);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: widget.game.builder),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.game.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoCard(title: 'Tutorial', body: widget.game.tutorial),
            const SizedBox(height: 20),
            const Text(
              'Players',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mode in _modes)
                  _ModeChip(
                    label: _modeLabel(mode),
                    icon: _modeIcon(mode),
                    selected: _effectiveMode == mode,
                    onTap: () => setState(() => _mode = mode),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Difficulty',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var d = 0; d <= 2; d++)
                  _DiffChip(
                    label: _diffLabel(d),
                    selected: _difficulty == d,
                    onTap: () => setState(() => _difficulty = d),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _start,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gameAmber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(
                    color: AppColors.bg,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> get _modes {
    final list = <String>[Prefs.playersSolo];
    if (widget.game.supportsBot) list.add(Prefs.playersBot);
    list.add(Prefs.playersTwo);
    return list;
  }
}

String _modeLabel(String m) => switch (m) {
      Prefs.playersSolo => 'Solo',
      Prefs.playersBot => 'vs Bot',
      Prefs.playersTwo => 'Two players',
      _ => m,
    };

IconData _modeIcon(String m) => switch (m) {
      Prefs.playersSolo => Icons.person_outline,
      Prefs.playersBot => Icons.smart_toy_outlined,
      _ => Icons.people_outline,
    };

String _diffLabel(int d) => switch (d) {
      0 => 'Easy',
      1 => 'Normal',
      2 => 'Hard',
      _ => 'Normal',
    };

IconData _diffIcon(int d) => switch (d) {
      0 => Icons.sentiment_satisfied,
      1 => Icons.sentiment_neutral,
      2 => Icons.sentiment_very_dissatisfied,
      _ => Icons.sentiment_neutral,
    };

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Chip(
      label: label,
      icon: icon,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.gameAmber : AppColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected ? AppColors.gameAmber : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? AppColors.bg : AppColors.subtext),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.bg : AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiffChip extends StatelessWidget {
  const _DiffChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Chip(
      label: label,
      icon: _diffIconFor(label),
      selected: selected,
      onTap: onTap,
    );
  }
}

IconData _diffIconFor(String label) => switch (label) {
      'Easy' => Icons.sentiment_satisfied,
      'Hard' => Icons.sentiment_very_dissatisfied,
      _ => Icons.sentiment_neutral,
    };
</content>
