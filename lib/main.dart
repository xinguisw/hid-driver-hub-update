import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:driver_hub/desktop_shell/window_bootstrap_stub.dart'
    if (dart.library.io) 'package:driver_hub/desktop_shell/window_bootstrap.dart'
    as window_bootstrap;
import 'package:driver_hub/layer3_ui/theme/app_theme.dart';
import 'package:driver_hub/layer3_ui/theme/theme_controller.dart';
import 'package:driver_hub/layer3_ui/widgets/osd_overlay_window.dart';
import 'package:driver_hub/layer1_discovery/device_runtime.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:driver_hub/layer3_ui/widgets/main_shell.dart';
import 'package:driver_hub/layer6_transport/app_settings_storage.dart';
import 'package:driver_hub/layer6_transport/macro_storage.dart';
import 'package:driver_hub/i18n/strings.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure lifecycle channel buffer to allow overflow and prevent discarded message warnings on Web startup
  ui.channelBuffers.allowOverflow('flutter/lifecycle', true);

  // Silence all debugPrint logs when running in release mode
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Initialize theme storage before running the app
  await ThemeController.instance.init();

  // Set slang locale to device locale
  LocaleSettings.useDeviceLocale();

  if (_isDesktop) {
    if (_isWindows && window_bootstrap.isOsdWindow(args)) {
      final osdController = OsdOverlayWindowController(
        showWindow: window_bootstrap.showOsdWindow,
        hideWindow: window_bootstrap.hideOsdWindow,
      );
      runApp(OsdOverlayApp(controller: osdController));
      await WidgetsBinding.instance.endOfFrame;
      await window_bootstrap.prepareOsdWindow(
        args: args,
        handler: osdController.handle,
      );
      return;
    }

    await windowManager.ensureInitialized();

    //  Hide the default title bar and make window frameless
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false, // hides native min/max/close
    );

    FlutterSingleInstance.debugMode = false;
    if (!await FlutterSingleInstance().isFirstInstance()) {
      await FlutterSingleInstance().focus();
      exit(0);
    }

    FlutterSingleInstance.onFocus = (_) async {
      await window_bootstrap.showAndFocusMainWindow();
    };

    await window_bootstrap.setupDesktopWindowAndTray();
    await window_bootstrap.configureDesktopWindow();
    // Removed the duplicate call to configureDesktopWindow() inside post-frame callback
    // to avoid resetting window size and layout immediately after app launch.
  }
  runApp(TranslationProvider(child: DriverHubApp(scope: _createDeviceScope())));
}

DeviceScope _createDeviceScope() => DeviceScope(
  runtime: LiveDeviceRuntime(),
  macroRepository: PersistentMacroRepository(),
  appSettingsRepository: SharedPreferencesAppSettingsRepository(),
);

bool get _isDesktop {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
      return true;
    default:
      return false;
  }
}

bool get _isWindows =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

class DriverHubApp extends StatelessWidget {
  const DriverHubApp({super.key, required this.scope});

  final DeviceScope scope;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'driver_hub',
          themeMode: themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          locale: TranslationProvider.of(context).locale.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: MainShell(scope: scope),
        );
      },
    );
  }
}
