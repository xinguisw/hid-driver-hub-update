import 'dart:io';

import 'macro_storage_backend.dart';

MacroStorageBackend createMacroStorageBackend() => _DesktopMacroStorage();

class _DesktopMacroStorage implements MacroStorageBackend {
  File get _file {
    final appData = Platform.environment['APPDATA'];
    final home = Platform.environment['USERPROFILE'] ?? '.';
    final root = appData == null || appData.isEmpty ? home : appData;
    return File(
      '$root${Platform.pathSeparator}driver_hub'
      '${Platform.pathSeparator}macros.json',
    );
  }

  @override
  Future<String?> read() async {
    final file = _file;
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<void> write(String value) async {
    final file = _file;
    await file.parent.create(recursive: true);
    await file.writeAsString(value);
  }
}
