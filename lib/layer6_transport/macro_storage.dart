import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:driver_hub/layer4_domain/macro_repository.dart';
import 'package:driver_hub/layer4_domain/models/macro.dart';

import 'macro_storage_backend.dart';
import 'macro_storage_io.dart'
    if (dart.library.js_interop) 'web/macro_storage_web.dart'
    as platform;

/// L6-backed macro repository.
///
/// The semantic JSON schema is shared by desktop and web. Only the storage
/// backend differs: app-data JSON on desktop, IndexedDB in the browser.
class PersistentMacroRepository implements MacroRepository {
  PersistentMacroRepository({MacroStorageBackend? backend})
    : _backend = backend ?? platform.createMacroStorageBackend();

  static const schemaVersion = 1;
  final MacroStorageBackend _backend;

  @override
  Future<List<MacroDefinition>> load(String deviceId) async {
    final raw = await _backend.read();
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! Map) throw const FormatException('Invalid macro store');
    final version = decoded['schemaVersion'];
    if (version != schemaVersion) {
      throw FormatException('Unsupported macro store version: $version');
    }
    final devices = decoded['devices'];
    if (devices is! Map) return const [];
    final rawMacros = devices[deviceId];
    if (rawMacros is! List) return const [];
    return List.unmodifiable(
      rawMacros.map((raw) {
        if (raw is! Map) throw const FormatException('Invalid stored macro');
        return MacroDefinition.fromJson(Map<String, Object?>.from(raw));
      }),
    );
  }

  @override
  Future<void> save(String deviceId, List<MacroDefinition> macros) async {
    final current = await _readStore();
    current[deviceId] = macros.map((macro) => macro.toJson()).toList();
    await _backend.write(
      jsonEncode({'schemaVersion': schemaVersion, 'devices': current}),
    );
    debugPrint(
      '[storage] saved updated macro store for device $deviceId (${macros.length} macro(s))',
    );
  }

  Future<Map<String, dynamic>> _readStore() async {
    final raw = await _backend.read();
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['schemaVersion'] != schemaVersion) {
      return <String, dynamic>{};
    }
    final devices = decoded['devices'];
    return devices is Map
        ? Map<String, dynamic>.from(devices)
        : <String, dynamic>{};
  }
}
