import 'dart:async';
import 'dart:typed_data';

import 'package:hid_tool/hid_tool.dart';

/// Thrown when an in-flight [HidSession.receiveReport] is aborted because the
/// session was closed (device unplugged or [close] called) while waiting.
/// Lets callers distinguish "device gone" from a generic transport error.
class HidSessionClosedException implements Exception {
  final String message;
  const HidSessionClosedException([this.message = 'HidSession closed while a report receive was in flight.']);
  @override
  String toString() => 'HidSessionClosedException: $message';
}

/// The ONE transport object. Owns a single open [HidDevice] and is the only
/// place in the application that calls [HidDevice.sendReport],
/// [HidDevice.receiveReport], or [HidDevice.inputStream].
///
/// This layer is strictly the device-independent transport primitive:
/// open/close the device and send/receive raw reports. It contains NO
/// device-specific protocol — no report-id constants, no frame layout, no
/// opcodes, no CRC, no ack matching. Those belong to a per-device framing
/// layer that sits above this one and is built when a real device's firmware
/// protocol is known.
///
/// Transport is shared across platforms — `hid_tool` already unifies
/// send/receive on desktop and web. There is no desktop/web split here.
///
/// The command verbs (sendQuery / getSetting / setSetting / listenPush) are
/// the intended contract for the layer above; they are NOT implemented here
/// because their implementation is per-device framing, which is out of scope
/// until the target firmware protocol is available.
class HidSession {
  final HidDevice _device;
  bool _open = false;

  /// Completed when [close] runs. Racing a [receiveReport] against this lets
  /// an in-flight read abort promptly on disconnect instead of hanging until
  /// its timeout, so the watcher's dispose and the scope's publish don't
  /// fight over a dead session.
  Completer<void>? _closed;

  HidSession(this._device);

  /// Whether the underlying device is open.
  bool get isOpen => _open;

  /// Opens the underlying device.
  Future<void> open() async {
    if (_open) return;
    await _device.open();
    // Required on web: hid_tool's HidDeviceWeb creates its input-report
    // controller lazily inside inputStream(), and receiveReport() dereferences
    // it with `!`. Calling inputStream() here ensures the controller exists
    // before any receiveReport, or the first read throws a null-check error.
    // On desktop inputStream() is an async* generator, so this is a no-op.
    _device.inputStream();
    _open = true;
    _closed = null; // fresh — a reopened session can receive again
  }

  /// Closes the underlying device. Aborts any in-flight [receiveReport] by
  /// completing [_closed]; the losing receive throws
  /// [HidSessionClosedException] instead of hanging to its timeout.
  Future<void> close() async {
    if (!_open) return;
    _open = false;
    _closed ??= Completer<void>();
    _closed!.complete(); // abort in-flight receives first
    if (_device.isOpen) {
      await _device.close();
    }
  }

  /// Sends a raw output report. The [reportId] is prefixed by hid_tool per
  /// HID rules. No framing is applied — callers pass already-framed bytes.
  Future<void> sendReport(Uint8List data, {int reportId = 0x00}) {
    _ensureOpen();
    return _device.sendReport(data, reportId: reportId);
  }

  /// Receives a raw input report of [reportLength] bytes. No parsing is
  /// applied — callers interpret the bytes per their device's protocol.
  ///
  /// Races the device read against [_closed]: if [close] runs while waiting,
  /// this throws [HidSessionClosedException] promptly rather than hanging
  /// until [timeout].
  Future<Uint8List> receiveReport(int reportLength, {Duration? timeout}) {
    _ensureOpen();
    _closed ??= Completer<void>();
    final read = _device.receiveReport(reportLength, timeout: timeout);
    // If close() completes _closed first, surface a typed abort error.
    return Future.any([
      read,
      _closed!.future.then((_) =>
          throw const HidSessionClosedException()),
    ]);
  }

  /// The raw input byte stream from the device. Each event is one byte.
  /// No framing or demuxing is applied — that is the caller's responsibility
  /// (per-device framing layer).
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
