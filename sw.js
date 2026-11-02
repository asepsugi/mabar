// Pengganti service worker app Mabar lama (cache-first) di /mabar/: tanpa ini PWA yang sudah terpasang terus
// menyajikan versi lama dari cache dan tidak pernah melihat pengalihan ke Match Addict. Begitu terpasang, cache lama
// dihapus, service worker ini melepas dirinya, lalu setiap tab dimuat ulang dari jaringan → index.html pengalih.
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
