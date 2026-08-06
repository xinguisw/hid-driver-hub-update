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
              const Text('+'),
              const SizedBox(width: 8),
              const Text('x'),
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
                      onValueChanged: (value) => onValueChanged(
                        (level: stage.level, value: value),
                      ),
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
  });

  final DpiStageData stage;

  /// Staged value (staging ?? synced); drives the slider position + label.
  final int stagedValue;

  final int min;
  final int max;

  /// Slider step; null = continuous (stepMode 'any').
  final int? step;

  final ValueChanged<int> onValueChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divisions =
        step == null || step! < 1 ? null : ((max - min) ~/ step!).clamp(1, 1000);
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
