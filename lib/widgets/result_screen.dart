import 'package:flutter/material.dart';

import '../theme.dart';

enum ResultType { win, lose, draw }

/// Shared win/lose/result overlay shown at the end of every game.
/// Can be switched off in Settings (Prefs.showResultScreens).
///
/// Place it as the last child of a Stack covering the game area:
///
///   Stack(children: [ game, if (showResult) ResultOverlay(...) ])
class ResultOverlay extends StatelessWidget {
  const ResultOverlay({
    super.key,
    required this.title,
    required this.type,
    this.subtitle,
    this.primaryLabel = 'Play again',
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final ResultType type;
  final String? subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  IconData get _icon => switch (type) {
    ResultType.win => Icons.emoji_events,
    ResultType.lose => Icons.sentiment_dissatisfied,
    ResultType.draw => Icons.balance,
  };

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppColors.bg.withValues(alpha: 0.78),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(_icon, color: AppColors.accent, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.subtext,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              accentButton(primaryLabel, onPrimary),
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(height: 10),
                ghostButton(secondaryLabel!, onSecondary!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


/// Full-screen match-over page used by the hub flow (Hangman, Tower of Hanoi).
/// Shows the result, best score when provided, and replay / hub actions.
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.type,
    required this.title,
    this.subtitle,
    this.bestScore,
    this.gameId,
    required this.onReplay,
    this.onHub,
  });

  final ResultType type;
  final String title;
  final String? subtitle;
  final int? bestScore;
  final String? gameId;
  final VoidCallback onReplay;
  final VoidCallback? onHub;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type == ResultType.win
                    ? Icons.emoji_events
                    : (type == ResultType.lose
                        ? Icons.sentiment_dissatisfied
                        : Icons.balance),
                size: 72,
                color: type == ResultType.win ? AppColors.accent : AppColors.subtext,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.subtext, fontSize: 15),
                ),
              ],
              if (bestScore != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Best: $bestScore',
                  style: const TextStyle(color: AppColors.subtext, fontSize: 13),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(onPressed: onReplay, child: const Text('Play again')),
              if (onHub != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: onHub, child: const Text('Back to hub')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
