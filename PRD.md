# PRD — Device Session Feature Layer

**Project:** driver_hub
**Status:** Draft, pending implementation
**Scope:** feature layer above the HID surface; the frozen core is not in scope

## 1. Purpose

This document specifies the feature layer that takes a discovered HID device
through identification to a per-device card, and scales to multiple devices.

The layer sits above the HID surface defined in
`Documentation/app/HID_Surface_Specification.docx`. The surface provides
discovery, matching, and raw transport. This layer orchestrates those parts
into a per-device lifecycle and exposes device state to a minimal card.

The layer targets both desktop and web. UI presentation is out of scope for
this phase; the card renders state as plain data.

## 2. Conventions

The key words MUST, MUST NOT, and MAY are to be interpreted as described in
RFC 2119.

Actors are named concretely: the scanner, the orchestrator, the protocol, the
bloc, the card. The word "system" is not used.

## 3. Background

The frozen HID surface provides:

- `DeviceScanner.discover()` returns `List<DiscoveredDevice>`. Each
  `DiscoveredDevice` bundles a catalog entry, a connection mode, and a
  `HidDevice` handle.
- `HidSession` owns one open `HidDevice` and exposes raw report I/O:
  `open()`, `close()`, `sendReport()`, `receiveReport()`, `inputStream()`.
  It performs no framing and no parsing.

`HidSession` does not handshake, does not verify a device identifier, and does
not read battery. Those operations require a device protocol, which is not
available yet. This layer defines the protocol as a seam and supplies a stub so
the pipeline runs end to end without hardware.

## 4. Goals

- G1. Enumerate connected HID devices and match each to a catalog entry.
- G2. Load the per-device capabilities file lazily, only for discovered devices.
- G3. Handshake and verify the device identifier before opening a session.
- G4. Open a session and surface battery, charging, device name, and
  connection mode.
- G5. Render one card per discovered device. Multiple devices render multiple
  cards.
- G6. Run on both desktop and web.

## 5. Non-goals

- N1. UI design, styling, images, and layout. The card renders state as text.
- N2. The real device protocol. Handshake and battery are stubbed.
- N3. Live plug/unplug detection. Scan is user-triggered.
- N4. Per-device settings persistence.
- N5. Sensor profile loading (`sensors.json`). Required only when DPI math is
  implemented.

## 6. Flow

For each discovered device, the orchestrator executes the following steps in
order. A step that fails stops the pipeline for that device; other devices are
unaffected.

1. **Enumerate.** `DeviceScanner.discover()` returns the list of discovered
   devices.
2. **Match.** Each returned `HidDevice` is matched to a catalog entry by
   `vid`, `pid`, and `usagePage`. Matching is performed by the surface and is
   not repeated here.
3. **Load detail file.** The orchestrator loads
   `assets/catalog/<type>/capabilities/<devId>.json` for the device. Loading is
   lazy: only files for discovered devices are loaded, and each file is loaded
   at most once and cached by `devId`.
4. **Handshake.** The orchestrator calls the protocol's handshake operation.
   The protocol returns a device identifier reported by the device.
5. **Verify identifier.** The orchestrator compares the reported identifier to
   the catalog `devId`. If they differ, the pipeline stops for that device.
6. **Open.** The orchestrator opens a `HidSession` over the device handle.
7. **Load state.** The orchestrator subscribes to device state. Device name and
   mode come from the catalog entry. Battery and charging come from the
   protocol, sourced from the device's OSD push stream.

Steps 4, 5, and 7 (battery/charging) depend on the device protocol and are
stubbed. Steps 1, 2, 3, 6, and 7 (name, mode) do not depend on the protocol and
are implemented.

## 7. Components

### 7.1 CapabilityStore

Loads and caches per-device capability files.

```
class CapabilityStore {
  Future<Capabilities> load(String devId, int deviceType);
}
```

- Reads `assets/catalog/<type>/capabilities/<devId>.json`.
- Caches by `devId`. A second call for the same `devId` returns the cached
  value and does not re-read the asset.
- Performs no HID I/O.
- Throws if the file is missing or fails to parse.

### 7.2 DeviceProtocol (seam)

Defines the device-dependent operations. The orchestrator depends on this
interface, not on any implementation.

```
abstract class DeviceProtocol {
  Future<DeviceHandshake> handshake(HidSession session);
  Stream<DeviceStatus> status(HidSession session);
}

class DeviceHandshake {
  final String deviceId;   // identifier reported by the device
}

class DeviceStatus {
  final int batteryPercent;     // 0..100, or null if unknown
  final bool charging;
}
```

- `handshake` sends the device's handshake frame, awaits the reply, and returns
  the identifier the device reported.
- `status` returns a stream of device status, sourced from the device's OSD
  push stream. The stream emits on each push; it does not poll.

Two implementations:

- `StubDeviceProtocol` — used now. `handshake` returns the catalog `devId`
  (verification always passes). `status` emits mock values so the pipeline is
  observable. No HID I/O is performed.
- `<devId>Protocol` — used when firmware is available. `handshake` sends the
  handshake frame and parses the reply. `status` parses OSD push bytes from
  `session.inputStream()`.

The orchestrator MUST depend on `DeviceProtocol`, not on a concrete
implementation. Swapping stub for real changes one wiring site per device and
touches nothing else.

### 7.3 DeviceSession

The per-device orchestrator. One instance per discovered device. Owns the
lifecycle from handshake through state subscription.

```
class DeviceSession {
  DeviceSession({
    required DiscoveredDevice device,
    required CapabilityStore capabilities,
    required DeviceProtocol protocol,
  });

  Future<void> start();    // run steps 3..7
  Future<void> dispose();  // close session, cancel subscriptions
  Stream<DeviceCardState> get state;
}
```

- `start` runs steps 3 through 7 of the flow. On any failure it stops and
  emits a terminal error state for that device only.
- `state` emits `DeviceCardState` as each step completes and as battery/charging
  pushes arrive.
- `dispose` closes the `HidSession` and cancels the status subscription.

`DeviceSession` MUST NOT call `HidDevice` directly. It uses `HidSession` for
transport and `DeviceProtocol` for protocol-dependent steps.

### 7.4 DeviceCardState

The state a card renders.

```
class DeviceCardState {
  final String name;              // catalog model
  final String mode;              // connection mode description (USB, 2.4G)
  final bool handshakeVerified;
  final int? batteryPercent;      // null until first push
  final bool charging;
  final bool isStub;              // true while StubDeviceProtocol is in use
}
```

### 7.5 MouseCardBloc

One bloc per `DeviceSession`. Exposes `DeviceCardState` to the card.

```
class MouseCardBloc {
  MouseCardBloc(DeviceSession session);
  Stream<DeviceCardState> get state;
}
```

### 7.6 DevicesScreen and MouseCard

- `DevicesScreen` calls `DeviceScanner.discover()` on a user gesture, then
  creates one `DeviceSession` per result. It renders one `MouseCard` per
  session.
- `MouseCard` renders `DeviceCardState` as plain text rows. No styling.
- The list of cards is keyed by `DeviceSession` object identity, not by a
  string identifier. Two devices of the same model are distinct objects and
  render as distinct cards.

## 8. Scalability

Multiple devices are multiple `DeviceSession` instances. Each session owns its
own `HidSession` and its own status subscription. There is no shared global, no
device array indexed by position, and no broadcaster.

The pipeline for one device MUST NOT block or affect another. A handshake
failure on device A stops device A only.

## 9. Platform: web and desktop

- Discovery is user-triggered by a scan action. On web, the browser requires a
  user gesture for `Hid.requestDevice()`; a scan button satisfies this on both
  platforms. The scan entry point MUST NOT branch on `kIsWeb`.
- Transport, matching, and the orchestrator are platform-agnostic. No code in
  this layer branches on the host platform.
- If WebHID is unsupported, the scan action reports this to the user. The
  pipeline does not run.

## 10. File layout

```
core/device/
  capability_store.dart          CapabilityStore
features/mouse/
  protocol/
    device_protocol.dart         DeviceProtocol, DeviceHandshake, DeviceStatus
    stub_device_protocol.dart    StubDeviceProtocol
  repositories/
    device_session.dart          DeviceSession, DeviceCardState
  controllers/
    mouse_card_bloc.dart         MouseCardBloc
  views/
    screens/devices_screen.dart  DevicesScreen
    widgets/mouse_card.dart      MouseCard
lib/main.dart                    app shell (replaces counter template)
```

`core/hid/` and `core/device/hid_session.dart` are not modified.

## 11. Open decisions

1. **Stub battery/charging values.** Emit mock values (for example 80, false)
   so the pipeline is observable, or emit null/unknown. Recommendation: mock
   values, marked by `isStub`.
2. **Stub handshake behavior.** Always verify, or randomly fail to exercise
   the failure path. Recommendation: always verify.
3. **Scan trigger.** User-triggered scan now, with live plug/unplug as a later
   additive change; or live plug/unplug from the start. Recommendation:
   user-triggered now.
4. **Detail file.** Confirm the "detail file" is the capabilities JSON, not
   the sensor profile. Recommendation: capabilities JSON.

## 12. Verification

- `flutter analyze` reports no issues.
- `flutter build web` and `flutter build windows` both succeed.
- With `StubDeviceProtocol`, two devices render two cards, each showing name,
  mode, verified handshake, and mock battery/charging.
- Swapping `StubDeviceProtocol` for a real protocol requires a change at one
  wiring site per device and no change to the orchestrator, bloc, or card.

## 13. References

- `Documentation/app/HID_Surface_Specification.docx` — the frozen HID surface
  this layer builds on.
- `assets/catalog/supported_model.json` — the device registry.
- `assets/catalog/<type>/capabilities/<devId>.json` — per-device capability
  files.
- RFC 2119 — requirement keywords.
