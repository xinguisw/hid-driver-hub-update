import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter/material.dart';

/// Parameter Setting page — sensor feature + other feature.
///
/// L3 only. Dispatches events to BLoC.
/// Structure: outer group container → rows inside.
/// All rows are data-driven for future L2 capability filtering.
///
/// NOTE: this file only restyles presentation (spacing, typography, shapes,
/// chip/stepper look). Public API, gating logic, and callback wiring are
/// unchanged from the previous version.
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasSensorContent) ...[
            const _SectionHeader(title: 'Sensor feature'),
            const SizedBox(height: 10),
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
            const _SectionHeader(title: 'Other feature'),
            const SizedBox(height: 10),
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

/// Section label with a small accent bar, used above each feature group.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Title + optional icon + optional one-line hint text, stacked. Shared
/// across the sensor and other-feature boxes so every control gets the
/// same label styling.
class _FieldTitle extends StatelessWidget {
  const _FieldTitle({required this.title, this.description, this.icon});

  final String title;
  final String? description;

  /// Small leading glyph shown before the title, matching the icon-per-row
  /// style of the reference design.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: theme.colorScheme.onSurface),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
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
                const SizedBox(width: 12),
              ],
              if (hasLod) ...[
                Expanded(
                  child: _LodBox(
                    options: lodOptions,
                    lodMm: lodMm,
                    onLodChanged: onLodChanged,
                  ),
                ),
                const SizedBox(width: 12),
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
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: _FieldTitle(
                  title: 'Ripple Control',
                  description:
                      'Smooths out micro-movements to reduce cursor jitter at high sensitivity.',
                  icon: Icons.waves,
                ),
              ),
              Switch(value: rippleOn, onChanged: onRippleChanged),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: _FieldTitle(
                  title: 'Angle Snap',
                  description:
                      'Forces horizontal or vertical movement to follow a perfect straight line.',
                  icon: Icons.straighten,
                ),
              ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldTitle(
            title: 'LOD',
            description:
                'The height at which the sensor stops tracking when you lift the mouse.',
            icon: Icons.arrow_upward,
          ),
          const SizedBox(height: 12),
          RadioGroup<int>(
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Radio<int>(
                            value: opt.wire,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('${opt.mm}mm', style: theme.textTheme.bodyMedium),
                      ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: _FieldTitle(
                  title: 'Angle Tune',
                  description:
                      'Rotates the tracking axis to match your natural hand grip angle.',
                  icon: Icons.rotate_right,
                ),
              ),
              Switch(value: angleTuneOn, onChanged: onAngleTuneToggled),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepperButton(
                icon: Icons.chevron_left,
                onTap: onAngleTuneDecrement,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  angleTuneLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              _StepperButton(
                icon: Icons.chevron_right,
                onTap: onAngleTuneIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small circular icon button used for the angle-tune stepper controls.
class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: theme.colorScheme.onSurface),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldTitle(
            title: 'Performance',
            description:
                'Optimizes the sensor between maximum speed and power efficiency.',
            icon: Icons.speed,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
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
                    description:
                        'Filters out unintended double-clicks caused by mechanical switch bounce.',
                    icon: Icons.timer,
                    options: buttonDebounceOptions,
                    selectedWire: debounceMs,
                    onSelected: onDebounceChanged,
                  ),
                ),
                const SizedBox(width: 12),
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
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _OptionsBox(
                    title: 'Sleep time',
                    description:
                        'How long the mouse waits before entering low-power sleep mode.',
                    icon: Icons.bedtime,
                    options: sleepTimeOptions,
                    selectedWire: sleepSeconds,
                    onSelected: onSleepChanged,
                  ),
                ),
                const SizedBox(width: 12),
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
    this.description,
    this.icon,
    required this.options,
    this.selectedWire,
    this.onSelected,
  });

  final String title;

  /// One-line hint shown under the title, explaining what the setting does.
  final String? description;

  /// Small leading glyph shown before the title.
  final IconData? icon;
  final List<SettingsOptionData> options;

  /// Wire value of the currently selected option (if any).
  final int? selectedWire;

  /// Called with the wire value of a tapped option; null = not selectable.
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldTitle(title: title, description: description, icon: icon),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldTitle(
            title: 'Wheel direction',
            description:
                'Reverses the physical scroll wheel direction to your preferred workflow.',
            icon: Icons.sync_alt,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
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

/// Tappable pill that highlights when [selected] — used for every chip-style
/// option group (performance, debounce, sleep time, wheel direction).
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
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? theme.colorScheme.onSecondaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
