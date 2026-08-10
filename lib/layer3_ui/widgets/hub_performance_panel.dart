import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter/material.dart';

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
  final VoidCallback? onDpiStageRemove;
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DPI Settings
          const Text('DPI settings'),
          const SizedBox(height: 8),
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
            onRemoveStage: () => onDpiStageRemove?.call(),
            removeEnabled: dpiRemoveEnabled,
            rgbPerStage: dpiRgbPerStage,
            onColorChanged: onDpiColorChanged,
          ),
          const SizedBox(height: 24),
          // Report Rate
          const Text('Report rate'),
          const SizedBox(height: 8),
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
    required this.onRemoveStage,
    this.removeEnabled = false,
    this.rgbPerStage = false,
    this.onColorChanged,
  });

  final List<DpiStageData> stages;
  final int? selectedLevel;
  final ValueChanged<int> onLevelSelected;
  final int dpiMin;
  final int dpiMax;
  final int? dpiStep;

  /// Staged per-level DPI values (level → value).
  final Map<int, int> valueStaging;

  final ValueChanged<({int level, int value})> onValueChanged;
  final int activeCount;
  final int maxLevels;
  final VoidCallback onAddStage;
  final VoidCallback onRemoveStage;

  /// True only when the user has selected a level (so `x` removes the
  /// selection, not the device's default active level).
  final bool removeEnabled;
  final bool rgbPerStage;
  final ValueChanged<({int level, Color color})>? onColorChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Levels row — each level in its own container
          Row(
            children: [
              const Text('Levels'),
              const SizedBox(width: 16),
              for (final stage in stages)
                _LevelChip(
                  index: stage.level,
                  isSelected: stage.level == selectedLevel,
                  onTap: () => onLevelSelected(stage.level),
                ),
              const Spacer(),
              // Add stage: disabled at max levels.
              InkWell(
                onTap: activeCount >= maxLevels ? null : onAddStage,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '+',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Remove stage: disabled when only one remains or no selection.
              InkWell(
                onTap: activeCount <= 1 || !removeEnabled
                    ? null
                    : onRemoveStage,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    'x',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // DPI slider rows — each row in its own container
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 500 ? 2 : 1;
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 110,
                ),
                children: [
                  for (final stage in stages)
                    _DpiSliderRow(
                      stage: stage,
                      stagedValue: valueStaging[stage.level] ?? stage.value,
                      min: dpiMin,
                      max: dpiMax,
                      step: dpiStep,
                      onValueChanged: (value) =>
                          onValueChanged((level: stage.level, value: value)),
                      rgbPerStage: rgbPerStage,
                      onColorChanged: onColorChanged,
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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '$index',
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontSize: 12,
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
class _DpiSliderRow extends StatelessWidget {
  const _DpiSliderRow({
    required this.stage,
    required this.stagedValue,
    required this.min,
    required this.max,
    this.step,
    required this.onValueChanged,
    this.rgbPerStage = false,
    this.onColorChanged,
  });

  final DpiStageData stage;

  /// Staged value (staging ?? synced); drives the slider position + label.
  final int stagedValue;

  final int min;
  final int max;

  /// Slider step; null = continuous (stepMode 'any').
  final int? step;

  final ValueChanged<int> onValueChanged;
  final bool rgbPerStage;
  final ValueChanged<({int level, Color color})>? onColorChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divisions = step == null || step! < 1
        ? null
        : ((max - min) ~/ step!).clamp(1, 1000);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (rgbPerStage) ...[
                _DpiColorButton(
                  color: _colorFromHex(stage.color),
                  onTap: () async {
                    final color = await showDialog<Color>(
                      context: context,
                      builder: (_) =>
                          _DpiColorDialog(initial: _colorFromHex(stage.color)),
                    );
                    if (color != null) {
                      onColorChanged?.call((level: stage.level, color: color));
                    }
                  },
                ),
                const SizedBox(width: 6),
              ],
              Text('DPI ${stage.level}'),
              const Spacer(),
              Text('$stagedValue'),
            ],
          ),
          const SizedBox(height: 4),
          Slider(
            value: stagedValue.toDouble().clamp(min.toDouble(), max.toDouble()),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions,
            onChanged: (v) => onValueChanged(v.round()),
          ),
          // Min / max range labels under the slider (live from the catalog).
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$min', style: const TextStyle(fontSize: 9)),
              Text('$max', style: const TextStyle(fontSize: 9)),
            ],
          ),
        ],
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

String _colorToHex(Color color) {
  int channel(double value) => (value * 255).round().clamp(0, 255);
  String part(int value) => value.toRadixString(16).padLeft(2, '0');
  return '#${part(channel(color.r))}${part(channel(color.g))}${part(channel(color.b))}'
      .toUpperCase();
}

class _DpiColorButton extends StatelessWidget {
  const _DpiColorButton({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'DPI stage color',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        ),
      ),
    );
  }
}

class _DpiColorDialog extends StatefulWidget {
  const _DpiColorDialog({required this.initial});

  final Color initial;

  @override
  State<_DpiColorDialog> createState() => _DpiColorDialogState();
}

class _DpiColorDialogState extends State<_DpiColorDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
  }

  void _setSv(Offset local, double width, double height) {
    final saturation = (local.dx / width).clamp(0.0, 1.0);
    final value = 1 - (local.dy / height).clamp(0.0, 1.0);
    setState(() {
      _hsv = _hsv.withSaturation(saturation).withValue(value);
    });
  }

  void _setHue(Offset local, double width) {
    setState(() {
      _hsv = _hsv.withHue((local.dx / width * 360).clamp(0.0, 359.999));
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();
    return AlertDialog(
      title: const Text('DPI stage color'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(_colorToHex(color)),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                const height = 160.0;
                return GestureDetector(
                  onPanDown: (details) =>
                      _setSv(details.localPosition, width, height),
                  onPanUpdate: (details) =>
                      _setSv(details.localPosition, width, height),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: width,
                      height: height,
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
                            left: (_hsv.saturation * width - 8).clamp(
                              0.0,
                              width - 16,
                            ),
                            top: ((1 - _hsv.value) * height - 8).clamp(
                              0.0,
                              height - 16,
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
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                const height = 18.0;
                return GestureDetector(
                  onPanDown: (details) => _setHue(details.localPosition, width),
                  onPanUpdate: (details) =>
                      _setHue(details.localPosition, width),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red,
                              Colors.yellow,
                              Colors.green,
                              Colors.cyan,
                              Colors.blue,
                              Colors.purple,
                              Colors.red,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(color),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

/// Outer group container for Report Rate.
///
/// Later, radio options will be filtered by L2 capabilities
/// (e.g. device may only support 125/250/500 Hz).
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose a polling rate for mouse (reports per second)',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          // Row container for radio options
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: RadioGroup<int>(
              groupValue: selectedHz,
              onChanged: (value) {
                if (value != null) onChanged?.call(value);
              },
              child: Row(
                children: [
                  for (final rate in options)
                    Expanded(
                      child: Row(
                        children: [
                          Radio<int>(value: rate),
                          Text('$rate'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
