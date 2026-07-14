// Web-only localStorage bindings via dart:js_interop.
// Selected by the conditional import in local_storage.dart. Off-web uses the
// stub in web_local_storage_stub.dart, so desktop never compiles dart:js_interop.
import 'dart:js_interop';

@JS('localStorage')
external _Storage get _localStorage;

@JS('Storage')
extension type _Storage._(JSObject _) implements JSObject {
  external void setItem(JSString key, JSString value);
}

void writeLocalStorage(String key, String value) {
  try {
    _localStorage.setItem(key.toJS, value.toJS);
  } catch (_) {}
}
