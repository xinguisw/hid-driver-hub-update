import 'package:flutter/services.dart';

/// Web / non-desktop stub — browser and mobile have no OS window min size.

void configureDesktopWindow() {}

bool isOsdWindow(List<String> args) => false;

Future<bool> prepareOsdWindow({
  required Future<dynamic> Function(MethodCall call) handler,
  required List<String> args,
}) async {
  return false;
}

Future<void> showOsdWindow() async {}

Future<void> hideOsdWindow() async {}
