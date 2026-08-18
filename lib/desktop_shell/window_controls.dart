import 'package:window_manager/window_manager.dart';

/// Native desktop implementation of window controls.
///
/// Uses [window_manager] to manipulate the OS window. Only compiled on
/// dart.library.io platforms (Windows, Linux, macOS).

Future<void> startDragging() => windowManager.startDragging();

Future<void> minimizeWindow() => windowManager.minimize();

Future<void> toggleMaximizeWindow() async {
  if (await windowManager.isMaximized()) {
    await windowManager.unmaximize();
  } else {
    await windowManager.maximize();
  }
}

Future<void> closeWindow() => windowManager.close();
