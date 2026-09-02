/// Standalone App Updater Subsystem for HID Driver Hub.
///
/// Features:
/// - Desktop (Windows/macOS) automatic updates via WinSparkle / Sparkle.
/// - Safe Web / non-desktop stubs without native dependencies.
/// - Concurrency-protected [AppUpdateBloc] state machine.
/// - Sleek, localized [UpdaterActionButton] for settings panel integration.
library;

export 'bloc/app_update_bloc.dart';
export 'bloc/app_update_event.dart';
export 'bloc/app_update_state.dart';
export 'models/app_release.dart';
export 'models/update_progress.dart';
export 'models/updater_config.dart';
export 'services/auto_updater_service.dart';
export 'ui/updater_action_button.dart';
