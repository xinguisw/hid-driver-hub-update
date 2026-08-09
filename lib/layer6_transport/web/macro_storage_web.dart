import 'dart:async';
import 'dart:js_interop';

import '../macro_storage_backend.dart';

MacroStorageBackend createMacroStorageBackend() => _IndexedDbMacroStorage();

const _databaseName = 'driver_hub';
const _storeName = 'macro_store';
const _storeKey = 'macros';

@JS('indexedDB')
external _IdbFactory? get _indexedDb;

@JS('IDBFactory')
extension type _IdbFactory._(JSObject _) implements JSObject {
  external _IdbOpenRequest open(String name, int version);
}

@JS('IDBOpenDBRequest')
extension type _IdbOpenRequest._(JSObject _) implements JSObject {
  external set onsuccess(JSFunction? callback);
  external set onerror(JSFunction? callback);
  external set onupgradeneeded(JSFunction? callback);
  external _IdbDatabase get result;
}

@JS('IDBDatabase')
extension type _IdbDatabase._(JSObject _) implements JSObject {
  external _IdbStringList get objectStoreNames;
  external _IdbObjectStore createObjectStore(String name);
  external _IdbTransaction transaction(String storeName, String mode);
}

@JS('DOMStringList')
extension type _IdbStringList._(JSObject _) implements JSObject {
  external bool contains(String name);
}

@JS('IDBTransaction')
extension type _IdbTransaction._(JSObject _) implements JSObject {
  external _IdbObjectStore objectStore(String name);
}

@JS('IDBObjectStore')
extension type _IdbObjectStore._(JSObject _) implements JSObject {
  external _IdbRequest get(JSString key);
  external _IdbRequest put(JSAny value, JSString key);
}

@JS('IDBRequest')
extension type _IdbRequest._(JSObject _) implements JSObject {
  external set onsuccess(JSFunction? callback);
  external set onerror(JSFunction? callback);
  external JSAny? get result;
}

class _IndexedDbMacroStorage implements MacroStorageBackend {
  @override
  Future<String?> read() async {
    final db = await _open();
    final request = db
        .transaction(_storeName, 'readonly')
        .objectStore(_storeName)
        .get(_storeKey.toJS);
    final result = await _request(request);
    return result?.dartify() as String?;
  }

  @override
  Future<void> write(String value) async {
    final db = await _open();
    final request = db
        .transaction(_storeName, 'readwrite')
        .objectStore(_storeName)
        .put(value.toJS, _storeKey.toJS);
    await _request(request);
  }

  Future<_IdbDatabase> _open() async {
    final factory = _indexedDb;
    if (factory == null) throw UnsupportedError('IndexedDB is unavailable');
    final request = factory.open(_databaseName, 1);
    request.onupgradeneeded = ((JSAny? _) {
      final db = request.result;
      if (!db.objectStoreNames.contains(_storeName)) {
        db.createObjectStore(_storeName);
      }
    }).toJS;
    await _request(request);
    return request.result;
  }
}

Future<JSAny?> _request(JSObject requestObject) {
  final request = requestObject as _IdbRequest;
  final completer = Completer<JSAny?>();
  request.onsuccess = ((JSAny? _) {
    if (!completer.isCompleted) completer.complete(request.result);
  }).toJS;
  request.onerror = ((JSAny? _) {
    if (!completer.isCompleted) {
      completer.completeError(StateError('IndexedDB macro request failed'));
    }
  }).toJS;
  return completer.future;
}
