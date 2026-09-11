import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences: settings + per-game high scores.
class Prefs {
  Prefs._();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Test-only: clears the cached instance so the next [init] reloads.
  @visibleForTesting
  static void debugReset() {
    _prefs = null;
  }

  static SharedPreferences get _p {
    assert(_prefs != null, 'Prefs.init() must be called first');
    return _prefs!;
  }

  // ---- settings ----

  static const _kHaptics = 'settings.haptics';
  static const _kTwoPlayer = 'settings.twoPlayer';
  static const _kShowResults = 'settings.showResultScreens';

  static bool get haptics => _p.getBool(_kHaptics) ?? true;

  static Future<void> setHaptics(bool value) => _p.setBool(_kHaptics, value);

  /// Global game mode. When true every game plays in two-player mode
  /// (head-to-head where possible, pass-and-play otherwise).
  static bool get twoPlayer => _p.getBool(_kTwoPlayer) ?? false;

  static Future<void> setTwoPlayer(bool value) =>
      _p.setBool(_kTwoPlayer, value);

  /// Shows the win/lose result overlay at the end of every game.
  static bool get showResultScreens => _p.getBool(_kShowResults) ?? true;

  static Future<void> setShowResultScreens(bool value) =>
      _p.setBool(_kShowResults, value);

  // ---- high scores ----

  static String _scoreKey(String gameId) => 'highscore.$gameId';

  static int bestScore(String gameId) => _p.getInt(_scoreKey(gameId)) ?? 0;

  static Future<void> saveBestScore(String gameId, int score) async {
    if (score <= bestScore(gameId)) return;
    await _p.setInt(_scoreKey(gameId), score);
  }

  static Future<void> resetAllScores() async {
    for (final game in _gameIds) {
      await _p.remove(_scoreKey(game));
    }
  }

  static const List<String> _gameIds = [
    'memory_match',
    'simon_says',
    'snake',
    'game_2048',
    'tic_tac_toe',
    'rps',
    'connect_four',
    'color_rush',
    'word_unscramble',
    'higher_lower',
  ];
}
