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
