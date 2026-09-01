/// Represents live download progress of an update binary installer.
class UpdateProgress {
  const UpdateProgress({
    required this.receivedBytes,
    required this.totalBytes,
    this.bytesPerSecond,
  });

  /// Total number of bytes downloaded so far.
  final int receivedBytes;

  /// Total size of the file in bytes (-1 if unknown / chunked transfer encoding).
  final int totalBytes;

  /// Instantaneous or average download speed in bytes/sec.
  final double? bytesPerSecond;

  /// Returns progress fraction as a double between 0.0 and 1.0.
  /// If totalBytes is unknown or non-positive, returns 0.0.
  double get fraction {
    if (totalBytes <= 0) return 0.0;
    final f = receivedBytes / totalBytes;
    if (f < 0.0) return 0.0;
    if (f > 1.0) return 1.0;
    return f;
  }

  /// Progress integer percentage from 0 to 100.
  int get percentage => (fraction * 100).round();

  /// Whether the download has completed (100% of bytes received).
  bool get isCompleted => totalBytes > 0 && receivedBytes >= totalBytes;

  /// Formatted string of received bytes (e.g. "15.4 MB").
  String get receivedMbFormatted => _formatBytes(receivedBytes);

  /// Formatted string of total bytes (e.g. "45.0 MB" or "-- MB" if unknown).
  String get totalMbFormatted =>
      totalBytes > 0 ? _formatBytes(totalBytes) : '-- MB';

  /// Formatted download speed (e.g. "2.4 MB/s").
  String get speedFormatted {
    if (bytesPerSecond == null || bytesPerSecond! <= 0) return '';
    return '${_formatBytes(bytesPerSecond!.round())}/s';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      final gb = bytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB';
    }
  }

  @override
  String toString() =>
      'UpdateProgress($percentage%, $receivedMbFormatted / $totalMbFormatted, $speedFormatted)';
}
