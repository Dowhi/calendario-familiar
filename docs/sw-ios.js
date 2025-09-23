// Service Worker específico para iOS
const CACHE_NAME = 'calendario-familiar-ios-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/main.dart.js',
  '/flutter.js',
  '/flutter_bootstrap.js'
];

// Instalar service worker
self.addEventListener('install', (event) => {
  console.log('iOS Service Worker: Installing...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('iOS Service Worker: Caching files');
        return cache.addAll(urlsToCache);
      })
      .catch((error) => {
        console.log('iOS Service Worker: Cache failed', error);
      })
  );
});

// Activar service worker
self.addEventListener('activate', (event) => {
  console.log('iOS Service Worker: Activating...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            console.log('iOS Service Worker: Deleting old cache', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});

// Interceptar requests
self.addEventListener('fetch', (event) => {
  // Solo interceptar requests GET
  if (event.request.method !== 'GET') {
    return;
  }

  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        // Si está en cache, devolverlo
        if (response) {
          console.log('iOS Service Worker: Serving from cache', event.request.url);
          return response;
        }

        // Si no está en cache, hacer fetch
        console.log('iOS Service Worker: Fetching from network', event.request.url);
        return fetch(event.request)
          .then((response) => {
            // Verificar si la respuesta es válida
            if (!response || response.status !== 200 || response.type !== 'basic') {
              return response;
            }

            // Clonar la respuesta
            const responseToCache = response.clone();

            // Agregar al cache
            caches.open(CACHE_NAME)
              .then((cache) => {
                cache.put(event.request, responseToCache);
              });

            return response;
          })
          .catch((error) => {
            console.log('iOS Service Worker: Fetch failed', error);
            // En caso de error, devolver página offline si es una navegación
            if (event.request.mode === 'navigate') {
              return caches.match('/index.html');
            }
          });
      })
  );
});

// Manejar mensajes del cliente
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});
