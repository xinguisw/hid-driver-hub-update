import 'package:flutter/material.dart';

/// Performance Setting page — DPI levels + Report Rate.
///
/// L3 only. Dispatches events to BLoC.
/// Structure: outer group container → rows inside.
/// All rows are data-driven for future L2 capability filtering.
class HubPerformancePanel extends StatelessWidget {
  const HubPerformancePanel({
    super.key,
    this.reportRateOptions,
    this.reportRateHz,
    this.reportRateStaging,
    this.onReportRateChanged,
  });

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
          const _DpiSettingsGroup(),
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
  const _DpiSettingsGroup();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Skeleton: 8 levels, all active
    const levelCount = 8;
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
              for (var i = 1; i <= levelCount; i++)
                _LevelChip(index: i),
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
                children: List.generate(levelCount, (index) {
                  return _DpiSliderRow(index: index + 1);
                }),
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
  const _LevelChip({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: index == 1 ? theme.colorScheme.primary : Colors.transparent,
        border: Border.all(
          color: index == 1
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$index',
        style: TextStyle(
          color: index == 1
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          fontSize: 12,
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
  const _DpiSliderRow({required this.index});

  final int index;

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
              Text('DPI $index'),
              const Spacer(),
              Text('${(index * 800)}'),
            ],
          ),
          const SizedBox(height: 4),
          Slider(
            value: (index * 800).toDouble(),
            min: 500,
            max: 15000,
            onChanged: null,
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('500', style: TextStyle(fontSize: 9)),
              Text('1500', style: TextStyle(fontSize: 9)),
              Text('2500', style: TextStyle(fontSize: 9)),
              Text('3500', style: TextStyle(fontSize: 9)),
              Text('4500', style: TextStyle(fontSize: 9)),
              Text('15000', style: TextStyle(fontSize: 9)),
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
