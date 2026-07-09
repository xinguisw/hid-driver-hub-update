import 'web/web_local_storage_stub.dart'
    if (dart.library.js_interop) 'web/web_local_storage.dart'
    as webstorage;

/// Writes [key]/[value] to localStorage on web. No-op on non-web platforms.
void writeLocalStorage(String key, String value) {
  webstorage.writeLocalStorage(key, value);
}
