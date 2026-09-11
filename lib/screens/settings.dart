import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import '../app_info.dart';
import '../models/game_info.dart';
import '../services/prefs.dart';
import '../services/update_service.dart';
import '../theme.dart';

/// Settings screen: gameplay toggles, high scores, updates and about.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.autoCheck = false});

  /// When true, runs an update check right away (used by the hub banner).
  final bool autoCheck;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _haptics = true;
  bool _firstBuildDone = false;

  UpdateStatus _status = UpdateStatus.idle;
  UpdateInfo? _update;
  String? _lastError;

  double _progress = 0;
  bool _downloading = false;
  String? _downloadedPath;

  @override
  void initState() {
    super.initState();
    _haptics = Prefs.haptics;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.autoCheck && !_firstBuildDone) {
      _firstBuildDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdates());
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _status = UpdateStatus.checking;
      _lastError = null;
      _update = null;
    });
    final info = await UpdateService().checkForUpdate();
    if (!mounted) return;
    setState(() {
      if (info != null) {
        _status = UpdateStatus.available;
        _update = info;
      } else {
        _status = UpdateStatus.upToDate;
      }
    });
  }

  Future<void> _downloadAndInstall() async {
    final info = _update;
    if (info == null || _downloading) return;
    if (_downloadedPath != null) {
      _install(_downloadedPath!);
      return;
    }

    setState(() {
      _downloading = true;
      _progress = 0;
    });

    final service = UpdateService();
    try {
      final path = await service.downloadApk(info, (received, total) {
        if (!mounted) return;
        setState(() {
          _progress = total > 0 ? received / total : 0;
        });
      });
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _progress = 1;
        _downloadedPath = path;
      });
      _install(path);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _lastError = 'Download failed — check your connection.';
      });
    } finally {
      service.dispose();
    }
  }

  Future<void> _install(String path) async {
    if (Prefs.haptics) HapticFeedback.mediumImpact();
    final result = await OpenFilex.open(
      path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Open the APK manually: $path'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _sectionTitle('Gameplay'),
          _card(
            children: [
              _toggleRow(
                title: 'Haptics',
                subtitle: 'Vibrate on taps and moves',
                value: _haptics,
                onChanged: (value) {
                  setState(() => _haptics = value);
                  Prefs.setHaptics(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('High scores'),
          _card(
            children: [
              for (final game in kGames) ...[
                _scoreRow(game),
                if (game != kGames.last) _divider(),
              ],
              _divider(),
              _row(
                onTap: _confirmResetScores,
                child: const Row(
                  children: [
                    Icon(
                      Icons.delete_sweep_outlined,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Reset all scores',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('Updates'),
          _card(
            children: [
              _row(
                child: Row(
                  children: [
                    const Text(
                      'Installed version',
                      style: TextStyle(color: AppColors.subtext, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      AppInfo.versionLabel,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _divider(),
              _updatePanel(),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('About'),
          _card(
            children: [
              const Row(
                children: [
                  Icon(Icons.games_outlined, color: AppColors.accent, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'MiniGames — a growing hub of mini games.',
                    style: TextStyle(color: AppColors.subtext, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Built by DALI951 · ${AppInfo.repo}',
                style: const TextStyle(color: AppColors.subtext, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _updatePanel() {
    switch (_status) {
      case UpdateStatus.idle:
        return _row(
          onTap: _checkForUpdates,
          child: const Row(
            children: [
              Icon(Icons.update, color: AppColors.accent, size: 20),
              SizedBox(width: 12),
              Text(
                'Check for updates',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      case UpdateStatus.checking:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(
                'Checking for updates…',
                style: TextStyle(color: AppColors.subtext, fontSize: 13),
              ),
            ],
          ),
        );
      case UpdateStatus.upToDate:
        return Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.gameGreen,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "You're on the latest version.",
                style: TextStyle(color: AppColors.subtext, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _checkForUpdates,
              child: const Text('Check again'),
            ),
          ],
        );
      case UpdateStatus.available:
        final info = _update!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.system_update_alt,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Update ${info.version} available',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (info.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                info.notes,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.subtext, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            if (_downloading)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    backgroundColor: AppColors.cardBorder,
                    color: AppColors.accent,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(_progress * 100).round()}%',
                    style: const TextStyle(
                      color: AppColors.subtext,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            else
              accentButton(
                _downloadedPath != null ? 'Install now' : 'Download & install',
                _downloadAndInstall,
              ),
            if (_lastError != null) ...[
              const SizedBox(height: 8),
              Text(
                _lastError!,
                style: const TextStyle(color: AppColors.accent, fontSize: 12),
              ),
            ],
          ],
        );
      case UpdateStatus.error:
        return Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.accent, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Could not reach GitHub.',
                style: TextStyle(color: AppColors.subtext, fontSize: 13),
              ),
            ),
            TextButton(onPressed: _checkForUpdates, child: const Text('Retry')),
          ],
        );
    }
  }

  Future<void> _confirmResetScores() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Reset all scores?',
          style: TextStyle(color: AppColors.text, fontSize: 17),
        ),
        content: const Text(
          'This clears every high score in MiniGames.',
          style: TextStyle(color: AppColors.subtext, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await Prefs.resetAllScores();
      if (mounted) setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scores reset.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.subtext,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
      ),
    ),
  );

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Column(children: children),
  );

  Widget _divider() => const Divider(
    height: 1,
    thickness: 1,
    color: AppColors.cardBorder,
    indent: 12,
    endIndent: 12,
  );

  Widget _row({required Widget child, VoidCallback? onTap}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: child,
    ),
  );

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.subtext,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.accentDark,
            activeThumbColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(GameInfo game) {
    final best = Prefs.bestScore(game.id);
    return _row(
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: game.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(game.icon, color: game.color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              game.title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            best > 0 ? '$best' : '—',
            style: const TextStyle(
              color: AppColors.subtext,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
