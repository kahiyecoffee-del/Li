import 'package:sembast/sembast_memory.dart';

import 'database_factory_io.dart' if (dart.library.js_interop) 'database_factory_web.dart' as platform;
import 'local_store.dart';

/// Opens the per-user local database. Each account gets its own database so
/// data never leaks between accounts on a shared device. Mobile uses a file
/// (sembast_io); the web build uses IndexedDB (sembast_web).
abstract final class DatabaseOpener {
  static String _name(String uid) => 'lifeos_${uid.replaceAll(RegExp('[^A-Za-z0-9_-]'), '_')}.db';

  static Future<LocalStore> openForUser(String uid) async => LocalStore(await platform.openDatabase(_name(uid)));

  static Future<void> deleteForUser(String uid) => platform.deleteDatabase(_name(uid));

  /// In-memory store for tests and previews.
  static Future<LocalStore> inMemory([String name = 'test']) async =>
      LocalStore(await newDatabaseFactoryMemory().openDatabase(name));
}
