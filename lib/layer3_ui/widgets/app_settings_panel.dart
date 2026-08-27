import 'package:driver_hub/i18n/strings.g.dart';
import 'package:driver_hub/layer3_ui/theme/theme_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// App Settings page matching the UI specification.
///
/// Features:
/// - Left Sidebar: Navigation tabs (Back button, System, Help, Performance Setting, About NEWMEN HUB)
///   allowing instant jump / scroll-to-section.
/// - Right Panel: Dedicated grouped cards with spacious, overflow-proof layouts for both English & Chinese.
class AppSettingsPanel extends StatefulWidget {
  const AppSettingsPanel({
    required this.lowBatteryThreshold,
    required this.onLowBatteryThresholdChanged,
    super.key,
  });

  final ValueListenable<int> lowBatteryThreshold;
  final ValueChanged<int> onLowBatteryThresholdChanged;

  @override
  State<AppSettingsPanel> createState() => _AppSettingsPanelState();
}

class _AppSettingsPanelState extends State<AppSettingsPanel> {
  int _selectedSectionIndex = 0;
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _systemKey = GlobalKey();
  final GlobalKey _helpKey = GlobalKey();
  final GlobalKey _performanceKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

  void _scrollToSection(int index) {
    setState(() => _selectedSectionIndex = index);
    final key = switch (index) {
      0 => _systemKey,
      1 => _helpKey,
      2 => _performanceKey,
      3 => _aboutKey,
      _ => _systemKey,
    };
    final targetContext = key.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final navItems = [
      t.appSettings.system,
      t.appSettings.help,
      t.appSettings.performanceSettings,
      t.appSettings.about,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;

        if (isCompact) {
          // Single-column scrollable layout for small screens
          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SettingsGroupCard(
                  key: _systemKey,
                  title: t.appSettings.system,
                  child: _buildSystemContent(context),
                ),
                const SizedBox(height: 16),
                _SettingsGroupCard(
                  key: _helpKey,
                  title: t.appSettings.help,
                  child: _buildHelpContent(context),
                ),
                const SizedBox(height: 16),
                _SettingsGroupCard(
                  key: _performanceKey,
                  title: t.appSettings.performanceSettings,
                  child: _buildPerformanceContent(context),
                ),
                const SizedBox(height: 16),
                _SettingsGroupCard(
                  key: _aboutKey,
                  title: t.appSettings.about,
                  child: _buildAboutContent(context),
                ),
              ],
            ),
          );
        }

        // Two-column layout matching the design reference
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Sub-navigation Bar
            SizedBox(
              width: 260,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  top: 20,
                  right: 16,
                  bottom: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button item
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.chevron_left,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t.common.back,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Navigation sections
                    for (int i = 0; i < navItems.length; i++) ...[
                      _SidebarNavItem(
                        title: navItems[i],
                        isSelected: _selectedSectionIndex == i,
                        onTap: () => _scrollToSection(i),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ),

            // Vertical divider between sidebar and content
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.08,
              ),
            ),

            // Right Main Settings Content Area
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SettingsGroupCard(
                        key: _systemKey,
                        title: t.appSettings.system,
                        child: _buildSystemContent(context),
                      ),
                      const SizedBox(height: 16),
                      _SettingsGroupCard(
                        key: _helpKey,
                        title: t.appSettings.help,
                        child: _buildHelpContent(context),
                      ),
                      const SizedBox(height: 16),
                      _SettingsGroupCard(
                        key: _performanceKey,
                        title: t.appSettings.performanceSettings,
                        child: _buildPerformanceContent(context),
                      ),
                      const SizedBox(height: 16),
                      _SettingsGroupCard(
                        key: _aboutKey,
                        title: t.appSettings.about,
                        child: _buildAboutContent(context),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSystemContent(BuildContext context) {
    final currentLocale = LocaleSettings.currentLocale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language Row
        _SettingFieldRow(
          label: t.appSettings.language,
          control: _SettingsDropdownContainer<AppLocale>(
            value: currentLocale,
            items: const [
              DropdownMenuItem(
                value: AppLocale.en,
                child: Text('English', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              DropdownMenuItem(
                value: AppLocale.zh,
                child: Text('简体中文', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ],
            onChanged: (newLocale) {
              if (newLocale != null) {
                LocaleSettings.setLocale(newLocale);
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        // Theme Row
        _SettingFieldRow(
          label: t.appSettings.theme,
          control: ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.instance,
            builder: (ctx, themeMode, _) => _SettingsDropdownContainer<ThemeMode>(
              value: themeMode,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(
                    t.appSettings.lightTheme,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(
                    t.appSettings.darkTheme,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(
                    t.appSettings.systemTheme,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
              onChanged: (newMode) {
                if (newMode != null) {
                  ThemeController.instance.setThemeMode(newMode);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Row 1: FAQ, Customer Service, Key Test
        Row(
          children: [
            Expanded(
              child: _HelpButton(label: t.appSettings.faq, onTap: () {}),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HelpButton(
                label: t.appSettings.customerService,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HelpButton(label: t.appSettings.keyTest, onTap: () {}),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 2: Product Manual, Driver Bug Feedback
        Row(
          children: [
            Expanded(
              flex: 4,
              child: _HelpButton(
                label: t.appSettings.productManual,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 7,
              child: _HelpButton(
                label: t.appSettings.driverBugFeedback,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 3: Communities
        _HelpButton(label: t.appSettings.communities, onTap: () {}),
      ],
    );
  }

  Widget _buildPerformanceContent(BuildContext context) {
    return _SettingFieldRow(
      label: t.appSettings.lowBatteryThreshold,
      control: ValueListenableBuilder<int>(
        valueListenable: widget.lowBatteryThreshold,
        builder: (ctx, threshold, _) => _SettingsDropdownContainer<int>(
          key: const Key('app-setting-threshold'),
          value: threshold,
          items: const [
            DropdownMenuItem(
              value: 10,
              child: Text('10%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            DropdownMenuItem(
              value: 20,
              child: Text('20%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            DropdownMenuItem(
              value: 30,
              child: Text('30%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            DropdownMenuItem(
              value: 40,
              child: Text('40%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
          onChanged: (value) {
            if (value != null) widget.onLowBatteryThresholdChanged(value);
          },
        ),
      ),
    );
  }

  Widget _buildAboutContent(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.appSettings.currentVersion(version: '0.0.1'),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          t.appSettings.officialWebsite(url: 'xxxx.com'),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// Setting field with a fixed-width left label and aligned control on the right.
class _SettingFieldRow extends StatelessWidget {
  const _SettingFieldRow({required this.label, required this.control});

  final String label;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 230,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        control,
      ],
    );
  }
}

/// Styled group card matching the reference screenshot.
class _SettingsGroupCard extends StatelessWidget {
  const _SettingsGroupCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark
        ? const Color(0xFF222327)
        : theme.colorScheme.surface;

    final borderColor = (isDark ? Colors.white : Colors.black).withValues(
      alpha: 0.12,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Navigation item in the left sidebar.
class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedBgColor = isDark
        ? const Color(0xFF2C2E35)
        : theme.colorScheme.primary.withValues(alpha: 0.12);

    return Material(
      color: isSelected ? selectedBgColor : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : theme.colorScheme.primary)
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Help button widget matching the design screenshot.
class _HelpButton extends StatefulWidget {
  const _HelpButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_HelpButton> createState() => _HelpButtonState();
}

class _HelpButtonState extends State<_HelpButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark
        ? const Color(0xFF33353D)
        : const Color(0xFFE5E7EB);
    final hoverColor = isDark
        ? const Color(0xFF40434D)
        : const Color(0xFFD1D5DB);
    final textColor = isDark
        ? const Color(0xFFDCDFE5)
        : const Color(0xFF1F2937);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? hoverColor : baseColor,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom dropdown widget matching standard desktop dropdown box and below-the-box popup menu.
class _SettingsDropdownContainer<T> extends StatelessWidget {
  const _SettingsDropdownContainer({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = 190,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Find current selected item child
    final selectedItem = items.cast<DropdownMenuItem<T>?>().firstWhere(
      (item) => item?.value == value,
      orElse: () => items.isNotEmpty ? items.first : null,
    );

    return PopupMenuButton<T>(
      initialValue: value,
      tooltip: '',
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: (isDark ? const Color(0xFF3F424B) : const Color(0xFFD0D5DD)),
          width: 1.0,
        ),
      ),
      color: isDark ? const Color(0xFF26282E) : Colors.white,
      elevation: 6,
      constraints: BoxConstraints(minWidth: width, maxWidth: width + 40),
      onSelected: (T selected) => onChanged(selected),
      itemBuilder: (BuildContext context) {
        return items.map((item) {
          final isItemSelected = item.value == value;
          final itemBgColor = isItemSelected
              ? (isDark ? const Color(0xFF3A3D46) : const Color(0xFFE5E7EB))
              : Colors.transparent;

          return PopupMenuItem<T>(
            value: item.value,
            height: 38,
            padding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              color: itemBgColor,
              alignment: Alignment.centerLeft,
              child: DefaultTextStyle(
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontSize: 13,
                  fontWeight: isItemSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                child: item.child,
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        width: width,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1C20) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (isDark
                ? const Color(0xFF3F424B)
                : const Color(0xFFD0D5DD)),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: DefaultTextStyle(
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                child: selectedItem?.child ?? const SizedBox.shrink(),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
