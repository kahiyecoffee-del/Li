import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/data/local/database_opener.dart';
import 'package:lifeos/data/repositories/journal_repository.dart';
import 'package:lifeos/data/repositories/repository.dart';
import 'package:lifeos/domain/models/wellbeing.dart';

void main() {
  test('journal text is encrypted at rest, never synced, and decrypts', () async {
    final store = await DatabaseOpener.inMemory('journal');
    final repo = JournalRepository(Repository(store, JournalEntry.codec), MemoryJournalKeyStore());
    await repo.save(
      JournalEntry(id: 'j1', updatedAt: DateTime(2026), createdAt: DateTime(2026), text: 'Bugün kötü geçti.'),
    );

    final raw = await repo.rawText('j1');
    expect(raw, startsWith('enc1:'));
    expect(raw, isNot(contains('kötü')));
    expect(await store.outboxCount(), 0, reason: 'journal must not be queued for cloud sync');

    final all = await repo.getAll();
    expect(all.single.text, 'Bugün kötü geçti.');

    await repo.delete('j1');
    expect(await repo.getAll(), isEmpty);
    expect(await store.get('journal_entries', 'j1'), isNull, reason: 'local-only data is hard-deleted');
  });
}
