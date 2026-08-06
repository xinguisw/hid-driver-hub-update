import 'package:driver_hub/layer2_capabilities/action_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(ActionCatalogStore.clearCache);

  group('ActionCatalogStore mouse', () {
    test('loads sections from assets/catalog/action/mouse.json', () async {
      final tab = await ActionCatalogStore.load('mouse');
      expect(tab.tab, 'mouse');
      expect(tab.sections.length, 5);
      expect(tab.sections[0].title, 'Mouse');
      expect(tab.sections[0].items.first.label, 'Disable');
      expect(tab.sections[0].items[1].id, 'mouse.left');
      expect(tab.sections[1].title, 'Mouse Action');
      expect(tab.sections[2].title, 'Mouse Wheel Action');
      expect(tab.sections[3].title, 'Multimedia');
      // Multimedia: volume + transport (7 items).
      expect(tab.sections[3].items.length, 7);
      expect(tab.sections[3].items.last.label, 'Play / Pause');
      expect(tab.sections[4].title, 'Consumer');
      // Consumer: web + app shortcuts (11 items).
      expect(tab.sections[4].items.length, 11);
      expect(tab.sections[4].items.first.id, 'mouse.web_search');
      expect(tab.sections[4].items.any((i) => i.id == 'mouse.email'), isTrue);
      expect(tab.sections[4].items.any((i) => i.id == 'mouse.my_computer'), isTrue);
    });

    test('second load hits cache', () async {
      final a = await ActionCatalogStore.load('mouse');
      final b = await ActionCatalogStore.load('mouse');
      expect(identical(a, b), isTrue);
    });

    test('loads keyboard sections', () async {
      final tab = await ActionCatalogStore.load('keyboard');
      expect(tab.tab, 'keyboard');
      expect(tab.sections.length, 3);
      expect(tab.sections[0].title, 'Letter & Symbol & Number keys');
      expect(tab.sections[0].items.first.label, 'A');
      expect(tab.sections[1].title, 'Numeric Keypad Keys');
      expect(tab.sections[2].title, 'Modifier Key');
      expect(tab.sections[2].items.first.label, 'CapsLk');
    });

    test('loads special combination layout', () async {
      final tab = await ActionCatalogStore.load('special');
      expect(tab.tab, 'special');
      expect(tab.layout, 'combination');
      expect(tab.sections.single.title, 'Combination Keys');
      final mods = tab.sections.single.items
          .where((i) => i.role == 'modifier')
          .map((i) => i.label)
          .toList();
      expect(mods, ['Alt', 'Ctrl', 'Win', 'Shift']);
      expect(
        tab.sections.single.items.where((i) => i.role == 'any_key').single.label,
        'Any key',
      );
    });
  });
}
