import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_failure.dart';
import '../../core/utils/ids.dart';

enum AuthProviderType { anonymous, email, google, local }

class AppUser {
  const AppUser({required this.uid, required this.provider, this.email, this.displayName});

  final String uid;
  final AuthProviderType provider;
  final String? email;
  final String? displayName;

  bool get isAnonymous => provider == AuthProviderType.anonymous || provider == AuthProviderType.local;

  /// Local users exist when Firebase is not configured: everything works on
  /// device, but there is no cloud sync, AI or purchases.
  bool get isLocalOnly => provider == AuthProviderType.local;
}

abstract class AuthService {
  Stream<AppUser?> get userChanges;
  AppUser? get currentUser;

  Future<AppUser> signInAnonymously();
  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> createAccountWithEmail(String email, String password);
  Future<AppUser> signInWithGoogle();

  /// Upgrades an anonymous account, keeping its uid and data.
  Future<AppUser> linkEmail(String email, String password);
  Future<AppUser> linkGoogle();
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();

  /// Deletes the auth record (data deletion is done by the backend first).
  Future<void> deleteCurrentUser();

  Future<String?> idToken();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);

  final fb.FirebaseAuth _auth;
  bool _googleInitialized = false;

  static AppUser? _map(fb.User? u) {
    if (u == null) return null;
    final providers = u.providerData.map((p) => p.providerId).toSet();
    final type = u.isAnonymous
        ? AuthProviderType.anonymous
        : providers.contains('google.com')
        ? AuthProviderType.google
        : AuthProviderType.email;
    return AppUser(uid: u.uid, provider: type, email: u.email, displayName: u.displayName);
  }

  @override
  Stream<AppUser?> get userChanges => _auth.userChanges().map(_map);

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  Future<AppUser> _run(Future<fb.UserCredential> Function() f) async {
    try {
      final cred = await f();
      return _map(cred.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AppFailure(_kind(e.code), cause: e);
    }
  }

  static FailureKind _kind(String code) => switch (code) {
    'email-already-in-use' || 'credential-already-in-use' || 'provider-already-linked' => FailureKind.emailInUse,
    'wrong-password' || 'user-not-found' || 'invalid-credential' || 'invalid-email' => FailureKind.wrongCredentials,
    'weak-password' => FailureKind.weakPassword,
    'requires-recent-login' => FailureKind.requiresRecentLogin,
    'network-request-failed' => FailureKind.network,
    'too-many-requests' => FailureKind.rateLimited,
    _ => FailureKind.unknown,
  };

  @override
  Future<AppUser> signInAnonymously() => _run(_auth.signInAnonymously);

  @override
  Future<AppUser> signInWithEmail(String email, String password) =>
      _run(() => _auth.signInWithEmailAndPassword(email: email.trim(), password: password));

  @override
  Future<AppUser> createAccountWithEmail(String email, String password) =>
      _run(() => _auth.createUserWithEmailAndPassword(email: email.trim(), password: password));

  Future<fb.AuthCredential> _googleCredential() async {
    final g = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await g.initialize(
        serverClientId: AppConfig.googleServerClientId.isEmpty ? null : AppConfig.googleServerClientId,
      );
      _googleInitialized = true;
    }
    try {
      final account = await g.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AppFailure(FailureKind.unknown);
      return fb.GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      throw AppFailure(
        e.code == GoogleSignInExceptionCode.canceled ? FailureKind.cancelled : FailureKind.unknown,
        cause: e,
      );
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final cred = await _googleCredential();
    return _run(() => _auth.signInWithCredential(cred));
  }

  @override
  Future<AppUser> linkEmail(String email, String password) {
    final user = _auth.currentUser;
    if (user == null) throw const AppFailure(FailureKind.unauthenticated);
    return _run(
      () => user.linkWithCredential(fb.EmailAuthProvider.credential(email: email.trim(), password: password)),
    );
  }

  @override
  Future<AppUser> linkGoogle() async {
    final user = _auth.currentUser;
    if (user == null) throw const AppFailure(FailureKind.unauthenticated);
    final cred = await _googleCredential();
    return _run(() => user.linkWithCredential(cred));
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw AppFailure(_kind(e.code), cause: e);
    }
  }

  @override
  Future<void> signOut() async {
    if (_googleInitialized) await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  @override
  Future<void> deleteCurrentUser() async {
    try {
      await _auth.currentUser?.delete();
    } on fb.FirebaseAuthException catch (e) {
      // The backend deletes the auth record too; "user-not-found" is fine.
      if (e.code != 'user-not-found') throw AppFailure(_kind(e.code), cause: e);
    }
  }

  @override
  Future<String?> idToken() async => _auth.currentUser?.getIdToken();
}

/// Device-only identity used when Firebase is not configured (e.g. local
/// development before `google-services.json` is added).
class LocalAuthService implements AuthService {
  LocalAuthService(this._prefs);

  final SharedPreferences _prefs;
  final _controller = StreamController<AppUser?>.broadcast();
  static const _key = 'local_uid';

  AppUser? get _user {
    final uid = _prefs.getString(_key);
    return uid == null ? null : AppUser(uid: uid, provider: AuthProviderType.local);
  }

  @override
  Stream<AppUser?> get userChanges async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signInAnonymously() async {
    await _prefs.setString(_key, _prefs.getString(_key) ?? 'local-${newId()}');
    _controller.add(_user);
    return _user!;
  }

  Never _unsupported() => throw const AppFailure(FailureKind.unavailable);

  @override
  Future<AppUser> signInWithEmail(String email, String password) async => _unsupported();

  @override
  Future<AppUser> createAccountWithEmail(String email, String password) async => _unsupported();

  @override
  Future<AppUser> signInWithGoogle() async => _unsupported();

  @override
  Future<AppUser> linkEmail(String email, String password) async => _unsupported();

  @override
  Future<AppUser> linkGoogle() async => _unsupported();

  @override
  Future<void> sendPasswordReset(String email) async => _unsupported();

  @override
  Future<void> signOut() async {
    await _prefs.remove(_key);
    _controller.add(null);
  }

  @override
  Future<void> deleteCurrentUser() => signOut();

  @override
  Future<String?> idToken() async => null;
}
