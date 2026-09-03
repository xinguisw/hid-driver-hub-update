import 'dart:io';

/// CLI Tool to generate or update `dist/appcast.xml` for WinSparkle/Sparkle auto-updates.
///
/// Usage:
///   `dart run tool/generate_appcast.dart [options]`
///
/// Options:
///   `--version <ver>`         Override version (defaults to version in pubspec.yaml)
///   `--installer <path>`      Path to installer (defaults to build/installer/hid_driver_hub_installer.exe)
///   `--owner <name>`          GitHub owner (defaults to sumanram23)
///   `--repo <name>`           GitHub repo (defaults to hid-driver-hub)
///   `--dsa <signature>`       DSA signature string (optional)
///   `--notes <url>`           Release notes URL (optional)
void main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('''
Generate AppCast XML for WinSparkle/Sparkle.

Usage:
  dart run tool/generate_appcast.dart [options]

Options:
  --version <ver>      Release version (e.g. 1.0.1)
  --installer <path>   Path to installer .exe
  --owner <owner>      GitHub repository owner
  --repo <repo>        GitHub repository name
  --dsa <signature>    Sparkle DSA signature
  --output <path>      Output file path (default: dist/appcast.xml)
''');
    return;
  }

  // Parse CLI args
  String? versionArg = _getArg(args, '--version');
  final installerPath = _getArg(args, '--installer') ?? 'build/installer/hid_driver_hub_installer.exe';
  final owner = _getArg(args, '--owner') ?? 'xinguisw';
  final repo = _getArg(args, '--repo') ?? 'hid-driver-hub-update';
  final dsaSignature = _getArg(args, '--dsa') ?? '';
  final outputPath = _getArg(args, '--output') ?? 'dist/appcast.xml';

  // Read version from pubspec.yaml if not provided
  if (versionArg == null) {
    final pubspecFile = File('pubspec.yaml');
    if (pubspecFile.existsSync()) {
      final lines = pubspecFile.readAsLinesSync();
      for (final line in lines) {
        if (line.startsWith('version:')) {
          final raw = line.replaceFirst('version:', '').trim();
          versionArg = raw.split('+').first;
          break;
        }
      }
    }
  }

  final version = versionArg ?? '1.0.0';

  // Check installer size
  final installerFile = File(installerPath);
  int fileSize = 50000000; // default estimated 50MB
  if (installerFile.existsSync()) {
    fileSize = installerFile.lengthSync();
    stdout.writeln('[AppCast] Found installer: $installerPath (${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB)');
  } else {
    stdout.writeln('[AppCast] Installer not found at $installerPath (using estimated size $fileSize bytes)');
  }

  final now = DateTime.now().toUtc();
  final pubDate = _formatRssDate(now);
  final downloadUrl = 'https://github.com/$owner/$repo/releases/download/v$version/hid_driver_hub_installer.exe';
  final notesUrl = 'https://github.com/$owner/$repo/releases/tag/v$version';

  final dsaAttr = dsaSignature.isNotEmpty ? ' sparkle:dsaSignature="$dsaSignature"' : '';

  final appcastContent = '''<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>HID Driver Hub Updates</title>
    <link>https://github.com/$owner/$repo</link>
    <description>Latest updates and improvements for HID Driver Hub</description>
    <language>en</language>
    <item>
      <title>Version $version</title>
      <sparkle:releaseNotesLink>
        $notesUrl
      </sparkle:releaseNotesLink>
      <pubDate>$pubDate</pubDate>
      <enclosure
        url="$downloadUrl"
        sparkle:version="$version"
        sparkle:os="windows"$dsaAttr
        length="$fileSize"
        type="application/octet-stream" />
    </item>
  </channel>
</rss>
''';

  final outFile = File(outputPath);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(appcastContent);

  stdout.writeln('[AppCast] Successfully generated $outputPath for version $version:');
  stdout.writeln('  Download URL: $downloadUrl');
  stdout.writeln('  Size: $fileSize bytes');
  if (dsaSignature.isNotEmpty) {
    stdout.writeln('  DSA Signature: $dsaSignature');
  }
}

String? _getArg(List<String> args, String flag) {
  final idx = args.indexOf(flag);
  if (idx != -1 && idx + 1 < args.length) {
    return args[idx + 1];
  }
  return null;
}

String _formatRssDate(DateTime dt) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final dayName = days[dt.weekday - 1];
  final monthName = months[dt.month - 1];
  final day = dt.day.toString().padLeft(2, '0');
  final year = dt.year.toString();
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  final second = dt.second.toString().padLeft(2, '0');
  return '$dayName, $day $monthName $year $hour:$minute:$second +0000';
}
