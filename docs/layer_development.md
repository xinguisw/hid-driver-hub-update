# driver_hub — Layer Development

Layers listed top to bottom by contract boundary: L1 is the top-level
orchestration concern, L6 is the metal. Each is one module with its own
responsibility and boundary. Tiers below L6 (P1–P3) are the platform, not app
code.

driver_hub targets desktop (Windows) and web (WebHID). Both paths converge at
`hid_tool` and split at enumeration — the only platform-specific code.

## Application layers

| # | Layer | Responsibility | Realized in | Status |
|---|-------|----------------|-------------|--------|
| L1 | Discovery & Lifecycle | Scan the bus, match to catalog, fail-fast authenticate, own session lifecycle; output an immutable list of `DiscoveredCardState` for the home grid | `device_scanner.dart`, `device_catalog.dart`, `discovered_device.dart`, `device_session.dart`, `device_watcher.dart` | partial |
| L2 | Capability Blueprint | Static lookup: devId (+ firmware version) → immutable `DeviceCapabilities`; image paths, sensor, max DPI, feature gates | `capabilities.dart`, `sensor_profiles.dart`, `device_type.dart`, `assets/catalog/supported_model.json` | built |
| L3 | Presentation | Flutter view controllers, view models, widgets. Blind to hardware and protocol bytes; reads capability maps, subscribes to state, renders cards | `features/mouse/views/widgets/mouse_card.dart`, `features/mouse/models/discovered_card_state.dart` | partial |
| L4 | Domain | Abstract `DeviceRepository` + `DeviceHydrationService`; source of truth for the active config profile as typed classes (`DpiConfiguration`, `ButtonMap`), not dynamic maps | — | not yet reached |
| L5 | Codec & Sequencing | `ProtocolCodec` facade delegating to sub-codecs (`dpi_codec`, `rgb_codec`); math transforms, framing, CRC, async priority `CommandPlanner` | `features/mouse/protocol/device_protocol.dart` (handshake only), `core/utils/crc16.dart` (staged, unused) | partial |
| L6 | Hardware Transport Router | Uniform transport abstraction; platform-specific enumeration drivers; raw `read()`/`write()` | `core/device/hid_session.dart`, `core/hid/hid_scanner.dart`, `core/hid/hid_scanner_factory.dart`, `core/hid/desktop/desktop_hid_scanner.dart`, `core/hid/web/web_hid_scanner.dart`, `core/hid/hid_events.dart` | built |

## Layer detail and gaps

### L1 — Discovery & Lifecycle
Built: catalog-driven enumeration and (vid, pid) matching (`DeviceScanner`),
open → handshake → verify lifecycle (`DeviceSession`), and connect/disconnect
reconnect keyed by device path (`DeviceWatcher`). Fail-fast auth is the
handshake+verify step.

Missing: the output contract is an immutable `List<DiscoveredCardState>` for
the home grid. Sessions emit per-device state to the test harness only; nothing
aggregates them. Next step for the device-card UI stage.

### L2 — Capability Blueprint
Built: `CapabilityStore.forDevice(devId)` returns a hardcoded immutable
`DeviceCapabilities`; `SensorProfiles` holds the DPI encoding tables. Each
block carries a `present` flag for UI feature-gating. `DeviceType` is the typed
device-kind enum spoken by catalog and handshake.

Missing: lookup keys on devId only. Intended to also key on firmwareVersion so
a hardware revision can change capabilities. Deferred until firmware queries
exist (L5 opcode A8).

### L3 — Presentation
Built: `MouseCard`, a pure CDD component rendering `DiscoveredCardState` only —
no streams, no HID, no catalog lookup. `DiscoveredCardState` is an immutable
view model with value equality.

Missing: the `DevicesScreen` grid (one card per device) and the BLoC/view-model
that subscribes to L1's list and feeds the grid. `main.dart` is currently a
verify-test harness, not the presentation layer.

### L4 — Domain
No code. Will host the abstract `DeviceRepository` and `DeviceHydrationService`
(aggregating L2 capabilities + live device state), and be the source of truth
for the active config profile as typed classes (`DpiConfiguration`, `ButtonMap`)
instead of dynamic maps. Reached when settings read/write begins.

### L5 — Codec & Sequencing
Built: `MouseProtocol.handshake()` — the ask/ack probe over report id 7, with
device-type and devId parse. Fail-fast auth seed only.

Missing: the `ProtocolCodec` facade and per-feature sub-codecs (`dpi_codec`,
`rgb_codec`, …); CRC integration (`crc16.dart` is staged, called nowhere); the
async priority `CommandPlanner` for write scheduling; and `sendAndWait`
(ack + retry) on L6. Full opcodes (C2/A4/A8/B2/C6/D4/E2 CONFIG; 0xFF0A OSD
push) are deferred to this stage.

### L6 — Hardware Transport Router
Built: `HidSession` is the single shared transport primitive (open, close,
sendReport, receiveReport, inputStream) — no framing, no parsing. Enumeration
is split by platform behind `HidScanner`: desktop enumerates silently, web
presents the permission picker. `HidEvents` unifies connect/disconnect.
`hid_tool` unifies the actual read/write on both backends.

## Platform tiers (below the application)

| # | Tier | Evidence |
|---|------|----------|
| P1 | HID library | `hid_tool` abstracts hidapi/FFI (desktop) and WebHID (web); two backends, one API |
| P2 | OS HID/USB stack | Windows HID driver (desktop); browser WebHID implementation (web) |
| P3 | Physical device | mouse/keyboard hardware and firmware |

## Desktop and web

The only platform-specific code is enumeration (L6):

- Desktop: `DesktopHidScanner` enumerates silently via `Hid.getDevices()`.
- Web: `WebHidScanner` presents the browser permission picker via
  `Hid.requestDevice()`.

`HidScannerFactory.current()` selects via `kIsWeb` — the single platform seam;
no other code branches on the host.

WebHID input is event-based, not blocking. L6 will add `sendAndWait`
(request/response with ack + retry) for L5's codec to use.

## Status and build order

Built: L2, L6, and parts of L1, L3, L5.

Not yet reached: L4 in full; L1's list output; L3's grid/BLoC; L5's facade,
sub-codecs, CRC, and `CommandPlanner`.

Build order for the current stage (device-card UI, UI-only-loads-data):

1. L1 list output — aggregate verified sessions into an immutable
   `List<DiscoveredCardState>` the UI can consume.
2. L3 grid — `DevicesScreen` renders one `MouseCard` per entry, driven by a
   BLoC/view-model that subscribes to that list.

L4 and the rest of L5 are later stages (settings read/write), not needed for
the cards.
