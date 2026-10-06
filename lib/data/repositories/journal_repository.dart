import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/wellbeing.dart';
import 'repository.dart';

/// Holds the device-bound journal key.
abstract class JournalKeyStore {
  Future<List<int>> getOrCreateKey();
  Future<void> deleteKey();
}

/// Android Keystore / iOS Keychain backed key storage.
class SecureJournalKeyStore implements JournalKeyStore {
  SecureJournalKeyStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _keyName = 'lifeos_journal_key_v1';

  @override
  Future<List<int>> getOrCreateKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null) return base64Decode(existing);
    final key = await AesGcm.with256bits().newSecretKey();
    final bytes = await key.extractBytes();
    await _storage.write(key: _keyName, value: base64Encode(bytes));
    return bytes;
  }

  @override
  Future<void> deleteKey() => _storage.delete(key: _keyName);
}

/// In-memory key store for tests.
class MemoryJournalKeyStore implements JournalKeyStore {
  List<int>? _key;

  @override
  Future<List<int>> getOrCreateKey() async => _key ??= await (await AesGcm.with256bits().newSecretKey()).extractBytes();

  @override
  Future<void> deleteKey() async => _key = null;
}

/// Journal entries are private: never synced, and their text is encrypted at
/// rest with AES-256-GCM using a key kept in the platform keystore.
///
/// Limitation: the key is device-bound, so entries do not follow the user to
/// a new device (they are included decrypted in the user's data export).
class JournalRepository {
  JournalRepository(this._repo, this._keys);

  final Repository<JournalEntry> _repo;
  final JournalKeyStore _keys;
  final _algo = AesGcm.with256bits();
  static const _prefix = 'enc1:';

  Future<SecretKey> _key() async => SecretKey(await _keys.getOrCreateKey());

  Future<String> _encrypt(String plain) async {
    final box = await _algo.encrypt(utf8.encode(plain), secretKey: await _key());
    return '$_prefix${base64Encode(box.concatenation())}';
  }

  Future<String> _decrypt(String stored) async {
    if (!stored.startsWith(_prefix)) return stored;
    try {
      final box = SecretBox.fromConcatenation(
        base64Decode(stored.substring(_prefix.length)),
        nonceLength: _algo.nonceLength,
        macLength: _algo.macAlgorithm.macLength,
      );
      return utf8.decode(await _algo.decrypt(box, secretKey: await _key()));
    } on SecretBoxAuthenticationError {
      return '';
    }
  }

  Future<JournalEntry> _open(JournalEntry e) async =>
      JournalEntry(id: e.id, updatedAt: e.updatedAt, createdAt: e.createdAt, text: await _decrypt(e.text));

  Stream<List<JournalEntry>> watchAll() => _repo.watchAll().asyncMap((list) async {
    final out = await Future.wait(list.map(_open));
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  });

  Future<List<JournalEntry>> getAll() async => Future.wait((await _repo.getAll()).map(_open));

  Future<void> save(JournalEntry e) async =>
      _repo.save(JournalEntry(id: e.id, updatedAt: e.updatedAt, createdAt: e.createdAt, text: await _encrypt(e.text)));

  Future<void> delete(String id) => _repo.delete(id);

  Future<void> deleteAll() => _repo.deleteAll();

  /// Raw stored text (for tests: proves nothing is kept in plain text).
  Future<String?> rawText(String id) async => (await _repo.get(id))?.text;
}
