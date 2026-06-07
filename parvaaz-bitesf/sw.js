const CACHE_NAME = 'parvaaz-v2';
const ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/site-config.js',
  '/icons/icon-192.png',
  'https://fonts.googleapis.com/css2?family=Vazirmatn:wght@200;300;400;500;600;700;800;900&display=swap'
];

// Install - cache assets
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(ASSETS))
  );
  self.skipWaiting();
});

// Activate - clean old caches
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// Fetch - serve from cache, fallback to network
self.addEventListener('fetch', e => {
  // API — always network (cloud core)
  const url = e.request.url;
  if (url.includes('/api/') || url.includes('api.anthropic.com')) return;

  e.respondWith(
    caches.match(e.request).then(cached => {
      if (cached) return cached;
      return fetch(e.request).then(response => {
        if (!response || response.status !== 200 || response.type !== 'basic') return response;
        const clone = response.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(e.request, clone));
        return response;
      }).catch(() => caches.match('/index.html'));
    })
  );
});

// Background sync for form submissions
self.addEventListener('sync', e => {
  if (e.tag === 'contact-form') {
    e.waitUntil(syncContactForms());
  }
});

async function syncContactForms() {
  // When back online, retry failed form submissions
  const db = await openDB();
  const pending = await db.getAll('pending-forms');
  for (const form of pending) {
    console.log('Syncing form:', form);
  }
}

function openDB() {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open('parvaaz-db', 1);
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
    req.onupgradeneeded = e => {
      e.target.result.createObjectStore('pending-forms', { autoIncrement: true });
      e.target.result.createObjectStore('chat-history', { keyPath: 'id' });
    };
  });
}
