import 'dart:async';
import 'dart:io';
import 'package:driver_hub/desktop_shell/window_bootstrap_stub.dart'
    if (dart.library.io) 'package:driver_hub/desktop_shell/window_bootstrap.dart'
    as window_bootstrap;
import 'package:driver_hub/layer3_ui/screens/devices_screen.dart';
import 'package:driver_hub/layer3_ui/widgets/osd_overlay_window.dart';
import 'package:driver_hub/layer1_discovery/device_runtime.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:driver_hub/layer6_transport/app_settings_storage.dart';
import 'package:driver_hub/layer6_transport/macro_storage.dart';
import 'package:driver_hub/i18n/strings.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(window_bootstrap.configureDesktopWindow());
    });
  }
  runApp(
    TranslationProvider(
      child: DriverHubApp(scope: _createDeviceScope()),
    ),
  );
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
    return MaterialApp(
      title: 'driver_hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      locale: TranslationProvider.of(context).locale.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: DevicesScreen(scope: scope),
    );
  }
}
