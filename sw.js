// Alamat lama asepsugi.github.io/mabar/ sudah dimatikan (keputusan host 2026-11-02): PWA lama yang membuka
// /match-addict/ menampilkan bar URL karena di luar scope-nya, jadi tidak dialihkan lagi.
// File ini satu-satunya yang tersisa: service worker app Mabar lama (cache-first) terus menyajikan versi lama dari
// cache selama sw.js baru tidak bisa diunduh (404 tidak mencopotnya). Begitu terpasang, cache lama dihapus, service
// worker ini melepas dirinya, lalu setiap tab dimuat ulang dari jaringan → halaman 404.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter((k) => k.startsWith('mabar-')).map((k) => caches.delete(k)));
    await self.clients.claim();
    await self.registration.unregister();
    const clients = await self.clients.matchAll({ type: 'window' });
    await Promise.all(clients.map((c) => c.navigate(c.url).catch(() => {})));
  })());
});
