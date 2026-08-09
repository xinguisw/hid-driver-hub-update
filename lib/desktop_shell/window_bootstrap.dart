import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
import 'package:nativeapi/nativeapi.dart';

/// Default and minimum outer window size (logical px).
const double kDesktopWindowWidth = 1256;
const double kDesktopWindowHeight = 753;

const _osdWindowArgument = 'driver_hub.osd';

WindowController? _osdController;

bool isOsdWindow(List<String> args) {
  return args.length >= 3 &&
      args[0] == 'multi_window' &&
      args[2] == _osdWindowArgument;
}

/// Registers the OSD handler after the child engine has reached its first frame.
Future<bool> prepareOsdWindow({
  required Future<dynamic> Function(MethodCall call) handler,
  required List<String> args,
}) async {
  if (!isOsdWindow(args)) return false;

  // why: the native callback registers child plugins after the child engine
  // starts, so current-engine discovery is not safe during Dart startup.
  final controller = WindowController.fromWindowId(args[1]);
  _osdController = controller;
  await controller.setWindowMethodHandler(handler);
  return true;
}

Future<void> showOsdWindow() async {
  await _osdController?.show();
}

Future<void> hideOsdWindow() async {
  await _osdController?.hide();
}

/// Apply default + minimum size and center on the current desktop window.
///
/// No-op if the native window handle is not ready yet.
void configureDesktopWindow() {
  final window = WindowManager.instance.getCurrent();
  if (window == null) return;
  window.setMinimumSize(kDesktopWindowWidth, kDesktopWindowHeight);
  window.setSize(kDesktopWindowWidth, kDesktopWindowHeight);
  // why: size first, then center — center uses the final outer bounds.
  window.center();
}
