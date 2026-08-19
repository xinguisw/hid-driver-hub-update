import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/i18n/strings.g.dart';
import 'package:flutter/material.dart';

/// Center hub pane — large mouse image + hotspot callouts (skeleton).
///
/// L3 only. Dot = placement; line + label = callout.
/// Tap remappable callout **label** only → [onButtonSelected] (not the dot).
class HubMouseCanvas extends StatefulWidget {
  const HubMouseCanvas({
    super.key,
    required this.imageLarge,
    this.buttons = const [],
    this.selectedButtonId,
    this.isDirty = false,
    this.committing = false,
    this.onButtonSelected,
    this.onBackgroundTap,
    this.onResetToDefault,
    this.onSave,
    this.onCancel,
  });

  final String imageLarge;
  final List<ButtonData> buttons;

  /// Currently selected callout (label tap); orange highlight.
  final int? selectedButtonId;

  /// SDRD FR-OPS: staging dirty → enable Save/Cancel (always laid out).
  final bool isDirty;

  /// True while L4 Save is in flight (disable actions).
  final bool committing;

  /// Button Mapping: label tap opens mapping panel; dots are placement only.
  final ValueChanged<int>? onButtonSelected;

  /// Called when user taps the empty canvas background (outside any callout/dot).
  final VoidCallback? onBackgroundTap;

  /// After user Confirms reset tip dialog → L3 dispatches BLoC event only.
  final VoidCallback? onResetToDefault;

  /// FR-OPS-003 explicit Save (dispatch only).
  final VoidCallback? onSave;

  /// FR-OPS-004 Cancel / discard staging (dispatch only).
  final VoidCallback? onCancel;

  @override
  State<HubMouseCanvas> createState() => _HubMouseCanvasState();
}
//Make the button hover

class _HubMouseCanvasState extends State<HubMouseCanvas> {
  int? _hoveredButtonId;

  @override
  Widget build(BuildContext context) {
    // why: Extract Theme.of(context) tokens to ensure buttons and painter adapt to Light/Dark mode
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final paneW = constraints.maxWidth;
        final paneH = constraints.maxHeight;
        if (!paneW.isFinite || !paneH.isFinite || paneW <= 0 || paneH <= 0) {
          return const SizedBox.shrink();
        }

        // why: fixed band so mouse never jumps; Save/Cancel hide when clean (ref)
        const actionBand = 88.0;
        final drawH = (paneH - actionBand).clamp(1.0, paneH);
        // Ensure side margins (left & right) preserve at least 115px each so text boxes & stem lines fit cleanly
        final maxAllowedW = (paneW - 230.0).clamp(120.0, paneW * 0.5);
        final imgMaxW = maxAllowedW;
        final imgMaxH = drawH * 0.55;

        // Calculate exact fitted Rect preserving image aspect ratio (765/750 = 1.02)
        // so hotspot coordinates (x, y) NEVER drift when window is resized/minimized
        const double aspect = 765.0 / 750.0;
        late final double actualW;
        late final double actualH;
        if (imgMaxW / imgMaxH > aspect) {
          actualH = imgMaxH;
          actualW = imgMaxH * aspect;
        } else {
          actualW = imgMaxW;
          actualH = imgMaxW / aspect;
        }

        final imageRect = Rect.fromLTWH(
          (paneW - actualW) / 2,
          (drawH - actualH) / 2,
          actualW,
          actualH,
        );
        final paneSize = Size(paneW, drawH);
        final targets = _CalloutLayout.build(
          widget.buttons,
          imageRect,
          paneSize,
        );

        return Column(
          children: [
            // -----------------------------------------------------------------
            // 1. MOUSE CANVAS AREA
            // -----------------------------------------------------------------
            Expanded(
              child: MouseRegion(
                cursor: _hoveredButtonId != null
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                onHover: (event) {
                  final id = _hitButtonId(targets, event.localPosition);
                  if (id != _hoveredButtonId) {
                    setState(() => _hoveredButtonId = id);
                  }
                },
                onExit: (_) {
                  if (_hoveredButtonId != null) {
                    setState(() => _hoveredButtonId = null);
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final id = _hitButtonId(targets, details.localPosition);
                    if (id != null) {
                      widget.onButtonSelected?.call(id);
                    } else {
                      widget.onBackgroundTap?.call();
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fromRect(
                        rect: imageRect,
                        child: Image.asset(
                          widget.imageLarge,
                          fit: BoxFit.fill,
                          errorBuilder: (_, _, _) => Image.asset(
                            'assets/images/m7xse/large.png',
                            fit: BoxFit.fill,
                            errorBuilder: (_, _, _) =>
                                Text(t.mouseCanvas.imageMissing),
                          ),
                        ),
                      ),
                      CustomPaint(
                        size: paneSize,
                        painter: _HotspotPainter(
                          targets: targets,
                          selectedButtonId: widget.selectedButtonId,
                          hoveredButtonId: _hoveredButtonId,
                          isDark: isDark,
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // 2. BOTTOM ACTIONS BAR
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // RESET TO DEFAULT (ALWAYS VISIBLE)
                  OutlinedButton(
                    onPressed: widget.onResetToDefault,
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(t.common.resetToDefault),
                  ),

                  // SAVE & CANCEL (VISIBLE ONLY WHEN A BUTTON IS SELECTED)
                  if (widget.selectedButtonId != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton(
                          onPressed: widget.onSave,
                          style: FilledButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                          ),
                          child: Text(t.common.save),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => widget.onBackgroundTap?.call(),
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                          ),
                          child: Text(t.common.cancel),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static int? _hitButtonId(List<_CalloutTarget> targets, Offset local) {
    for (final t in targets.reversed) {
      if (t.contains(local)) return t.id;
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
    required this.boxRect,
    required this.textOrigin,
    required this.labelSize,
  });

  final int id;
  final Offset center;
  final double radius;
  final Offset stemStart;
  final Offset stemEnd;
  final String label;
  final Rect boxRect;
  final Offset textOrigin;
  final Size labelSize;

  Rect get labelHit => boxRect.inflate(4);

  /// Performs hit testing to check if pointer touch/hover coordinate [local]
  /// falls inside the dot circle, text label box, or leader stem line.
  bool contains(Offset local) {
    // Dot circle hit test (minimum 16px radius touch target)
    final minRadius = radius < 16.0 ? 16.0 : radius;
    if ((local - center).distance <= minRadius) return true;

    // Label box hit test
    if (labelHit.contains(local)) return true;

    // Stem line hit test
    if (_distanceToSegment(local, stemStart, stemEnd) <= 8.0) return true;

    return false;
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final l2 = (b - a).distanceSquared;
    if (l2 == 0) return (p - a).distance;
    var t =
        ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2;
    t = t.clamp(0.0, 1.0);
    final projection = Offset(
      a.dx + t * (b.dx - a.dx),
      a.dy + t * (b.dy - a.dy),
    );
    return (p - projection).distance;
  }
}

enum _StemKind { horizontalLeft, horizontalRight, vertical }

class _CalloutLayout {
  // why: leader length in px — edit here
  static const double stemLength = 40.0;

  static const labelStyle = TextStyle(
    color: Colors.black87,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const selectedLabelStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const hoveredLabelStyle = TextStyle(
    color: Color(0xFFE65100),
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static List<_CalloutTarget> build(
    List<ButtonData> buttons,
    Rect imageRect,
    Size paneSize,
  ) {
    final sideMargin = (paneSize.width - imageRect.width) / 2;
    final effectiveStemLength = (sideMargin * 0.25).clamp(16.0, stemLength);

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

      const boxPadding = EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0);
      final boxWidth = tp.width + boxPadding.horizontal;
      final boxHeight = tp.height + boxPadding.vertical;

      late final Offset stemStart;
      late final Offset stemEnd;
      late final Rect boxRect;
      late final Offset textOrigin;

      // why: 1 left←, 2 right→, 4/5 side←, 6 right→ horizontal; 3 middle vertical
      switch (_stemKind(b.id)) {
        case _StemKind.horizontalLeft:
          stemStart = Offset(c.dx - r, c.dy);
          stemEnd = Offset(c.dx - r - effectiveStemLength, c.dy);
          final boxLeft = (stemEnd.dx - boxWidth).clamp(
            0.0,
            _max(0.0, paneSize.width - boxWidth),
          );
          final boxTop = (c.dy - boxHeight / 2).clamp(
            0.0,
            _max(0.0, paneSize.height - boxHeight),
          );
          boxRect = Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight);
          textOrigin = Offset(
            boxLeft + boxPadding.left,
            boxTop + boxPadding.top,
          );

        case _StemKind.horizontalRight:
          stemStart = Offset(c.dx + r, c.dy);
          stemEnd = Offset(c.dx + r + effectiveStemLength, c.dy);
          final boxLeft = (stemEnd.dx).clamp(
            0.0,
            _max(0.0, paneSize.width - boxWidth),
          );
          final boxTop = (c.dy - boxHeight / 2).clamp(
            0.0,
            _max(0.0, paneSize.height - boxHeight),
          );
          boxRect = Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight);
          textOrigin = Offset(
            boxLeft + boxPadding.left,
            boxTop + boxPadding.top,
          );

        case _StemKind.vertical:
          stemStart = Offset(c.dx, c.dy - r);
          // Extend stem past the top edge of mouse image so label floats cleanly above
          final topEdgeLimit = imageRect.top - 10.0;
          final calculatedEnd = c.dy - r - effectiveStemLength;
          stemEnd = Offset(
            c.dx,
            calculatedEnd < topEdgeLimit ? calculatedEnd : topEdgeLimit,
          );
          final boxLeft = (stemEnd.dx - boxWidth / 2).clamp(
            0.0,
            _max(0.0, paneSize.width - boxWidth),
          );
          final boxTop = (stemEnd.dy - boxHeight).clamp(
            0.0,
            _max(0.0, paneSize.height - boxHeight),
          );
          boxRect = Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight);
          textOrigin = Offset(
            boxLeft + boxPadding.left,
            boxTop + boxPadding.top,
          );
      }

      out.add(
        _CalloutTarget(
          id: b.id,
          center: c,
          radius: r,
          stemStart: stemStart,
          stemEnd: stemEnd,
          label: label,
          boxRect: boxRect,
          textOrigin: textOrigin,
          labelSize: tp.size,
        ),
      );
    }
    return out;
  }

  static _StemKind _stemKind(int id) {
    switch (id) {
      case 1: // left
      case 4: // forward
      case 5: // backward
        return _StemKind.horizontalLeft;
      case 2: // right
      case 6: // dpi cycle
        return _StemKind.horizontalRight;
      default: // middle click
        return _StemKind.vertical;
    }
  }

  static double _max(double a, double b) => a > b ? a : b;
}

class _HotspotPainter extends CustomPainter {
  _HotspotPainter({
    required this.targets,
    this.selectedButtonId,
    this.hoveredButtonId,
    required this.isDark,
    required this.theme,
  });

  final List<_CalloutTarget> targets;
  final int? selectedButtonId;
  final int? hoveredButtonId;
  final bool isDark;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    for (final t in targets) {
      final isSelected = t.id == selectedButtonId;
      final isHovered = t.id == hoveredButtonId;

      final Color accent;
      final Color dotFillColor;
      final Color boxFillColor;
      final Color boxBorderColor;
      final TextStyle textStyle;

      if (isSelected) {
        accent = Colors.orange;
        dotFillColor = Colors.orange;
        boxFillColor = Colors.orange;
        boxBorderColor = Colors.deepOrange;
        textStyle = _CalloutLayout.selectedLabelStyle;
      } else if (isHovered) {
        accent = Colors.orange;
        dotFillColor = Colors.orange.withValues(alpha: 0.35);
        boxFillColor = isDark
            ? const Color(0xFF3E2723)
            : const Color(0xFFFFF3E0);
        boxBorderColor = Colors.orange;
        textStyle = isDark
            ? _CalloutLayout.selectedLabelStyle
            : _CalloutLayout.hoveredLabelStyle;
      } else {
        // why: Unselected callout pins and label boxes adapt to Dark/Light mode theme
        accent = isDark ? theme.colorScheme.onSurface : Colors.black87;
        dotFillColor = isDark ? theme.cardColor : Colors.white;
        boxFillColor = isDark ? theme.cardColor : Colors.white;
        boxBorderColor = isDark
            ? theme.colorScheme.outline
            : const Color(0xFFD6D6D6);
        textStyle = isDark
            ? TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              )
            : _CalloutLayout.labelStyle;
      }

      final dotFill = Paint()..color = dotFillColor;
      final dotStroke = Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : (isHovered ? 2.0 : 1.5);
      final linePaint = Paint()
        ..color = accent
        ..strokeWidth = isSelected ? 2.0 : (isHovered ? 2.0 : 1.5)
        ..style = PaintingStyle.stroke;

      final effectiveRadius = (isSelected || isHovered)
          ? t.radius + 1.5
          : t.radius;

      // 1. Draw dot circle on mouse button
      canvas.drawCircle(t.center, effectiveRadius, dotFill);
      canvas.drawCircle(t.center, effectiveRadius, dotStroke);

      // 2. Draw stem line pointer
      canvas.drawLine(t.stemStart, t.stemEnd, linePaint);

      // 3. Draw text container box with rounded corners and shadow
      final rrect = RRect.fromRectAndRadius(
        t.boxRect,
        const Radius.circular(6.0),
      );

      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: isSelected ? 0.2 : 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawRRect(rrect.shift(const Offset(0, 1.5)), shadowPaint);

      final boxFill = Paint()..color = boxFillColor;
      final boxBorder = Paint()
        ..color = boxBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : (isHovered ? 1.8 : 1.2);

      canvas.drawRRect(rrect, boxFill);
      canvas.drawRRect(rrect, boxBorder);

      // 4. Paint text inside container box
      final tp = TextPainter(
        text: TextSpan(text: t.label, style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: t.labelSize.width + 1);
      tp.paint(canvas, t.textOrigin);
    }
  }

  @override
  bool shouldRepaint(covariant _HotspotPainter oldDelegate) {
    return oldDelegate.targets != targets ||
        oldDelegate.selectedButtonId != selectedButtonId ||
        oldDelegate.hoveredButtonId != hoveredButtonId ||
        oldDelegate.isDark != isDark ||
        oldDelegate.theme != theme;
  }
}
