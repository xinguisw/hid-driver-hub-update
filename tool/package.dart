import 'dart:io';
import 'package:innosetup/innosetup.dart';
import 'package:version/version.dart';

/// Signs a Windows PE binary (.exe) using Windows SDK signtool.exe and a code signing certificate.
Future<void> signBinary(String filePath) async {
  final targetFile = File(filePath);
  if (!targetFile.existsSync()) {
    stdout.writeln('[SignTool] Target file not found: $filePath (skipping)');
    return;
  }

  // Paths can be configured via environment variables or fallback to standard paths
  final certPath = Platform.environment['DRIVER_HUB_CERT_PATH'] ?? r'C:\certs\driver_hub_cert.pfx';
  final certPassword = Platform.environment['DRIVER_HUB_CERT_PASS'] ?? 'HubPass123';

  if (!File(certPath).existsSync()) {
    stdout.writeln('[SignTool] Certificate not found at $certPath. Skipping signing.');
    return;
  }

  // Locate signtool.exe from Windows SDK installations
  String? signtoolPath = Platform.environment['SIGNTOOL_PATH'];
  if (signtoolPath == null || !File(signtoolPath).existsSync()) {
    final candidatePaths = [
      r'C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe',
      r'C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe',
      r'C:\Program Files (x86)\Windows Kits\10\bin\10.0.22000.0\x64\signtool.exe',
      r'C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\signtool.exe',
      r'C:\Program Files (x86)\Windows Kits\10\bin\x64\signtool.exe',
    ];
    for (final p in candidatePaths) {
      if (File(p).existsSync()) {
        signtoolPath = p;
        break;
      }
    }
  }

  signtoolPath ??= 'signtool';

  stdout.writeln('[SignTool] Signing $filePath with $signtoolPath...');
  try {
    final result = await Process.run(signtoolPath, [
      'sign',
      '/f', certPath,
      '/p', certPassword,
      '/tr', 'http://timestamp.digicert.com',
      '/td', 'sha256',
      '/fd', 'sha256',
      filePath,
    ]);

    if (result.exitCode == 0) {
      stdout.writeln('[SignTool] Successfully signed: $filePath');
    } else {
      stderr.writeln('[SignTool] Signing failed for $filePath with exit code ${result.exitCode}:\n${result.stderr}');
    }
  } catch (e) {
    stdout.writeln('[SignTool] Could not invoke signtool: $e (skipping signing)');
  }
}

void main() async {
  // 1. Sign the compiled Flutter binary first if available
  await signBinary('build/windows/x64/runner/Release/driver_hub.exe');

  // 2. Generate build/innosetup.iss script via innosetup package
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

  // 3. Ensure executable target in generated iss script is correct
  final issFile = File('build/innosetup.iss');
  if (issFile.existsSync()) {
    var content = issFile.readAsStringSync();
    content = content.replaceAll(
      r'Filename: "{app}\HID Driver Hub"',
      r'Filename: "{app}\driver_hub.exe"',
    );
    issFile.writeAsStringSync(content);
  }

  // 4. Locate ISCC executable on Windows
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
    // 5. Sign the final generated installer
    await signBinary('build/installer/hid_driver_hub_installer.exe');
  } else {
    stderr.writeln('\n[InnoSetup] Compilation failed with exit code ${result.exitCode}');
    exitCode = result.exitCode;
  }
}



