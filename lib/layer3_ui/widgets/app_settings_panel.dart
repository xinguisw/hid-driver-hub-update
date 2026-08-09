import 'package:flutter/material.dart';

class AppSettingsPanel extends StatefulWidget {
  const AppSettingsPanel({super.key});

  @override
  State<AppSettingsPanel> createState() => _AppSettingsPanelState();
}

class _AppSettingsPanelState extends State<AppSettingsPanel> {
  static const _thresholds = <int>[10, 20, 30, 40];
  int _lowBatteryThreshold = 20;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsSection(title: 'System', child: _systemSettings()),
          const SizedBox(height: 8),
          _SettingsSection(title: 'Help', child: _helpSettings()),
          const SizedBox(height: 8),
          _SettingsSection(
            title: 'Performance Settings',
            child: _performanceSettings(),
          ),
          const SizedBox(height: 8),
          _SettingsSection(title: 'About NEWMEN HUB', child: _aboutSettings()),
        ],
      ),
    );
  }

  Widget _systemSettings() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const SizedBox(width: 180, child: Text('Language')),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            initialValue: 'English',
            decoration: const InputDecoration(isDense: true),
            items: const [
              DropdownMenuItem(value: 'English', child: Text('English')),
            ],
            onChanged: null,
          ),
        ),
        const SizedBox(width: 180, child: Text('Theme')),
        const SizedBox(
          width: 220,
          child: TextField(
            enabled: false,
            decoration: InputDecoration(isDense: true),
          ),
        ),
      ],
    );
  }

  Widget _helpSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _helpButton('FAQ')),
            const SizedBox(width: 8),
            Expanded(child: _helpButton('Customer Service')),
            const SizedBox(width: 8),
            Expanded(child: _helpButton('Key Test')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _helpButton('Product Manual')),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: _helpButton('Driver Bug Feedback')),
          ],
        ),
        const SizedBox(height: 8),
        _helpButton('NEWMEN HUB Communities'),
      ],
    );
  }

  Widget _performanceSettings() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const SizedBox(width: 180, child: Text('Low Battery Alert Threshold')),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<int>(
            key: const Key('app-setting-threshold'),
            initialValue: _lowBatteryThreshold,
            decoration: const InputDecoration(isDense: true),
            items: [
              for (final threshold in _thresholds)
                DropdownMenuItem(value: threshold, child: Text('$threshold%')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _lowBatteryThreshold = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _aboutSettings() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Current Version: 0.0.1'),
        SizedBox(height: 8),
        Text('Official Website: xxxx.com'),
      ],
    );
  }

  Widget _helpButton(String label) {
    return OutlinedButton(
      onPressed: null,
      style: _appSettingsButtonStyle(context),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Text(title), const SizedBox(height: 12), child],
      ),
    );
  }
}

ButtonStyle _appSettingsButtonStyle(BuildContext context) {
  final theme = Theme.of(context);
  return OutlinedButton.styleFrom(
    foregroundColor: theme.colorScheme.onSurface,
    side: BorderSide(color: theme.colorScheme.outline),
    shape: const StadiumBorder(),
  );
}
