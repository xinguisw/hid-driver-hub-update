# driver_hub — Layer Development

This document lists the application tiers of driver_hub, top to bottom, by
contract boundary. Each tier is one module with its own responsibility and
boundary. The platform tiers below the application are not part of the app
code.

driver_hub targets both desktop (Windows) and web (WebHID). The desktop and
web paths converge at the `hid_tool` library and split at discovery. The
layering is identical for both platforms above transport; the only
platform-specific code is the discovery implementation.

## Application tiers

| # | Tier | File(s) | Status |
|---|------|---------|--------|
| 1 | Presentation / UI | `features/<type>/views/` (MouseCard, DevicesScreen) + BLoC | to build |
| 2 | Session Orchestration | `DeviceSession` (lifecycle, handshake-verify, intent to command, state stream) + BLoC | to build |
| 3 | Device Descriptor | `capabilities.dart` + `sensor_profiles.dart` + `supported_model.json` | built |
| 4 | Vendor Protocol Codec | `features/<type>/protocol/<devId>_protocol.dart` (frame, CRC, command encode/decode, parse) | to build |
| 5 | Device Matching | `device_scanner.dart` + `device_catalog.dart` + `discovered_device.dart` | built |
| 6 | HID Transport (shared) | `hid_session.dart` (open, close, sendReport, receiveReport, inputStream) | built |
| 7 | HID Discovery (split) | `hid_scanner.dart`, `desktop/desktop_hid_scanner.dart`, `web/web_hid_scanner.dart`, `hid_scanner_factory.dart` | built |

## Platform tiers (below the app)

| # | Tier | Evidence |
|---|------|----------|
| 8 | HID library | `hid_tool` abstracts hidapi/FFI (desktop) and WebHID (web); two backends, one API |
| 9 | OS HID/USB stack | Windows HID driver (desktop); browser WebHID implementation (web) |
| 10 | Physical device | mouse/keyboard hardware and firmware |

## Built vs to build

Built: tiers 3, 5, 6, 7.

To build: tiers 1, 2, 4.

Build order, bottom up:

1. Tier 4 (Vendor Protocol Codec). Requires a `sendAndWait` (ack and retry)
   added to tier 6 (HidSession).
2. Tier 2 (Session Orchestration).
3. Tier 1 (Presentation / UI).

## Desktop and web

The layering is identical for all application tiers on both platforms. The
only platform-specific code is the discovery implementation (tier 7):

- Desktop: `DesktopHidScanner` enumerates silently via `Hid.getDevices()`.
- Web: `WebHidScanner` presents the browser permission picker via
  `Hid.requestDevice()`.

`HidScannerFactory.current()` selects the implementation via `kIsWeb`. This is
the single platform seam. No other code branches on the host platform.

WebHID input is event-based, not a blocking read. The transport layer (tier 6)
adds an async request/response correlation (`sendAndWait`) for ack and retry.
Everything above transport is platform-agnostic.

