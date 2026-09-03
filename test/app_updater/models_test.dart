import 'package:driver_hub/app_updater/models/app_release.dart';
import 'package:driver_hub/app_updater/models/update_progress.dart';
import 'package:driver_hub/app_updater/models/updater_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdaterConfig', () {
    test('provides defaults and compiles asset regex', () {
      const config = UpdaterConfig();
      expect(config.owner, equals('xinguisw'));
      expect(config.repo, equals('hid-driver-hub-update'));
      expect(config.assetRegExp.hasMatch('hid_driver_hub_installer.exe'), isTrue);
      expect(config.assetRegExp.hasMatch('other_file.zip'), isFalse);
      expect(
        config.githubLatestReleaseUrl,
        equals('https://api.github.com/repos/xinguisw/hid-driver-hub-update/releases/latest'),
      );
    });

    test('custom values override defaults properly', () {
      final config = UpdaterConfig(
        owner: 'custom_org',
        repo: 'custom_repo',
        assetPattern: r'\.msi$',
        requestTimeout: const Duration(seconds: 5),
        customFeedUrl: 'https://updates.example.com/version.json',
      );
      expect(config.owner, equals('custom_org'));
      expect(config.repo, equals('custom_repo'));
      expect(config.assetRegExp.hasMatch('setup.msi'), isTrue);
      expect(config.assetRegExp.hasMatch('setup.exe'), isFalse);
      expect(config.customFeedUrl, equals('https://updates.example.com/version.json'));
    });
  });

  group('AppRelease - SemVer comparison', () {
    AppRelease createRelease(String tag) {
      return AppRelease(
        tagName: tag,
        version: AppRelease.cleanVersionTag(tag),
        releaseNotes: 'Some release notes',
        assetDownloadUrl: 'https://example.com/setup.exe',
        assetName: 'hid_driver_hub_installer.exe',
        assetSizeBytes: 1024 * 1024 * 10,
        publishedAt: DateTime(2026, 9, 1),
        htmlUrl: 'https://github.com/sumanram23/hid-driver-hub/releases/tag/$tag',
      );
    }

    test('correctly identifies newer patch and minor versions', () {
      final r1 = createRelease('v1.0.1');
      expect(r1.isNewerThan('1.0.0'), isTrue);
      expect(r1.isNewerThan('v1.0.0'), isTrue);
      expect(r1.isNewerThan('1.0.1'), isFalse);
      expect(r1.isNewerThan('1.0.2'), isFalse);

      final r2 = createRelease('v1.1.0');
      expect(r2.isNewerThan('1.0.9'), isTrue);
      expect(r2.isNewerThan('1.0.10'), isTrue);
      expect(r2.isNewerThan('1.1.0'), isFalse);
      expect(r2.isNewerThan('2.0.0'), isFalse);
    });

    test('handles two-digit SemVer elements e.g. 1.0.10 > 1.0.9', () {
      final r = createRelease('v1.0.10');
      expect(r.isNewerThan('1.0.9'), isTrue);
      expect(r.isNewerThan('1.0.10'), isFalse);
      expect(r.isNewerThan('1.0.11'), isFalse);
    });

    test('handles version strings with build metadata (+1)', () {
      final r = createRelease('1.0.1+2');
      expect(r.isNewerThan('1.0.0+1'), isTrue);
      expect(r.isNewerThan('1.0.1+1'), isFalse); // SemVer standard ignores build numbers
    });

    test('strips leading v/V prefixes in cleanVersionTag', () {
      expect(AppRelease.cleanVersionTag('v1.2.3'), equals('1.2.3'));
      expect(AppRelease.cleanVersionTag('V2.0.0'), equals('2.0.0'));
      expect(AppRelease.cleanVersionTag('  v1.0.0  '), equals('1.0.0'));
      expect(AppRelease.cleanVersionTag('1.0.0'), equals('1.0.0'));
    });
  });

  group('AppRelease - GitHub JSON parsing', () {
    final sampleJson = {
      'tag_name': 'v2.1.0',
      'body': '## What is changed\n- Added cool feature',
      'html_url': 'https://github.com/sumanram23/hid-driver-hub/releases/tag/v2.1.0',
      'published_at': '2026-09-01T12:00:00Z',
      'assets': [
        {
          'name': 'source_code.tar.gz',
          'size': 500000,
          'browser_download_url': 'https://github.com/.../source_code.tar.gz',
        },
        {
          'name': 'hid_driver_hub_installer.exe',
          'size': 45000000,
          'browser_download_url':
              'https://github.com/.../hid_driver_hub_installer.exe',
        },
      ],
    };

    test('parses full GitHub release payload and matches installer asset', () {
      final release = AppRelease.fromGitHubJson(sampleJson);
      expect(release.tagName, equals('v2.1.0'));
      expect(release.version, equals('2.1.0'));
      expect(release.releaseNotes, contains('Added cool feature'));
      expect(release.assetName, equals('hid_driver_hub_installer.exe'));
      expect(release.assetSizeBytes, equals(45000000));
      expect(
        release.assetDownloadUrl,
        equals('https://github.com/.../hid_driver_hub_installer.exe'),
      );
      expect(release.publishedAt.year, equals(2026));
      expect(release.htmlUrl, contains('/v2.1.0'));
    });

    test('falls back to generic .exe asset if specific name not found', () {
      final fallbackJson = {
        'tag_name': 'v1.5.0',
        'body': 'Release notes',
        'html_url': 'https://github.com/...',
        'assets': [
          {
            'name': 'CustomAppSetup_v1.5.0.exe',
            'size': 20000000,
            'browser_download_url': 'https://github.com/.../CustomAppSetup_v1.5.0.exe',
          },
        ],
      };

      final release = AppRelease.fromGitHubJson(fallbackJson);
      expect(release.assetName, equals('CustomAppSetup_v1.5.0.exe'));
      expect(release.assetDownloadUrl, contains('CustomAppSetup_v1.5.0.exe'));
    });
  });

  group('UpdateProgress', () {
    test('calculates fraction and percentage correctly', () {
      const p1 = UpdateProgress(
        receivedBytes: 25000000,
        totalBytes: 100000000,
        bytesPerSecond: 5000000,
      );
      expect(p1.fraction, closeTo(0.25, 0.001));
      expect(p1.percentage, equals(25));
      expect(p1.isCompleted, isFalse);
      expect(p1.receivedMbFormatted, equals('23.8 MB'));
      expect(p1.totalMbFormatted, equals('95.4 MB'));
      expect(p1.speedFormatted, equals('4.8 MB/s'));

      const pComplete = UpdateProgress(
        receivedBytes: 100000000,
        totalBytes: 100000000,
      );
      expect(pComplete.fraction, equals(1.0));
      expect(pComplete.percentage, equals(100));
      expect(pComplete.isCompleted, isTrue);
    });

    test('handles unknown total bytes gracefully', () {
      const pUnknown = UpdateProgress(
        receivedBytes: 500000,
        totalBytes: -1,
      );
      expect(pUnknown.fraction, equals(0.0));
      expect(pUnknown.percentage, equals(0));
      expect(pUnknown.isCompleted, isFalse);
      expect(pUnknown.totalMbFormatted, equals('-- MB'));
      expect(pUnknown.receivedMbFormatted, equals('488.3 KB'));
    });
  });
}
