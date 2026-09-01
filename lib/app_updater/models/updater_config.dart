/// Configuration options for the App Updater subsystem.
class UpdaterConfig {
  const UpdaterConfig({
    this.owner = 'sumanram23',
    this.repo = 'hid-driver-hub',
    this.assetPattern = r'hid_driver_hub_installer\.exe$',
    this.requestTimeout = const Duration(seconds: 15),
    this.downloadTimeout = const Duration(seconds: 60),
    this.customFeedUrl,
  });

  /// GitHub repository owner (username or organization).
  final String owner;

  /// GitHub repository name.
  final String repo;

  /// Regular expression pattern string to identify the target executable installer asset.
  final String assetPattern;

  /// HTTP timeout for metadata and release info requests.
  final Duration requestTimeout;

  /// HTTP timeout for streaming binary chunks.
  final Duration downloadTimeout;

  /// Optional override URL for self-hosted or Web version checking (e.g. `/version.json`).
  final String? customFeedUrl;

  /// Compiled RegExp from [assetPattern].
  RegExp get assetRegExp => RegExp(assetPattern, caseSensitive: false);

  /// Default GitHub API endpoint URL for the latest release.
  String get githubLatestReleaseUrl =>
      'https://api.github.com/repos/$owner/$repo/releases/latest';

  @override
  String toString() =>
      'UpdaterConfig(owner: $owner, repo: $repo, assetPattern: $assetPattern)';
}
