import 'dart:async';
import 'dart:typed_data';

import 'package:hid_tool/hid_tool.dart';

import 'send_queue.dart';

/// [receiveReport] aborted because [close] ran while waiting.
class HidSessionClosedException implements Exception {
  final String message;
  const HidSessionClosedException(
      [this.message = 'HidSession closed while a report receive was in flight.']);
  @override
  String toString() => 'HidSessionClosedException: $message';
}

/// Owns one open [HidDevice]. Only site that calls sendReport/receiveReport/inputStream.
/// No framing, opcodes, or CRC. Desktop and web share this path via hid_tool.
class HidSession {
  final HidDevice _device;
  final SendQueue _queue = SendQueue();
  bool _open = false;

  /// Completes on [close]; races [receiveReport] so unplug aborts the wait.
  Completer<void>? _closed;

  HidSession(this._device);

  bool get isOpen => _open;

  /// Serialize work on this device. One task = full receive+send+await pair.
  Future<T> enqueue<T>(Future<T> Function() task) => _queue.enqueue(task);

  Future<void> open() async {
    if (_open) return;
    await _device.open();
    // Web: receiveReport needs inputStream controller; desktop inputStream is a no-op generator.
    _device.inputStream();
    _open = true;
    _closed = null;
  }

  Future<void> close() async {
    if (!_open) return;
    _open = false;
    _closed ??= Completer<void>();
    _closed!.complete();
    if (_device.isOpen) {
      await _device.close();
    }
  }

  /// Raw OUT report. Use inside [enqueue].
  Future<void> sendReport(Uint8List data, {int reportId = 0x00}) {
    _ensureOpen();
    return _device.sendReport(data, reportId: reportId);
  }

  /// Raw IN report. Throws [HidSessionClosedException] if [close] wins the race.
  /// Use inside [enqueue].
  Future<Uint8List> receiveReport(int reportLength, {Duration? timeout}) {
    _ensureOpen();
    _closed ??= Completer<void>();
    final read = _device.receiveReport(reportLength, timeout: timeout);
    return Future.any([
      read,
      _closed!.future.then((_) => throw const HidSessionClosedException()),
    ]);
  }

  /// Raw byte stream from the device. No framing.
  Stream<int> inputStream() {
    _ensureOpen();
    return _device.inputStream();
  }

  void _ensureOpen() {
    if (!_open) {
      throw StateError('HidSession is not open. Call open() first.');
    }
  }
}
