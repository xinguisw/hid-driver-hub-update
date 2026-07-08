import 'dart:async';
import 'dart:typed_data';

import 'package:hid_tool/hid_tool.dart';

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

  HidSession(this._device);

  /// Whether the underlying device is open.
  bool get isOpen => _open;

  /// Opens the underlying device.
  Future<void> open() async {
    if (_open) return;
    await _device.open();
    _open = true;
  }

  /// Closes the underlying device.
  Future<void> close() async {
    if (!_open) return;
    if (_device.isOpen) {
      await _device.close();
    }
    _open = false;
  }

  /// Sends a raw output report. The [reportId] is prefixed by hid_tool per
  /// HID rules. No framing is applied — callers pass already-framed bytes.
  Future<void> sendReport(Uint8List data, {int reportId = 0x00}) {
    _ensureOpen();
    return _device.sendReport(data, reportId: reportId);
  }

  /// Receives a raw input report of [reportLength] bytes. No parsing is
  /// applied — callers interpret the bytes per their device's protocol.
  Future<Uint8List> receiveReport(int reportLength, {Duration? timeout}) {
    _ensureOpen();
    return _device.receiveReport(reportLength, timeout: timeout);
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
