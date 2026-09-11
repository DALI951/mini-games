/// Static app identity shared across the app.
///
/// Version must be kept in sync with pubspec.yaml. It is bumped together
/// with each release tag (v0.1.0, v0.2.0, ...) which is how the in-app
/// update checker decides whether a newer build exists on GitHub.
class AppInfo {
  AppInfo._();

  static const String name = 'MiniGames';
  static const String version = '0.1.0';
  static const String repo = 'DALI951/mini-games';
  static const String repoUrl = 'https://github.com/DALI951/mini-games';

  static String get versionLabel => 'v$version';
}

/// Small semantic-version helper used by the update checker.
class AppVersion {
  const AppVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  /// Parses a "v1.2.3" or "1.2.3" style string. Returns null if invalid.
  static AppVersion? tryParse(String raw) {
    final cleaned = raw.trim().replaceFirst(RegExp(r'^v'), '');
    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)').firstMatch(cleaned);
    if (match == null) return null;
    return AppVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  bool isNewerThan(AppVersion other) {
    if (major != other.major) return major > other.major;
    if (minor != other.minor) return minor > other.minor;
    return patch > other.patch;
  }

  @override
  String toString() => '$major.$minor.$patch';
}
