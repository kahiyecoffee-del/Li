import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/sembast_memory.dart';

import 'local_store.dart';

/// Opens the per-user local database. Each account gets its own file so data
/// never leaks between accounts on a shared device.
abstract final class DatabaseOpener {
  static Future<LocalStore> openForUser(String uid) async {
    final dir = await getApplicationSupportDirectory();
    final safe = uid.replaceAll(RegExp('[^A-Za-z0-9_-]'), '_');
    final db = await databaseFactoryIo.openDatabase(p.join(dir.path, 'lifeos_$safe.db'));
    return LocalStore(db);
  }

  static Future<void> deleteForUser(String uid) async {
    final dir = await getApplicationSupportDirectory();
    final safe = uid.replaceAll(RegExp('[^A-Za-z0-9_-]'), '_');
    await databaseFactoryIo.deleteDatabase(p.join(dir.path, 'lifeos_$safe.db'));
  }

  /// In-memory store for tests and previews.
  static Future<LocalStore> inMemory([String name = 'test']) async =>
      LocalStore(await newDatabaseFactoryMemory().openDatabase(name));
}
