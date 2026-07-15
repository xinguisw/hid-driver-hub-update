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

class _PendingWait {
  final bool Function(Uint8List raw) match;
  final Completer<Uint8List> completer;
  final Timer timer;

  _PendingWait({
    required this.match,
    required this.completer,
    required this.timer,
  });
}

/// Owns one open [HidDevice]. Only site that calls sendReport/receiveReport/inputStream.
/// No framing, opcodes, or CRC. Desktop and web share this path via hid_tool.
///
/// One inbound pump reassembles reports and demuxes:
/// - matching [sendAndWait] waiter (report 7 host ack)
/// - otherwise [unsolicitedReports] (OSD report 9 and other noise)
class HidSession {
  final HidDevice _device;
  final SendQueue _queue = SendQueue();
  bool _open = false;

  Completer<void>? _closed;
  StreamSubscription<int>? _pumpSub;
  final _buf = <int>[];
  _PendingWait? _pending;

  final _unsolicited =
      StreamController<Uint8List>.broadcast(sync: true);

  HidSession(this._device);

  bool get isOpen => _open;

  /// Raw inbound reports not claimed by an active [sendAndWait] (e.g. OSD).
  Stream<Uint8List> get unsolicitedReports => _unsolicited.stream;

  /// Serialize work on this device. One task = full critical section.
  Future<T> enqueue<T>(Future<T> Function() task) => _queue.enqueue(task);

  /// Send [data], then wait for the first pump report where [match] is true.
  ///
  /// Runs as one [enqueue] job (do not wrap again). Arms waiter before send.
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
          match: match,
          timeout: timeout,
        ));
  }

  Future<Uint8List> _sendAndWaitBody({
    required Uint8List data,
    required int reportId,
    required bool Function(Uint8List raw) match,
    required Duration timeout,
  }) async {
    final done = Completer<Uint8List>();
    final timer = Timer(timeout, () {
      if (!done.isCompleted) {
        if (_pending?.completer == done) _pending = null;
        done.completeError(TimeoutException(
          'HidSession.sendAndWait timed out waiting for a matching report',
          timeout,
        ));
      }
    });
    _pending = _PendingWait(match: match, completer: done, timer: timer);
    try {
      // Listener-first: waiter is registered before send.
      await sendReport(data, reportId: reportId);
      return await done.future;
    } finally {
      timer.cancel();
      if (_pending?.completer == done) _pending = null;
    }
  }

  Future<void> open() async {
    if (_open) return;
    await _device.open();
    _open = true;
    _closed = null;
    _buf.clear();
    _startPump();
  }

  void _startPump() {
    _pumpSub?.cancel();
    // Single consumer of device bytes (desktop + web).
    _pumpSub = _device.inputStream().listen(
      _onByte,
      onError: (_) {},
      onDone: () {},
      cancelOnError: false,
    );
  }

  void _onByte(int byte) {
    if (!_open) return;
    _buf.add(byte);
    _drainBuffer();
  }

  void _drainBuffer() {
    while (_buf.isNotEmpty) {
      final size = _frameSizeFor(_buf);
      if (size == null) {
        // Resync: drop unknown lead byte.
        _buf.removeAt(0);
        continue;
      }
      if (_buf.length < size) return;
      final frame = Uint8List.fromList(_buf.sublist(0, size));
      _buf.removeRange(0, size);
      _dispatch(frame);
    }
  }

  /// Report size from first byte. Desktop prefixes report id; web often does not.
  ///
  /// Do NOT treat bare 0x01/0x02 as frames — those are common boot-mouse
  /// button bytes and were mis-parsed as OSD battery 0%/1%.
  int? _frameSizeFor(List<int> buf) {
    if (buf.isEmpty) return null;
    final b0 = buf[0];
    if (b0 == 0x07) return 32; // config, desktop (report id + body)
    if (b0 == 0x09) return 8; // OSD, desktop (report id 9, 8 bytes total)
    if (b0 == 0xA1 || b0 == 0xA4 || b0 == 0xA8) return 31; // config, web body
    return null;
  }

  void _dispatch(Uint8List report) {
    final pending = _pending;
    if (pending != null && pending.match(report)) {
      _pending = null;
      pending.timer.cancel();
      if (!pending.completer.isCompleted) {
        pending.completer.complete(report);
      }
      return;
    }
    if (!_unsolicited.isClosed) {
      _unsolicited.add(report);
    }
  }

  Future<void> close() async {
    if (!_open) return;
    _open = false;
    await _pumpSub?.cancel();
    _pumpSub = null;
    _buf.clear();
    final pending = _pending;
    _pending = null;
    pending?.timer.cancel();
    if (pending != null && !pending.completer.isCompleted) {
      pending.completer.completeError(const HidSessionClosedException());
    }
    _closed ??= Completer<void>();
    if (!_closed!.isCompleted) _closed!.complete();
    if (_device.isOpen) {
      await _device.close();
    }
  }

  /// Raw OUT report. Use inside [enqueue] / [sendAndWait].
  Future<void> sendReport(Uint8List data, {int reportId = 0x00}) {
    _ensureOpen();
    return _device.sendReport(data, reportId: reportId);
  }

  /// Raw IN report (legacy one-shot). Prefer [sendAndWait] / [unsolicitedReports].
  /// Throws [HidSessionClosedException] if [close] wins the race.
  Future<Uint8List> receiveReport(int reportLength, {Duration? timeout}) {
    _ensureOpen();
    _closed ??= Completer<void>();
    final read = _device.receiveReport(reportLength, timeout: timeout);
    return Future.any([
      read,
      _closed!.future.then((_) => throw const HidSessionClosedException()),
    ]);
  }

  /// Raw byte stream from the device. Prefer the session pump.
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
