import 'package:driver_hub/i18n/strings.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppSettingsPanel extends StatelessWidget {
  const AppSettingsPanel({
    required this.lowBatteryThreshold,
    required this.onLowBatteryThresholdChanged,
    super.key,
  });

  final ValueListenable<int> lowBatteryThreshold;
  final ValueChanged<int> onLowBatteryThresholdChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsSection(title: t.appSettings.system, child: _systemSettings(context)),
          const SizedBox(height: 8),
          _SettingsSection(title: t.appSettings.help, child: _helpSettings(context)),
          const SizedBox(height: 8),
          _SettingsSection(
            title: t.appSettings.performanceSettings,
            child: _performanceSettings(context),
          ),
          const SizedBox(height: 8),
          _SettingsSection(title: t.appSettings.about, child: _aboutSettings()),
        ],
      ),
    );
  }

  Widget _systemSettings(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: 180, child: Text(t.appSettings.language)),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            initialValue: 'English',
            decoration: _dropdownDecoration(context),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            borderRadius: BorderRadius.circular(10),
            items: const [
              DropdownMenuItem(value: 'English', child: Text('English')),
            ],
            onChanged: null,
          ),
        ),
        SizedBox(width: 180, child: Text(t.appSettings.theme)),
        SizedBox(
          width: 220,
          child: TextField(
            enabled: false,
            decoration: _dropdownDecoration(context),
          ),
        ),
      ],
    );
  }

  Widget _helpSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _helpButton(context, t.appSettings.faq)),
            const SizedBox(width: 8),
            Expanded(child: _helpButton(context, t.appSettings.customerService)),
            const SizedBox(width: 8),
            Expanded(child: _helpButton(context, t.appSettings.keyTest)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _helpButton(context, t.appSettings.productManual)),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _helpButton(context, t.appSettings.driverBugFeedback),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _helpButton(context, t.appSettings.communities),
      ],
    );
  }

  Widget _performanceSettings(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: 180, child: Text(t.appSettings.lowBatteryThreshold)),
        SizedBox(
          width: 220,
          child: ValueListenableBuilder<int>(
            valueListenable: lowBatteryThreshold,
            builder: (ctx, threshold, _) => DropdownButtonFormField<int>(
              key: const Key('app-setting-threshold'),
              initialValue: threshold,
              decoration: _dropdownDecoration(ctx),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              borderRadius: BorderRadius.circular(10),
              items: const [
                DropdownMenuItem(value: 10, child: Text('10%')),
                DropdownMenuItem(value: 20, child: Text('20%')),
                DropdownMenuItem(value: 30, child: Text('30%')),
                DropdownMenuItem(value: 40, child: Text('40%')),
              ],
              onChanged: (value) {
                if (value != null) onLowBatteryThresholdChanged(value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _aboutSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.appSettings.currentVersion(version: '0.0.1')),
        const SizedBox(height: 8),
        Text(t.appSettings.officialWebsite(url: 'xxxx.com')),
      ],
    );
  }

  Widget _helpButton(BuildContext context, String label) {
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
  final isDark = theme.brightness == Brightness.dark;
  return OutlinedButton.styleFrom(
    backgroundColor: isDark ? const Color(0xFF26282E) : Colors.white,
    foregroundColor: theme.colorScheme.onSurface,
    side: BorderSide(
      color: (isDark ? const Color(0xFF3F424B) : const Color(0xFFD0D5DD)),
      width: 1.0,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    elevation: 1.5,
    shadowColor: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
  );
}

InputDecoration _dropdownDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: isDark ? const Color(0xFF26282E) : Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: (isDark ? const Color(0xFF3F424B) : const Color(0xFFD0D5DD)),
        width: 1.0,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: (isDark ? const Color(0xFF3F424B) : const Color(0xFFD0D5DD)),
        width: 1.0,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: theme.colorScheme.primary,
        width: 1.5,
      ),
    ),
  );
}
