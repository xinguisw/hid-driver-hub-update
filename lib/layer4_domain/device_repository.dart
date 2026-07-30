import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:driver_hub/layer5_codec/device_protocol.dart';

/// Abstract repository for device operations needed by L4 domain layer.
///
/// L4 depends on this abstraction, not on L1's concrete [DeviceSession].
/// L1 implements this interface to bridge discovery and domain layers.
///
/// Per SDRD: L4 should have "Abstract DeviceRepository + DeviceHydrationService"
abstract class DeviceRepository {
  /// Whether the device is currently connected and responsive.
  bool get isAlive;

  /// The device card state associated with this repository.
  DiscoveredCardState get card;

  /// Re-establish handshake with the device.
  Future<bool> rehandshake();

  /// Query button mapping configuration from device.
  Future<ButtonMappingResult?> queryButtonMapping();

  /// Query report rate and DPI info from device.
  Future<ReportRateDpiInfoResult?> queryReportRateDpiInfo();

  /// Query DPI table from device.
  Future<DpiTableResult?> queryDpiTable();

  /// Query DPI RGB configuration from device.
  Future<DpiRgbResult?> queryDpiRgb();

  /// Query sensor and other features from device.
  Future<SensorOtherResult?> querySensorOther();

  /// Query RGB backlight configuration from device.
  Future<RgbBacklightResult?> queryRgbBacklight();
}
