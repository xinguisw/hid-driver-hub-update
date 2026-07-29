import 'package:driver_hub/layer2_capabilities/action_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(ActionCatalogStore.clearCache);

  group('ActionCatalogStore mouse', () {
    test('loads sections from assets/catalog/action/mouse.json', () async {
      final tab = await ActionCatalogStore.load('mouse');
      expect(tab.tab, 'mouse');
      expect(tab.sections.length, 4);
      expect(tab.sections[0].title, 'Mouse');
      expect(tab.sections[0].items.first.label, 'Disable');
      expect(tab.sections[0].items[1].id, 'mouse.left');
      expect(tab.sections[1].title, 'Mouse Action');
      expect(tab.sections[2].title, 'Mouse Wheel Action');
      expect(tab.sections[3].title, 'Multimedia');
      expect(tab.sections[3].items.last.label, 'Volume Mute');
    });

    test('second load hits cache', () async {
      final a = await ActionCatalogStore.load('mouse');
      final b = await ActionCatalogStore.load('mouse');
      expect(identical(a, b), isTrue);
    });
  });
}
