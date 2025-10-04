// Service Worker para Calendario Familiar PWA
// Maneja notificaciones programadas incluso con la app cerrada

const CACHE_NAME = 'calendario-familiar-v1';
const DB_NAME = 'CalendarioFamiliarDB';
const DB_VERSION = 1;
const STORE_NAME = 'reminders';

// Instalar Service Worker
self.addEventListener('install', (event) => {
  console.log('🔧 Service Worker instalado');
  self.skipWaiting();
});

// Activar Service Worker
self.addEventListener('activate', (event) => {
  console.log('✅ Service Worker activado');
  event.waitUntil(self.clients.claim());
  
  // Iniciar verificación periódica de alarmas
  startReminderCheck();
});

// Abrir base de datos IndexedDB
function openDatabase() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);
    
    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);
    
    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        db.createObjectStore(STORE_NAME, { keyPath: 'id' });
      }
    };
  });
}

// Obtener todos los recordatorios pendientes
async function getPendingReminders() {
  try {
    const db = await openDatabase();
    const transaction = db.transaction(STORE_NAME, 'readonly');
    const store = transaction.objectStore(STORE_NAME);
    
    return new Promise((resolve, reject) => {
      const request = store.getAll();
      request.onsuccess = () => resolve(request.result || []);
      request.onerror = () => reject(request.error);
    });
  } catch (error) {
    console.error('❌ Error obteniendo recordatorios:', error);
    return [];
  }
}

// Eliminar recordatorio de la base de datos
async function deleteReminder(id) {
  try {
    const db = await openDatabase();
    const transaction = db.transaction(STORE_NAME, 'readwrite');
    const store = transaction.objectStore(STORE_NAME);
    
    return new Promise((resolve, reject) => {
      const request = store.delete(id);
      request.onsuccess = () => {
        console.log('✅ Recordatorio eliminado:', id);
        resolve();
      };
      request.onerror = () => reject(request.error);
    });
  } catch (error) {
    console.error('❌ Error eliminando recordatorio:', error);
  }
}

// Mostrar notificación
async function showNotification(title, body, tag) {
  try {
    // Verificar si tenemos permiso
    if (self.Notification && self.Notification.permission === 'granted') {
      await self.registration.showNotification(title, {
        body: body,
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        tag: tag,
        vibrate: [200, 100, 200],
        requireInteraction: true,
        actions: [
          { action: 'open', title: 'Abrir' },
          { action: 'close', title: 'Cerrar' }
        ]
      });
      console.log('🔔 Notificación mostrada:', title);
    } else {
      console.warn('⚠️ Sin permisos de notificación');
    }
  } catch (error) {
    console.error('❌ Error mostrando notificación:', error);
  }
}

// Verificar y mostrar recordatorios que deben dispararse
async function checkAndShowReminders() {
  try {
    const reminders = await getPendingReminders();
    const now = Date.now();
    
    console.log(`🔍 Verificando ${reminders.length} recordatorios...`);
    
    for (const reminder of reminders) {
      const scheduledTime = new Date(reminder.scheduledTime).getTime();
      
      // Si la hora programada ya pasó (con margen de 2 minutos)
      if (scheduledTime <= now && scheduledTime > (now - 120000)) {
        console.log('⏰ Disparando recordatorio:', reminder.title);
        
        // Mostrar notificación
        await showNotification(
          reminder.title,
          reminder.body,
          reminder.id
        );
        
        // Eliminar recordatorio de la base de datos
        await deleteReminder(reminder.id);
      }
      // Si el recordatorio es muy antiguo (más de 1 hora), eliminarlo
      else if (scheduledTime < (now - 3600000)) {
        console.log('🗑️ Eliminando recordatorio antiguo:', reminder.id);
        await deleteReminder(reminder.id);
      }
    }
  } catch (error) {
    console.error('❌ Error verificando recordatorios:', error);
  }
}

// Iniciar verificación periódica cada 30 segundos
function startReminderCheck() {
  console.log('⏰ Iniciando verificación periódica de recordatorios...');
  
  // Verificar inmediatamente
  checkAndShowReminders();
  
  // Verificar cada 30 segundos
  setInterval(() => {
    checkAndShowReminders();
  }, 30000); // 30 segundos
}

// Manejar clics en notificaciones
self.addEventListener('notificationclick', (event) => {
  console.log('👆 Click en notificación');
  event.notification.close();
  
  if (event.action === 'open' || !event.action) {
    // Abrir o enfocar la app
    event.waitUntil(
      clients.matchAll({ type: 'window', includeUncontrolled: true })
        .then((clientList) => {
          // Si hay una ventana abierta, enfocarla
          for (let client of clientList) {
            if (client.url.includes(self.location.origin) && 'focus' in client) {
              return client.focus();
            }
          }
          // Si no hay ventana abierta, abrir una nueva
          if (clients.openWindow) {
            return clients.openWindow('/');
          }
        })
    );
  }
});

// Manejar mensajes desde la app
self.addEventListener('message', async (event) => {
  console.log('📨 Mensaje recibido:', event.data);
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'CHECK_REMINDERS') {
    await checkAndShowReminders();
  }
});

// Manejar fetch (caché básico)
self.addEventListener('fetch', (event) => {
  // Solo cachear solicitudes GET
  if (event.request.method !== 'GET') return;
  
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        return response || fetch(event.request);
      })
  );
});

console.log('🚀 Service Worker cargado y listo');

