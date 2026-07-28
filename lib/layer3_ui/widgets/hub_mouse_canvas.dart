import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter/material.dart';

/// Center hub pane — large mouse image + catalog hotspot dots (skeleton).
///
/// L3 only. Independent dart. [hotspots] from L4 button pack (catalog x/y/r
/// normalized 0..1 on the image). Values are tunable in model JSON — not exact.
class HubMouseCanvas extends StatelessWidget {
  const HubMouseCanvas({
    super.key,
    required this.imageLarge,
    this.buttons = const [],
  });

  /// Catalog large asset path ([DiscoveredCardState.imageLarge]).
  final String imageLarge;

  /// Buttons with optional [ButtonData.hotspotX]/[hotspotY]/[hotspotR].
  final List<ButtonData> buttons;

  @override
  Widget build(BuildContext context) {
    // why: full-bleed large asset was too big; cap to half the pane
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth * 0.5;
        final maxH = constraints.maxHeight * 0.5;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxW,
              maxHeight: maxH,
            ),
            child: _MouseWithHotspots(
              imageLarge: imageLarge,
              buttons: buttons,
            ),
          ),
        );
      },
    );
  }
}

class _MouseWithHotspots extends StatelessWidget {
  const _MouseWithHotspots({
    required this.imageLarge,
    required this.buttons,
  });

  final String imageLarge;
  final List<ButtonData> buttons;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        // why: BoxFit.contain letterboxes; map 0..1 hotspot into the drawn image box
        return Image.asset(
          imageLarge,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Text('Mouse image missing'),
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            return Stack(
              alignment: Alignment.center,
              children: [
                child,
                // why: overlay only after we have a laid-out size
                if (w.isFinite && h.isFinite && w > 0 && h > 0)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _HotspotPainter(
                        buttons: buttons,
                        // approximate contain box: image aspect unknown until
                        // decode; use full constraint box (good enough skeleton)
                        width: w,
                        height: h,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Dots at catalog hotspot centers (white circle, like product callouts).
class _HotspotPainter extends CustomPainter {
  _HotspotPainter({
    required this.buttons,
    required this.width,
    required this.height,
  });

  final List<ButtonData> buttons;
  final double width;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = Colors.white;
    final stroke = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final b in buttons) {
      // why: catalog remappable:false → no canvas marker (hide that button only)
      if (!b.remappable) continue;
      final x = b.hotspotX;
      final y = b.hotspotY;
      final rNorm = b.hotspotR;
      if (x == null || y == null) continue;
      // why: r as fraction of min side; floor so tiny r still visible
      final r = ((rNorm ?? 0.04) * (size.shortestSide)).clamp(6.0, 24.0);
      final c = Offset(x * size.width, y * size.height);
      canvas.drawCircle(c, r, fill);
      canvas.drawCircle(c, r, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _HotspotPainter oldDelegate) {
    return oldDelegate.buttons != buttons ||
        oldDelegate.width != width ||
        oldDelegate.height != height;
  }
}
