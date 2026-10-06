import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/errors/app_failure.dart';
import '../../data/collections.dart';
import '../../data/local/local_store.dart';
import '../../data/repositories/journal_repository.dart';

/// Privacy operations: data export and full account deletion.
class AccountService {
  AccountService({required this.store, required this.journal, required this.journalKeys, this.functions});

  final LocalStore store;
  final JournalRepository journal;
  final JournalKeyStore journalKeys;

  /// Null when running without Firebase (local-only mode).
  final FirebaseFunctions? functions;

  /// Writes a JSON export of everything stored for this user (journal
  /// decrypted) and returns the file.
  Future<File> exportData({required String uid}) async {
    final dump = await store.dumpAll(Collections.names.where((c) => c != 'journal_entries'));
    final journalEntries = (await journal.getAll())
        .map((e) => {'id': e.id, 'createdAt': e.createdAt.toIso8601String(), 'text': e.text})
        .toList();
    final data = {
      'format': 'lifeos-export-v1',
      'exportedAt': DateTime.now().toIso8601String(),
      'uid': uid,
      'collections': dump,
      'journal_entries': journalEntries,
    };
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/lifeos-export-${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file;
  }

  /// Deletes cloud data (server-side, including auth record, entitlements and
  /// usage), then all local data and the journal key.
  Future<void> deleteEverything() async {
    if (functions != null) {
      try {
        await functions!.httpsCallable('deleteAccount').call<Object?>();
      } on FirebaseFunctionsException catch (e) {
        throw AppFailure(FailureKind.unknown, cause: e);
      }
    }
    await store.wipe(Collections.names);
    await journalKeys.deleteKey();
  }
}
