import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/presentation/widgets/dealer_roulette_scheduler.dart';

void main() {
  group('DealerRouletteScheduler', () {
    test('intervalForElapsed matches fast / medium / slow phases', () {
      final scheduler = DealerRouletteScheduler(
        playerIds: const ['a', 'b'],
        winnerId: 'a',
        onHighlight: (_) {},
        onComplete: () {},
      );

      expect(
        scheduler.intervalForElapsed(Duration.zero),
        DealerRouletteScheduler.fastInterval,
      );
      expect(
        scheduler.intervalForElapsed(const Duration(milliseconds: 999)),
        DealerRouletteScheduler.fastInterval,
      );
      expect(
        scheduler.intervalForElapsed(const Duration(milliseconds: 1000)),
        DealerRouletteScheduler.mediumInterval,
      );
      expect(
        scheduler.intervalForElapsed(const Duration(milliseconds: 1999)),
        DealerRouletteScheduler.mediumInterval,
      );
      expect(
        scheduler.intervalForElapsed(const Duration(milliseconds: 2000)),
        DealerRouletteScheduler.slowInterval,
      );
    });

    test('lands on winner after total duration and calls onComplete', () {
      fakeAsync((async) {
        final highlights = <String>[];
        var completed = false;

        final scheduler = DealerRouletteScheduler(
          playerIds: const ['p1', 'p2', 'p3'],
          winnerId: 'p2',
          onHighlight: highlights.add,
          onComplete: () => completed = true,
        )..start();

        expect(scheduler.isRunning, isTrue);
        expect(highlights, isNotEmpty);

        // Just before the last slow interval would push elapsed past 2.5s.
        async.elapse(const Duration(milliseconds: 2400));
        expect(completed, isFalse);

        async.elapse(DealerRouletteScheduler.totalDuration);
        expect(completed, isTrue);
        expect(highlights.last, 'p2');
        expect(scheduler.isRunning, isFalse);
      });
    });

    test('cancel stops further ticks', () {
      fakeAsync((async) {
        final highlights = <String>[];

        final scheduler = DealerRouletteScheduler(
          playerIds: const ['p1', 'p2'],
          winnerId: 'p1',
          onHighlight: highlights.add,
          onComplete: () {},
        )..start();

        final countAfterStart = highlights.length;
        scheduler.cancel();
        async.elapse(DealerRouletteScheduler.totalDuration);

        expect(highlights, hasLength(countAfterStart));
        expect(scheduler.isRunning, isFalse);
      });
    });
  });
}
