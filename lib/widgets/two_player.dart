import 'result_screen.dart';

/// Pass-and-play session for two-player arcade games.
///
/// How it works: player 1 plays a full round, then player 2 plays a full
/// round. [finishRound] records the score, switches to the other player and
/// returns the next player (1 or 2), or 0 when both players have played —
/// at which point [winnerIdx] / [resultType] describe the match result.
class TwoPlayerSession {
  TwoPlayerSession({required this.enabled, this.lowerIsBetter = false});

  final bool enabled;

  /// Memory-style games where a LOWER number wins.
  final bool lowerIsBetter;

  int _current = 1;
  int? _a;
  int? _b;

  bool get isTwoPlayer => enabled;
  int get currentPlayer => _current;
  int get scoreA => _a ?? 0;
  int get scoreB => _b ?? 0;
  bool get finished => _a != null && _b != null;

  /// 0 = draw, 1 = player 1, 2 = player 2.
  int get winnerIdx {
    if (!finished || scoreA == scoreB) return 0;
    if (lowerIsBetter) return scoreA < scoreB ? 1 : 2;
    return scoreA > scoreB ? 1 : 2;
  }

  /// Win/lose/draw from the perspective of the current player's win.
  ResultType get resultType => switch (winnerIdx) {
    1 => ResultType.win,
    2 => ResultType.lose,
    _ => ResultType.draw,
  };

  String get winnerTitle => switch (winnerIdx) {
    1 => 'Player 1 wins!',
    2 => 'Player 2 wins!',
    _ => "It's a draw!",
  };

  /// Subtitle line for the match-over banner: scores plus next player.
  String get fullSubtitle {
    final next = currentPlayer == 1 ? 'P1' : 'P2';
    return 'P1: $scoreA  ·  P2: $scoreB  ($next to move)'.replaceAll('\\u00b7','\u00b7');
  }

  /// Score of the session winner (0 when nobody has won yet).
  int get winnerScore => winnerIdx == 1 ? scoreA : (winnerIdx == 2 ? scoreB : 0);

  /// Score of the player whose turn it currently is (P1 or P2).
  int get scoreForCurrent => currentPlayer == 1 ? scoreA : scoreB;

  String get matchSubtitle => 'P1: $scoreA  ·  P2: $scoreB';

  /// Records the finished round's score. Returns the next player to play,
  /// or 0 when the whole match finished.
  int finishRound(int score) {
    if (_current == 1) {
      _a = score;
    } else {
      _b = score;
    }
    if (finished) return 0;
    _current = _current == 1 ? 2 : 1;
    return _current;
  }

  void reset() {
    _current = 1;
    _a = null;
    _b = null;
  }
}

