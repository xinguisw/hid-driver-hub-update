import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:hid_tool/hid_tool.dart';

import 'package:driver_hub/layer5_codec/protocol_transport.dart';

import 'send_queue.dart';

/// [receiveReport] aborted because [close] ran while waiting.
class HidSessionClosedException implements Exception {
  final String message;
  const HidSessionClosedException([
    this.message = 'HidSession closed while a report receive was in flight.',
  ]);
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
/// No framing, opcodes, or CRC. Desktop and web share this type via hid_tool.
///
/// Inbound pump demux:
/// - matching [sendAndWait] waiter
/// - otherwise [unsolicitedReports]
///
/// Desktop: byte stream + size by first bytes.
/// Web: each WebHID inputreport is one burst — flush whole buffer on short idle
/// (avoids GET opcode 0x07 vs report-id 0x07 size mistakes).
class HidSession implements ProtocolTransport {
  final HidDevice _device;
  final SendQueue _queue = SendQueue();
  bool _open = false;

  Completer<void>? _closed;
  StreamSubscription<int>? _pumpSub;
  final _buf = <int>[];
  _PendingWait? _pending;
  Timer? _webIdleFlush;

  final _unsolicited = StreamController<Uint8List>.broadcast(sync: true);

  HidSession(this._device);

  bool get isOpen => _open;

  Stream<Uint8List> get unsolicitedReports => _unsolicited.stream;

  Future<T> enqueue<T>(Future<T> Function() task) => _queue.enqueue(task);

  /// Send [data], then wait for the first pump report where [match] is true.
  @override
  Future<Uint8List> sendAndWait({
    required Uint8List data,
    required int reportId,
    required int reportLength,
    required bool Function(Uint8List raw) match,
    Duration timeout = const Duration(seconds: 3),
  }) {
    return enqueue(
      () => _sendAndWaitBody(
        data: data,
        reportId: reportId,
        match: match,
        timeout: timeout,
      ),
    );
  }

  Future<Uint8List> _sendAndWaitBody({
    required Uint8List data,
    required int reportId,
    required bool Function(Uint8List raw) match,
    required Duration timeout,
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 120),
  }) async {
    Object? lastError;
    StackTrace? lastStackTrace;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      if (attempt > 0) {
        debugPrint(
          '[hid_session] sendAndWait attempt ${attempt + 1}/${maxRetries + 1} '
          'after error (${lastError?.toString()}), retrying in ${retryDelay.inMilliseconds}ms...',
        );
        await Future.delayed(retryDelay);
      }
      final done = Completer<Uint8List>();
      final timer = Timer(timeout, () {
        if (!done.isCompleted) {
          if (_pending?.completer == done) _pending = null;
          done.completeError(
            TimeoutException(
              'HidSession.sendAndWait timed out waiting for a matching report (attempt ${attempt + 1}/${maxRetries + 1})',
              timeout,
            ),
          );
        }
      });
      _pending = _PendingWait(match: match, completer: done, timer: timer);
      try {
        await sendReport(data, reportId: reportId);
        return await done.future;
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;
      } finally {
        timer.cancel();
        if (_pending?.completer == done) _pending = null;
      }
    }
    Error.throwWithStackTrace(
      lastError ??
          TimeoutException(
            'HidSession.sendAndWait failed after ${maxRetries + 1} attempts',
          ),
      lastStackTrace ?? StackTrace.current,
    );
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
    _webIdleFlush?.cancel();
    _webIdleFlush = null;
    _buf.clear();
    _pumpSub = _device.inputStream().listen(
      kIsWeb ? _onByteWeb : _onByteDesktop,
      onError: (_) {},
      onDone: () {},
      cancelOnError: false,
    );
  }

  void _onByteDesktop(int byte) {
    if (!_open) return;
    _buf.add(byte);
    _drainBufferDesktop();
  }

  /// Web: one inputreport = one burst of bytes; flush as a single frame.
  void _onByteWeb(int byte) {
    if (!_open) return;
    _buf.add(byte);
    _webIdleFlush?.cancel();
    _webIdleFlush = Timer(const Duration(milliseconds: 2), _flushWebReport);
  }

  void _flushWebReport() {
    _webIdleFlush = null;
    if (!_open || _buf.isEmpty) return;
    final frame = Uint8List.fromList(_buf);
    _buf.clear();
    _dispatch(frame);
  }

  void _drainBufferDesktop() {
    while (_buf.isNotEmpty) {
      final size = _frameSizeForDesktop(_buf);
      if (size == null) {
        _buf.removeAt(0);
        continue;
      }
      if (_buf.length < size) return;
      final frame = Uint8List.fromList(_buf.sublist(0, size));
      _buf.removeRange(0, size);
      _dispatch(frame);
    }
  }

  /// Desktop sizes only (report id often prefixed).
  int? _frameSizeForDesktop(List<int> buf) {
    if (buf.isEmpty) return null;
    final b0 = buf[0];
    if (b0 == 0x07) return 32;
    if (b0 == 0x08) return 32;
    if (b0 == 0x09) return 8;
    if (b0 == 0xA1 || b0 == 0xA4 || b0 == 0xA8) return 31;
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
    _webIdleFlush?.cancel();
    _webIdleFlush = null;
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

  static const int maxWriteAttempts = 2;
  static const Duration writeRetryDelay = Duration(milliseconds: 16);

  Future<void> sendReport(Uint8List data, {int reportId = 0x00}) async {
    _ensureOpen();
    Object? lastError;
    for (var attempt = 1; attempt <= maxWriteAttempts; attempt++) {
      try {
        await _device.sendReport(data, reportId: reportId);
        return;
      } catch (e) {
        lastError = e;
        if (attempt < maxWriteAttempts) {
          await Future<void>.delayed(writeRetryDelay);
        }
      }
    }
    // TODO(phase-L4): report write failure to BLoC instead of rethrowing.
    throw lastError ??
        StateError('sendReport failed after $maxWriteAttempts attempts');
  }

  Future<Uint8List> receiveReport(int reportLength, {Duration? timeout}) {
    _ensureOpen();
    _closed ??= Completer<void>();
    final read = _device.receiveReport(reportLength, timeout: timeout);
    return Future.any([
      read,
      _closed!.future.then((_) => throw const HidSessionClosedException()),
    ]);
  }

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
