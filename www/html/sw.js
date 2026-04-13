// Legacy root service worker. KPAB now owns its own scoped worker under /kpab/.
// Unregister this one so it stops intercepting unrelated public rooms.
self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    self.registration.unregister().then(() => self.clients.claim())
  );
});
