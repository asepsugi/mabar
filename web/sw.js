// Service worker offline Mabar. Dua placeholder di bawah diisi tool/build_web.sh setelah
// `flutter build web`; tanpa skrip itu file ini tidak berguna (daftar precache-nya kosong).
const VERSION = '__MABAR_VERSION__';
const PRECACHE = __MABAR_PRECACHE__;
const CACHE = `mabar-${VERSION}`;

// Semua file app di-precache saat install, supaya layar yang belum pernah dibuka (dan gambarnya)
// tetap jalan offline di lapangan. Pengecualian: canvaskit/ punya beberapa varian ~5MB per browser,
// jadi hanya varian yang benar-benar diunduh browser yang disimpan, lewat cache saat fetch.
self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(PRECACHE)));
});

// Tidak skipWaiting otomatis: satu sesi tidak boleh mencampur main.dart.js lama dengan aset baru.
// index.html yang memintanya, hanya saat app baru dibuka (lihat sana).
self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k.startsWith('mabar-') && k !== CACHE).map((k) => caches.delete(k))),
    ),
  );
});

// Cache-first: di lapangan sinyal sering jelek, jadi app tidak boleh menunggu jaringan.
// Pembaruan datang lewat sw.js baru (isinya berubah tiap build), bukan lewat fetch ini.
self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET' || new URL(req.url).origin !== self.location.origin) return;

  event.respondWith(
    caches.open(CACHE).then(async (cache) => {
      // Navigasi (buka app, termasuk ?query) selalu dilayani index.html yang di-precache.
      const key = req.mode === 'navigate' ? 'index.html' : req;
      const hit = await cache.match(key, { ignoreSearch: true });
      if (hit) return hit;
      const res = await fetch(req);
      if (res.ok) cache.put(req, res.clone());
      return res;
    }),
  );
});
