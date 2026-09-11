import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../app_info.dart';

/// A release discovered on the GitHub Releases API.
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.title,
    required this.notes,
    required this.apkUrl,
  });

  final String version;
  final String title;
  final String notes;
  final String apkUrl;
}

enum UpdateStatus { idle, checking, upToDate, available, error }

/// Checks GitHub Releases for newer versions and downloads the APK.
///
/// The repo is public, so the anonymous `releases/latest` endpoint works
/// without a token. Every release tag (v0.1.0, v0.2.0, ...) is published by
/// the CI workflow with `Mini-Games-vX.Y.Z.apk` attached.
class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _releaseUrl =
      'https://api.github.com/repos/${AppInfo.repo}/releases/latest';

  /// Returns update info when a newer release exists, otherwise null.
  /// Never throws: failures are treated as "no update known".
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final res = await _client
          .get(Uri.parse(_releaseUrl))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final tag = (data['tag_name'] as String?) ?? '';
      final remote = AppVersion.tryParse(tag);
      final current = AppVersion.tryParse(AppInfo.version);
      if (remote == null || current == null) return null;
      if (!remote.isNewerThan(current)) return null;

      final assets = (data['assets'] as List<dynamic>?) ?? const [];
      String? apkUrl;
      for (final asset in assets) {
        final name = (asset['name'] as String?) ?? '';
        if (name.toLowerCase().endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          break;
        }
      }
      if (apkUrl == null) return null;

      return UpdateInfo(
        version: 'v$remote',
        title: (data['name'] as String?) ?? 'MiniGames $remote',
        notes: ((data['body'] as String?) ?? '').trim(),
        apkUrl: apkUrl,
      );
    } catch (_) {
      return null;
    }
  }

  /// Downloads the release APK into the app's external files dir and returns
  /// the absolute file path. Reports progress via [onProgress].
  Future<String> downloadApk(
    UpdateInfo info,
    void Function(int received, int total) onProgress,
  ) async {
    final dir = await getExternalStorageDirectory();
    final downloadDir = Directory('${dir!.path}/Download');
    if (!downloadDir.existsSync()) {
      downloadDir.createSync(recursive: true);
    }

    final file = File('${downloadDir.path}/Mini-Games-${info.version}.apk');
    if (file.existsSync()) file.deleteSync();

    final request = http.Request('GET', Uri.parse(info.apkUrl));
    final streamed = await _client.send(request);
    if (streamed.statusCode != 200) {
      throw HttpException('Download failed (${streamed.statusCode})');
    }

    final total = streamed.contentLength ?? 0;
    final sink = file.openSync(mode: FileMode.write);
    var received = 0;
    try {
      await for (final chunk in streamed.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress(received, total);
      }
      await sink.flush();
    } finally {
      sink.closeSync();
    }
    return file.path;
  }

  void dispose() => _client.close();
}
