import 'package:driver_hub/layer2_capabilities/capabilities.dart';
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
    this.hasSensorTuning = true,
    this.rippleOn,
    this.rippleStaging,
    this.angleSnapOn,
    this.angleSnapStaging,
    this.onRippleChanged,
    this.onAngleSnapChanged,
  });

  final List<LodOption>? lodOptions;
  final List<int>? performanceOptions;
  final List<int>? buttonDebounceOptions;
  final List<int>? sleepTimeOptions;

  /// L2 gate: ripple + angle snap hide together when the device lacks them.
  final bool hasSensorTuning;

  final bool? rippleOn;
  final bool? rippleStaging;
  final bool? angleSnapOn;
  final bool? angleSnapStaging;
  final ValueChanged<bool>? onRippleChanged;
  final ValueChanged<bool>? onAngleSnapChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sensor feature'),
          const SizedBox(height: 8),
          _SensorFeatureGroup(
            lodOptions: lodOptions ?? const [],
            performanceOptions: performanceOptions ?? const [0, 1, 2],
            // why: staging paints ahead of synced so the switch follows the tap.
            rippleOn: rippleStaging ?? rippleOn ?? false,
            angleSnapOn: angleSnapStaging ?? angleSnapOn ?? false,
            onRippleChanged: onRippleChanged,
            onAngleSnapChanged: onAngleSnapChanged,
            hasSensorTuning: hasSensorTuning,
          ),
          const SizedBox(height: 24),
          const Text('Other feature'),
          const SizedBox(height: 8),
          _OtherFeatureGroup(
            buttonDebounceOptions:
                buttonDebounceOptions ?? const [0, 1, 2, 4, 8, 16],
            sleepTimeOptions:
                sleepTimeOptions ?? const [30, 60, 120, 180, 300, 1500, 1800],
          ),
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
    required this.onRippleChanged,
    required this.onAngleSnapChanged,
    required this.hasSensorTuning,
  });

  final List<LodOption> lodOptions;
  final List<int> performanceOptions;
  final bool hasSensorTuning;
  final bool rippleOn;
  final bool angleSnapOn;
  final ValueChanged<bool>? onRippleChanged;
  final ValueChanged<bool>? onAngleSnapChanged;

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
              Expanded(child: _LodBox(options: lodOptions)),
              const SizedBox(width: 8),
              const Expanded(child: _AngleTuneBox()),
            ],
          ),
          const SizedBox(height: 8),
          _PerformanceRow(options: performanceOptions),
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
  const _LodBox({required this.options});

  final List<LodOption> options;

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
              groupValue: options.isEmpty ? null : options.last.wire,
              onChanged: (_) {},
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
  const _AngleTuneBox();

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
              Switch(value: false, onChanged: null),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('<'),
              SizedBox(width: 16),
              Text('0'),
              SizedBox(width: 16),
              Text('>'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({required this.options});

  final List<int> options;

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
          for (final wire in options) ...[
            _OptionChip(label: _performanceLabel(wire)),
            const SizedBox(width: 8),
          ],
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
  });

  final List<int> buttonDebounceOptions;
  final List<int> sleepTimeOptions;

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
              Expanded(
                flex: 2,
                child: _OptionsBox(
                  title: 'Button debounce',
                  labels: [
                    for (final ms in buttonDebounceOptions) '$ms ms',
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _OptionsBox(
                  title: 'Wheel direction',
                  labels: ['Forward', 'Reverse'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _OptionsBox(
                  title: 'Sleep time',
                  labels: [
                    for (final seconds in sleepTimeOptions)
                      _sleepLabel(seconds),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  String _sleepLabel(int seconds) {
    if (seconds < 60) return '$seconds s';
    final mins = seconds ~/ 60;
    return mins == 1 ? '1 min' : '$mins mins';
  }
}

class _OptionsBox extends StatelessWidget {
  const _OptionsBox({required this.title, required this.labels});

  final String title;
  final List<String> labels;

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
          Text(title),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in labels) _OptionChip(label: label),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
