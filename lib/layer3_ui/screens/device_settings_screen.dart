import 'package:driver_hub/layer3_ui/widgets/settings_block_card.dart';
import 'package:driver_hub/layer4_domain/device_scope.dart';
import 'package:driver_hub/layer4_domain/models/device_settings_state.dart';
import 'package:driver_hub/layer4_domain/models/discovered_card_state.dart';
import 'package:flutter/material.dart';

/// Settings for one connected mouse.
///
/// L3 only: renders L4 [DeviceSettingsState], dispatches load via
/// [DeviceScope.loadOnboardSettings]. No L1 session, no L5 codec, no raw GET.
class DeviceSettingsScreen extends StatefulWidget {
  const DeviceSettingsScreen({
    super.key,
    required this.card,
    required this.scope,
  });

  /// Snapshot of the mouse the user selected on home.
  final DiscoveredCardState card;
  final DeviceScope scope;

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  DeviceSettingsState? _state;

  @override
  void initState() {
    super.initState();
    // why: paint the values held from a previous visit so re-entry has no
    // spinner; the read below still runs and refreshes them.
    _state = widget.scope.settingsFor(widget.card);
    widget.scope.cards.addListener(_onCardsChanged);
    widget.scope.settingsVersion.addListener(_onSettingsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOnboardConfig());
  }

  @override
  void dispose() {
    widget.scope.cards.removeListener(_onCardsChanged);
    widget.scope.settingsVersion.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onCardsChanged() {
    if (!mounted) return;
    if (!widget.scope.isCardConnected(widget.card)) {
      debugPrint(
        '[settings] ${widget.card.displayName}: disconnected — pop',
      );
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {});
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final next = widget.scope.settingsFor(widget.card);
    if (next == null) return;
    setState(() => _state = next);
  }

  Future<void> _loadOnboardConfig() async {
    if (!widget.scope.isCardConnected(widget.card)) {
      debugPrint('[settings] ${widget.card.displayName}: no live session');
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    if (_state == null) {
      setState(() {
        _state = DeviceSettingsState(
          devId: widget.card.devId,
          displayName: widget.card.displayName,
          connectionMode: widget.card.connectionMode,
          loading: true,
        );
      });
    }
    debugPrint(
      '[settings] ${widget.card.displayName}: loading onboard config…',
    );
    final packed = await widget.scope.loadOnboardSettings(widget.card);
    if (!mounted) return;
    if (!widget.scope.isCardConnected(widget.card) || packed.error != null) {
      debugPrint(
        '[settings] ${widget.card.displayName}: load failed '
        '(${packed.error ?? 'no session'}) — pop home',
      );
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _state = packed);
    debugPrint(
      '[settings] ${widget.card.displayName}: onboard config done',
    );
  }

  void _popHome() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final selected = widget.scope.resolveCard(widget.card);
    // final loading = state == null || state.loading;

    return Scaffold(
      appBar: AppBar(
        title: Text(selected.displayName),
      ),
      // body: loading
      //     ? const Center(child: CircularProgressIndicator())
      //     : ListView(
      body: state == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _selectedDeviceTextSummary(selected),
                if (state.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                // if (state.buttons != null)
                //   SettingsBlockCard(
                //     title: 'Buttons',
                //     lines: _buttonLines(state),
                //   ),
                // if (state.reportRateOptions != null ||
                //     state.reportRateHz != null)
                //   SettingsBlockCard(
                //     title: 'Report rate',
                //     lines: [
                //       'report rate: ${_dash(state.reportRateHz)} Hz',
                //     ],
                //   ),
                // if (state.dpiMaxLevels != null || state.dpiLevels != null)
                //   SettingsBlockCard(
                //     title: 'DPI',
                //     lines: _dpiLines(state),
                //   ),
                // if (state.dpiLevels != null)
                //   SettingsBlockCard(
                //     title: 'DPI table',
                //     lines: _dpiTableLines(state),
                //   ),
                // if (state.hasSensorTuning)
                //   SettingsBlockCard(
                //     title: 'Sensor tuning',
                //     lines: [
                //       'ripple control: ${_dash(state.rippleOn)}',
                //       'angle snap: ${_dash(state.angleSnapOn)}',
                //     ],
                //   ),
                // if (state.hasLod)
                //   SettingsBlockCard(
                //     title: 'LOD',
                //     lines: ['LOD (raw): ${_dash(state.lodMm)}'],
                //   ),
                // if (state.hasAngleTune)
                //   SettingsBlockCard(
                //     title: 'Angle tune',
                //     lines: [
                //       'angle tune (raw): ${_dash(state.angleTune)}',
                //     ],
                //   ),
                // if (state.hasPerformance)
                //   SettingsBlockCard(
                //     title: 'Performance',
                //     lines: [
                //       'performance (raw): ${_dash(state.performance)}',
                //     ],
                //   ),
                // if (state.hasButtonDebounce)
                //   SettingsBlockCard(
                //     title: 'Key debounce delay',
                //     lines: [
                //       'debounce (raw): ${_dash(state.debounceMs)}',
                //     ],
                //   ),
                // if (state.hasSleepTime)
                //   SettingsBlockCard(
                //     title: 'Sleep time',
                //     lines: [
                //       'sleep (raw): ${_dash(state.sleepSeconds)}',
                //     ],
                //   ),
                // if (state.hasWheelInvert)
                //   SettingsBlockCard(
                //     title: 'Wheel invert',
                //     lines: [
                //       'wheel invert: ${_dash(state.wheelInvert)}',
                //     ],
                //   ),
                // if (state.hasRgbBacklight)
                //   SettingsBlockCard(
                //     title: 'RGB backlight',
                //     lines: _rgbLines(state),
                //   ),
                ButtonsSettingsBlock(state: state),
                ReportRateSettingsBlock(state: state),
                DpiSettingsBlock(state: state),
                DpiTableSettingsBlock(state: state),
                SensorTuningSettingsBlock(state: state),
                LodSettingsBlock(state: state),
                AngleTuneSettingsBlock(state: state),
                PerformanceSettingsBlock(state: state),
                DebounceSettingsBlock(state: state),
                SleepTimeSettingsBlock(state: state),
                WheelInvertSettingsBlock(state: state),
                RgbBacklightSettingsBlock(state: state),
              ],
            ),
    );
  }

  Widget _selectedDeviceTextSummary(DiscoveredCardState card) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: _popHome,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(_batteryText(card), style: _summaryLine),
              const SizedBox(height: 4),
              Text(
                'Mode: ${_modeLabel(card.connectionMode)}',
                style: _summaryLine,
              ),
              const SizedBox(height: 4),
              Text(_firmwareText(card), style: _summaryLine),
            ],
          ),
        ),
      ),
    );
  }

  String _batteryText(DiscoveredCardState card) {
    if (card.batteryPercentage < 0) return 'Battery —';
    final pct = '${card.batteryPercentage}%';
    return card.isCharging ? 'Battery $pct charging' : 'Battery $pct';
  }

  String _firmwareText(DiscoveredCardState card) {
    if (card.firmwareVersion.isEmpty) return 'Firmware —';
    return 'Firmware ${card.firmwareVersion}';
  }

  String _modeLabel(int mode) {
    if (mode == 0) return 'USB';
    if (mode == 1) return '2.4G';
    return '—';
  }

  static const _summaryLine = TextStyle(fontSize: 13, color: Colors.grey);

  // String _dash(Object? v) => v == null ? '—' : '$v';
  //
  // List<String> _buttonLines(DeviceSettingsState s) {
  //   final list = s.buttons;
  //   if (list == null || list.isEmpty) return const ['—'];
  //   return [
  //     for (final b in list)
  //       '${b.buttonLabel ?? 'Button ${b.id}'}: ${b.actionLabel ?? '—'}',
  //   ];
  // }
  //
  // List<String> _dpiLines(DeviceSettingsState s) {
  //   return [
  //     'DPI current level: ${_dash(s.dpiActiveIndex)}',
  //     'DPI active count: ${_dash(s.dpiActiveLevelCount)}',
  //   ];
  // }
  //
  // List<String> _dpiTableLines(DeviceSettingsState s) {
  //   final list = s.dpiLevels;
  //   if (list == null || list.isEmpty) return const ['—'];
  //   return [
  //     for (final d in list)
  //       d.y != null
  //           ? 'L${d.level}: X=${d.value} Y=${d.y}'
  //               '${d.color != null ? '  ${d.color}' : ''}'
  //           : 'L${d.level}: ${d.value}'
  //               '${d.color != null ? '  ${d.color}' : ''}',
  //   ];
  // }
  //
  // List<String> _rgbLines(DeviceSettingsState s) {
  //   return [
  //     'enable: ${_dash(s.rgbEnable)}',
  //     'mode: ${_dash(s.rgbModeId)}',
  //     'brightness: ${_dash(s.rgbBrightness)}',
  //     'speed: ${_dash(s.rgbSpeed)}',
  //     'R: ${_dash(s.rgbR)}',
  //     'G: ${_dash(s.rgbG)}',
  //     'B: ${_dash(s.rgbB)}',
  //     'RGB sleep (raw): ${_dash(s.rgbSleepTime)}',
  //   ];
  // }
}
