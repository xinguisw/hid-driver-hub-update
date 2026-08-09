import 'models/macro.dart';

/// L4 persistence seam. Concrete storage is supplied by L6.
abstract class MacroRepository {
  Future<List<MacroDefinition>> load(String deviceId);

  Future<void> save(String deviceId, List<MacroDefinition> macros);
}

class InMemoryMacroRepository implements MacroRepository {
  final _data = <String, List<MacroDefinition>>{};

  @override
  Future<List<MacroDefinition>> load(String deviceId) async =>
      List.unmodifiable(_data[deviceId] ?? const []);

  @override
  Future<void> save(String deviceId, List<MacroDefinition> macros) async {
    _data[deviceId] = List.unmodifiable(macros);
  }
}
