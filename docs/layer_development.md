# driver_hub — Layer Development

Layers are listed top to bottom by contract boundary: **L1** is discovery and
session ownership, **L6** is raw HID metal. Each lives in its own `lib/layerN_*`
folder. Tiers below L6 (P1–P3) are platform, not app code.

driver_hub targets **desktop (Windows)** and **web (WebHID)**. Both paths
converge on `hid_tool`. App-level platform splits are only in L6: enumeration
and HID plug events (plus web localStorage for a last-device hint).

## Application layers

| # | Layer | Responsibility | Realized in | Status |
|---|-------|----------------|-------------|--------|
| L1 | Discovery & Lifecycle | Catalog load, bus scan, (vid, pid) match, open → handshake → verify, path-keyed sessions, plug/unplug, aggregate card list + settings GET orchestration | `lib/layer1_discovery/` | built |
| L2 | Capability Blueprint | Lazy product matrix + sensor tables: `devId` → immutable `DeviceCapabilities`; feature flags, DPI defaults, button defs | `lib/layer2_capabilities/`, `assets/catalog/mouse/` | built (UI gating partial) |
| L3 | Presentation | Screens and pure CDD widgets/view models; no HID bytes; reads `DeviceScope` notifiers | `lib/layer3_ui/` | built (text-first settings) |
| L4 | Domain | Typed config profile / repository seam (`DpiConfiguration`, `ButtonMap`, hydration) | `lib/layer4_domain/` | empty |
| L5 | Codec & Protocol | Wire framing, opcodes, ack match/parse; OSD battery codec; CRC util staged | `lib/layer5_codec/` | built for GET path |
| L6 | Hardware Transport | `HidSession` pump + `sendAndWait`, `SendQueue`, platform `HidScanner` / `HidEvents`, web storage | `lib/layer6_transport/` | built |

### Source tree (current)

```
lib/
  main.dart                          → DevicesScreen
  layer1_discovery/
    device_catalog.dart              registry JSON → DeviceCatalogEntry
    device_scanner.dart              catalog + HidScanner → DiscoveredDevice
    discovered_device.dart           entry + mode + HidDevice
    device_session.dart              open / handshake / verify / query proxies / OSD listen
    device_watcher.dart              path-keyed connect / disconnect / re-verify
    device_connection_manager.dart   DeviceScope: L1↔L3 seam (cards, busy, settings GETs)
  layer2_capabilities/
    capabilities.dart                DeviceCapabilities + DeviceCapabilityStore (JSON)
    sensor_profiles.dart             SensorProfiles (sensors.json)
    device_type.dart                 DeviceType enum (mouse=1)
  layer3_ui/
    models/
      discovered_card_state.dart     home card VM
      device_settings_state.dart     settings VM
    screens/
      devices_screen.dart            home grid + web “Add device”
      device_settings_screen.dart    onboard config text bloks; pop on fail/disconnect
    widgets/
      device_card.dart
      device_card_grid.dart
      empty_device_state.dart
      settings_block_card.dart
  layer4_domain/                     (empty)
  layer5_codec/
    device_protocol.dart             DeviceProtocol / MouseProtocol + result types
    codecs/osd_codec.dart            report 9 battery push
    utils/crc16.dart                 staged; not used on current frames
  layer6_transport/
    hid_session.dart                 open/close, pump demux, sendAndWait
    send_queue.dart                  one-at-a-time task queue per session
    hid_scanner.dart                 abstract scan / getAuthorized
    hid_scanner_factory.dart         kIsWeb → desktop vs web scanner
    hid_events.dart                  connect/disconnect (desktop + web)
    hid_event_handle.dart
    local_storage.dart               facade
    desktop/desktop_hid_impl.dart
    web/                             web scanner, events, storage + stubs
```

### Assets

| Asset | Role |
|-------|------|
| `assets/catalog/supported_model.json` | Device registry (devId, model, images, USB/2.4G vid/pid, usagePage) — L1 only |
| `assets/catalog/mouse/{model}.json` | Per-mouse capability matrix (e.g. `m7xse.json`) — L2, load on settings entry |
| `assets/catalog/mouse/sensors.json` | DPI encoding tables / sensor profiles — L2 |
| `assets/images/{model}/` | Card art (small/large) |

Supported product today: **M7XSE** (`devId` `aa4ecd01`, USB `0x248A:0x8208`, 2.4G `0x248A:0x8373`).

---

## Layer detail (as implemented)

### L1 — Discovery & Lifecycle

**Owners**

| Type | Role |
|------|------|
| `DeviceCatalog` | Loads registry; sole reader of `supported_model.json` |
| `DeviceScanner` | Builds HID filters; match by **(vid, pid)** only (`usagePage` unreliable on web) |
| `DiscoveredDevice` | Downstream handle: catalog entry + connection mode + raw `HidDevice` |
| `DeviceSession` | Per device: open → A1 handshake → type/devId verify; rehandshake; query proxies; unsolicited → OSD battery stream |
| `DeviceWatcher` | Sessions keyed by **device path**; 300 ms replug debounce; reconnect via `discoverAuthorized` |
| `DeviceScope` | Seam to L3: `ValueNotifier` `cards` / `busy`; probe at launch; web `addDevice`; soft A4/A8; live OSD patch; `queryOnboardConfig` for settings |

**Runtime contract**

1. Launch → `DeviceScope.start()` → watcher + `probeExisting()` (authorized devices).
2. Per device → `DeviceSession.start()`; rejected sessions are disposed, not shown.
3. After verify → A4 battery + A8 firmware (soft-fail → card still shown, “—”).
4. Live battery via OSD push only (A4 poll intentionally disabled).
5. Settings path: `rehandshake` then sequential config GETs; timeout / rehandshake fail → `DeviceSettingsState.error` (UI pops home).
6. Disconnect → remove card, cancel battery sub, dispose session.

**Gaps**

- Settings orchestration and card packing live in `DeviceScope` (L1), not L4.
- L2 capability matrix is not yet merged into `queryOnboardConfig` / feature gates.

### L2 — Capability Blueprint

**Built**

- `DeviceCapabilityStore.load(model)` lazy-loads `assets/catalog/mouse/{slug}.json`; `forDevice(devId)` returns cached `DeviceCapabilities`.
- Typed blocks: buttons, report rate, DPI, sensor flags, other features, RGB backlight, macro, OSD.
- `SensorProfiles` + encoding tables from `sensors.json` (e.g. SG8925 for M7XSE).
- `DeviceType` shared by catalog and handshake verify.

**Gaps**

- Lookup is by `devId` only (not firmware version / revision).
- Product matrix not yet used to hide/show settings sections or clamp controls.
- DPI wire→display math via sensor encoding not applied in UI (settings show raw wire where applicable).

### L3 — Presentation

**Built**

- `main.dart` → `DevicesScreen` (real app shell, not a harness).
- Pure CDD: `DeviceCard`, `DeviceCardGrid`, `EmptyDeviceState`, `SettingsBlockCard`.
- View models: `DiscoveredCardState`, `DeviceSettingsState` (value equality, `copyWith`).
- Home: `ValueListenableBuilder` on `DeviceScope.cards` / `busy`; web always shows “Add device”.
- Settings: text summary (name, battery, mode, FW) + text bloks for all onboard GET fields.
- Pop home when: device disconnects, no live session, rehandshake fail, or GET `TimeoutException`.

**Gaps**

- Settings UI is text/debug style — not interactive controls.
- Does not yet gate blocks from L2 capabilities.
- `flutter_bloc` is a dependency but home/settings use `ValueNotifier` / local state.
- No polish canvas / large-image layout yet (paths exist on card state).

### L4 — Domain

**Status:** folder exists, no code.

**Intended later**

- Abstract repository / hydration over L2 capabilities + live L5 results.
- Source of truth for active typed config (`DpiConfiguration`, `ButtonMap`, …) instead of packing maps in L1/L3.
- Natural home for SET/write planning once config write ships.

Until then, L1 `DeviceScope` bridges discovery/session to L3 view models.

### L5 — Codec & Protocol

**Built — `MouseProtocol` (report id 7, 32-byte frames)**

| Op / addrs | Role |
|------------|------|
| A1 | Handshake ask/ack → `DeviceType` + hex `deviceId` |
| A4 | Battery % + charging |
| A8 | Mouse + dongle firmware (display: reverse wire → `1.2.3.4`) |
| GET 0x07 / SET 0x08 / NAK 0xFF | Onboard config |
| B2 | Button mapping |
| C2 | Report rate + DPI level info |
| C4 | DPI table (XY wire) |
| C6 | DPI RGB |
| D4 | Sensor + other (ripple, LOD, debounce, sleep, wheel, …) |
| E2 | RGB backlight |

**Also built**

- `OsdCodec` — report 9, opcode 2 battery push (desktop report-id prefix vs short web frames).
- Report-id strip that does **not** confuse GET opcode `0x07` with report id `0x07`.
- Config ack match accepts SET **or** GET+data (observed on M7XSE); surfaces NAK reason.

**Gaps**

- No SET/write path for config.
- No per-feature codec split (`dpi_codec`, `rgb_codec`, …) — all in `device_protocol.dart`.
- No `CommandPlanner` / priority write scheduler.
- `crc16.dart` staged; current ask frames leave CRC zero per firmware contract.
- Sensor DPI decode (L2 tables) not applied when packing settings state.

### L6 — Hardware Transport Router

**Built**

- `HidSession`: open/close; byte pump; demux matching `sendAndWait` waiter vs `unsolicitedReports`; desktop frame sizing vs web idle-flush; `HidSessionClosedException` aborts in-flight waits.
- `SendQueue`: serializes tasks per session (failed task does not block later ones).
- `HidScanner` + factory: desktop silent `Hid.getDevices()`; web `requestDevice` / authorized `getDevices`.
- `HidEvents`: desktop `HidDeviceEvents`; web js_interop listeners; path-based identity.
- Web `localStorage` helper for last-device hint (no-op desktop).

**Gaps**

- No automatic retry inside `sendAndWait` (single timeout; caller decides).
- Web: identical mice may share synthesized path (`web:<vid>:<pid>`) — hid_tool limitation.

---

## Platform tiers (below the application)

| # | Tier | Evidence |
|---|------|----------|
| P1 | HID library | `hid_tool` — hidapi/FFI (desktop) + WebHID (web) |
| P2 | OS HID/USB | Windows HID stack; browser WebHID |
| P3 | Physical device | Mouse/keyboard + Telink-family firmware (see `Documentation/mouse_structure/`) |

## Desktop and web

Platform-specific code is confined to L6:

| Concern | Desktop | Web |
|---------|---------|-----|
| Scan | Silent enumerate | Permission picker (`requestDevice`) on user gesture |
| Reconnect / probe | Same as scan | `getAuthorized` only (no picker) |
| Plug events | Method-channel device events | `navigator.hid` connect/disconnect |
| Report framing | Report id often prefixed; sized frames | Often no report-id prefix; whole inputreport flush |
| Multi-device of same model | Unique hidapi path | May collapse to one path |

`HidScannerFactory.current()` is the primary `kIsWeb` seam for discovery.
`HidEvents` and `HidSession` pump also branch for web/desktop transport behavior.
Above L6, product code stays platform-blind (web “Add device” UI is a gesture surface, not a second scanner).

---

## End-to-end flow (current)

```
main
  └─ DevicesScreen
       └─ DeviceScope.start()
            ├─ DeviceWatcher (plug events)
            └─ probeExisting / addDevice
                 └─ DeviceScanner → DiscoveredDevice[]
                      └─ DeviceSession.start()
                           ├─ HidSession.open()
                           ├─ MouseProtocol.handshake (A1)
                           ├─ verify type + devId
                           └─ unsolicited → OsdCodec battery
                      └─ DeviceScope._publishCard
                           ├─ A4 + A8 (soft)
                           └─ cards ValueNotifier → DeviceCardGrid

card tap → DeviceSettingsScreen
  └─ DeviceScope.queryOnboardConfig
       ├─ rehandshake (A1)
       └─ GET B2, C2, C4, C6, D4, E2
            └─ DeviceSettingsState → text bloks
                 (error / timeout / dead session → pop home)
```

---

## Status and next build order

| Area | Status |
|------|--------|
| L6 transport | Built |
| L5 handshake + battery/FW + config GET + OSD | Built (GET only) |
| L2 JSON capabilities + sensors | Built |
| L1 scan / session / watcher / DeviceScope cards | Built |
| L3 home + settings (text) | Built |
| L4 domain | Not started |
| Config SET / write | Not started |
| Capability-gated interactive settings UI | Not started |
| DPI encode/decode in UI | Not started |

Suggested next stages (settings write path):

1. **L4 (or keep L1 briefly)** — merge L2 matrix + L5 GET results into a typed settings model; gate L3 sections from capabilities.
2. **L5 SET** — encode writes (B2/C2/C4/…); optional CRC if firmware requires it.
3. **L3 controls** — replace text bloks with real widgets; keep soft-fail / pop-on-fatal policy.
4. **L6** — only if write path needs retry/backoff beyond current single-shot `sendAndWait`.

---

## Doc hygiene

- This file tracks **current** `lib/layerN_*` layout. Older names (`core/hid`, `features/mouse`, hardcoded `CapabilityStore`) are obsolete.
- `PRD.md` describes an earlier feature-layer draft; treat it as historical unless refreshed.
- After adding/removing modules under `lib/`, update the source tree table above.
