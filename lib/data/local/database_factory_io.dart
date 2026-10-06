import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> openDatabase(String name) async {
  final dir = await getApplicationSupportDirectory();
  return databaseFactoryIo.openDatabase(p.join(dir.path, name));
}

Future<void> deleteDatabase(String name) async {
  final dir = await getApplicationSupportDirectory();
  await databaseFactoryIo.deleteDatabase(p.join(dir.path, name));
}
