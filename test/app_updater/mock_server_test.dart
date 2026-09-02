import 'dart:io';

import 'package:auto_updater_platform_interface/auto_updater_platform_interface.dart';
import 'package:driver_hub/app_updater/bloc/app_update_bloc.dart';
import 'package:driver_hub/app_updater/bloc/app_update_event.dart';
import 'package:driver_hub/app_updater/bloc/app_update_state.dart';
import 'package:driver_hub/app_updater/models/app_release.dart';
import 'package:driver_hub/app_updater/models/updater_config.dart';
import 'package:driver_hub/app_updater/services/auto_updater_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class MockChannelPlatform extends AutoUpdaterPlatform {
  String? feedUrl;
  int checkCount = 0;

  @override
  Stream<Map<Object?, Object?>> get sparkleEvents => const Stream.empty();

  @override
  Future<void> setFeedURL(String feedURL) async {
    feedUrl = feedURL;
  }

  @override
  Future<void> checkForUpdates({bool? inBackground}) async {
    checkCount++;
  }

  @override
  Future<void> setScheduledCheckInterval(int interval) async {}
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('Live Local Mock Server & AppCast XML End-to-End Test', () {
    late HttpServer mockServer;
    late int port;
    late String feedUrl;
    late MockChannelPlatform mockPlatform;

    setUp(() async {
      mockPlatform = MockChannelPlatform();
      AutoUpdaterPlatform.instance = mockPlatform;

      // 1. Bind an ephemeral local HTTP server
      mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      port = mockServer.port;
      feedUrl = 'http://127.0.0.1:$port/appcast.xml';

      // 2. Configure HTTP request handler serving valid AppCast XML and notes
      mockServer.listen((HttpRequest request) async {
        if (request.uri.path == '/appcast.xml') {
          const mockXml = '''<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>HID Driver Hub Test Updates</title>
    <link>http://localhost/</link>
    <description>Test feed</description>
    <language>en</language>
    <item>
      <title>Version 2.0.0</title>
      <sparkle:releaseNotesLink>http://127.0.0.1/notes.html</sparkle:releaseNotesLink>
      <pubDate>Wed, 02 Sep 2026 12:00:00 +0000</pubDate>
      <enclosure
        url="http://127.0.0.1/hid_driver_hub_installer.exe"
        sparkle:version="2.0.0"
        sparkle:os="windows"
        length="36951926"
        type="application/octet-stream" />
    </item>
  </channel>
</rss>''';
          request.response
            ..headers.contentType = ContentType('application', 'xml', charset: 'utf-8')
            ..write(mockXml);
          await request.response.close();
        } else if (request.uri.path == '/hid_driver_hub_installer.exe') {
          request.response
            ..headers.contentType = ContentType('application', 'octet-stream')
            ..write('MZ... simulated PE executable bytes');
          await request.response.close();
        } else {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        }
      });
    });

    tearDown(() async {
      await mockServer.close(force: true);
    });

    test('HTTP feed endpoint returns 200 OK and valid XML structure', () async {
      final response = await http.get(Uri.parse(feedUrl));
      expect(response.statusCode, equals(200));
      expect(response.body, contains('<rss version="2.0"'));
      expect(response.body, contains('sparkle:version="2.0.0"'));
      expect(response.body, contains('hid_driver_hub_installer.exe'));
    });

    test('UpdaterConfig receives and resolves localhost feed URL correctly', () {
      final config = UpdaterConfig(feedUrl: feedUrl);
      expect(config.effectiveFeedUrl, equals(feedUrl));
    });

    test('AppRelease detects simulated v2.0.0 is newer than current v0.0.1', () {
      final remoteRelease = AppRelease(
        tagName: 'v2.0.0',
        version: '2.0.0',
        releaseNotes: 'Major new release',
        assetDownloadUrl: 'http://127.0.0.1:$port/hid_driver_hub_installer.exe',
        assetName: 'hid_driver_hub_installer.exe',
        assetSizeBytes: 36951926,
        publishedAt: DateTime.now(),
        htmlUrl: 'http://127.0.0.1:$port/tag/v2.0.0',
      );

      expect(remoteRelease.isNewerThan('0.0.1'), isTrue);
      expect(remoteRelease.isNewerThan('1.0.0'), isTrue);
      expect(remoteRelease.isNewerThan('2.0.0'), isFalse);
    });

    test('AppUpdateBloc initializes against local feed and runs full update pipeline', () async {
      final config = UpdaterConfig(feedUrl: feedUrl);
      final service = AutoUpdaterIoService();
      final bloc = AppUpdateBloc(
        autoUpdaterService: service,
        defaultConfig: config,
      );

      // Initialize
      bloc.add(InitializeUpdaterRequested(config: config));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(service.isInitialized, isTrue);
      expect(service.config?.effectiveFeedUrl, equals(feedUrl));

      // Trigger update check
      bloc.add(const CheckForUpdatesRequested(isManual: true));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AppUpdateChecking(isManual: true),
          isA<AppUpdateCheckSuccess>().having((s) => s.isManual, 'isManual', isTrue),
        ]),
      );

      await bloc.close();
    });
  });
}
