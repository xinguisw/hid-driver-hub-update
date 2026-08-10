import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter/material.dart';

/// Parameter Setting page — sensor feature + other feature.
///
/// L3 only. Dispatches events to BLoC.
/// Structure: outer group container → rows inside.
/// All rows are data-driven for future L2 capability filtering.
class HubParameterPanel extends StatelessWidget {
  const HubParameterPanel({
    super.key,
    this.lodOptions,
    this.performanceOptions,
    this.buttonDebounceOptions,
    this.sleepTimeOptions,
    this.hasSensorTuning = false,
    this.hasLod = false,
    this.hasAngleTune = false,
    this.hasPerformance = false,
    this.hasButtonDebounce = false,
    this.hasWheelInvert = false,
    this.hasSleepTime = false,
    this.rippleOn,
    this.rippleStaging,
    this.angleSnapOn,
    this.angleSnapStaging,
    this.angleTuneOn,
    this.angleTuneLabel,
    this.lodMm,
    this.performance,
    this.debounceMs,
    this.sleepSeconds,
    this.wheelInvert,
    this.onRippleChanged,
    this.onAngleSnapChanged,
    this.onAngleTuneToggled,
    this.onAngleTuneDecrement,
    this.onAngleTuneIncrement,
    this.onLodChanged,
    this.onPerformanceChanged,
    this.onDebounceChanged,
    this.onSleepChanged,
    this.onWheelInvertChanged,
  });

  final List<LodOptionData>? lodOptions;
  final List<int>? performanceOptions;
  final List<SettingsOptionData>? buttonDebounceOptions;
  final List<SettingsOptionData>? sleepTimeOptions;

  /// L2 gates: each feature hides when the device lacks it.
  final bool hasSensorTuning;
  final bool hasLod;
  final bool hasAngleTune;
  final bool hasPerformance;
  final bool hasButtonDebounce;
  final bool hasWheelInvert;
  final bool hasSleepTime;

  final bool? rippleOn;
  final bool? rippleStaging;
  final bool? angleSnapOn;
  final bool? angleSnapStaging;
  final bool? angleTuneOn;
  final String? angleTuneLabel;
  final int? lodMm;
  final int? performance;
  final int? debounceMs;
  final int? sleepSeconds;
  final bool? wheelInvert;
  final ValueChanged<bool>? onRippleChanged;
  final ValueChanged<bool>? onAngleSnapChanged;
  final ValueChanged<bool>? onAngleTuneToggled;
  final VoidCallback? onAngleTuneDecrement;
  final VoidCallback? onAngleTuneIncrement;
  final ValueChanged<int>? onLodChanged;
  final ValueChanged<int>? onPerformanceChanged;
  final ValueChanged<int>? onDebounceChanged;
  final ValueChanged<int>? onSleepChanged;
  final ValueChanged<bool>? onWheelInvertChanged;

  @override
  Widget build(BuildContext context) {
    final hasSensorContent =
        hasSensorTuning || hasLod || hasAngleTune || hasPerformance;
    final hasOtherContent = hasButtonDebounce || hasWheelInvert || hasSleepTime;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasSensorContent) ...[
            const Text('Sensor feature'),
            const SizedBox(height: 8),
            _SensorFeatureGroup(
              lodOptions: lodOptions ?? const [],
              performanceOptions: performanceOptions ?? const [],
              // why: staging paints ahead of synced so the switch follows the tap.
              rippleOn: rippleStaging ?? rippleOn ?? false,
              angleSnapOn: angleSnapStaging ?? angleSnapOn ?? false,
              // why: value shows live data even when toggled off.
              angleTuneOn: angleTuneOn ?? false,
              angleTuneLabel: angleTuneLabel ?? '0°',
              lodMm: lodMm,
              performance: performance,
              onRippleChanged: onRippleChanged,
              onAngleSnapChanged: onAngleSnapChanged,
              onAngleTuneToggled: onAngleTuneToggled,
              onAngleTuneDecrement: onAngleTuneDecrement,
              onAngleTuneIncrement: onAngleTuneIncrement,
              onLodChanged: onLodChanged,
              onPerformanceChanged: onPerformanceChanged,
              hasSensorTuning: hasSensorTuning,
              hasLod: hasLod,
              hasAngleTune: hasAngleTune,
              hasPerformance: hasPerformance,
            ),
            const SizedBox(height: 24),
          ],
          if (hasOtherContent) ...[
            const Text('Other feature'),
            const SizedBox(height: 8),
            _OtherFeatureGroup(
              buttonDebounceOptions: buttonDebounceOptions ?? const [],
              sleepTimeOptions: sleepTimeOptions ?? const [],
              debounceMs: debounceMs,
              sleepSeconds: sleepSeconds,
              wheelInvert: wheelInvert,
              onDebounceChanged: onDebounceChanged,
              onSleepChanged: onSleepChanged,
              onWheelInvertChanged: onWheelInvertChanged,
              hasButtonDebounce: hasButtonDebounce,
              hasWheelInvert: hasWheelInvert,
              hasSleepTime: hasSleepTime,
            ),
          ],
        ],
      ),
    );
  }
}

/// Outer group container for sensor feature.
class _SensorFeatureGroup extends StatelessWidget {
  const _SensorFeatureGroup({
    required this.lodOptions,
    required this.performanceOptions,
    required this.rippleOn,
    required this.angleSnapOn,
    required this.angleTuneOn,
    required this.angleTuneLabel,
    required this.lodMm,
    required this.performance,
    required this.onRippleChanged,
    required this.onAngleSnapChanged,
    required this.onAngleTuneToggled,
    required this.onAngleTuneDecrement,
    required this.onAngleTuneIncrement,
    required this.onLodChanged,
    required this.onPerformanceChanged,
    required this.hasSensorTuning,
    required this.hasLod,
    required this.hasAngleTune,
    required this.hasPerformance,
  });

  final List<LodOptionData> lodOptions;
  final List<int> performanceOptions;
  final bool hasSensorTuning;
  final bool hasLod;
  final bool hasAngleTune;
  final bool hasPerformance;
  final bool rippleOn;
  final bool angleSnapOn;
  final bool angleTuneOn;
  final String angleTuneLabel;
  final int? lodMm;
  final int? performance;
  final ValueChanged<bool>? onRippleChanged;
  final ValueChanged<bool>? onAngleSnapChanged;
  final ValueChanged<bool>? onAngleTuneToggled;
  final VoidCallback? onAngleTuneDecrement;
  final VoidCallback? onAngleTuneIncrement;
  final ValueChanged<int>? onLodChanged;
  final ValueChanged<int>? onPerformanceChanged;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // L2 gate: absent on this device -> row keeps LOD + angle tune.
              if (hasSensorTuning) ...[
                Expanded(
                  child: _SensorTuningBox(
                    rippleOn: rippleOn,
                    angleSnapOn: angleSnapOn,
                    onRippleChanged: onRippleChanged,
                    onAngleSnapChanged: onAngleSnapChanged,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (hasLod) ...[
                Expanded(
                  child: _LodBox(
                    options: lodOptions,
                    lodMm: lodMm,
                    onLodChanged: onLodChanged,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (hasAngleTune) ...[
                Expanded(
                  child: _AngleTuneBox(
                    angleTuneOn: angleTuneOn,
                    angleTuneLabel: angleTuneLabel,
                    onAngleTuneToggled: onAngleTuneToggled,
                    onAngleTuneDecrement: onAngleTuneDecrement,
                    onAngleTuneIncrement: onAngleTuneIncrement,
                  ),
                ),
              ],
            ],
          ),
          if (hasPerformance) ...[
            const SizedBox(height: 8),
            _PerformanceRow(
              options: performanceOptions,
              performance: performance,
              onPerformanceChanged: onPerformanceChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _SensorTuningBox extends StatelessWidget {
  const _SensorTuningBox({
    required this.rippleOn,
    required this.angleSnapOn,
    required this.onRippleChanged,
    required this.onAngleSnapChanged,
  });

  final bool rippleOn;
  final bool angleSnapOn;
  final ValueChanged<bool>? onRippleChanged;
  final ValueChanged<bool>? onAngleSnapChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Text('Ripple Control')),
              Switch(value: rippleOn, onChanged: onRippleChanged),
            ],
          ),
          Row(
            children: [
              const Expanded(child: Text('Angle Snap')),
              Switch(value: angleSnapOn, onChanged: onAngleSnapChanged),
            ],
          ),
        ],
      ),
    );
  }
}

class _LodBox extends StatelessWidget {
  const _LodBox({
    required this.options,
    required this.lodMm,
    required this.onLodChanged,
  });

  final List<LodOptionData> options;
  final int? lodMm;
  final ValueChanged<int>? onLodChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Text('LOD'),
          const SizedBox(width: 8),
          Expanded(
            child: RadioGroup<int>(
              groupValue: lodMm,
              // why: RadioGroup always fires with a value; null only means
              // deselected, which a radio group cannot reach on its own.
              onChanged: (value) {
                if (value != null) onLodChanged?.call(value);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final opt in options)
                    Row(
                      children: [
                        Radio<int>(value: opt.wire),
                        Text('${opt.mm}mm'),
                      ],
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

class _AngleTuneBox extends StatelessWidget {
  const _AngleTuneBox({
    required this.angleTuneOn,
    required this.angleTuneLabel,
    required this.onAngleTuneToggled,
    required this.onAngleTuneDecrement,
    required this.onAngleTuneIncrement,
  });

  final bool angleTuneOn;
  final String angleTuneLabel;
  final ValueChanged<bool>? onAngleTuneToggled;
  final VoidCallback? onAngleTuneDecrement;
  final VoidCallback? onAngleTuneIncrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              const Expanded(child: Text('Angle Tune')),
              Switch(value: angleTuneOn, onChanged: onAngleTuneToggled),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: onAngleTuneDecrement,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('<'),
                ),
              ),
              Text(angleTuneLabel),
              InkWell(
                onTap: onAngleTuneIncrement,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('>'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({
    required this.options,
    required this.performance,
    required this.onPerformanceChanged,
  });

  final List<int> options;
  final int? performance;
  final ValueChanged<int>? onPerformanceChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Text('Performance'),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final wire in options)
                  _SelectableChip(
                    label: _performanceLabel(wire),
                    selected: performance == wire,
                    onTap: onPerformanceChanged == null
                        ? null
                        : () => onPerformanceChanged!(wire),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _performanceLabel(int wire) {
    switch (wire) {
      case 0:
        return 'Low Performance';
      case 1:
        return 'Office Mouse';
      case 2:
        return 'High Performance';
      default:
        return '$wire';
    }
  }
}

class _OtherFeatureGroup extends StatelessWidget {
  const _OtherFeatureGroup({
    required this.buttonDebounceOptions,
    required this.sleepTimeOptions,
    required this.debounceMs,
    required this.sleepSeconds,
    required this.wheelInvert,
    required this.onDebounceChanged,
    required this.onSleepChanged,
    required this.onWheelInvertChanged,
    required this.hasButtonDebounce,
    required this.hasWheelInvert,
    required this.hasSleepTime,
  });

  final List<SettingsOptionData> buttonDebounceOptions;
  final List<SettingsOptionData> sleepTimeOptions;
  final int? debounceMs;
  final int? sleepSeconds;
  final bool? wheelInvert;
  final ValueChanged<int>? onDebounceChanged;
  final ValueChanged<int>? onSleepChanged;
  final ValueChanged<bool>? onWheelInvertChanged;
  final bool hasButtonDebounce;
  final bool hasWheelInvert;
  final bool hasSleepTime;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasButtonDebounce) ...[
                Expanded(
                  flex: 2,
                  child: _OptionsBox(
                    title: 'Button debounce',
                    options: buttonDebounceOptions,
                    selectedWire: debounceMs,
                    onSelected: onDebounceChanged,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (hasWheelInvert) ...[
                Expanded(
                  child: _WheelBox(
                    invert: wheelInvert ?? false,
                    onInvertChanged: onWheelInvertChanged,
                  ),
                ),
              ],
            ],
          ),
          if (hasSleepTime) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _OptionsBox(
                    title: 'Sleep time',
                    options: sleepTimeOptions,
                    selectedWire: sleepSeconds,
                    onSelected: onSleepChanged,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionsBox extends StatelessWidget {
  const _OptionsBox({
    required this.title,
    required this.options,
    this.selectedWire,
    this.onSelected,
  });

  final String title;
  final List<SettingsOptionData> options;

  /// Wire value of the currently selected option (if any).
  final int? selectedWire;

  /// Called with the wire value of a tapped option; null = not selectable.
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final opt in options)
                _SelectableChip(
                  label: opt.label,
                  selected: selectedWire == opt.wire,
                  onTap: onSelected == null
                      ? null
                      : () => onSelected!(opt.wire),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Wheel direction box — two selectable states: Forward / Reverse.
///
/// Backed by the tri-state wheel-direction byte (0xFF/0x0F/0x00); the bool is
/// the decoded "invert" flag. L4 owns encode/decode, L3 only paints.
class _WheelBox extends StatelessWidget {
  const _WheelBox({required this.invert, required this.onInvertChanged});

  final bool invert;
  final ValueChanged<bool>? onInvertChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wheel direction'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SelectableChip(
                label: 'Forward',
                selected: !invert,
                // why: both chips stay tappable so the user can switch away
                // from the current selection; selection only paints state.
                onTap: onInvertChanged == null
                    ? null
                    : () => onInvertChanged!(false),
              ),
              _SelectableChip(
                label: 'Reverse',
                selected: invert,
                onTap: onInvertChanged == null
                    ? null
                    : () => onInvertChanged!(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tappable chip that highlights when [selected].
class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.secondaryContainer
              : Colors.transparent,
          border: Border.all(
            color: selected
                ? theme.colorScheme.secondary
                : theme.colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
