import 'dart:typed_data';

import 'package:driver_hub/layer5_codec/utils/crc16.dart';

/// L5 wire-ready macro action. It contains no UI label or domain behavior.
class MacroTransferAction {
  const MacroTransferAction({
    required this.keyCode,
    required this.isBreak,
    required this.delay,
  });

  final int keyCode;
  final bool isBreak;
  final int delay;
}

/// L5 wire-ready macro transfer input.
class MacroTransferDefinition {
  const MacroTransferDefinition({
    required this.slot,
    required this.modeWire,
    required this.loopTimes,
    required this.actions,
  });

  static const maxSlots = 16;
  static const maxActions = 30;

  final int slot;
  final int modeWire;
  final int loopTimes;
  final List<MacroTransferAction> actions;
}

/// L5 encoder for the dedicated Telink B80 macro transfer.
class MacroTransferCodec {
  const MacroTransferCodec();

  static const reportId = 0x08;
  static const opcode = 0xEF;
  static const frameLength = 32;
  static const packetLength = 67;
  static const transferLength = 69;
  static const statusReceived = 0x01;
  static const statusOk = 0x02;

  static const _firstChunkLength = 26;
  static const _secondChunkOffset = 26;
  static const _finalChunkOffset = 52;

  /// Builds the packet before CRC and chunking.
  static Uint8List encodePacket(MacroTransferDefinition macro) {
    final errors = _validate(macro);
    if (errors.isNotEmpty) throw FormatException(errors.join('; '));

    final packet = Uint8List(packetLength);
    packet[0] = macro.slot;
    packet[1] = macro.modeWire;
    // packet[2..4] are the three reserved bytes and remain zero.
    packet[5] = macro.loopTimes;
    packet[6] = macro.actions.length;
    var offset = 7;
    for (final action in macro.actions) {
      packet[offset++] = (action.isBreak ? 0x80 : 0) | action.delay;
      packet[offset++] = action.keyCode;
    }
    return packet;
  }

  /// Appends the protocol CRC16 to the 67-byte packet.
  static Uint8List encodeTransfer(MacroTransferDefinition macro) {
    final packet = encodePacket(macro);
    final crc = const Crc16().bytes(packet);
    return Uint8List.fromList([...packet, crc[0], crc[1]]);
  }

  /// Builds one report-8 macro chunk body. The report ID is supplied separately
  /// to HidSession, matching the existing HID transport contract.
  static Uint8List buildChunkFrame({
    required int macroIndex,
    required int chunkIndex,
    required List<int> payload,
  }) {
    if (macroIndex < 1 || macroIndex > MacroTransferDefinition.maxSlots) {
      throw ArgumentError.value(macroIndex, 'macroIndex');
    }
    if (chunkIndex < 0 || chunkIndex > 2) {
      throw ArgumentError.value(chunkIndex, 'chunkIndex');
    }
    final expectedLength = switch (chunkIndex) {
      0 || 1 => _firstChunkLength,
      2 => transferLength - _finalChunkOffset,
      _ => throw StateError('unreachable'),
    };
    if (payload.length != expectedLength) {
      throw ArgumentError.value(
        payload.length,
        'payload.length',
        'chunk $chunkIndex requires $expectedLength bytes',
      );
    }

    final frame = Uint8List(frameLength);
    frame[0] = opcode;
    // The PDF's macro-transfer section assigns reserve[0] to chunk index
    // (0, 1, then 2); reserve[1] remains zero.
    frame[1] = chunkIndex;
    frame[3] = macroIndex; // addrs/index
    frame[4] = payload.length;
    frame.setRange(5, 5 + payload.length, payload);
    return frame;
  }

  static List<Uint8List> chunkTransfer(MacroTransferDefinition macro) {
    final transfer = encodeTransfer(macro);
    return [
      Uint8List.fromList(transfer.sublist(0, _firstChunkLength)),
      Uint8List.fromList(
        transfer.sublist(_secondChunkOffset, _finalChunkOffset),
      ),
      Uint8List.fromList(transfer.sublist(_finalChunkOffset)),
    ];
  }

  /// Returns the transfer status from a report-8 reply body, after optional
  /// desktop report-id stripping.
  static int parseReplyStatus(Uint8List body) {
    if (body.length <= 5 || body[0] != opcode) {
      throw FormatException('Invalid macro reply frame');
    }
    return body[5]; // dat[0]
  }

  static int parseReplyChunk(Uint8List body) {
    if (body.length < 2 || body[0] != opcode) {
      throw FormatException('Invalid macro reply frame');
    }
    return body[1];
  }

  static List<String> _validate(MacroTransferDefinition macro) {
    final errors = <String>[];
    if (macro.slot < 1 || macro.slot > MacroTransferDefinition.maxSlots) {
      errors.add('Macro slot must be between 1 and 16');
    }
    if (macro.modeWire < 0 || macro.modeWire > 0xFF) {
      errors.add('Macro mode must fit one byte');
    }
    if (macro.loopTimes < 1 || macro.loopTimes > 0xFF) {
      errors.add('Loop count must be between 1 and 255');
    }
    if (macro.actions.isEmpty ||
        macro.actions.length > MacroTransferDefinition.maxActions) {
      errors.add('Macro must contain between 1 and 30 actions');
    }
    for (var i = 0; i < macro.actions.length; i++) {
      final action = macro.actions[i];
      if (action.delay < 0 || action.delay > 0x7F) {
        errors.add('Action ${i + 1} delay must be between 0 and 127');
      }
      if (action.keyCode < 0 || action.keyCode > 0xFF) {
        errors.add('Action ${i + 1} key code must fit one byte');
      }
    }
    return errors;
  }
}
