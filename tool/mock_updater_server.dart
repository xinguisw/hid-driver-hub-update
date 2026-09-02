import 'dart:io';

/// Mock Local HTTP Server for App Updater Testing.
///
/// Serves `dist/appcast.xml` and test installer files over localhost (e.g. `http://localhost:8080/appcast.xml`).
///
/// Usage:
///   `dart run tool/mock_updater_server.dart [--port 8080] [--new-version 2.0.0]`
void main(List<String> args) async {
  int port = 8080;
  String newVersion = '2.0.0';

  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--port' && i + 1 < args.length) {
      port = int.tryParse(args[i + 1]) ?? 8080;
    }
    if (args[i] == '--new-version' && i + 1 < args.length) {
      newVersion = args[i + 1];
    }
  }

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  final feedUrl = 'http://localhost:$port/appcast.xml';

  stdout.writeln('====================================================');
  stdout.writeln('[Mock Updater Server] LIVE on $feedUrl');
  stdout.writeln('[Mock Updater Server] Simulating available new version: v$newVersion');
  stdout.writeln('====================================================');
  stdout.writeln('To test in the app, configure UpdaterConfig with:');
  stdout.writeln('  feedUrl: \'$feedUrl\'');
  stdout.writeln('----------------------------------------------------');
  stdout.writeln('Press Ctrl+C in this terminal when you are done.');
  stdout.writeln('====================================================\n');

  await for (HttpRequest request in server) {
    final path = request.uri.path;
    stdout.writeln('[HTTP] ${request.method} $path');

    if (path == '/appcast.xml' || path == '/dist/appcast.xml') {
      final now = DateTime.now().toUtc();
      final xml = '''<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>HID Driver Hub Test Updates</title>
    <link>http://localhost:$port/</link>
    <description>Local mock update feed for HID Driver Hub</description>
    <language>en</language>
    <item>
      <title>Version $newVersion</title>
      <sparkle:releaseNotesLink>
        http://localhost:$port/release_notes.html
      </sparkle:releaseNotesLink>
      <pubDate>${now.toIso8601String()}</pubDate>
      <enclosure
        url="http://localhost:$port/installer.exe"
        sparkle:version="$newVersion"
        sparkle:os="windows"
        length="36951926"
        type="application/octet-stream" />
    </item>
  </channel>
</rss>''';

      request.response
        ..headers.contentType = ContentType('application', 'xml', charset: 'utf-8')
        ..headers.add('Access-Control-Allow-Origin', '*')
        ..write(xml);
      await request.response.close();
      stdout.writeln('  -> Served mock appcast.xml with version $newVersion (200 OK)');
    } else if (path == '/release_notes.html') {
      final html = '''<!DOCTYPE html>
<html>
<head><title>Release Notes</title></head>
<body>
  <h2>What's New in v$newVersion</h2>
  <ul>
    <li>Brand new HID device communication engine</li>
    <li>Smooth macro playback improvements</li>
    <li>Automatic updater subsystem integrated</li>
  </ul>
</body>
</html>''';
      request.response
        ..headers.contentType = ContentType.html
        ..headers.add('Access-Control-Allow-Origin', '*')
        ..write(html);
      await request.response.close();
    } else if (path == '/installer.exe') {
      final installerFile = File('build/installer/hid_driver_hub_installer.exe');
      if (installerFile.existsSync()) {
        request.response.headers.contentType = ContentType('application', 'octet-stream');
        request.response.headers.add('Content-Disposition', 'attachment; filename="hid_driver_hub_installer.exe"');
        await request.response.addStream(installerFile.openRead());
        await request.response.close();
        stdout.writeln('  -> Streaming real installer.exe (200 OK)');
      } else {
        request.response.statusCode = HttpStatus.ok;
        request.response.write('Dummy installer binary content');
        await request.response.close();
        stdout.writeln('  -> Served dummy installer (200 OK)');
      }
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('Not Found');
      await request.response.close();
    }
  }
}
