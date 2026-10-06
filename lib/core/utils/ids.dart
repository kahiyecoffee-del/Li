import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Generates a random, collision-resistant document id.
String newId() => _uuid.v4();
