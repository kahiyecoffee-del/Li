import 'dart:async';

import '../data/collections.dart';
import '../data/local/local_store.dart';
import '../data/repositories/user_repos.dart';
import '../data/sync/firestore_gateway.dart';
import '../data/sync/sync_engine.dart';
import '../services/auth/auth_service.dart';
import '../services/billing/entitlement.dart';
import 'services.dart';

/// Everything scoped to one signed-in user. Created when auth resolves and
/// disposed on sign-out or account switch.
class Session {
  Session._(this.user, this.store, this.repos, this.sync, this.entitlements);

  final AppUser user;
  final LocalStore store;
  final UserRepos repos;

  /// Null for local-only users.
  final SyncEngine? sync;
  final EntitlementService entitlements;
  StreamSubscription<bool>? _connectivitySub;

  static Future<Session> open(AppUser user, Services s, Future<LocalStore> Function(String uid) openStore) async {
    final store = await openStore(user.uid);
    SyncEngine? sync;
    final canSync = s.firestore != null && !user.isLocalOnly;
    if (canSync) {
      sync = SyncEngine(
        store: store,
        gateway: FirestoreSyncGateway(s.firestore!),
        uid: user.uid,
        collections: Collections.synced,
      );
    }
    final repos = UserRepos(
      store,
      journalKeys: s.journalKeys,
      onWrite: sync == null ? null : () => sync!.scheduleSync(),
    );
    final ent = canSync ? FirestoreEntitlementService(s.firestore!, user.uid, s.prefs) : StaticEntitlementService();
    final session = Session._(user, store, repos, sync, ent);
    if (sync != null) {
      // Sync now and whenever connectivity returns.
      session._connectivitySub = s.connectivity.onlineChanges.listen((online) {
        if (online) sync!.scheduleSync(const Duration(seconds: 1));
      });
      sync.scheduleSync(const Duration(milliseconds: 500));
    }
    return session;
  }

  Future<void> close() async {
    await _connectivitySub?.cancel();
    await sync?.dispose();
    await store.close();
  }
}
