import 'package:flutter/material.dart';

import '../theme.dart';
import 'two_player.dart';

/// Shared chrome for every game screen: an AppBar with the game title, the
/// body supplied by the game, and (when a two-player session is active) a
/// round banner showing scores / whose turn it is.
class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.title,
    required this.body,
    this.session,
    this.matchBannerTitle,
    this.showScores = true,
  });

  final String title;
  final Widget body;

  /// Optional pass-and-play session. When non-null and [session.enabled], a
  /// banner with the current player + scores is shown under the AppBar.
  final TwoPlayerSession? session;

  /// Override for the banner title (defaults to the two-player round state).
  final String? matchBannerTitle;

  final bool showScores;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final banner = (s != null && s.enabled)
        ? Container(
            width: double.infinity,
            color: AppColors.card,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              matchBannerTitle ??
                  (s.finished
                      ? s.winnerTitle
                      : 'Player ${s.currentPlayer} — to move'),
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        : const SizedBox.shrink();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        title: Text(title),
      ),
      body: Column(
        children: [
          banner,
          Expanded(child: body),
        ],
      ),
    );
  }
}
