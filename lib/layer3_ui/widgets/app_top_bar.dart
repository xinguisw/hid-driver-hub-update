import 'package:driver_hub/i18n/strings.g.dart';
import 'package:flutter/material.dart';

/// Application top bar — a pure atom (CDD).
///
/// Renders the app title and a locale-switcher popup menu. No lifecycle,
/// no data; drop it as [Scaffold.appBar] wherever needed.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('driver_hub'),
      actions: [
        PopupMenuButton<AppLocale>(
          icon: const Icon(Icons.translate, size: 20),
          tooltip: t.common.language,
          initialValue: TranslationProvider.of(context).locale,
          onSelected: (AppLocale locale) {
            LocaleSettings.setLocale(locale);
          },
          itemBuilder: (BuildContext context) {
            return AppLocale.values.map((AppLocale locale) {
              String name = locale.languageTag.toUpperCase();
              if (locale.languageTag == 'en') name = 'English';
              if (locale.languageTag == 'zh') name = '简体中文';
              return PopupMenuItem<AppLocale>(value: locale, child: Text(name));
            }).toList();
          },
        ),
      ],
    );
  }
}
