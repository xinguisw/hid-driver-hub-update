import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter/material.dart';

/// Center hub pane — large mouse image + hotspot callouts (skeleton).
///
/// L3 only. Dot = placement; line + label = callout.
/// Tap remappable callout **label** only → [onButtonSelected] (not the dot).
class HubMouseCanvas extends StatelessWidget {
  const HubMouseCanvas({
    super.key,
    required this.imageLarge,
    this.buttons = const [],
    this.onButtonSelected,
    this.onResetToDefault,
  });

  final String imageLarge;
  final List<ButtonData> buttons;

  /// Button Mapping: label tap opens mapping panel; dots are placement only.
  final ValueChanged<int>? onButtonSelected;

  /// After user Confirms reset tip dialog; L4 wire later (no SET in this step).
  final VoidCallback? onResetToDefault;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final paneW = constraints.maxWidth;
        final paneH = constraints.maxHeight;
        if (!paneW.isFinite || !paneH.isFinite || paneW <= 0 || paneH <= 0) {
          return const SizedBox.shrink();
        }

        // why: leave band under art for Reset to Default (ref)
        const resetBand = 56.0;
        final drawH = (paneH - resetBand).clamp(1.0, paneH);
        final imgMaxW = paneW * 0.5;
        final imgMaxH = drawH * 0.55;
        final imageRect = Rect.fromLTWH(
          (paneW - imgMaxW) / 2,
          (drawH - imgMaxH) / 2,
          imgMaxW,
          imgMaxH,
        );
        final paneSize = Size(paneW, drawH);
        final targets = _CalloutLayout.build(buttons, imageRect, paneSize);

        return Column(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final id = _hitButtonId(targets, details.localPosition);
                  if (id != null) onButtonSelected?.call(id);
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fromRect(
                      rect: imageRect,
                      child: Image.asset(
                        imageLarge,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const Text('Mouse image missing'),
                      ),
                    ),
                    CustomPaint(
                      size: paneSize,
                      painter: _HotspotPainter(targets: targets),
                    ),
                  ],
                ),
              ),
            ),
            // why: below mouse — confirm tip first; not the action-catalog flow
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: OutlinedButton(
                onPressed: () => _onResetPressed(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black54),
                ),
                child: const Text('Reset to Default'),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Skeleton tip: restore default keys — Cancel / Confirm only.
  Future<void> _onResetPressed(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tip'),
        content: const Text('Are you sure you want to restore default keys?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) onResetToDefault?.call();
  }

  static int? _hitButtonId(List<_CalloutTarget> targets, Offset local) {
    // why: label only — dot is placement, does not open mapping panel
    for (final t in targets.reversed) {
      if (t.labelHit.contains(local)) return t.id;
    }
    return null;
  }
}

class _CalloutTarget {
  _CalloutTarget({
    required this.id,
    required this.center,
    required this.radius,
    required this.stemStart,
    required this.stemEnd,
    required this.label,
    required this.labelOrigin,
    required this.labelSize,
  });

  final int id;
  final Offset center;
  final double radius;
  final Offset stemStart;
  final Offset stemEnd;
  final String label;
  final Offset labelOrigin;
  final Size labelSize;

  Rect get labelHit => (labelOrigin & labelSize).inflate(4);
}

class _CalloutLayout {
  // why: leader length in px — edit here
  static const double stemLength = 30.0;

  static const labelStyle = TextStyle(
    color: Colors.black,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static List<_CalloutTarget> build(
    List<ButtonData> buttons,
    Rect imageRect,
    Size paneSize,
  ) {
    final out = <_CalloutTarget>[];
    for (final b in buttons) {
      if (!b.remappable) continue;
      final x = b.hotspotX;
      final y = b.hotspotY;
      final rNorm = b.hotspotR;
      if (x == null || y == null) continue;

      final c = Offset(
        imageRect.left + x * imageRect.width,
        imageRect.top + y * imageRect.height,
      );
      final r = ((rNorm ?? 0.04) * imageRect.shortestSide).clamp(6.0, 24.0);

      final label = b.actionLabel ?? b.buttonLabel ?? 'B${b.id}';
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: paneSize.width * 0.4);

      late final Offset stemStart;
      late final Offset stemEnd;
      late final Offset labelOrigin;

      if (_useVerticalStem(b.id)) {
        stemStart = Offset(c.dx, c.dy - r);
        stemEnd = Offset(c.dx, c.dy - r - stemLength);
        var labelX = stemEnd.dx - tp.width / 2;
        if (b.id == 1) {
          labelX = stemEnd.dx - tp.width;
        } else if (b.id == 2) {
          labelX = stemEnd.dx;
        }
        labelX = labelX.clamp(0.0, _max(0.0, paneSize.width - tp.width));
        final labelY = (stemEnd.dy - tp.height - 4)
            .clamp(0.0, _max(0.0, paneSize.height - tp.height));
        labelOrigin = Offset(labelX, labelY);
      } else {
        stemStart = Offset(c.dx - r, c.dy);
        stemEnd = Offset(c.dx - r - stemLength, c.dy);
        final labelX = (stemEnd.dx - tp.width - 4)
            .clamp(0.0, _max(0.0, paneSize.width - tp.width));
        final labelY = (c.dy - tp.height / 2)
            .clamp(0.0, _max(0.0, paneSize.height - tp.height));
        labelOrigin = Offset(labelX, labelY);
      }

      out.add(
        _CalloutTarget(
          id: b.id,
          center: c,
          radius: r,
          stemStart: stemStart,
          stemEnd: stemEnd,
          label: label,
          labelOrigin: labelOrigin,
          labelSize: tp.size,
        ),
      );
    }
    return out;
  }

  static bool _useVerticalStem(int id) {
    switch (id) {
      case 4:
      case 5:
        return false;
      default:
        return true;
    }
  }

  static double _max(double a, double b) => a > b ? a : b;
}

class _HotspotPainter extends CustomPainter {
  _HotspotPainter({required this.targets});

  final List<_CalloutTarget> targets;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = Colors.white;
    final stroke = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final linePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final t in targets) {
      canvas.drawCircle(t.center, t.radius, fill);
      canvas.drawCircle(t.center, t.radius, stroke);
      canvas.drawLine(t.stemStart, t.stemEnd, linePaint);

      final tp = TextPainter(
        text: TextSpan(text: t.label, style: _CalloutLayout.labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: t.labelSize.width + 1);
      tp.paint(canvas, t.labelOrigin);
    }
  }

  @override
  bool shouldRepaint(covariant _HotspotPainter oldDelegate) {
    return oldDelegate.targets != targets;
  }
}
