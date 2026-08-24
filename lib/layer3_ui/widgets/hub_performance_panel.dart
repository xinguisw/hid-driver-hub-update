import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Performance Setting page — DPI levels + Report Rate.
///
/// L3 only. Dispatches events to BLoC.
/// Structure: outer group container → rows inside.
/// All rows are data-driven for future L2 capability filtering.
class HubPerformancePanel extends StatelessWidget {
  const HubPerformancePanel({
    super.key,
    this.dpiStages,
    this.dpiCurrentLevel,
    this.dpiCurrentLevelStaging,
    this.onDpiLevelSelected,
    this.dpiMin,
    this.dpiMax,
    this.dpiStep,
    this.dpiValueStaging,
    this.onDpiValueChanged,
    this.dpiActiveLevelCount,
    this.dpiMaxLevels,
    this.onDpiStageAdd,
    this.onDpiStageRemove,
    this.dpiRemoveEnabled = false,
    this.dpiRgbPerStage = false,
    this.onDpiColorChanged,
    this.reportRateOptions,
    this.reportRateHz,
    this.reportRateStaging,
    this.onReportRateChanged,
  });

  final List<DpiStageData>? dpiStages;
  final int? dpiCurrentLevel;
  final int? dpiCurrentLevelStaging;
  final ValueChanged<int>? onDpiLevelSelected;
  final int? dpiMin;
  final int? dpiMax;
  final int? dpiStep;
  final Map<int, int>? dpiValueStaging;
  final ValueChanged<({int level, int value})>? onDpiValueChanged;
  final int? dpiActiveLevelCount;
  final int? dpiMaxLevels;
  final VoidCallback? onDpiStageAdd;
  final ValueChanged<int>? onDpiStageRemove;
  final bool dpiRemoveEnabled;
  final bool dpiRgbPerStage;
  final ValueChanged<({int level, Color color})>? onDpiColorChanged;
  final List<int>? reportRateOptions;
  final int? reportRateHz;
  final int? reportRateStaging;
  final ValueChanged<int>? onReportRateChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DPI Settings Header
          const _SectionHeader(
            icon: Icons.speed_rounded,
            title: 'DPI Settings',
            subtitle:
                'Configure sensitivity stages, color identifiers, and active levels',
          ),
          const SizedBox(height: 12),
          _DpiSettingsGroup(
            stages: dpiStages ?? const [],
            selectedLevel: dpiCurrentLevelStaging ?? dpiCurrentLevel,
            onLevelSelected: (level) => onDpiLevelSelected?.call(level),
            dpiMin: dpiMin ?? 50,
            dpiMax: dpiMax ?? 5000,
            dpiStep: dpiStep,
            valueStaging: dpiValueStaging ?? const {},
            onValueChanged: (pair) => onDpiValueChanged?.call(pair),
            activeCount: dpiActiveLevelCount ?? 0,
            maxLevels: dpiMaxLevels ?? 8,
            onAddStage: () => onDpiStageAdd?.call(),
            onDpiStageRemove: onDpiStageRemove,
            rgbPerStage: dpiRgbPerStage,
            onColorChanged: onDpiColorChanged,
          ),
          const SizedBox(height: 28),
          // Report Rate Header
          const _SectionHeader(
            icon: Icons.timer_outlined,
            title: 'Polling Rate',
            subtitle:
                'Choose how frequently the mouse reports data to your computer',
          ),
          const SizedBox(height: 12),
          _ReportRateGroup(
            options: reportRateOptions ?? const [125, 250, 500, 1000],
            selectedHz: reportRateStaging ?? reportRateHz ?? 250,
            onChanged: onReportRateChanged,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, size: 16, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 33),
            child: Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.8,
                ),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Outer group container for DPI settings.
///
/// Later, levels and DPI rows will be filtered by L2 capabilities
/// (e.g. if device only supports 4 levels, only 4 show).
class _DpiSettingsGroup extends StatelessWidget {
  const _DpiSettingsGroup({
    required this.stages,
    required this.selectedLevel,
    required this.onLevelSelected,
    required this.dpiMin,
    required this.dpiMax,
    this.dpiStep,
    required this.valueStaging,
    required this.onValueChanged,
    required this.activeCount,
    required this.maxLevels,
    required this.onAddStage,
    this.onDpiStageRemove,
    this.rgbPerStage = false,
    this.onColorChanged,
  });

  final List<DpiStageData> stages;
  final int? selectedLevel;
  final ValueChanged<int> onLevelSelected;
  final int dpiMin;
  final int dpiMax;
  final int? dpiStep;
  final Map<int, int> valueStaging;
  final ValueChanged<({int level, int value})> onValueChanged;
  final int activeCount;
  final int maxLevels;
  final VoidCallback onAddStage;
  final ValueChanged<int>? onDpiStageRemove;
  final bool rgbPerStage;
  final ValueChanged<({int level, Color color})>? onColorChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Levels row with modern chips and add stage trigger on the far right
          Row(
            children: [
              Text(
                'Levels',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final stage in stages)
                      _LevelChip(
                        index: stage.level,
                        isSelected: stage.level == selectedLevel,
                        onTap: () => onLevelSelected(stage.level),
                      ),
                  ],
                ),
              ),
              if (activeCount < maxLevels) ...[
                const SizedBox(width: 12),
                InkWell(
                  onTap: onAddStage,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.35,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // DPI slider cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 580 ? 2 : 1;
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 114,
                ),
                children: [
                  for (final stage in stages)
                    _DpiSliderRow(
                      stage: stage,
                      stagedValue: valueStaging[stage.level] ?? stage.value,
                      isSelected: stage.level == selectedLevel,
                      onSelect: () => onLevelSelected(stage.level),
                      min: dpiMin,
                      max: dpiMax,
                      step: dpiStep,
                      onValueChanged: (value) =>
                          onValueChanged((level: stage.level, value: value)),
                      rgbPerStage: rgbPerStage,
                      onColorChanged: onColorChanged,
                      onRemoveStage:
                          activeCount <= 1 || onDpiStageRemove == null
                          ? null
                          : () => onDpiStageRemove?.call(stage.level),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// One level chip inside the Levels row.
///
/// Later this will be conditionally rendered based on L2 capabilities
/// (e.g. device may only support levels 1-4).
class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final int index;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark ? const Color(0xFF26282E) : Colors.white),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark
                    ? const Color(0xFF3F424B)
                    : const Color(0xFFD0D5DD)),
            width: 1.0,
          ),
          boxShadow: isSelected
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
          '$index',
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark
                    ? const Color(0xFFE0E3EB)
                    : const Color(0xFF344054)),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// One DPI slider row inside the DPI group.
///
/// Later this row will be conditionally rendered based on
/// L2 capabilities (e.g. device may only have 4 DPI levels).
class _DpiSliderRow extends StatefulWidget {
  const _DpiSliderRow({
    required this.stage,
    required this.stagedValue,
    this.isSelected = false,
    this.onSelect,
    required this.min,
    required this.max,
    this.step,
    required this.onValueChanged,
    required this.rgbPerStage,
    this.onColorChanged,
    this.onRemoveStage,
  });

  final DpiStageData stage;

  /// Staged value (staging ?? synced); drives the slider position + label.
  final int stagedValue;

  final bool isSelected;
  final VoidCallback? onSelect;
  final int min;
  final int max;

  /// Slider step; null = continuous (stepMode 'any').
  final int? step;
  final ValueChanged<int> onValueChanged;
  final bool rgbPerStage;
  final ValueChanged<({int level, Color color})>? onColorChanged;
  final VoidCallback? onRemoveStage;

  @override
  State<_DpiSliderRow> createState() => _DpiSliderRowState();
}

class _DpiSliderRowState extends State<_DpiSliderRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = widget.isSelected
        ? theme.colorScheme.primary
        : _isHovered
        ? theme.colorScheme.primary.withValues(alpha: 0.6)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? (widget.isSelected
                      ? theme.colorScheme.surface.withValues(alpha: 0.95)
                      : _isHovered
                      ? theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        )
                      : theme.colorScheme.surface.withValues(alpha: 0.9))
                : (widget.isSelected
                      ? theme.colorScheme.surface
                      : _isHovered
                      ? theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.7,
                        )
                      : theme.colorScheme.surface),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 1.8 : (_isHovered ? 1.4 : 1.0),
            ),
            boxShadow: [
              if (widget.isSelected)
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              else if (_isHovered)
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.rgbPerStage) ...[
                    _DpiColorButton(
                      color: _colorFromHex(widget.stage.color),
                      onColorChanged: (color) {
                        widget.onColorChanged?.call((
                          level: widget.stage.level,
                          color: color,
                        ));
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    'DPI ${widget.stage.level}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: widget.isSelected
                          ? theme.colorScheme.primary
                          : null,
                    ),
                  ),
                  const Spacer(),
                  _DpiStepperInput(
                    value: widget.stagedValue,
                    min: widget.min,
                    max: widget.max,
                    step: widget.step,
                    onChanged: widget.onValueChanged,
                  ),
                  if (widget.onRemoveStage != null) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Delete DPI stage ${widget.stage.level}',
                      child: InkWell(
                        onTap: widget.onRemoveStage,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: isDark ? Colors.white : Colors.black,
                  inactiveTrackColor: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.15),
                  thumbColor: isDark ? Colors.white : Colors.black,
                  overlayColor: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.1),
                  thumbShape: _RingSliderThumbShape(
                    enabledThumbRadius: 6,
                    thickness: 3,
                    fillColor: isDark
                        ? theme.colorScheme.surface.withValues(alpha: 0.95)
                        : theme.colorScheme.surface,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                ),
                child: Slider(
                  value: widget.stagedValue.toDouble().clamp(
                    widget.min.toDouble(),
                    widget.max.toDouble(),
                  ),
                  min: widget.min.toDouble(),
                  max: widget.max.toDouble(),
                  onChanged: (v) => widget.onValueChanged(
                    snapToStep(
                      v.round(),
                      min: widget.min,
                      max: widget.max,
                      step: widget.step,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.min}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.85,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.max}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.85,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _colorFromHex(String? value) {
  final raw = value?.replaceFirst('#', '');
  final parsed = raw == null || raw.length != 6
      ? null
      : int.tryParse(raw, radix: 16);
  return parsed == null ? Colors.white : Color(0xFF000000 | parsed);
}

class _DpiColorButton extends StatefulWidget {
  const _DpiColorButton({required this.color, required this.onColorChanged});

  final Color color;
  final ValueChanged<Color>? onColorChanged;

  @override
  State<_DpiColorButton> createState() => _DpiColorButtonState();
}

class _DpiColorButtonState extends State<_DpiColorButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _togglePopover() {
    if (_overlayEntry != null) {
      _closePopover();
    } else {
      _openPopover();
    }
  }

  void _closePopover() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _openPopover() {
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss when clicking anywhere outside
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closePopover,
            ),
          ),
          Positioned(
            width: 240,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(-8, 22),
              child: Material(
                elevation: 16,
                color: Colors.transparent,
                child: _DpiCompactColorOverlay(
                  initialColor: widget.color,
                  onColorChanged: (color) {
                    widget.onColorChanged?.call(color);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  @override
  void dispose() {
    _closePopover();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final outerBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.35);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Tooltip(
        message: 'DPI stage color',
        child: InkWell(
          onTap: _togglePopover,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                border: Border.all(color: outerBorderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.45),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DpiCompactColorOverlay extends StatefulWidget {
  const _DpiCompactColorOverlay({
    required this.initialColor,
    required this.onColorChanged,
  });

  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  @override
  State<_DpiCompactColorOverlay> createState() =>
      _DpiCompactColorOverlayState();
}

class _DpiCompactColorOverlayState extends State<_DpiCompactColorOverlay> {
  late HSVColor _hsv;
  late TextEditingController _rCtrl;
  late TextEditingController _gCtrl;
  late TextEditingController _bCtrl;

  @override
  void initState() {
    super.initState();
    final c = widget.initialColor;
    final parsedHsv = HSVColor.fromColor(c);
    _hsv = (parsedHsv.saturation == 0 && parsedHsv.value == 1.0)
        ? HSVColor.fromAHSV(1.0, 0.0, 0.0, 1.0)
        : parsedHsv;
    _rCtrl = TextEditingController(text: '${(c.r * 255).round()}');
    _gCtrl = TextEditingController(text: '${(c.g * 255).round()}');
    _bCtrl = TextEditingController(text: '${(c.b * 255).round()}');
  }

  @override
  void dispose() {
    _rCtrl.dispose();
    _gCtrl.dispose();
    _bCtrl.dispose();
    super.dispose();
  }

  void _updateFromHsv(HSVColor newHsv) {
    setState(() {
      _hsv = newHsv;
      final c = _hsv.toColor();
      _rCtrl.text = '${(c.r * 255).round()}';
      _gCtrl.text = '${(c.g * 255).round()}';
      _bCtrl.text = '${(c.b * 255).round()}';
    });
    widget.onColorChanged(_hsv.toColor());
  }

  void _setSv(Offset local, double width, double height) {
    final saturation = (local.dx / width).clamp(0.0, 1.0);
    final value = 1.0 - (local.dy / height).clamp(0.0, 1.0);
    _updateFromHsv(_hsv.withSaturation(saturation).withValue(value));
  }

  void _setHue(Offset local, double width) {
    final hue = (local.dx / width * 360).clamp(0.0, 359.999);
    _updateFromHsv(_hsv.withHue(hue));
  }

  void _onRgbInputChanged() {
    final r = int.tryParse(_rCtrl.text)?.clamp(0, 255);
    final g = int.tryParse(_gCtrl.text)?.clamp(0, 255);
    final b = int.tryParse(_bCtrl.text)?.clamp(0, 255);
    if (r != null && g != null && b != null) {
      final color = Color.fromARGB(255, r, g, b);
      setState(() {
        _hsv = HSVColor.fromColor(color);
      });
      widget.onColorChanged(color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _hsv.toColor();
    const double pickerWidth = 240.0;
    const double svHeight = 140.0;

    return Container(
      width: pickerWidth,
      decoration: BoxDecoration(
        color: const Color(0xFF26262B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3F3F46), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 2D Saturation / Value Gradient Box
          GestureDetector(
            onPanDown: (d) => _setSv(d.localPosition, pickerWidth, svHeight),
            onPanUpdate: (d) => _setSv(d.localPosition, pickerWidth, svHeight),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(9),
              ),
              child: SizedBox(
                width: pickerWidth,
                height: svHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
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
                      left: (_hsv.saturation * pickerWidth - 7).clamp(
                        0.0,
                        pickerWidth - 14,
                      ),
                      top: ((1 - _hsv.value) * svHeight - 7).clamp(
                        0.0,
                        svHeight - 14,
                      ),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, blurRadius: 3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Swatch + Hue Bar row
                Row(
                  children: [
                    Icon(
                      Icons.colorize,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: currentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: currentColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Hue Rainbow Slider
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final barWidth = constraints.maxWidth;
                          const barHeight = 12.0;
                          return GestureDetector(
                            onPanDown: (d) =>
                                _setHue(d.localPosition, barWidth),
                            onPanUpdate: (d) =>
                                _setHue(d.localPosition, barWidth),
                            child: SizedBox(
                              height: 18,
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      height: barHeight,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFFF0000),
                                            Color(0xFFFFFF00),
                                            Color(0xFF00FF00),
                                            Color(0xFF00FFFF),
                                            Color(0xFF0000FF),
                                            Color(0xFFFF00FF),
                                            Color(0xFFFF0000),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: (_hsv.hue / 360 * barWidth - 6).clamp(
                                      0.0,
                                      barWidth - 12,
                                    ),
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.black54,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // RGB Value inputs row
                Row(
                  children: [
                    _buildRgbField('R', _rCtrl),
                    const SizedBox(width: 8),
                    _buildRgbField('G', _gCtrl),
                    const SizedBox(width: 8),
                    _buildRgbField('B', _bCtrl),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRgbField(String label, TextEditingController controller) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E22),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF3F3F46)),
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              onChanged: (_) => _onRgbInputChanged(),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportRateGroup extends StatelessWidget {
  const _ReportRateGroup({
    required this.options,
    required this.selectedHz,
    required this.onChanged,
  });

  final List<int> options;
  final int selectedHz;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Report Rate',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($selectedHz Hz)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final rate in options)
                _PollingRateChip(
                  hz: rate,
                  isSelected: rate == selectedHz,
                  onTap: () => onChanged?.call(rate),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PollingRateChip extends StatelessWidget {
  const _PollingRateChip({
    required this.hz,
    required this.isSelected,
    required this.onTap,
  });

  final int hz;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? const Color(0xFF26282E) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark
                      ? const Color(0xFF3F424B)
                      : const Color(0xFFD0D5DD)),
              width: 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2.5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.25 : 0.05,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
          ),
          child: Text(
            '$hz Hz',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? const Color(0xFFE0E3EB)
                      : const Color(0xFF344054)),
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Quantizes [rawValue] to the nearest valid step [step] above [min], clamped to [min..max].
int snapToStep(int rawValue, {required int min, required int max, int? step}) {
  final clamped = rawValue.clamp(min, max);
  if (step == null || step <= 1) return clamped;
  final stepsFromMin = ((clamped - min) / step).round();
  final snapped = min + (stepsFromMin * step);
  return snapped.clamp(min, max);
}

class _DpiStepperInput extends StatefulWidget {
  const _DpiStepperInput({
    required this.value,
    required this.min,
    required this.max,
    this.step,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final int? step;
  final ValueChanged<int> onChanged;

  @override
  State<_DpiStepperInput> createState() => _DpiStepperInputState();
}

class _DpiStepperInputState extends State<_DpiStepperInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_DpiStepperInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _submitCurrentText();
    }
  }

  void _submitCurrentText() {
    final parsed = int.tryParse(_controller.text) ?? widget.value;
    final snapped = snapToStep(
      parsed,
      min: widget.min,
      max: widget.max,
      step: widget.step,
    );
    _controller.text = '$snapped';
    if (snapped != widget.value) {
      widget.onChanged(snapped);
    }
  }

  void _stepBy(int delta) {
    final stepSize = widget.step ?? 50;
    final target = widget.value + (delta * stepSize);
    final snapped = snapToStep(
      target,
      min: widget.min,
      max: widget.max,
      step: widget.step,
    );
    _controller.text = '$snapped';
    if (snapped != widget.value) {
      widget.onChanged(snapped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _focusNode.hasFocus
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 54,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 2,
                ),
                border: InputBorder.none,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _submitCurrentText(),
            ),
          ),
          Container(
            width: 1,
            height: 26,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _stepBy(1),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(6),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _stepBy(-1),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(6),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom slider thumb that draws a hollow ring, useful for precise DPI tuning.
class _RingSliderThumbShape extends SliderComponentShape {
  const _RingSliderThumbShape({
    this.enabledThumbRadius = 6.0,
    this.thickness = 2.5,
    required this.fillColor,
  });

  final double enabledThumbRadius;
  final double thickness;
  final Color fillColor;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.black
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, enabledThumbRadius, fillPaint);
    canvas.drawCircle(center, enabledThumbRadius, strokePaint);
  }
}
