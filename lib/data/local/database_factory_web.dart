import 'package:sembast_web/sembast_web.dart';

Future<Database> openDatabase(String name) => databaseFactoryWeb.openDatabase(name);

Future<void> deleteDatabase(String name) => databaseFactoryWeb.deleteDatabase(name);
