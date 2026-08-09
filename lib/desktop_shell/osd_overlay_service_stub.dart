/// No-op OSD adapter for web and unsupported platforms.
class OsdOverlayService {
  const OsdOverlayService();

  Future<void> show({
    required String title,
    required List<String> lines,
  }) async {}

  void dispose() {}
}
