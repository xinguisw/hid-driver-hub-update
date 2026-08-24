import 'dart:io';
import 'package:innosetup/innosetup.dart';
import 'package:version/version.dart';

void main() async {
  // 1. Generate build/innosetup.iss script via innosetup package
  try {
    await InnoSetup(
      name: const InnoSetupName('hid_driver_hub_installer'),
      app: InnoSetupApp(
        name: 'HID Driver Hub',
        version: Version.parse('1.0.0'),
        publisher: 'Driver Hub Team',
        urls: InnoSetupAppUrls(
          homeUrl: Uri.parse('https://example.com/'),
        ),
      ),
      files: InnoSetupFiles(
        executable: File('build/windows/x64/runner/Release/driver_hub.exe'),
        location: Directory('build/windows/x64/runner/Release'),
      ),
      location: InnoSetupInstallerDirectory(
        Directory('build/installer'),
      ),
      icon: InnoSetupIcon(
        File('assets/images/app_icon.ico'),
      ),
    ).make();
  } catch (_) {
    // If ISCC.exe is not in PATH, InnoSetup.make() generates .iss before throwing
  }

  // 2. Ensure executable target in generated iss script is correct
  final issFile = File('build/innosetup.iss');
  if (issFile.existsSync()) {
    var content = issFile.readAsStringSync();
    content = content.replaceAll(
      r'Filename: "{app}\HID Driver Hub"',
      r'Filename: "{app}\driver_hub.exe"',
    );
    issFile.writeAsStringSync(content);
  }

  // 3. Locate ISCC executable on Windows
  String? isccPath;
  for (final path in [
    r'C:\Program Files\Inno Setup 7\ISCC.exe',
    r'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
    r'C:\Program Files\Inno Setup 6\ISCC.exe',
  ]) {
    if (File(path).existsSync()) {
      isccPath = path;
      break;
    }
  }

  isccPath ??= 'iscc';

  stdout.writeln('[InnoSetup] Compiling installer with $isccPath...');
  final result = await Process.run(isccPath, ['build/innosetup.iss']);
  stdout.write(result.stdout);
  stderr.write(result.stderr);

  if (result.exitCode == 0) {
    stdout.writeln('\n[InnoSetup] Success! Installer built at: build/installer/hid_driver_hub_installer.exe');
  } else {
    stderr.writeln('\n[InnoSetup] Compilation failed with exit code ${result.exitCode}');
    exitCode = result.exitCode;
  }
}


