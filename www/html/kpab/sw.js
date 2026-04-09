const CACHE_NAME = 'kpab-v5';
const STATIC_ASSETS = [
  '/',
  '/manifest.json',
  '/offline.html'
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

  // Never intercept: stream, API, dynamic routes, catalog, third-party
  if (url.pathname === '/radio.mp3' ||
      url.pathname.startsWith('/api/') ||
      url.pathname.startsWith('/listen/') ||
      url.pathname.startsWith('/mutiny/') ||
      url.pathname.startsWith('/msg/') ||
      url.pathname === '/catalog.json' ||
      url.hostname !== self.location.hostname) {
    return;
  }

  // Network-first for HTML, JS, and CSS (always get latest)
  if (e.request.mode === 'navigate' ||
      url.pathname.endsWith('.js') ||
      url.pathname.endsWith('.css')) {
    e.respondWith(
      fetch(e.request).then(res => {
        if (res.ok) {
          const clone = res.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(e.request, clone));
        }
        return res;
      }).catch(() => caches.match(e.request).then(cached => cached || caches.match('/offline.html')))
    );
    return;
  }

  // Cache-first for static assets (icons, fonts, images)
  e.respondWith(
    caches.match(e.request).then(cached => cached || fetch(e.request))
  );
});
