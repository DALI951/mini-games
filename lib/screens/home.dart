import 'package:flutter/material.dart';

import '../app_info.dart';
import '../models/game_info.dart';
import '../services/update_service.dart';
import '../theme.dart';
import 'settings.dart';

/// The game hub: a grid of all available games, one card each.
/// Also surfaces a slim banner when a newer release exists.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UpdateInfo? _update;
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final info = await UpdateService().checkForUpdate();
    if (!mounted) return;
    if (info != null) {
      setState(() => _update = info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MiniGames'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  AppInfo.versionLabel,
                  style: const TextStyle(
                    color: AppColors.subtext,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            'Pick a game',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${kGames.length} games and counting — more added with every version.',
            style: const TextStyle(color: AppColors.subtext, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (_update != null && !_bannerDismissed) ...[
            _UpdateBanner(
              info: _update!,
              onDismiss: () => setState(() => _bannerDismissed = true),
              onOpen: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(autoCheck: true),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _GameGrid(games: kGames),
        ],
      ),
    );
  }
}

class _GameGrid extends StatelessWidget {
  const _GameGrid({required this.games});

  final List<GameInfo> games;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) => _GameCard(game: games[index]),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});

  final GameInfo game;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: game.builder)),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: game.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(game.icon, color: game.color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    game.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.subtext,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({
    required this.info,
    required this.onDismiss,
    required this.onOpen,
  });

  final UpdateInfo info;
  final VoidCallback onDismiss;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.system_update_alt,
            color: AppColors.accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Update ${info.version} available — Install',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onOpen,
            icon: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.text,
            ),
            tooltip: 'Open settings',
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 18, color: AppColors.subtext),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}
