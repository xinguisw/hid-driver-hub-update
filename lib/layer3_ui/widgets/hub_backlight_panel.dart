import 'dart:math' as math;
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer3_ui/theme/app_theme.dart';
import 'package:driver_hub/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Backlight Setting page — RGB backlight controls.
///
/// L3 only. Dispatches events to BLoC.
/// Structure: one container per section in a clean vertical column.
/// Features descriptions for each setting, compact level boxes,
/// bounded color palette (no stretching), working hex code input, and quick presets.
class HubBacklightPanel extends StatelessWidget {
  const HubBacklightPanel({
    super.key,
    this.rgbModes,
    this.rgbModeLabels,
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
    this.onModeChanged,
    this.onColorChanged,
    this.onBrightnessChanged,
    this.onSpeedChanged,
    this.onSleepChanged,
  });

  final List<RgbModeData>? rgbModes;

  /// Display labels parallel to [rgbModes] (human-readable, L5-owned). When
  /// null or mismatched, the mode dropdown falls back to `RgbModeData.nameKey`.
  final List<String>? rgbModeLabels;
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ModeBox(
            rgbModes: rgbModes ?? const [],
            rgbModeLabels: rgbModeLabels,
            rgbModeId: rgbModeId,
            onModeChanged: onModeChanged,
          ),
          const SizedBox(height: 10),
          // why: FR-RGB-003 — the color palette only applies to color modes
          // (constant / single breathing). For modes whose supportsColor is
          // false (off / multi / running / cycle) the device ignores R/G/B, so
          // the picker is disabled to signal that.
          _ColorBox(
            r: rgbR,
            g: rgbG,
            b: rgbB,
            enabled: _selectedModeSupportsColor(),
            onColorChanged: onColorChanged,
          ),
          const SizedBox(height: 10),
          _LevelBox(
            title: t.backlight.brightness,
            description: t.backlight.brightnessDesc,
            icon: Icons.brightness_6_outlined,
            levels: rgbBrightnessLevels ?? 0,
            selected: rgbBrightness,
            onChanged: onBrightnessChanged,
            // why: reference brightness table is 0/25/50/75/100% (L5 codec owns
            // the same table) — not the generic 0..100% percent-of-index.
            labels: const ['0%', '25%', '50%', '75%', '100%'],
          ),
          const SizedBox(height: 10),
          _LevelBox(
            title: t.backlight.speed,
            description: t.backlight.speedDesc,
            icon: Icons.speed_outlined,
            levels: rgbSpeedLevels ?? 0,
            selected: rgbSpeed,
            onChanged: onSpeedChanged,
          ),
          const SizedBox(height: 10),
          // why: RGB power-saving is a chip row like brightness/speed (not a
          // dropdown) per request; options come from the capability schema.
          _LevelBox(
            title: t.backlight.powerSaving,
            description: t.backlight.powerSavingDesc,
            icon: Icons.bedtime_outlined,
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

  /// Whether the currently-selected mode uses the custom R/G/B color.
  ///
  /// Looks up [rgbModeId] in [rgbModes] and returns its `supportsColor`. When
  /// the mode is unknown or no modes are loaded, defaults to true so the
  /// picker isn't wrongly locked before capabilities/GET land.
  bool _selectedModeSupportsColor() {
    final modes = rgbModes;
    final id = rgbModeId;
    if (modes == null || modes.isEmpty || id == null) return true;
    for (final m in modes) {
      if (m.id == id) return m.supportsColor;
    }
    return true;
  }
}

// ---------------------------------------------------------------------------
// Design System Card Container
// ---------------------------------------------------------------------------

class _CardBox extends StatelessWidget {
  const _CardBox({
    required this.child,
    this.isActive = false,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final bool isActive;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.28)
        : theme.colorScheme.surfaceContainerLowest;

    final borderColor = (isDark ? Colors.white : Colors.black).withValues(
      alpha: 0.45,
    );

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Mode Box with Description & Bounded Dropdown Menu
// ---------------------------------------------------------------------------

class _ModeBox extends StatelessWidget {
  const _ModeBox({
    required this.rgbModes,
    required this.rgbModeId,
    this.rgbModeLabels,
    this.onModeChanged,
  });

  final List<RgbModeData> rgbModes;
  final int? rgbModeId;

  /// Display labels parallel to [rgbModes]; falls back to `RgbMode.nameKey`.
  final List<String>? rgbModeLabels;
  final ValueChanged<int>? onModeChanged;

  String _labelAt(int i) {
    final raw = (rgbModeLabels != null && i < rgbModeLabels!.length)
        ? rgbModeLabels![i]
        : rgbModes[i].nameKey;
    switch (raw.trim().toLowerCase()) {
      case 'constant':
      case 'light.constant':
      case 'rgb.mode.constant':
        return t.backlight.modes.constant;
      case 'single breathing':
      case 'single_breathing':
      case 'light.single_breathing':
      case 'rgb.mode.single_breathing':
        return t.backlight.modes.singleBreathing;
      case 'multi breathing':
      case 'multi_breathing':
      case 'light.multi_breathing':
      case 'rgb.mode.multi_breathing':
        return t.backlight.modes.multiBreathing;
      case 'multi color':
      case 'multi_color':
      case 'light.multi_color':
      case 'rgb.mode.multi_color':
        return t.backlight.modes.multiColor;
      case 'running color':
      case 'running_color':
      case 'light.running_color':
      case 'rgb.mode.running_color':
        return t.backlight.modes.runningColor;
      case 'cycle wave':
      case 'cycle_wave':
      case 'light.cycle_wave':
      case 'rgb.mode.cycle_wave':
        return t.backlight.modes.cycleWave;
      case 'cycle':
      case 'cycle color':
      case 'cycle_color':
      case 'light.cycle':
      case 'light.cycle_color':
      case 'rgb.mode.cycle':
      case 'rgb.mode.cycle_color':
        return t.backlight.modes.cycle;
      case 'running':
      case 'light.running':
      case 'rgb.mode.running':
        return t.backlight.modes.running;
      case 'off':
      case 'light.off':
      case 'rgb.mode.off':
        return t.backlight.modes.off;
      default:
        return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return _CardBox(
      isActive: rgbModeId != null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;

          final titleSection = Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.backlight.mode,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.backlight.modeDesc,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.75,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final dropdownWidget = Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF26282E) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (isDark
                    ? const Color(0xFF3F424B)
                    : const Color(0xFFD0D5DD)),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value:
                    rgbModeId != null && rgbModes.any((m) => m.id == rgbModeId)
                    ? rgbModeId
                    : null,
                hint: Text(
                  t.backlight.selectModeHint,
                  style: const TextStyle(fontSize: 13),
                ),
                menuMaxHeight: 240,
                borderRadius: BorderRadius.circular(10),
                dropdownColor: isDark ? const Color(0xFF26282E) : Colors.white,
                elevation: 4,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                items: [
                  for (var i = 0; i < rgbModes.length; i++)
                    DropdownMenuItem<int>(
                      value: rgbModes[i].id,
                      child: Text(
                        _labelAt(i),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) onModeChanged?.call(value);
                },
              ),
            ),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: titleSection),
                const SizedBox(width: 16),
                dropdownWidget,
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleSection,
                const SizedBox(height: 10),
                dropdownWidget,
              ],
            );
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Color Box with Proportional SV/Hue Picker (Bounded Width), Presets & Hex Code
// ---------------------------------------------------------------------------

class _ColorBox extends StatefulWidget {
  const _ColorBox({
    this.r,
    this.g,
    this.b,
    this.enabled = true,
    this.onColorChanged,
  });

  final int? r;
  final int? g;
  final int? b;

  /// Whether the picker accepts input (false when the mode ignores R/G/B).
  final bool enabled;
  final ValueChanged<Color>? onColorChanged;

  @override
  State<_ColorBox> createState() => _ColorBoxState();
}

class _ColorBoxState extends State<_ColorBox> {
  late HSVColor _hsv;
  late TextEditingController _hexController;

  static const List<Color> _presetColors = [
    Color(0xFFFF0000), // Red
    Color(0xFFFF7700), // Orange
    Color(0xFFFFFF00), // Yellow
    Color(0xFF00E676), // Green
    Color(0xFF00E5FF), // Cyan
    Color(0xFF2979FF), // Blue
    Color(0xFF7C4DFF), // Purple
    Color(0xFFFF4081), // Pink
    Color(0xFFFFFFFF), // White
  ];

  static Color _rgbToColor(int? r, int? g, int? b) => Color.fromARGB(
    255,
    (r ?? 255).clamp(0, 255),
    (g ?? 255).clamp(0, 255),
    (b ?? 0).clamp(0, 255),
  );

  static String _hexOf(Color c) {
    final r = (c.r * 255.0).round().clamp(0, 255);
    final g = (c.g * 255.0).round().clamp(0, 255);
    final b = (c.b * 255.0).round().clamp(0, 255);
    return '${r.toRadixString(16).padLeft(2, '0')}'
            '${g.toRadixString(16).padLeft(2, '0')}'
            '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

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
      final newColor = _rgbToColor(widget.r, widget.g, widget.b);
      _hsv = HSVColor.fromColor(newColor);
      final newHex = _hexOf(newColor);
      if (_hexController.text.toUpperCase() != newHex) {
        _hexController.value = TextEditingValue(
          text: newHex,
          selection: TextSelection.collapsed(offset: newHex.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _apply(HSVColor next, {bool updateText = true}) {
    setState(() {
      _hsv = next;
      if (updateText) {
        final hex = _hexOf(next.toColor());
        _hexController.value = TextEditingValue(
          text: hex,
          selection: TextSelection.collapsed(offset: hex.length),
        );
      }
    });
    widget.onColorChanged?.call(next.toColor());
  }

  void _onSv(Offset local, double w, double h) {
    if (!widget.enabled) return;
    final s = (local.dx / w).clamp(0.0, 1.0);
    final v = 1.0 - (local.dy / h).clamp(0.0, 1.0);
    _apply(_hsv.withSaturation(s).withValue(v));
  }

  void _onHue(Offset local, double w) {
    if (!widget.enabled) return;
    final hue = (local.dx / w * 360).clamp(0.0, 359.999);
    _apply(_hsv.withHue(hue));
  }

  void _onHexChanged(String value) {
    if (!widget.enabled) return;
    final hex = value.replaceAll('#', '').trim();
    if (hex.length == 6) {
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) {
        final newColor = Color(0xFF000000 | parsed);
        final next = HSVColor.fromColor(newColor);
        setState(() {
          _hsv = next;
        });
        widget.onColorChanged?.call(newColor);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _hsv.toColor();

    final body = _CardBox(
      isActive: widget.enabled,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;
              final titleSection = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.color_lens_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t.backlight.color,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Live Color Swatch preview
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.outline.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.35),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.enabled
                              ? t.backlight.colorDescEnabled
                              : t.backlight.colorDescDisabled,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.75),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final hexFieldWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      t.backlight.colorCode,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 84,
                    height: 32,
                    child: TextField(
                      controller: _hexController,
                      enabled: widget.enabled,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(6),
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9a-fA-F]'),
                        ),
                      ],
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        prefixText: '#',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontFamilyFallback: AppTheme.fontFallbacks,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: _onHexChanged,
                      onSubmitted: _onHexChanged,
                    ),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: titleSection),
                    const SizedBox(width: 16),
                    hexFieldWidget,
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleSection,
                    const SizedBox(height: 10),
                    hexFieldWidget,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 12),

          // Preset Quick-Pick Color Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Presets:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              for (final preset in _presetColors)
                _PresetColorSwatch(
                  color: preset,
                  isSelected: _isSameColor(preset, color),
                  enabled: widget.enabled,
                  onTap: () => _apply(HSVColor.fromColor(preset)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Proportional Saturation / Value Gradient Picker (Bounded Width & Centered)
          LayoutBuilder(
            builder: (context, constraints) {
              final w = math.min(constraints.maxWidth, 480.0);
              const h = 160.0;
              return Align(
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
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
                                  color: HSVColor.fromAHSV(
                                    1,
                                    _hsv.hue,
                                    1,
                                    1,
                                  ).toColor(),
                                ),
                              ),
                              const Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.transparent,
                                      ],
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
                                      colors: [
                                        Colors.transparent,
                                        Colors.black,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: (w > 16
                                        ? (_hsv.saturation * w - 8)
                                        : 0.0)
                                    .clamp(0.0, math.max(0.0, w - 16)),
                                top: ((1 - _hsv.value) * h - 8).clamp(
                                  0.0,
                                  math.max(0.0, h - 16),
                                ),
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black45,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Continuous Hue Spectrum Bar (Matching Bounded Width)
                    GestureDetector(
                      onPanDown: (d) => _onHue(d.localPosition, w),
                      onPanUpdate: (d) => _onHue(d.localPosition, w),
                      child: SizedBox(
                        height: 24.0,
                        width: w,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          clipBehavior: Clip.none,
                          children: [
                            // Rainbow Gradient Bar
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: SizedBox(
                                  height: 14.0,
                                  width: w,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          for (var i = 0; i <= 6; i++)
                                            HSVColor.fromAHSV(
                                              1,
                                              i * 60.0,
                                              1,
                                              1,
                                            ).toColor(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Thumb Indicator (Not Clipped)
                            Positioned(
                              left: (w > 20
                                      ? (_hsv.hue / 360 * (w - 20))
                                      : 0.0)
                                  .clamp(0.0, math.max(0.0, w - 20)),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: HSVColor.fromAHSV(
                                      1,
                                      _hsv.hue,
                                      1,
                                      1,
                                    ).toColor(),
                                    width: 3,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    if (widget.enabled) return body;
    return Opacity(opacity: 0.45, child: IgnorePointer(child: body));
  }

  bool _isSameColor(Color a, Color b) {
    return (a.r * 255).round() == (b.r * 255).round() &&
        (a.g * 255).round() == (b.g * 255).round() &&
        (a.b * 255).round() == (b.b * 255).round();
  }
}

class _PresetColorSwatch extends StatelessWidget {
  const _PresetColorSwatch({
    required this.color,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.black26,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 12,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact Level Box with Description (Brightness, Speed, Power Saving)
// ---------------------------------------------------------------------------

class _LevelBox extends StatelessWidget {
  const _LevelBox({
    required this.title,
    this.description,
    required this.levels,
    required this.selected,
    this.icon,
    this.onChanged,
    this.labels,
  });

  final String title;
  final String? description;
  final IconData? icon;
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

    return _CardBox(
      isActive: selected != null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;

          final titleWidget = Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 16, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.75,
                          ),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          final pillsWidget = Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < levels; i++)
                _SelectablePill(
                  label: useLabels
                      ? labels![i]
                      : '${(100 * i / pctDenom).round()}',
                  selected: i == selected,
                  onTap: onChanged == null ? null : () => onChanged!(i),
                ),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: titleWidget),
                const SizedBox(width: 16),
                pillsWidget,
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleWidget, const SizedBox(height: 10), pillsWidget],
            );
          }
        },
      ),
    );
  }
}

class _SelectablePill extends StatelessWidget {
  const _SelectablePill({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: const BoxConstraints(minWidth: 46),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : (isDark ? const Color(0xFF26282E) : Colors.white),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : (isDark
                        ? const Color(0xFF3F424B)
                        : const Color(0xFFD0D5DD)),
              width: 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.25 : 0.05,
                      ),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? Colors.white
                  : (isDark
                        ? const Color(0xFFE0E3EB)
                        : const Color(0xFF344054)),
            ),
          ),
        ),
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
