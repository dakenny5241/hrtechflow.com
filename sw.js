// HRTechFlow Service Worker — v2.0
// Cache-first for the app shell (loads instantly even offline),
// network-first for everything else same-origin, and Supabase/Paystack
// requests are left alone entirely so the app's own offline-session
// logic handles those.

const CACHE_NAME = 'hrtechflow-v2';
const OFFLINE_URL = '/index.html';

// Core assets to cache on install — the app must be able to load
// from these alone with zero network access.
const PRECACHE_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icon-192.png',
  '/icon-512.png',
  '/apple-touch-icon.png',
];

// ── Install: cache core assets, activate immediately ──────────
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(PRECACHE_ASSETS))
      .then(() => self.skipWaiting())
  );
});

// ── Activate: clean up old caches, take control right away ────
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// ── Fetch ───────────────────────────────────────────────────────
self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;

  const url = new URL(event.request.url);
  // Never intercept Supabase or Paystack — the app's own JS handles
  // those directly, including the offline-session fallback logic.
  if (url.hostname.includes('supabase.co')) return;
  if (url.hostname.includes('paystack.com')) return;

  // ── Navigation requests (loading/reloading the app itself) ──
  // CACHE-FIRST: the app shell must appear instantly, with zero
  // wait on a network timeout, whether online or offline. Once it's
  // loaded, the app's own JS decides what to do about connectivity —
  // that's a much faster and more reliable experience than waiting
  // on a network request to fail before falling back to cache.
  if (event.request.mode === 'navigate') {
    event.respondWith(
      caches.match(OFFLINE_URL).then(cached => {
        if (cached) {
          // Serve the cached shell immediately, and refresh the cache
          // in the background if a connection exists — so the next
          // load gets the latest version without ever blocking this one.
          fetch(event.request).then(res => {
            if (res.ok) caches.open(CACHE_NAME).then(c => c.put(OFFLINE_URL, res));
          }).catch(() => {});
          return cached;
        }
        // Nothing cached yet (very first-ever visit) — must use network.
        return fetch(event.request).catch(() =>
          new Response('You are offline and this device has not loaded HRTechFlow before. Please connect to the internet once.', { status: 503 })
        );
      })
    );
    return;
  }

  // ── Everything else same-origin (icons, manifest, etc.) ──────
  // NETWORK-FIRST: keep these fresh when online, fall back to
  // cache only if the network genuinely fails.
  event.respondWith(
    fetch(event.request)
      .then(response => {
        if (response.ok && url.origin === self.location.origin) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
        }
        return response;
      })
      .catch(() => caches.match(event.request).then(cached => cached ||
        new Response('Offline', { status: 503, statusText: 'Service Unavailable' })
      ))
  );
});

// ── Allow the page to force an update ──────────────────────────
self.addEventListener('message', event => {
  if (event.data?.type === 'SKIP_WAITING') self.skipWaiting();
});
