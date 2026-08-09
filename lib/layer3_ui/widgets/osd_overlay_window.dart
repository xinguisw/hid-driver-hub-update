import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const osdToastDuration = Duration(seconds: 3);

/// Presentation data received by the dedicated desktop OSD window.
class OsdOverlayMessage {
  final String title;
  final List<String> lines;

  const OsdOverlayMessage({required this.title, required this.lines});

  factory OsdOverlayMessage.fromArguments(Object? arguments) {
    if (arguments is! Map) {
      throw const FormatException('OSD message arguments must be a map');
    }
    final title = arguments['title'];
    final lines = arguments['lines'];
    if (title is! String || lines is! List) {
      throw const FormatException('OSD message is missing title or lines');
    }
    final textLines = lines.whereType<String>().toList(growable: false);
    if (textLines.isEmpty) {
      throw const FormatException('OSD message must contain a line');
    }
    return OsdOverlayMessage(title: title, lines: textLines);
  }
}

/// Controller for the Flutter content hosted by the secondary OSD window.
///
/// Native window operations stay behind the desktop-shell callbacks. This
/// controller owns only presentation state and the three-second lifetime.
class OsdOverlayWindowController {
  OsdOverlayWindowController({
    required this._showWindow,
    required this._hideWindow,
  });

  final Future<void> Function() _showWindow;
  final Future<void> Function() _hideWindow;
  final message = ValueNotifier<OsdOverlayMessage?>(null);
  Timer? _hideTimer;

  Future<dynamic> handle(MethodCall call) async {
    if (call.method != 'osd_show') {
      throw MissingPluginException('Unsupported OSD method: ${call.method}');
    }

    final next = OsdOverlayMessage.fromArguments(call.arguments);
    _hideTimer?.cancel();
    message.value = next;
    await _showWindow();
    _hideTimer = Timer(osdToastDuration, () {
      message.value = null;
      unawaited(_hideWindow());
    });
    return null;
  }

  void dispose() {
    _hideTimer?.cancel();
    _hideTimer = null;
    message.dispose();
    unawaited(_hideWindow());
  }
}

/// Text-only OSD skeleton matching the approved compact desktop design.
class OsdOverlayApp extends StatelessWidget {
  const OsdOverlayApp({required this.controller, super.key});

  final OsdOverlayWindowController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: ValueListenableBuilder<OsdOverlayMessage?>(
          valueListenable: controller.message,
          builder: (context, value, _) {
            if (value == null) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: const Color(0xFF202020),
                border: Border.all(color: const Color(0xFF9A3DFF), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 7),
                  for (final line in value.lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        line,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.1,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
