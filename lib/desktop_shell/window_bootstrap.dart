import 'package:nativeapi/nativeapi.dart';

/// Default and minimum outer window size (logical px).
const double kDesktopWindowWidth = 1256;
const double kDesktopWindowHeight = 753;

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
