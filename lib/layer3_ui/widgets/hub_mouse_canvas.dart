import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter/material.dart';

/// Center hub pane — large mouse image + hotspot callouts (skeleton).
///
/// L3 only. Dot = placement; line + label = callout.
/// Left/right/middle: vertical stem. Forward/back: horizontal stem.
///
/// **Line length:** change [_HotspotPainter.stemLength] (px). It is applied
/// in full; callouts paint on the full pane so stems are not clipped away.
class HubMouseCanvas extends StatelessWidget {
  const HubMouseCanvas({
    super.key,
    required this.imageLarge,
    this.buttons = const [],
  });

  final String imageLarge;
  final List<ButtonData> buttons;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final paneW = constraints.maxWidth;
        final paneH = constraints.maxHeight;
        if (!paneW.isFinite || !paneH.isFinite || paneW <= 0 || paneH <= 0) {
          return const SizedBox.shrink();
        }

        // why: mouse art ~half pane; leftover margin is for stems + labels
        final imgMaxW = paneW * 0.5;
        final imgMaxH = paneH * 0.5;
        final imgLeft = (paneW - imgMaxW) / 2;
        final imgTop = (paneH - imgMaxH) / 2;
        final imageRect = Rect.fromLTWH(imgLeft, imgTop, imgMaxW, imgMaxH);

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fromRect(
              rect: imageRect,
              child: Image.asset(
                imageLarge,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Text('Mouse image missing'),
              ),
            ),
            // why: full-pane paint so stemLength is not eaten by image-only bounds
            CustomPaint(
              size: Size(paneW, paneH),
              painter: _HotspotPainter(
                buttons: buttons,
                imageRect: imageRect,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HotspotPainter extends CustomPainter {
  _HotspotPainter({
    required this.buttons,
    required this.imageRect,
  });

  final List<ButtonData> buttons;

  /// Drawn image box (hotspot 0..1 maps into this rect).
  final Rect imageRect;

  /// change stem or line length here *px 
  static const double stemLength = 30.0;

  static const _labelStyle = TextStyle(
    color: Colors.black,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = Colors.white;
    final stroke = Paint()
      ..color = Colors.black87 // color of the stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final linePaint = Paint()
      ..color = Colors.black87 // color of the line
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final b in buttons) {
      if (!b.remappable) continue;
      final x = b.hotspotX;
      final y = b.hotspotY;
      final rNorm = b.hotspotR;
      if (x == null || y == null) continue;

      // why: 0..1 hotspot is on the mouse image box, not the full pane
      final c = Offset(
        imageRect.left + x * imageRect.width,
        imageRect.top + y * imageRect.height,
      );
      final r = ((rNorm ?? 0.04) * imageRect.shortestSide).clamp(6.0, 24.0);

      canvas.drawCircle(c, r, fill);
      canvas.drawCircle(c, r, stroke);

      // why: live GET mapping first; physical name only if action unknown
      final label = b.actionLabel ?? b.buttonLabel ?? 'B${b.id}';
      final tp = TextPainter(
        text: TextSpan(text: label, style: _labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: size.width * 0.4);

      if (_useVerticalStem(b.id)) {
        _paintVerticalCallout(canvas, c, r, tp, linePaint, size, b.id);
      } else {
        _paintHorizontalCallout(canvas, c, r, tp, linePaint, size);
      }
    }
  }

  // why: ids 4/5 = side buttons → horizontal; L/R/M (and others) vertical
  bool _useVerticalStem(int id) {
    switch (id) {
      case 4:
      case 5:
        return false;
      default:
        return true;
    }
  }

  void _paintVerticalCallout(
    Canvas canvas,
    Offset c,
    double r,
    TextPainter tp,
    Paint linePaint,
    Size size,
    int id,
  ) {
    // why: full stemLength — do not clamp tip back onto the dot
    final tip = Offset(c.dx, c.dy - r - stemLength);
    canvas.drawLine(Offset(c.dx, c.dy - r), tip, linePaint);

    var labelX = tip.dx - tp.width / 2;
    if (id == 1) {
      labelX = tip.dx - tp.width;
    } else if (id == 2) {
      labelX = tip.dx;
    }
    labelX = labelX.clamp(0.0, mathMax(0.0, size.width - tp.width));
    final labelY =
        (tip.dy - tp.height - 4).clamp(0.0, mathMax(0.0, size.height - tp.height));
    tp.paint(canvas, Offset(labelX, labelY));
  }

  void _paintHorizontalCallout(
    Canvas canvas,
    Offset c,
    double r,
    TextPainter tp,
    Paint linePaint,
    Size size,
  ) {
    final tip = Offset(c.dx - r - stemLength, c.dy);
    canvas.drawLine(Offset(c.dx - r, c.dy), tip, linePaint);

    final labelX =
        (tip.dx - tp.width - 4).clamp(0.0, mathMax(0.0, size.width - tp.width));
    final labelY =
        (c.dy - tp.height / 2).clamp(0.0, mathMax(0.0, size.height - tp.height));
    tp.paint(canvas, Offset(labelX, labelY));
  }

  static double mathMax(double a, double b) => a > b ? a : b;

  @override
  bool shouldRepaint(covariant _HotspotPainter oldDelegate) {
    return oldDelegate.buttons != buttons || oldDelegate.imageRect != imageRect;
  }
}
