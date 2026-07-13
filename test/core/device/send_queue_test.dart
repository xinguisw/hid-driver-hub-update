import 'package:driver_hub/core/device/send_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SendQueue', () {
    test('runs concurrent enqueues in submission order', () async {
      final queue = SendQueue();
      final order = <int>[];

      // Enqueue without awaiting between calls so they contend for the queue.
      final a = queue.enqueue(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        order.add(1);
        return 1;
      });
      final b = queue.enqueue(() async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        order.add(2);
        return 2;
      });
      final c = queue.enqueue(() async {
        order.add(3);
        return 3;
      });

      expect(await Future.wait([a, b, c]), [1, 2, 3]);
      expect(order, [1, 2, 3]);
    });

    test('failed task does not block later tasks', () async {
      final queue = SendQueue();
      final order = <String>[];

      final fail = queue.enqueue(() async {
        order.add('fail');
        throw StateError('boom');
      });
      final ok = queue.enqueue(() async {
        order.add('ok');
        return 42;
      });

      await expectLater(fail, throwsA(isA<StateError>()));
      expect(await ok, 42);
      expect(order, ['fail', 'ok']);
    });

    test('returns each task result to its own caller', () async {
      final queue = SendQueue();
      final f1 = queue.enqueue(() async => 'a');
      final f2 = queue.enqueue(() async => 'b');
      expect(await f1, 'a');
      expect(await f2, 'b');
    });
  });
}
