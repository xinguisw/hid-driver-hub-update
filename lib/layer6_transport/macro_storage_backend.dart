/// Platform storage primitives used by the L6 macro repository.
abstract class MacroStorageBackend {
  Future<String?> read();

  Future<void> write(String value);
}
