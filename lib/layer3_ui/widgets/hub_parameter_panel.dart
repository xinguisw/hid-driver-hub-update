import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter/material.dart';

/// Parameter Setting page — sensor feature + other feature.
///
/// L3 only. Dispatches events to BLoC.
/// Structure: outer group container → rows inside.
/// All rows are data-driven for future L2 capability filtering.
///
/// Parameter Setting page — sensor feature + other feature.
///
/// L3 only. Dispatches events to BLoC.
/// Structure: outer group container → rows inside.
/// All rows are data-driven for future L2 capability filtering.
///
/// NOTE: this file enhances presentation (spacing, typography, shapes,
/// chip/stepper look, active highlights, card depth). Public API, gating logic,
/// and callback wiring are strictly unchanged.
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasSensorContent) ...[
            const _SectionHeader(
              title: 'Sensor features',
              subtitle: 'Advanced optical sensor tuning and calibration',
              icon: Icons.tune,
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 28),
          ],
          if (hasOtherContent) ...[
            const _SectionHeader(
              title: 'Device features',
              subtitle: 'Response times, power management and mechanics',
              icon: Icons.settings_input_component,
            ),
            const SizedBox(height: 14),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle, this.icon});

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
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
            ],
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
            padding: EdgeInsets.only(left: icon != null ? 42 : 0),
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

/// Title + icon + description helper.
class _FieldTitle extends StatelessWidget {
  const _FieldTitle({required this.title, this.description, this.icon});

  final String title;
  final String? description;
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 6),
          Text(
            description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
              height: 1.35,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

/// Outer group container with a subtle glass-card border and shadow.
class _GroupContainer extends StatelessWidget {
  const _GroupContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: child,
    );
  }
}

/// Inner card container with elevated surface background and clean neutral border.
class _CardBox extends StatelessWidget {
  const _CardBox({required this.child, this.isActive = false});

  final Widget child;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(
            alpha: isDark ? 0.25 : 0.35,
          ),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
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
    return _GroupContainer(
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
                const SizedBox(width: 14),
              ],
              if (hasLod) ...[
                Expanded(
                  child: _LodBox(
                    options: lodOptions,
                    lodMm: lodMm,
                    onLodChanged: onLodChanged,
                  ),
                ),
                const SizedBox(width: 14),
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
            const SizedBox(height: 14),
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
    final anyActive = rippleOn || angleSnapOn;

    return _CardBox(
      isActive: anyActive,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: _FieldTitle(
                  title: 'Ripple Control',
                  description:
                      'Smooths micro-movements to reduce cursor jitter at high DPI.',
                  icon: Icons.waves,
                ),
              ),
              const SizedBox(width: 8),
              _CustomSwitch(value: rippleOn, onChanged: onRippleChanged),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: _FieldTitle(
                  title: 'Angle Snap',
                  description:
                      'Locks horizontal or vertical lines to clean straight axes.',
                  icon: Icons.straighten,
                ),
              ),
              const SizedBox(width: 8),
              _CustomSwitch(value: angleSnapOn, onChanged: onAngleSnapChanged),
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
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldTitle(
            title: 'Lift-Off Distance',
            description:
                'Sensor cut-off tracking height when the mouse is lifted.',
            icon: Icons.arrow_upward,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final opt in options)
                _SelectableChip(
                  label: '${opt.mm} mm',
                  selected: lodMm == opt.wire,
                  onTap: onLodChanged == null
                      ? null
                      : () => onLodChanged!(opt.wire),
                ),
            ],
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
    return _CardBox(
      isActive: angleTuneOn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: _FieldTitle(
                  title: 'Angle Snapping & Tune',
                  description:
                      'Rotates tracking coordinate axis to match hand grip tilt.',
                  icon: Icons.rotate_right,
                ),
              ),
              const SizedBox(width: 8),
              _CustomSwitch(value: angleTuneOn, onChanged: onAngleTuneToggled),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StepperButton(
                  icon: Icons.remove,
                  tooltip: 'Decrease angle',
                  onTap: angleTuneOn ? onAngleTuneDecrement : null,
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: angleTuneOn
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                  child: Text(angleTuneLabel),
                ),
                _StepperButton(
                  icon: Icons.add,
                  tooltip: 'Increase angle',
                  onTap: angleTuneOn ? onAngleTuneIncrement : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Refined circular icon button used for angle-tune stepper controls.
class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? theme.colorScheme.surface
                : theme.colorScheme.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? theme.colorScheme.outline.withValues(alpha: 0.4)
                  : theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 16,
            color: enabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
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
    return _CardBox(
      isActive: performance != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldTitle(
            title: 'Performance Mode',
            description:
                'Balances sensor frame-rate between maximum responsiveness and battery endurance.',
            icon: Icons.speed,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              for (final wire in options)
                _SelectableChip(
                  label: _performanceLabel(wire),
                  icon: _performanceIcon(wire),
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

  IconData _performanceIcon(int wire) {
    switch (wire) {
      case 0:
        return Icons.eco_outlined;
      case 1:
        return Icons.work_outline;
      case 2:
        return Icons.bolt;
      default:
        return Icons.speed;
    }
  }

  String _performanceLabel(int wire) {
    switch (wire) {
      case 0:
        return 'Low Performance (Eco)';
      case 1:
        return 'Office Mouse';
      case 2:
        return 'High Performance (Gaming)';
      default:
        return 'Mode $wire';
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
    return _GroupContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasButtonDebounce) ...[
                Expanded(
                  flex: 3,
                  child: _OptionsBox(
                    title: 'Button debounce delay',
                    description:
                        'Filters out unintended double-clicks caused by mechanical contact bounce.',
                    icon: Icons.timer_outlined,
                    options: buttonDebounceOptions,
                    selectedWire: debounceMs,
                    onSelected: onDebounceChanged,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              if (hasWheelInvert) ...[
                Expanded(
                  flex: 2,
                  child: _WheelBox(
                    invert: wheelInvert ?? false,
                    onInvertChanged: onWheelInvertChanged,
                  ),
                ),
              ],
            ],
          ),
          if (hasSleepTime) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _OptionsBox(
                    title: 'Sleep timer',
                    description:
                        'Inactivity timeout before entering ultra-low power standby mode.',
                    icon: Icons.bedtime_outlined,
                    options: sleepTimeOptions,
                    selectedWire: sleepSeconds,
                    onSelected: onSleepChanged,
                  ),
                ),
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
    return _CardBox(
      isActive: selectedWire != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldTitle(title: title, description: description, icon: icon),
          const SizedBox(height: 14),
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
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldTitle(
            title: 'Wheel direction',
            description:
                'Inverts scroll direction to match your personal preference.',
            icon: Icons.sync_alt,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SelectableChip(
                  label: 'Forward (Standard)',
                  icon: Icons.arrow_upward,
                  selected: !invert,
                  onTap: onInvertChanged == null
                      ? null
                      : () => onInvertChanged!(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SelectableChip(
                  label: 'Reverse (Inverted)',
                  icon: Icons.arrow_downward,
                  selected: invert,
                  onTap: onInvertChanged == null
                      ? null
                      : () => onInvertChanged!(true),
                ),
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
    this.icon,
    this.onTap,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;

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
            color: selected
                ? theme.colorScheme.primary
                : (isDark ? const Color(0xFF26282E) : Colors.white),
            borderRadius: BorderRadius.circular(10),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected
                      ? Colors.white
                      : (isDark
                            ? const Color(0xFFE0E3EB)
                            : const Color(0xFF344054)),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : (isDark
                            ? const Color(0xFFE0E3EB)
                            : const Color(0xFF344054)),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom styled switch for clean alignment and vibrant brand primary coloring.
class _CustomSwitch extends StatelessWidget {
  const _CustomSwitch({required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: theme.colorScheme.primary,
      inactiveThumbColor: isDark ? const Color(0xFFA0A5B0) : Colors.white,
      inactiveTrackColor: isDark
          ? const Color(0xFF2C2D30)
          : const Color(0xFFDDE1E6),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : (isDark ? const Color(0xFF42454D) : const Color(0xFFBAC0CA)),
      ),
    );
  }
}
