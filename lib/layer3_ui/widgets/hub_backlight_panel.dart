import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Backlight Setting page — RGB backlight controls.
///
/// L3 only. Dispatches events to BLoC.
/// Structure: one container per section, left-aligned (same pattern as
/// Parameter / Performance panels).
class HubBacklightPanel extends StatelessWidget {
  const HubBacklightPanel({
    super.key,
    this.rgbModes,
    this.rgbEnable,
    this.rgbModeId,
    this.rgbBrightnessLevels,
    this.rgbBrightness,
    this.rgbSpeedLevels,
    this.rgbSpeed,
    this.rgbR,
    this.rgbG,
    this.rgbB,
    this.rgbSleepTime,
    this.rgbSleepOptions,
    this.onEnableChanged,
    this.onModeChanged,
    this.onColorChanged,
    this.onBrightnessChanged,
    this.onSpeedChanged,
    this.onSleepChanged,
  });

  final List<RgbMode>? rgbModes;
  final bool? rgbEnable;
  final int? rgbModeId;
  final int? rgbBrightnessLevels;
  final int? rgbBrightness;
  final int? rgbSpeedLevels;
  final int? rgbSpeed;
  final int? rgbR;
  final int? rgbG;
  final int? rgbB;

  /// Selected RGB power-saving index (into [rgbSleepOptions]).
  final int? rgbSleepTime;

  /// RGB power-saving options from the device capability schema
  /// (`RgbBacklightCapabilities.sleepTimeOptions`, seconds). Not hardcoded.
  final List<int>? rgbSleepOptions;
  final ValueChanged<bool>? onEnableChanged;
  final ValueChanged<int>? onModeChanged;
  final ValueChanged<Color>? onColorChanged;

  /// Emits the selected brightness level index `0 .. brightnessLevels-1`.
  final ValueChanged<int>? onBrightnessChanged;

  /// Emits the selected speed level index `0 .. speedLevels-1`.
  final ValueChanged<int>? onSpeedChanged;

  /// Emits the selected RGB power-saving index into [rgbSleepOptions].
  final ValueChanged<int>? onSleepChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BacklightToggleBox(
            enabled: rgbEnable ?? false,
            onChanged: onEnableChanged,
          ),
          const SizedBox(height: 8),
          _ModeBox(
            rgbModes: rgbModes ?? const [],
            rgbModeId: rgbModeId,
            onModeChanged: onModeChanged,
          ),
          const SizedBox(height: 8),
          _ColorBox(
            r: rgbR,
            g: rgbG,
            b: rgbB,
            onColorChanged: onColorChanged,
          ),
          const SizedBox(height: 8),
          _LevelBox(
            title: 'Brightness',
            levels: rgbBrightnessLevels ?? 0,
            selected: rgbBrightness,
            onChanged: onBrightnessChanged,
            // why: reference brightness table is 0/25/50/75/100% (L5 codec owns
            // the same table) — not the generic 0..100% percent-of-index.
            labels: const ['0%', '25%', '50%', '75%', '100%'],
          ),
          const SizedBox(height: 8),
          _LevelBox(
            title: 'Speed',
            levels: rgbSpeedLevels ?? 0,
            selected: rgbSpeed,
            onChanged: onSpeedChanged,
          ),
          const SizedBox(height: 8),
          // why: RGB power-saving is a chip row like brightness/speed (not a
          // dropdown) per request; options come from the capability schema.
          _LevelBox(
            title: 'Power saving',
            levels: rgbSleepOptions?.length ?? 0,
            selected: rgbSleepTime,
            onChanged: onSleepChanged,
            labels: [
              for (final s in rgbSleepOptions ?? const <int>[]) _sleepLabel(s),
            ],
          ),
        ],
      ),
    );
  }
}

/// Backlight on/off — own container: label left, toggle right.
class _BacklightToggleBox extends StatelessWidget {
  const _BacklightToggleBox({required this.enabled, this.onChanged});

  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('Backlight'),
          const Spacer(),
          Switch(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Mode — own container: label left, dropdown right.
class _ModeBox extends StatelessWidget {
  const _ModeBox({
    required this.rgbModes,
    required this.rgbModeId,
    this.onModeChanged,
  });

  final List<RgbMode> rgbModes;
  final int? rgbModeId;
  final ValueChanged<int>? onModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('Mode'),
          const Spacer(),
          DropdownButton<int>(
            value:
                rgbModeId != null && rgbModes.any((m) => m.id == rgbModeId)
                    ? rgbModeId
                    : null,
            hint: const Text('Select'),
            underline: const SizedBox.shrink(),
            items: [
              for (final mode in rgbModes)
                DropdownMenuItem<int>(
                  value: mode.id,
                  child: Text(mode.nameKey),
                ),
            ],
            onChanged: (value) {
              if (value != null) onModeChanged?.call(value);
            },
          ),
        ],
      ),
    );
  }
}

/// Color — own container: swatch + hex input on top, gradient SV picker and
/// hue bar below (matches the reference layout).
class _ColorBox extends StatefulWidget {
  const _ColorBox({
    this.r,
    this.g,
    this.b,
    this.onColorChanged,
  });

  final int? r;
  final int? g;
  final int? b;
  final ValueChanged<Color>? onColorChanged;

  @override
  State<_ColorBox> createState() => _ColorBoxState();
}

class _ColorBoxState extends State<_ColorBox> {
  late HSVColor _hsv;
  late TextEditingController _hexController;

  static Color _rgbToColor(int? r, int? g, int? b) => Color.fromARGB(
        255,
        (r ?? 0).clamp(0, 255),
        (g ?? 0).clamp(0, 255),
        (b ?? 0).clamp(0, 255),
      );

  static String _hexOf(Color c) =>
      '${(c.r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(c.g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(c.b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(_rgbToColor(widget.r, widget.g, widget.b));
    _hexController = TextEditingController(text: _hexOf(_hsv.toColor()));
  }

  @override
  void didUpdateWidget(_ColorBox old) {
    super.didUpdateWidget(old);
    if (old.r != widget.r || old.g != widget.g || old.b != widget.b) {
      _hsv = HSVColor.fromColor(_rgbToColor(widget.r, widget.g, widget.b));
      _hexController.text = _hexOf(_hsv.toColor());
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _apply(HSVColor next) {
    setState(() {
      _hsv = next;
      _hexController.text = _hexOf(next.toColor());
    });
    widget.onColorChanged?.call(next.toColor());
  }

  void _onSv(Offset local, double w, double h) {
    final s = (local.dx / w).clamp(0.0, 1.0);
    final v = 1.0 - (local.dy / h).clamp(0.0, 1.0);
    _apply(_hsv.withSaturation(s).withValue(v));
  }

  void _onHue(Offset local, double w) {
    final hue = (local.dx / w * 360).clamp(0.0, 359.999);
    _apply(_hsv.withHue(hue));
  }

  void _onHexSubmitted(String value) {
    final hex = value.replaceAll('#', '').trim();
    if (hex.length != 6) return;
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return;
    _apply(HSVColor.fromColor(Color(0xFF000000 | parsed)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _hsv.toColor();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Color'),
              const SizedBox(width: 16),
              Container(
                width: 32,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              const Text('Color code'),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _hexController,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                  ],
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    prefixText: '#',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  style:
                      const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  onSubmitted: _onHexSubmitted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Saturation/Value gradient picker
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              const h = 140.0;
              return GestureDetector(
                onPanDown: (d) => _onSv(d.localPosition, w, h),
                onPanUpdate: (d) => _onSv(d.localPosition, w, h),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: h,
                    width: w,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ColoredBox(
                            color: HSVColor.fromAHSV(1, _hsv.hue, 1, 1)
                                .toColor(),
                          ),
                        ),
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: (_hsv.saturation * w - 9).clamp(0.0, w - 18),
                          top: ((1 - _hsv.value) * h - 9).clamp(0.0, h - 18),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Hue bar
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              const h = 16.0;
              return GestureDetector(
                onPanDown: (d) => _onHue(d.localPosition, w),
                onPanUpdate: (d) => _onHue(d.localPosition, w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: h,
                    width: w,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  for (var i = 0; i <= 6; i++)
                                    HSVColor.fromAHSV(1, i * 60.0, 1, 1)
                                        .toColor(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left:
                              (_hsv.hue / 360 * w - 9).clamp(0.0, w - 18),
                          top: -1,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Brightness / Speed — own container: title top-left, equal-width level
/// buttons in a row (selected highlighted). Skeleton: inert.
class _LevelBox extends StatelessWidget {
  const _LevelBox({
    required this.title,
    required this.levels,
    required this.selected,
    this.onChanged,
    this.labels,
  });

  final String title;
  final int levels;
  final int? selected;

  /// Emits the tapped level index `0 .. levels-1`.
  final ValueChanged<int>? onChanged;

  /// Optional per-index labels (must match [levels] length). When null, the
  /// chip shows the percent of the index across the range (brightness/speed).
  final List<String>? labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pctDenom = levels > 1 ? (levels - 1) : 1;
    final useLabels = labels != null && labels!.length == levels;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < levels; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    onTap: onChanged == null ? null : () => onChanged!(i),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == selected
                            ? theme.colorScheme.secondaryContainer
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        useLabels
                            ? labels![i]
                            : '${(100 * i / pctDenom).round()}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Backlight power-saving timeout is now rendered as a chip row via
/// [_LevelBox] (see build), options sourced from the capability schema.
/// Formats a sleep timeout (seconds) for a chip label.
String _sleepLabel(int seconds) {
  if (seconds >= 60 && seconds % 60 == 0) {
    final m = seconds ~/ 60;
    return '${m}m';
  }
  return '${seconds}s';
}
