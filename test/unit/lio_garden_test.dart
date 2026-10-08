import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/lio/lio_garden.dart';

void main() {
  final now = DateTime(2026, 6, 10, 15);

  test('Lio charges, explores for two hours, then waits with a gift', () {
    expect(LioGarden.state(energy: 1, now: now, tripStart: null, openedToday: false).phase, GardenPhase.charging);
    final out = LioGarden.state(
      energy: 3,
      now: now,
      tripStart: now.subtract(const Duration(hours: 1)),
      openedToday: false,
    );
    expect(out.phase, GardenPhase.exploring);
    expect(out.backAt, DateTime(2026, 6, 10, 16));
    final back = LioGarden.state(
      energy: 3,
      now: now,
      tripStart: now.subtract(const Duration(hours: 3)),
      openedToday: false,
    );
    expect(back.phase, GardenPhase.giftWaiting);
    // Yesterday's trip does not count today.
    final old = LioGarden.state(energy: 0, now: now, tripStart: DateTime(2026, 6, 9, 20), openedToday: false);
    expect(old.phase, GardenPhase.charging);
    expect(LioGarden.state(energy: 3, now: now, tripStart: now, openedToday: true).phase, GardenPhase.opened);
  });

  test('postcards: new ones first, stable for the day, the bonus differs', () {
    final a = LioGarden.pick(now, {});
    expect(LioGarden.pick(now, {}).id, a.id);
    expect(LioGarden.pick(now, {a.id}).id, isNot(a.id));
    expect(LioGarden.pick(now, {}, salt: 1).id, isNot(a.id));
    final all = {for (final p in postcards) p.id};
    expect(all.length, postcards.length); // unique ids
    expect(postcards.map((p) => p.id), contains(LioGarden.pick(now, all).id));
  });
}
