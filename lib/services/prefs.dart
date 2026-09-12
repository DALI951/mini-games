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

  static const playersSolo = 'solo';
  static const playersBot = 'bot';
  static const playersTwo = 'two';

  /// Global default mode. When true games default to two-player
  /// (head-to-head where possible, pass-and-play otherwise). Individual
  /// games can override this via [playerModeFor].
  static bool get twoPlayer => _p.getBool(_kTwoPlayer) ?? false;

  static Future<void> setTwoPlayer(bool value) =>
      _p.setBool(_kTwoPlayer, value);

  static const _kModePrefix = 'game.mode.';

  /// Identifier for the Hangman game (used by its own mode/difficulty keys).
  static const hangmanId = 'hangman';

  /// The two hard-coded two-player mode strings used by the intro panel.

  /// Per-game mode override: 'solo', 'bot' or 'two'. Null when the game
  /// should follow the global [twoPlayer] switch.
  static String? playerModeFor(String gameId) =>
      _p.getString('$_kModePrefix$gameId');

  static Future<void> setPlayerModeFor(String gameId, String mode) =>
      _p.setString('$_kModePrefix$gameId', mode);

  static Future<void> clearPlayerModeFor(String gameId) =>
      _p.remove('$_kModePrefix$gameId');

  /// Effective two-player flag for a game: per-game override wins, otherwise
  /// the global switch.
  static bool effectiveTwoPlayer(String gameId) {
    final m = playerModeFor(gameId);
    if (m == playersTwo) return true;
    if (m == playersBot || m == playersSingle) return false;
    return twoPlayer;
  }

  /// Recomputation helpers used by the intro panel so mode chips stay in sync.
  static String playerModeLabelFor(String gameId) {
    final m = playerModeFor(gameId);
    if (m == playersTwo) return 'Two players';
    if (m == playersBot) return 'vs Bot';
    if (m == playersSingle) return 'Solo';
    return twoPlayer ? 'Two players' : 'Solo';
  }

  static const _kDiffPrefix = 'game.diff.';

  /// Per-game difficulty: 0 = Easy, 1 = Normal, 2 = Hard (default Normal).
  static int difficultyFor(String gameId) =>
      _p.getInt('$_kDiffPrefix$gameId') ?? 1;

  static Future<void> setDifficultyFor(String gameId, int value) =>
      _p.setInt('$_kDiffPrefix$gameId', value);

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
