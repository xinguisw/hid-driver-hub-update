import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _osdChannel = MethodChannel('driver_hub/osd_overlay');

/// Windows-only sender for the native OSD popup.
///
/// L3 supplies only semantic text. The Windows runner owns the transient
/// native popup and its three-second lifetime.
class OsdOverlayService {
  OsdOverlayService();

  bool _disposed = false;

  bool get _enabled =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  Future<void> show({
    required String title,
    required List<String> lines,
  }) async {
    if (!_enabled || _disposed) return;

    try {
      await _osdChannel.invokeMethod<void>('show', <String, Object?>{
        'title': title,
        'lines': List<String>.unmodifiable(lines),
      });
    } on PlatformException catch (error) {
      debugPrint('[osd] show failed: ${error.message ?? error.code}');
    }
  }

  void dispose() {
    _disposed = true;
  }
}
