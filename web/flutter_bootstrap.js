{{flutter_js}}
{{flutter_build_config}}

// Tanpa serviceWorkerSettings: service worker bawaan Flutter (3.47) cuma meng-unregister dirinya,
// dan karena scope-nya sama dia ikut mencopot sw.js kita. Offline ditangani sw.js (lihat index.html).
_flutter.loader.load();
