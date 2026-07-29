import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One row in an action-catalog section (static product UI list).
///
/// L2 blueprint only — ids are catalog keys, not HID frames.
class ActionCatalogItem {
  final String id;
  final String label;

  const ActionCatalogItem({required this.id, required this.label});

  factory ActionCatalogItem.fromJson(Map<String, dynamic> json) {
    return ActionCatalogItem(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }
}

/// Grouped rows under one section title (e.g. "Mouse Action").
class ActionCatalogSection {
  final String title;
  final List<ActionCatalogItem> items;

  const ActionCatalogSection({required this.title, required this.items});

  factory ActionCatalogSection.fromJson(Map<String, dynamic> json) {
    return ActionCatalogSection(
      title: json['title'] as String,
      items: (json['items'] as List)
          .map((e) => ActionCatalogItem.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

/// One action-catalog tab payload (e.g. Mouse tab).
class ActionCatalogTab {
  final String id;
  final String tab;
  final List<ActionCatalogSection> sections;

  const ActionCatalogTab({
    required this.id,
    required this.tab,
    required this.sections,
  });

  factory ActionCatalogTab.fromJson(Map<String, dynamic> json) {
    return ActionCatalogTab(
      id: json['id'] as String,
      tab: json['tab'] as String,
      sections: (json['sections'] as List)
          .map((e) => ActionCatalogSection.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

/// Loads static action-catalog JSON from [assets/catalog/action/].
///
/// Same pattern as [DeviceCapabilityStore]: cache after first load; no HID.
class ActionCatalogStore {
  ActionCatalogStore._();

  static const _dir = 'assets/catalog/action';

  static final Map<String, ActionCatalogTab> _byTab = {};

  static String assetPathForTab(String tab) =>
      '$_dir/${tab.toLowerCase()}.json';

  /// Loads e.g. `mouse` → `assets/catalog/action/mouse.json`.
  static Future<ActionCatalogTab> load(String tab) async {
    final key = tab.toLowerCase();
    final cached = _byTab[key];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(assetPathForTab(key));
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final parsed = ActionCatalogTab.fromJson(json);
    _byTab[key] = parsed;
    return parsed;
  }

  /// Cached tab or null if never loaded.
  static ActionCatalogTab? forTab(String tab) => _byTab[tab.toLowerCase()];

  /// Test/helper: drop cache.
  static void clearCache() => _byTab.clear();
}
