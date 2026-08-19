import 'package:driver_hub/layer3_ui/theme/theme_controller.dart';
import 'package:driver_hub/i18n/strings.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// Conditional import for desktop window controls
import 'package:driver_hub/desktop_shell/window_controls_stub.dart'
    if (dart.library.io) 'package:driver_hub/desktop_shell/window_controls.dart'
    as window_controls;

/// A unified AppBar/Header bar used across all pages of Driver Hub.
///
/// Contains localized actions (language selector, theme mode toggle, settings)
/// and native desktop window controls (minimize, maximize/restore, close).
/// Window controls are only rendered when running on a desktop platform.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.onSettingsPressed,
  });

  /// Optional title widget (e.g. text). If null, defaults to showing the Newmen brand logos.
  final Widget? title;

  /// Whether to display a leading back/pop button.
  final bool showBackButton;

  /// Optional callback when the settings button is pressed.
  final VoidCallback? onSettingsPressed;

  bool get _isDesktop {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return true;
      default:
        return false;
    }
  }

  // Locale display names (extend as needed)
  static const Map<String, String> _localeNames = {
    'en': 'English',
    'zh': '简体中文',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = theme.colorScheme.onSurface;
    final secondaryIconColor = theme.colorScheme.onSurfaceVariant;

    // Build the leading/title part
    Widget leadingTitle;
    if (title != null) {
      leadingTitle = title!;
    } else {
      leadingTitle = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 30,
            height: 30,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Image.asset(
            'assets/images/newmen_transparent_logo.png',
            height: 14,
            fit: BoxFit.contain,
          ),
        ],
      );
    }

    // Wrap only the title area with GestureDetector to enable window dragging
    // without interfering with buttons.
    final titleWithDrag = GestureDetector(
      onPanStart: (_) => window_controls.startDragging(),
      child: leadingTitle,
    );

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: showBackButton && Navigator.of(context).canPop()
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: iconColor),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
          : null,
      title: titleWithDrag,
      centerTitle: false,
      actions: [
        // Language switcher
        PopupMenuButton<AppLocale>(
          icon: Icon(Icons.translate, size: 20, color: iconColor),
          tooltip: t.common.language,
          initialValue: TranslationProvider.of(context).locale,
          onSelected: (AppLocale locale) {
            LocaleSettings.setLocale(locale);
          },
          itemBuilder: (BuildContext context) {
            return AppLocale.values.map((AppLocale locale) {
              final name =
                  _localeNames[locale.languageTag] ??
                  locale.languageTag.toUpperCase();
              return PopupMenuItem<AppLocale>(value: locale, child: Text(name));
            }).toList();
          },
        ),
        // Theme toggle
        IconButton(
          icon: Icon(
            isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
            size: 20,
            color: iconColor,
          ),
          onPressed: () => ThemeController.instance.toggleTheme(),
          tooltip: isDark
              ? t.common.switchToLightMode
              : t.common.switchToDarkMode,
        ),
        // Settings (only shown if a callback is provided)
        if (onSettingsPressed != null)
          IconButton(
            icon: Icon(Icons.settings_outlined, size: 20, color: iconColor),
            onPressed: onSettingsPressed,
            tooltip: t.common.settings,
          ),
        // Desktop window controls (with divider and spacing)
        if (_isDesktop) ...[
          const SizedBox(width: 8),
          VerticalDivider(
            width: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: theme.dividerColor,
          ),
          const SizedBox(width: 16),
          ..._buildDesktopWindowControls(secondaryIconColor),
        ],
      ],
    );
  }

  /// Helper to build standard desktop window controls with adequate tap targets.
  List<Widget> _buildDesktopWindowControls(Color iconColor) {
    const controlSize = 48.0;
    return [
      SizedBox(
        width: controlSize,
        height: controlSize,
        child: IconButton(
          icon: Icon(Icons.minimize, size: 18, color: iconColor),
          onPressed: () => window_controls.minimizeWindow(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Minimize',
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: controlSize,
        height: controlSize,
        child: IconButton(
          icon: Icon(Icons.crop_square, size: 16, color: iconColor),
          onPressed: () => window_controls.toggleMaximizeWindow(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Maximize',
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: controlSize,
        height: controlSize,
        child: IconButton(
          icon: Icon(Icons.close, size: 18, color: iconColor),
          onPressed: () => window_controls.closeWindow(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Close',
        ),
      ),
      const SizedBox(width: 16),
    ];
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
