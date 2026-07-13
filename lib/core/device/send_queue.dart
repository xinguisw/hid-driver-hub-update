import 'dart:async';

/// One task at a time. Failed task does not block later tasks.
/// Own one per [HidSession]. Put receive+send+await in a single [enqueue].
class SendQueue {
  Future<void> _tail = Future<void>.value();

  /// Runs [task] after prior enqueued tasks finish. Returns [task]'s result/error.
  Future<T> enqueue<T>(Future<T> Function() task) {
    final done = Completer<T>();
    _tail = _tail.catchError((_) {}).then((_) async {
      try {
        done.complete(await task());
      } catch (e, st) {
        done.completeError(e, st);
      }
    });
    return done.future;
  }
}
