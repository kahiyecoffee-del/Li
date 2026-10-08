{{flutter_js}}
{{flutter_build_config}}

// Always load the newest build: no offline service worker, and clear any
// one a previous version left behind (it kept serving stale code).
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then((rs) => rs.forEach((r) => r.unregister()));
}
if (window.caches) {
  caches.keys().then((keys) => keys.forEach((k) => caches.delete(k)));
}
_flutter.loader.load();
