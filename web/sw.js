const CACHE_NAME = 'calendario-familiar-v3';
const urlsToCache = [
  './',
  './index.html',
  './manifest.json',
  './favicon.png',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
  './icons/Icon-maskable-192.png',
  './icons/Icon-maskable-512.png',
  './main.dart.js',
  './flutter_bootstrap.js'
];

// URLs que NO deben ser cacheadas (Firebase y APIs)
const noCacheUrls = [
  'firebaseapp.com',
  'googleapis.com',
  'firestore.googleapis.com',
  'identitytoolkit.googleapis.com',
  'securetoken.googleapis.com',
  'firebaseio.com',
  'firebase.com'
];

// Patrones de URL que indican peticiones de Firebase
const firebasePatterns = [
  /\/v1\/projects\/.*\/databases\/.*\/documents/,
  /\/v1\/projects\/.*\/identitytoolkit/,
  /\/v1\/projects\/.*\/storage\/.*\/o/,
  /\/v1\/projects\/.*\/firestore\/.*\/documents/
];

// Instalación del Service Worker
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('📦 Cache abierto:', CACHE_NAME);
        return cache.addAll(urlsToCache);
      })
      .then(() => {
        console.log('✅ Recursos estáticos cacheados correctamente');
      })
      .catch((error) => {
        console.error('❌ Error cacheando recursos:', error);
      })
  );
});

// Activación del Service Worker
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            console.log('🗑️ Eliminando cache antiguo:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      console.log('✅ Service Worker activado y cache limpiado');
      // Notificar al cliente que el SW está listo
      self.clients.claim();
    })
  );
});

// Interceptación de peticiones
self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);
  
  // NO cachear peticiones a Firebase o APIs
  if (_isFirebaseRequest(url, request)) {
    console.log('🔄 Petición a Firebase/API, no cacheando:', url.hostname);
    event.respondWith(_handleFirebaseRequest(request));
    return;
  }
  
  // NO cachear peticiones de WebSocket (Firestore en tiempo real)
  if (request.headers.get('upgrade') === 'websocket') {
    console.log('🔌 Petición WebSocket, no cacheando');
    event.respondWith(fetch(request));
    return;
  }
  
  // NO cachear peticiones POST/PUT/DELETE
  if (['POST', 'PUT', 'DELETE', 'PATCH'].includes(request.method)) {
    console.log('📝 Petición de escritura, no cacheando:', request.method);
    event.respondWith(fetch(request));
    return;
  }
  
  // Para peticiones GET estáticas, usar cache primero
  if (request.method === 'GET') {
    event.respondWith(_handleStaticRequest(request, url));
  } else {
    // Para otros métodos, hacer fetch directo
    event.respondWith(fetch(request));
  }
});

// Función para determinar si una petición es de Firebase
function _isFirebaseRequest(url, request) {
  // Verificar por hostname
  if (noCacheUrls.some(domain => url.hostname.includes(domain))) {
    return true;
  }
  
  // Verificar por patrones de URL
  if (firebasePatterns.some(pattern => pattern.test(url.pathname))) {
    return true;
  }
  
  // Verificar headers específicos de Firebase
  if (request.headers.get('x-firebase-auth') || 
      request.headers.get('x-firebase-app') ||
      request.headers.get('x-firebase-project')) {
    return true;
  }
  
  return false;
}

// Manejar peticiones de Firebase
async function _handleFirebaseRequest(request) {
  try {
    // Para Firebase, siempre hacer fetch directo sin cache
    const response = await fetch(request);
    
    // Si la petición falla, intentar reconectar
    if (!response.ok) {
      console.warn('⚠️ Petición Firebase falló:', response.status, response.statusText);
      
      // Notificar al cliente sobre el problema de conectividad
      _notifyClientsAboutConnectivityIssue({
        type: 'FIREBASE_ERROR',
        status: response.status,
        statusText: response.statusText,
        url: request.url
      });
    }
    
    return response;
  } catch (error) {
    console.error('❌ Error en petición Firebase:', error);
    
    // Notificar al cliente sobre el error
    _notifyClientsAboutConnectivityIssue({
      type: 'FIREBASE_NETWORK_ERROR',
      error: error.message,
      url: request.url
    });
    
    // Retornar una respuesta de error para que la app pueda manejarla
    return new Response(JSON.stringify({
      error: 'Firebase connection failed',
      message: error.message
    }), {
      status: 503,
      statusText: 'Service Unavailable',
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }
}

// Manejar peticiones estáticas
async function _handleStaticRequest(request, url) {
  try {
    // Primero intentar servir desde cache
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      console.log('📦 Sirviendo desde cache:', url.pathname);
      return cachedResponse;
    }
    
    // Si no está en cache, hacer fetch a la red
    const response = await fetch(request);
    
    // Verificar que la respuesta sea válida
    if (!response || response.status !== 200 || response.type !== 'basic') {
      return response;
    }

    // Solo cachear recursos estáticos
    if (_isStaticResource(url.pathname)) {
      // Clona la respuesta para cachearla
      const responseToCache = response.clone();
      const cache = await caches.open(CACHE_NAME);
      await cache.put(request, responseToCache);
      console.log('💾 Recurso cacheado:', url.pathname);
    }

    return response;
  } catch (error) {
    console.log('❌ Error en fetch estático:', error);
    
    // Si no hay conexión, intentar servir una página offline
    if (request.destination === 'document') {
      const offlineResponse = await caches.match('/index.html');
      if (offlineResponse) {
        return offlineResponse;
      }
    }
    
    // Retornar una respuesta de error
    return new Response('Network error', {
      status: 503,
      statusText: 'Service Unavailable'
    });
  }
}

// Función para determinar si un recurso es estático
function _isStaticResource(pathname) {
  const staticExtensions = ['.js', '.css', '.png', '.jpg', '.jpeg', '.gif', '.svg', '.ico', '.woff', '.woff2', '.ttf', '.eot'];
  return staticExtensions.some(ext => pathname.endsWith(ext)) || 
         pathname === '/' || 
         pathname === '/index.html' ||
         pathname === '/manifest.json';
}

// Notificar a los clientes sobre problemas de conectividad
function _notifyClientsAboutConnectivityIssue(data) {
  self.clients.matchAll().then(clients => {
    clients.forEach(client => {
      client.postMessage({
        type: 'CONNECTIVITY_ISSUE',
        data: data
      });
    });
  });
}

// Manejo de mensajes del cliente
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'GET_VERSION') {
    event.ports[0].postMessage({ version: CACHE_NAME });
  }
  
  if (event.data && event.data.type === 'CLEAR_CACHE') {
    event.waitUntil(
      caches.keys().then(cacheNames => {
        return Promise.all(
          cacheNames.map(cacheName => caches.delete(cacheName))
        );
      }).then(() => {
        event.ports[0].postMessage({ success: true, message: 'Cache limpiado' });
      })
    );
  }
  
  if (event.data && event.data.type === 'GET_CACHE_STATUS') {
    event.waitUntil(
      caches.keys().then(cacheNames => {
        const status = {
          currentCache: CACHE_NAME,
          availableCaches: cacheNames,
          isFirebaseRequest: _isFirebaseRequest(new URL(event.data.url), event.data.request)
        };
        event.ports[0].postMessage(status);
      })
    );
  }
});

// Manejo de errores del Service Worker
self.addEventListener('error', (event) => {
  console.error('❌ Error en Service Worker:', event.error);
});

self.addEventListener('unhandledrejection', (event) => {
  console.error('❌ Promesa rechazada no manejada en Service Worker:', event.reason);
});
