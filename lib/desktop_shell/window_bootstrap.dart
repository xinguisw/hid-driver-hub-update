import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Default outer window size (logical px).
const double kDesktopWindowWidth = 1256;
const double kDesktopWindowHeight = 753;

/// Minimum window dimensions to ensure layout usability while allowing resize.
const double kMinDesktopWindowWidth = 1024;
const double kMinDesktopWindowHeight = 614;

/// Unhide, restore if minimized, and bring the main window to the foreground.
Future<void> showAndFocusMainWindow() async {
  if (await windowManager.isMinimized()) {
    await windowManager.restore();
  }
  await windowManager.show();
  await windowManager.focus();
}

/// Helper class to manage window close-to-tray and system tray interactions.
class AppWindowAndTrayListener with WindowListener, TrayListener {
  static final AppWindowAndTrayListener _instance =
      AppWindowAndTrayListener._internal();
  factory AppWindowAndTrayListener() => _instance;
  AppWindowAndTrayListener._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    windowManager.addListener(this);
    await windowManager.setPreventClose(true);

    // Windows native runner (flutter_window.cpp) manages the system tray icon,
    // single-click restore, and context menu directly via Win32 APIs.
    // For macOS/Linux, configure tray_manager.
    if (!Platform.isWindows) {
      trayManager.addListener(this);
      try {
        await trayManager.setIcon('assets/images/m7x_small.png');
        await trayManager.setToolTip('HID Driver Hub');
        final Menu menu = Menu(
          items: [
            MenuItem(
              key: 'show_window',
              label: 'Open HID Driver Hub',
            ),
            MenuItem.separator(),
            MenuItem(
              key: 'exit_app',
              label: 'Exit',
            ),
          ],
        );
        await trayManager.setContextMenu(menu);
      } catch (e) {
        debugPrint('[TrayManager] Init failed: $e');
      }
    }
  }

  @override
  void onWindowClose() async {
    final bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    } else {
      await windowManager.destroy();
    }
  }

  @override
  void onTrayIconMouseDown() async {
    await showAndFocusMainWindow();
  }

  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show_window') {
      await showAndFocusMainWindow();
    } else if (menuItem.key == 'exit_app') {
      await windowManager.setPreventClose(false);
      await windowManager.destroy();
      exit(0);
    }
  }
}

/// Sets up background-run-on-close and system tray listener.
Future<void> setupDesktopWindowAndTray() async {
  await AppWindowAndTrayListener().init();
}

/// Apply default + minimum size and center on the current desktop window.
Future<void> configureDesktopWindow() async {
  // Set minimum size to a smaller resolution (1024x614) so that the OS allows the window
  // to be resized down or up, rather than locking it to a static size.
  await windowManager.setMinimumSize(
    const Size(kMinDesktopWindowWidth, kMinDesktopWindowHeight),
  );
  await windowManager.setSize(
    const Size(kDesktopWindowWidth, kDesktopWindowHeight),
  );
  await windowManager.center();
}

