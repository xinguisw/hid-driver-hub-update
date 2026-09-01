import 'package:version/version.dart';

/// Represents release metadata fetched from a remote distribution provider (GitHub/GitLab/Custom).
class AppRelease {
  const AppRelease({
    required this.tagName,
    required this.version,
    required this.releaseNotes,
    required this.assetDownloadUrl,
    required this.assetName,
    required this.assetSizeBytes,
    required this.publishedAt,
    required this.htmlUrl,
  });

  /// The raw tag name on git, e.g. "v1.2.3" or "1.2.3".
  final String tagName;

  /// Clean semantic version string, e.g. "1.2.3".
  final String version;

  /// Changelog or markdown release body.
  final String releaseNotes;

  /// Direct binary download URL for the target installer asset (.exe).
  final String assetDownloadUrl;

  /// File name of the asset, e.g. "hid_driver_hub_installer.exe".
  final String assetName;

  /// Asset size in bytes, or -1 if unknown.
  final int assetSizeBytes;

  /// Publication timestamp.
  final DateTime publishedAt;

  /// Web release page URL (for browser viewing or web fallback).
  final String htmlUrl;

  /// Strips leading 'v' / 'V' and trims whitespace from a tag or version string.
  static String cleanVersionTag(String tag) {
    var cleaned = tag.trim();
    if (cleaned.startsWith('v') || cleaned.startsWith('V')) {
      cleaned = cleaned.substring(1).trim();
    }
    // Also remove build metadata suffix if needed for basic SemVer parsing
    return cleaned;
  }

  /// Parses a version string safely, returning a [Version] object or null if malformed.
  static Version? tryParseVersion(String ver) {
    try {
      final clean = cleanVersionTag(ver);
      // If version contains build number like 1.0.0+1, Version.parse handles standard semver
      // If there's an underscore or unusual delimiter, standardize to dot
      final normalized = clean.split('+').first;
      return Version.parse(normalized);
    } catch (_) {
      return null;
    }
  }

  /// Compares this release's version against [currentVersionString].
  /// Returns `true` if this release is strictly newer according to Semantic Versioning.
  bool isNewerThan(String currentVersionString) {
    final remote = tryParseVersion(version);
    final local = tryParseVersion(currentVersionString);

    if (remote != null && local != null) {
      return remote > local;
    }

    // Fallback lexicographical comparison if parsing fails
    return cleanVersionTag(version) != cleanVersionTag(currentVersionString);
  }

  /// Parses a GitHub REST API release JSON payload.
  ///
  /// Matches the executable installer asset according to [assetPattern].
  factory AppRelease.fromGitHubJson(
    Map<String, dynamic> json, {
    RegExp? assetPattern,
  }) {
    final tagName = (json['tag_name'] as String?) ?? '';
    final cleanVer = cleanVersionTag(tagName);
    final body = (json['body'] as String?) ?? '';
    final htmlUrl = (json['html_url'] as String?) ?? '';
    final publishedAtStr = json['published_at'] as String?;
    final publishedAt = publishedAtStr != null
        ? DateTime.tryParse(publishedAtStr) ?? DateTime.now()
        : DateTime.now();

    final assets = (json['assets'] as List<dynamic>?) ?? [];
    final matcher = assetPattern ?? RegExp(r'hid_driver_hub_installer\.exe$', caseSensitive: false);

    Map<String, dynamic>? matchedAsset;

    for (final raw in assets) {
      if (raw is Map<String, dynamic>) {
        final name = (raw['name'] as String?) ?? '';
        if (matcher.hasMatch(name)) {
          matchedAsset = raw;
          break;
        }
      }
    }

    // Fallback: match any .exe asset if specific name match not found
    if (matchedAsset == null) {
      for (final raw in assets) {
        if (raw is Map<String, dynamic>) {
          final name = (raw['name'] as String?) ?? '';
          if (name.toLowerCase().endsWith('.exe')) {
            matchedAsset = raw;
            break;
          }
        }
      }
    }

    final downloadUrl = (matchedAsset?['browser_download_url'] as String?) ?? '';
    final assetName = (matchedAsset?['name'] as String?) ?? '';
    final assetSize = (matchedAsset?['size'] as num?)?.toInt() ?? -1;

    return AppRelease(
      tagName: tagName,
      version: cleanVer,
      releaseNotes: body,
      assetDownloadUrl: downloadUrl,
      assetName: assetName,
      assetSizeBytes: assetSize,
      publishedAt: publishedAt,
      htmlUrl: htmlUrl,
    );
  }

  @override
  String toString() =>
      'AppRelease(version: $version, asset: $assetName, size: $assetSizeBytes, tag: $tagName)';
}
