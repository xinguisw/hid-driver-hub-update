import 'dart:typed_data';

import 'package:driver_hub/layer5_codec/macro_codec.dart';
import 'package:driver_hub/layer5_codec/utils/crc16.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const macro = MacroTransferDefinition(
    slot: 3,
    modeWire: 2,
    loopTimes: 2,
    actions: [
      MacroTransferAction(keyCode: 0x04, isBreak: false, delay: 5),
      MacroTransferAction(keyCode: 0xF1, isBreak: true, delay: 7),
    ],
  );

  test('encodes packet fields and CRC over all 67 packet bytes', () {
    final packet = MacroTransferCodec.encodePacket(macro);
    expect(packet, hasLength(67));
    expect(packet.sublist(0, 7), [3, 2, 0, 0, 0, 2, 2]);
    expect(packet.sublist(7, 11), [5, 0x04, 0x87, 0xF1]);

    final transfer = MacroTransferCodec.encodeTransfer(macro);
    final crc = const Crc16().bytes(packet);
    expect(transfer, hasLength(69));
    expect(transfer.sublist(67), crc);
  });

  test('encodes wheel actions as F6/F7 make+break mouse events', () {
    final wheelMacro = macro.copyWith(
      actions: const [
        MacroAction(keyCode: 0xF6, isBreak: false, delay: 1),
        MacroAction(keyCode: 0xF6, isBreak: true, delay: 0),
        MacroAction(keyCode: 0xF7, isBreak: false, delay: 1),
        MacroAction(keyCode: 0xF7, isBreak: true, delay: 0),
      ],
    );

    expect(MacroTransferCodec.encodePacket(wheelMacro).sublist(7, 15), [
      0x01,
      0xF6,
      0x80,
      0xF6,
      0x01,
      0xF7,
      0x80,
      0xF7,
    ]);
  });

  test('splits transfer into protocol chunk sizes', () {
    final chunks = MacroTransferCodec.chunkTransfer(macro);
    expect(chunks.map((c) => c.length), [26, 26, 17]);
    expect([
      ...chunks[0],
      ...chunks[1],
      ...chunks[2],
    ], MacroTransferCodec.encodeTransfer(macro));
  });

  test('places the chunk index in reserve[0] and keeps reserve[1] zero', () {
    final payload = Uint8List.fromList(List<int>.generate(26, (i) => i));
    final frame = MacroTransferCodec.buildChunkFrame(
      macroIndex: 3,
      chunkIndex: 1,
      payload: payload,
    );
    expect(frame, hasLength(32));
    expect(frame.sublist(0, 5), [0xEF, 1, 0, 3, 26]);
    expect(frame.sublist(5, 31), payload);
  });

  test('parses status from dat[0], not the echoed opcode', () {
    final reply = Uint8List(32)
      ..[0] = 0xEF
      ..[1] = 2
      ..[3] = 3
      ..[5] = MacroTransferCodec.statusOk;
    expect(MacroTransferCodec.parseReplyStatus(reply), 2);
    expect(MacroTransferCodec.parseReplyChunk(reply), 2);
  });
}
