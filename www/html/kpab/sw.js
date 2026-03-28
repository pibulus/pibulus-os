const CACHE_NAME = 'kpab-v6';
const STATIC_ASSETS = [
  '/',
  '/manifest.json'
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(STATIC_ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);

  // Never cache the stream, API calls, dynamic routes, or catalog
  if (url.pathname === '/radio.mp3' ||
      url.pathname.startsWith('/api/') ||
      url.pathname.startsWith('/listen/') ||
      url.pathname.startsWith('/mutiny/') ||
      url.pathname.startsWith('/msg/') ||
      url.pathname === '/catalog.json' ||
      url.hostname !== self.location.hostname) {
    return;
  }

  // Network-first for HTML, cache-first for static assets
  if (e.request.mode === 'navigate') {
    e.respondWith(
      fetch(e.request).then(res => {
        const clone = res.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(e.request, clone));
        return res;
      }).catch(() => caches.match(e.request))
    );
  } else {
    e.respondWith(
      caches.match(e.request).then(cached => cached || fetch(e.request))
    );
  }
});
