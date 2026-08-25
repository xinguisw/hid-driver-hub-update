import 'package:driver_hub/layer3_ui/screens/app_settings_screen.dart';
import 'package:driver_hub/layer3_ui/widgets/hub_button_mapping_panel.dart';
import 'package:driver_hub/layer3_ui/theme/theme_controller.dart';
import 'package:driver_hub/i18n/strings.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
// Conditional import for desktop window controls
import 'package:driver_hub/desktop_shell/window_controls_stub.dart'
    if (dart.library.io) 'package:driver_hub/desktop_shell/window_controls.dart'
    as window_controls;

/// A unified AppBar/Header bar used across all pages of Driver Hub.
///
/// Contains localized actions (language selector, theme mode toggle, settings)
/// and native desktop window controls (minimize, maximize/restore, close).
/// Window controls are only rendered when running on a desktop platform.
class AppTopBar extends StatefulWidget implements PreferredSizeWidget {
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

  @override
  State<AppTopBar> createState() => _AppTopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppTopBarState extends State<AppTopBar> with WindowListener {
  // Track whether the window is currently maximized to swap the maximize/restore icon
  bool _isMaximized = false;

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

  @override
  void initState() {
    super.initState();
    // Register listener so that we can react to native window state transitions
    if (_isDesktop) {
      windowManager.addListener(this);
      _checkMaximizedState();
    }
  }

  @override
  void dispose() {
    // Unregister to prevent memory leaks or exceptions on disposed widgets
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  // Eagerly check state on initialization since listeners only fire on state change transitions
  Future<void> _checkMaximizedState() async {
    final maximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = maximized;
      });
    }
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
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
    if (widget.title != null) {
      leadingTitle = widget.title!;
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

    // Wrap the title and all empty middle space of the top bar with GestureDetector.
    // By using width: double.infinity, height: kToolbarHeight, and HitTestBehavior.translucent,
    // we make the entire empty bar area draggable and double-clickable to maximize/restore,
    // while keeping interactive action buttons working properly.
    final titleWithDrag = GestureDetector(
      onPanStart: (_) => window_controls.startDragging(),
      onDoubleTap: () => window_controls.toggleMaximizeWindow(),
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: double.infinity,
        height: kToolbarHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: leadingTitle,
        ),
      ),
    );

    return TapRegion(
      groupId: hubButtonMappingTapRegionId,
      child: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 24,
        automaticallyImplyLeading: false,
        leading: widget.showBackButton
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
                return PopupMenuItem<AppLocale>(
                  value: locale,
                  child: Text(name),
                );
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
          // Settings (language, theme, app settings in top bar)
          IconButton(
            icon: Icon(Icons.settings_outlined, size: 20, color: iconColor),
            onPressed: widget.onSettingsPressed ??
                () {
                  if (context.findAncestorWidgetOfExactType<AppSettingsScreen>() != null) {
                    return;
                  }
                  final route = ModalRoute.of(context);
                  if (route?.settings.name == '/app_settings') {
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/app_settings'),
                      builder: (_) => const AppSettingsScreen(),
                    ),
                  );
                },
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
          ] else ...[
            const SizedBox(width: 24),
          ],
        ],
      ),
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
          tooltip: t.windowControls.minimize,
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: controlSize,
        height: controlSize,
        child: IconButton(
          icon: Icon(
            _isMaximized ? Icons.filter_none : Icons.crop_square,
            size: _isMaximized ? 14 : 16,
            color: iconColor,
          ),
          onPressed: () => window_controls.toggleMaximizeWindow(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: _isMaximized
              ? t.windowControls.restore
              : t.windowControls.maximize,
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
          tooltip: t.windowControls.close,
        ),
      ),
      const SizedBox(width: 16),
    ];
  }
}
