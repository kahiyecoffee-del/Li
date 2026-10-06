import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/data/local/database_opener.dart';
import 'package:lifeos/data/local/local_store.dart';
import 'package:lifeos/data/repositories/repository.dart';
import 'package:lifeos/data/sync/sync_engine.dart';
import 'package:lifeos/domain/models/task_item.dart';

import 'fake_gateway.dart';

TaskItem t(String id, String title) =>
    TaskItem(id: id, updatedAt: DateTime(2026), title: title, createdAt: DateTime(2026));

void main() {
  late FakeGateway cloud;
  var dbSeq = 0;

  Future<(LocalStore, Repository<TaskItem>, SyncEngine)> device(DateTime Function() clock) async {
    final store = await DatabaseOpener.inMemory('d${dbSeq++}');
    final repo = Repository(store, TaskItem.codec, clock: clock);
    final sync = SyncEngine(store: store, gateway: cloud, uid: 'u1', collections: const ['tasks'], clock: clock);
    return (store, repo, sync);
  }

  setUp(() => cloud = FakeGateway());

  test('local writes are queued and pushed; outbox drains', () async {
    final (store, repo, sync) = await device(() => DateTime(2026, 1, 1, 10));
    await repo.save(t('a', 'Gym'));
    expect(await store.outboxCount(), 1);
    final r = await sync.sync();
    expect(r.pushed, 1);
    expect(await store.outboxCount(), 0);
    expect(cloud.doc('u1', 'tasks', 'a')!['title'], 'Gym');
  });

  test('offline: data stays local and queued, then syncs when back online', () async {
    final (store, repo, sync) = await device(() => DateTime(2026, 1, 1, 10));
    cloud.offline = true;
    await repo.save(t('a', 'Read'));
    await expectLater(sync.sync(), throwsException);
    expect(sync.currentStatus, SyncStatus.error);
    expect((await repo.get('a'))!.title, 'Read'); // still usable offline
    expect(await store.outboxCount(), 1);
    cloud.offline = false;
    await sync.sync();
    expect(await store.outboxCount(), 0);
    expect(cloud.doc('u1', 'tasks', 'a'), isNotNull);
  });

  test('two devices converge; newest edit wins (LWW)', () async {
    var now = DateTime(2026, 1, 1, 10);
    final (_, repoA, syncA) = await device(() => now);
    final (_, repoB, syncB) = await device(() => now);

    await repoA.save(t('x', 'from A'));
    await syncA.sync();
    await syncB.sync();
    expect((await repoB.get('x'))!.title, 'from A');

    // Both edit offline; B edits later.
    now = DateTime(2026, 1, 1, 11);
    await repoA.save(t('x', 'A edit'));
    now = DateTime(2026, 1, 1, 12);
    await repoB.save(t('x', 'B edit'));

    // B syncs first, then A (whose older edit must lose).
    await syncB.sync();
    final rA = await syncA.sync();
    expect(rA.pushed, 1); // A's edit was uploaded before pulling...
    await syncB.sync();
    await syncA.sync();
    expect((await repoA.get('x'))!.title, 'B edit');
    expect((await repoB.get('x'))!.title, 'B edit');
    expect(cloud.doc('u1', 'tasks', 'x')!['title'], 'B edit');
  });

  test('deletes propagate as tombstones', () async {
    var now = DateTime(2026, 1, 1, 10);
    final (_, repoA, syncA) = await device(() => now);
    final (_, repoB, syncB) = await device(() => now);
    await repoA.save(t('x', 'temp'));
    await syncA.sync();
    await syncB.sync();
    now = DateTime(2026, 1, 1, 11);
    await repoA.delete('x');
    await syncA.sync();
    await syncB.sync();
    expect(await repoB.get('x'), isNull);
    expect(cloud.doc('u1', 'tasks', 'x')!['deleted'], isTrue);
  });

  test('older remote edit does not overwrite a newer local one', () {
    final local = {'id': 'x', 'updatedAt': 200, 'deleted': false};
    final remote = {'id': 'x', 'updatedAt': 100, 'deleted': false};
    expect(identical(SyncEngine.resolve(local, remote), local), isTrue);
    expect(identical(SyncEngine.resolve(null, remote), remote), isTrue);
    final tomb = {'id': 'x', 'updatedAt': 100, 'deleted': true};
    expect(identical(SyncEngine.resolve(tomb, remote), tomb), isTrue);
  });

  test('updatedAt is strictly increasing within the same millisecond', () async {
    final (store, repo, _) = await device(() => DateTime(2026, 1, 1, 10));
    await repo.save(t('a', 'one'));
    await repo.save(t('a', 'two'));
    final rec = await store.get('tasks', 'a');
    expect(rec!['updatedAt'], DateTime(2026, 1, 1, 10).millisecondsSinceEpoch + 1);
  });

  test('watchAll excludes tombstones', () async {
    final (_, repo, _) = await device(() => DateTime(2026, 1, 1, 10));
    await repo.save(t('a', 'one'));
    await repo.save(t('b', 'two'));
    await repo.delete('a');
    final list = await repo.watchAll().first;
    expect(list.map((e) => e.id), ['b']);
  });
}
