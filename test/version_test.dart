import 'package:flutter_test/flutter_test.dart';
import 'package:minigames/app_info.dart';

void main() {
  group('AppVersion', () {
    test('parses plain and v-prefixed versions', () {
      expect(AppVersion.tryParse('1.2.3'), isNotNull);
      expect(AppVersion.tryParse('v0.1.0'), isNotNull);
      expect(AppVersion.tryParse('0.1.0+9'), isNotNull);
    });

    test('rejects garbage', () {
      expect(AppVersion.tryParse('banana'), isNull);
      expect(AppVersion.tryParse('1.2'), isNull);
      expect(AppVersion.tryParse(''), isNull);
    });

    test('orders versions correctly', () {
      AppVersion parse(String v) => AppVersion.tryParse(v)!;
      expect(parse('0.2.0').isNewerThan(parse('0.1.0')), isTrue);
      expect(parse('1.0.0').isNewerThan(parse('0.9.9')), isTrue);
      expect(parse('0.1.1').isNewerThan(parse('0.1.0')), isTrue);
      expect(parse('0.1.0').isNewerThan(parse('0.1.0')), isFalse);
      expect(parse('0.1.0').isNewerThan(parse('0.1.1')), isFalse);
      expect(parse('0.2.0').isNewerThan(parse('0.10.0')), isFalse);
    });
  });

  test('current app version parses', () {
    expect(AppVersion.tryParse(AppInfo.version), isNotNull);
  });
}
