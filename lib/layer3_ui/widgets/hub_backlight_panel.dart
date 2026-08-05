import 'package:driver_hub/layer2_capabilities/capabilities.dart';
import 'package:flutter/material.dart';

/// Backlight Setting page — RGB backlight controls.
///
/// L3 only. Pure skeleton: reads values from state via constructor, paints
/// the layout. No events, no staging, no commit (wiring comes later).
/// Structure: outer group container → rows inside.
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
  final int? rgbSleepTime;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Backlight'),
          const SizedBox(height: 8),
          _BacklightGroup(
            rgbModes: rgbModes ?? const [],
            rgbEnable: rgbEnable ?? false,
            rgbModeId: rgbModeId,
            rgbBrightness: rgbBrightness,
            rgbBrightnessLevels: rgbBrightnessLevels ?? 5,
            rgbSpeed: rgbSpeed,
            rgbSpeedLevels: rgbSpeedLevels ?? 5,
            rgbR: rgbR,
            rgbG: rgbG,
            rgbB: rgbB,
            rgbSleepTime: rgbSleepTime,
          ),
        ],
      ),
    );
  }
}

/// Outer group container for backlight.
class _BacklightGroup extends StatelessWidget {
  const _BacklightGroup({
    required this.rgbModes,
    required this.rgbEnable,
    required this.rgbModeId,
    required this.rgbBrightness,
    required this.rgbBrightnessLevels,
    required this.rgbSpeed,
    required this.rgbSpeedLevels,
    required this.rgbR,
    required this.rgbG,
    required this.rgbB,
    required this.rgbSleepTime,
  });

  final List<RgbMode> rgbModes;
  final bool rgbEnable;
  final int? rgbModeId;
  final int? rgbBrightness;
  final int rgbBrightnessLevels;
  final int? rgbSpeed;
  final int rgbSpeedLevels;
  final int? rgbR;
  final int? rgbG;
  final int? rgbB;
  final int? rgbSleepTime;

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
          _ModeRow(rgbModes: rgbModes, rgbModeId: rgbModeId),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LevelBox(
                  title: 'Brightness',
                  levels: rgbBrightnessLevels,
                  selected: rgbBrightness,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LevelBox(
                  title: 'Speed',
                  levels: rgbSpeedLevels,
                  selected: rgbSpeed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ColorBox(r: rgbR, g: rgbG, b: rgbB),
          const SizedBox(height: 8),
          _PowerSavingBox(rgbSleepTime: rgbSleepTime),
        ],
      ),
    );
  }
}

/// RGB mode row — one box per catalog mode (skeleton: inert).
class _ModeRow extends StatelessWidget {
  const _ModeRow({required this.rgbModes, required this.rgbModeId});

  final List<RgbMode> rgbModes;
  final int? rgbModeId;

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
          const Text('Mode'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final mode in rgbModes)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: mode.id == rgbModeId
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    mode.nameKey,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Brightness / Speed level box (skeleton: inert).
class _LevelBox extends StatelessWidget {
  const _LevelBox({
    required this.title,
    required this.levels,
    required this.selected,
  });

  final String title;
  final int levels;
  final int? selected;

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
              for (var i = 0; i < levels; i++)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: i == selected
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(100 * i / (levels - 1)).round()}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// R/G/B color box (skeleton: inert).
class _ColorBox extends StatelessWidget {
  const _ColorBox({required this.r, required this.g, required this.b});

  final int? r;
  final int? g;
  final int? b;

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
          const Text('Color'),
          const SizedBox(width: 16),
          Text('R ${r ?? 0}'),
          const SizedBox(width: 12),
          Text('G ${g ?? 0}'),
          const SizedBox(width: 12),
          Text('B ${b ?? 0}'),
        ],
      ),
    );
  }
}

/// Backlight power-saving timeout box (skeleton: inert).
///
/// NOTE: this is the RGB power-saving idle timeout, NOT the device sleep time
/// (0xD4 byte 12, handled in Parameter Setting).
class _PowerSavingBox extends StatelessWidget {
  const _PowerSavingBox({required this.rgbSleepTime});

  final int? rgbSleepTime;

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
          const Text('Power saving'),
          const SizedBox(width: 16),
          Text('${rgbSleepTime ?? 0} sec'),
        ],
      ),
    );
  }
}
