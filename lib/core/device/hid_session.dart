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

  /// Serialize work on this device. One task = full critical section.
  Future<T> enqueue<T>(Future<T> Function() task) => _queue.enqueue(task);

  /// Send [data], then wait for the first IN report where [match] is true.
  ///
  /// Runs as one [enqueue] job (do not wrap again). Arms receive before send.
  /// Non-matching reports are skipped until [timeout] or [close].
  Future<Uint8List> sendAndWait({
    required Uint8List data,
    required int reportId,
    required int reportLength,
    required bool Function(Uint8List raw) match,
    Duration timeout = const Duration(milliseconds: 1000),
  }) {
    return enqueue(() => _sendAndWaitBody(
          data: data,
          reportId: reportId,
          reportLength: reportLength,
          match: match,
          timeout: timeout,
        ));
  }

  Future<Uint8List> _sendAndWaitBody({
    required Uint8List data,
    required int reportId,
    required int reportLength,
    required bool Function(Uint8List raw) match,
    required Duration timeout,
  }) async {
    final deadline = DateTime.now().add(timeout);

    Duration remaining() {
      final left = deadline.difference(DateTime.now());
      return left.isNegative ? Duration.zero : left;
    }

    void ensureTimeLeft() {
      if (remaining() == Duration.zero) {
        throw TimeoutException(
          'HidSession.sendAndWait timed out waiting for a matching report',
          timeout,
        );
      }
    }

    ensureTimeLeft();
    // Listener-first: arm receive before send (web can drop unsolicited acks).
    final first = receiveReport(reportLength, timeout: remaining());
    await sendReport(data, reportId: reportId);
    var raw = await first;
    if (match(raw)) return raw;

    while (true) {
      ensureTimeLeft();
      raw = await receiveReport(reportLength, timeout: remaining());
      if (match(raw)) return raw;
    }
  }

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

  /// Raw OUT report. Use inside [enqueue] / [sendAndWait].
  Future<void> sendReport(Uint8List data, {int reportId = 0x00}) {
    _ensureOpen();
    return _device.sendReport(data, reportId: reportId);
  }

  /// Raw IN report. Throws [HidSessionClosedException] if [close] wins the race.
  /// Use inside [enqueue] / [sendAndWait].
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
