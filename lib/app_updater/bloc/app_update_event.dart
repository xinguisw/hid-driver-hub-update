import 'package:driver_hub/app_updater/models/updater_config.dart';

/// Base class for all events handled by [AppUpdateBloc].
abstract class AppUpdateEvent {
  const AppUpdateEvent();
}

/// Dispatched to configure the updater subsystem with the AppCast feed URL and parameters.
class InitializeUpdaterRequested extends AppUpdateEvent {
  const InitializeUpdaterRequested({this.config});

  /// Optional configuration override. If omitted, uses the default [UpdaterConfig].
  final UpdaterConfig? config;

  @override
  String toString() => 'InitializeUpdaterRequested(config: $config)';
}

/// Dispatched when an update check is requested.
///
/// If [isManual] is true (e.g. user clicked "Check for Updates" in Settings),
/// WinSparkle will bring its modal dialog to the foreground even if up to date.
/// If [isManual] is false (e.g. background startup check), WinSparkle remains silent if up to date.
class CheckForUpdatesRequested extends AppUpdateEvent {
  const CheckForUpdatesRequested({this.isManual = true});

  final bool isManual;

  @override
  String toString() => 'CheckForUpdatesRequested(isManual: $isManual)';
}

/// Dispatched to set the periodic scheduled check interval (in seconds).
class SetUpdateIntervalRequested extends AppUpdateEvent {
  const SetUpdateIntervalRequested({required this.intervalSeconds});

  final int intervalSeconds;

  @override
  String toString() =>
      'SetUpdateIntervalRequested(intervalSeconds: $intervalSeconds)';
}

/// Dispatched to reset the bloc state back to [AppUpdateInitial].
class ResetUpdateStateRequested extends AppUpdateEvent {
  const ResetUpdateStateRequested();

  @override
  String toString() => 'ResetUpdateStateRequested()';
}
