import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:flutter/material.dart';

/// One settings group card: title + text lines (items).
class SettingsBlockCard extends StatelessWidget {
  const SettingsBlockCard({
    super.key,
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (lines.isEmpty)
              const Text('—', style: TextStyle(color: Colors.grey))
            else
              for (final line in lines) ...[
                Text(line, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
              ],
          ],
        ),
      ),
    );
  }
}

String _dash(Object? v) => v == null ? '—' : '$v';

/// Buttons feature block — present when count or list is known.
class ButtonsSettingsBlock extends StatelessWidget {
  const ButtonsSettingsBlock({super.key, required this.state});

  final DeviceSettingsState state;

  bool get _present => state.buttonCount != null || state.buttons != null;

  @override
  Widget build(BuildContext context) {
    if (!_present) return const SizedBox.shrink();
    return SettingsBlockCard(title: 'Buttons', lines: _lines(state));
  }

  static List<String> _lines(DeviceSettingsState s) {
    final list = s.buttons;
    if (list == null || list.isEmpty) return const ['—'];
    return [
      for (final b in list)
        '${b.buttonLabel ?? 'Button ${b.id}'}: ${b.actionLabel ?? '—'}',
    ];
  }
}

/// Report-rate feature block — present from options, not live Hz.
class ReportRateSettingsBlock extends StatelessWidget {
  const ReportRateSettingsBlock({super.key, required this.state});

  final DeviceSettingsState state;

  bool get _present => state.reportRateOptions != null;

  @override
  Widget build(BuildContext context) {
    if (!_present) return const SizedBox.shrink();
    return SettingsBlockCard(
      title: 'Report rate',
      lines: ['report rate: ${_dash(state.reportRateHz)} Hz'],
    );
  }
}

/// DPI summary feature block.
class DpiSettingsBlock extends StatelessWidget {
  const DpiSettingsBlock({super.key, required this.state});

  final DeviceSettingsState state;

  bool get _present => state.dpiMaxLevels != null || state.dpiMax != null;

  @override
  Widget build(BuildContext context) {
    if (!_present) return const SizedBox.shrink();
    return SettingsBlockCard(
      title: 'DPI',
      lines: [
        'DPI current level: ${_dash(state.dpiActiveIndex)}',
        'DPI active count: ${_dash(state.dpiActiveLevelCount)}',
      ],
    );
  }
}

/// DPI stage table feature block.
class DpiTableSettingsBlock extends StatelessWidget {
  const DpiTableSettingsBlock({super.key, required this.state});

  final DeviceSettingsState state;

  bool get _present => state.dpiMaxLevels != null || state.dpiLevels != null;

  @override
  Widget build(BuildContext context) {
    if (!_present) return const SizedBox.shrink();
    return SettingsBlockCard(title: 'DPI table', lines: _lines(state));
  }

  static List<String> _lines(DeviceSettingsState s) {
    final list = s.dpiLevels;
    if (list == null || list.isEmpty) return const ['—'];
    return [
      for (final d in list)
        d.y != null
            ? 'L${d.level}: X=${d.value} Y=${d.y}'
                '${d.color != null ? '  ${d.color}' : ''}'
            : 'L${d.level}: ${d.value}'
                '${d.color != null ? '  ${d.color}' : ''}',
    ];
  }
}

/// Sensor tuning feature block.
class SensorTuningSettingsBlock extends StatelessWidget {
  const SensorTuningSettingsBlock({super.key, required this.state});

  final DeviceSettingsState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasSensorTuning) return const SizedBox.shrink();
    return SettingsBlockCard(
      title: 'Sensor tuning',
      lines: [
        'ripple control: ${_dash(state.rippleOn)}',
        'angle snap: ${_dash(state.angleSnapOn)}',
      ],
    );
  }
}

/// LOD feature block.
class LodSettingsBlock extends StatelessWidget {
  const LodSettingsBlock({super.key, required this.state});

  final DeviceSettingsState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasLod) return const SizedBox.shrink();
    return SettingsBlockCard(
      title: 'LOD',
      lines: ['LOD (raw): ${_dash(state.lodMm)}'],
    );
  }
}

/// Angle tune feature block.
class AngleTuneSettingsBlock extends StatelessWidget {
  const AngleTuneSettingsBlock({super.key, required this.state});

  final DeviceSettingsState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasAngleTune) return const SizedBox.shrink();
    return SettingsBlockCard(
      title: 'Angle tune',
      lines: ['angle tune (raw): ${_dash(state.angleTune)}'],
    );
  }
}

/// Performance feature block.
class PerformanceSettingsBlock extends StatelessWidget {
  const PerformanceSettingsBlock({super.key, required this.state});

  final DeviceSettingsState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasPerformance) return const SizedBox.shrink();
    return SettingsBlockCard(
      title: 'Performance',
      lines: ['performance (raw): ${_dash(state.performance)}'],
    );
  }
}

/// Key debounce feature block.
class DebounceSettingsBlock extends StatelessWidget {
  const DebounceSettingsBlock({super.key, required this.state});

  final DeviceSettingsState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasButtonDebounce) return const SizedBox.shrink();
    return SettingsBlockCard(
      title: 'Key debounce delay',
      lines: ['debounce (raw): ${_dash(state.debounceMs)}'],
    );
  }
}

/// Sleep time feature block.
class SleepTimeSettingsBlock extends StatelessWidget {
  const SleepTimeSettingsBlock({super.key, required this.state});

  final DeviceSettingsState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasSleepTime) return const SizedBox.shrink();
    return SettingsBlockCard(
      title: 'Sleep time',
      lines: ['sleep (raw): ${_dash(state.sleepSeconds)}'],
    );
  }
}

/// Wheel invert feature block.
class WheelInvertSettingsBlock extends StatelessWidget {
  const WheelInvertSettingsBlock({super.key, required this.state});

  final DeviceSettingsState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasWheelInvert) return const SizedBox.shrink();
    return SettingsBlockCard(
      title: 'Wheel invert',
      lines: ['wheel invert: ${_dash(state.wheelInvert)}'],
    );
  }
}

/// RGB backlight feature block.
class RgbBacklightSettingsBlock extends StatelessWidget {
  const RgbBacklightSettingsBlock({super.key, required this.state});

  final DeviceSettingsState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasRgbBacklight) return const SizedBox.shrink();
    return SettingsBlockCard(title: 'RGB backlight', lines: _lines(state));
  }

  static List<String> _lines(DeviceSettingsState s) {
    return [
      'enable: ${_dash(s.rgbEnable)}',
      'mode: ${_dash(s.rgbModeId)}',
      'brightness: ${_dash(s.rgbBrightness)}',
      'speed: ${_dash(s.rgbSpeed)}',
      'R: ${_dash(s.rgbR)}',
      'G: ${_dash(s.rgbG)}',
      'B: ${_dash(s.rgbB)}',
      'RGB sleep (raw): ${_dash(s.rgbSleepTime)}',
    ];
  }
}
