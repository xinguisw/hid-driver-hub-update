/// Hardcoded **Mouse** tab action catalog (skeleton UI data).
///
/// L3 display only — labels/groups for the mapping panel. No L5 codec import,
/// no HID. Wire/stage on row pick is a later L4 event path.
class HubCatalogSection {
  final String title;
  final List<HubCatalogItem> items;

  const HubCatalogSection({required this.title, required this.items});
}

class HubCatalogItem {
  /// Stable id for selection highlight (not a wire opcode).
  final String id;
  final String label;

  const HubCatalogItem({required this.id, required this.label});
}

/// Mouse tab body — order and wording match product ref (manager screenshot).
const List<HubCatalogSection> kHubMouseActionCatalog = [
  HubCatalogSection(
    title: 'Mouse',
    items: [
      HubCatalogItem(id: 'mouse.disable', label: 'Disable'),
      HubCatalogItem(id: 'mouse.left', label: 'Left Button'),
      HubCatalogItem(id: 'mouse.right', label: 'Right Button'),
      HubCatalogItem(id: 'mouse.middle', label: 'Middle Button'),
      HubCatalogItem(id: 'mouse.forward', label: 'Forward Button'),
      HubCatalogItem(id: 'mouse.backward', label: 'Backward Button'),
    ],
  ),
  HubCatalogSection(
    title: 'Mouse Action',
    items: [
      HubCatalogItem(id: 'mouse.report_rate_cycle', label: 'Report Rate Cycle'),
      HubCatalogItem(id: 'mouse.dpi_cycle', label: 'DPI Cycle'),
      HubCatalogItem(id: 'mouse.dpi_up', label: 'DPI +'),
      HubCatalogItem(id: 'mouse.dpi_down', label: 'DPI -'),
    ],
  ),
  HubCatalogSection(
    title: 'Mouse Wheel Action',
    items: [
      HubCatalogItem(id: 'mouse.wheel_up', label: 'Wheel Up'),
      HubCatalogItem(id: 'mouse.wheel_down', label: 'Wheel Down'),
      HubCatalogItem(id: 'mouse.tilt_left', label: 'Tilt Left'),
      HubCatalogItem(id: 'mouse.tilt_right', label: 'Tilt Right'),
    ],
  ),
  HubCatalogSection(
    title: 'Multimedia',
    items: [
      HubCatalogItem(id: 'mouse.volume_up', label: 'Volume +'),
      HubCatalogItem(id: 'mouse.volume_down', label: 'Volume -'),
      HubCatalogItem(id: 'mouse.volume_mute', label: 'Volume Mute'),
    ],
  ),
];
