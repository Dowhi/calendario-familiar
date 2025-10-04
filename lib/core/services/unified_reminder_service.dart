import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:js' as js;

/// Servicio unificado de recordatorios que funciona en PWA y móvil
/// PWA: Usa Service Worker + IndexedDB
/// Móvil: Usa flutter_local_notifications
class UnifiedReminderService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  static bool _isWeb = kIsWeb;
  
  /// Inicializar el servicio
  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      print('🔔 Inicializando UnifiedReminderService...');
      print('   Plataforma: ${_isWeb ? "WEB" : "MOBILE"}');
      
      if (_isWeb) {
        return await _initializeWeb();
      } else {
        return await _initializeMobile();
      }
    } catch (e) {
      print('❌ Error inicializando servicio de recordatorios: $e');
      return false;
    }
  }
  
  /// Inicializar servicio web
  static Future<bool> _initializeWeb() async {
    try {
      print('🌐 Inicializando servicio web...');
      
      // Verificar si Service Workers están soportados
      if (!_isServiceWorkerSupported()) {
        print('❌ Service Workers no soportados en este navegador');
        return false;
      }
      
      // Solicitar permisos de notificación
      final permission = await _requestWebNotificationPermission();
      if (!permission) {
        print('❌ Permisos de notificación denegados');
        return false;
      }
      
      // Registrar Service Worker
      await _registerServiceWorker();
      
      _isInitialized = true;
      print('✅ Servicio web inicializado');
      return true;
      
    } catch (e) {
      print('❌ Error inicializando servicio web: $e');
      return false;
    }
  }
  
  /// Inicializar servicio móvil
  static Future<bool> _initializeMobile() async {
    try {
      print('📱 Inicializando servicio móvil...');
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      
      if (initialized != true) {
        print('❌ Falló inicialización de notificaciones móviles');
        return false;
      }
      
      // Crear canal para Android
      if (Platform.isAndroid) {
        await _createAndroidChannel();
      }
      
      // Solicitar permisos
      await _requestMobilePermissions();
      
      _isInitialized = true;
      print('✅ Servicio móvil inicializado');
      return true;
      
    } catch (e) {
      print('❌ Error inicializando servicio móvil: $e');
      return false;
    }
  }
  
  /// Verificar si Service Workers están soportados
  static bool _isServiceWorkerSupported() {
    if (!kIsWeb) return false;
    try {
      return js.context.hasProperty('navigator') &&
             js.context['navigator'].hasProperty('serviceWorker');
    } catch (e) {
      return false;
    }
  }
  
  /// Solicitar permisos de notificación en web
  static Future<bool> _requestWebNotificationPermission() async {
    if (!kIsWeb) return false;
    
    try {
      // Verificar permiso actual usando JS interop
      final permission = js.context.callMethod('eval', [
        'Notification.permission'
      ]);
      
      print('🔔 Permiso actual: $permission');
      
      if (permission == 'granted') {
        return true;
      }
      
      if (permission == 'denied') {
        print('❌ Permisos denegados permanentemente');
        return false;
      }
      
      // Solicitar permiso
      final result = await js.context['Notification'].callMethod('requestPermission');
      final granted = result.toString() == 'granted';
      
      print('🔔 Permiso ${granted ? "concedido" : "denegado"}');
      return granted;
      
    } catch (e) {
      print('❌ Error solicitando permisos web: $e');
      return false;
    }
  }
  
  /// Registrar Service Worker
  static Future<void> _registerServiceWorker() async {
    if (!kIsWeb) return;
    
    try {
      print('📝 Registrando Service Worker...');
      
      // Registrar SW usando JS interop
      js.context['navigator']['serviceWorker'].callMethod('register', ['/sw.js']);
      
      print('✅ Service Worker registrado');
      
    } catch (e) {
      print('❌ Error registrando Service Worker: $e');
    }
  }
  
  /// Crear canal de notificaciones para Android
  static Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      'reminders_channel',
      'Recordatorios',
      description: 'Recordatorios de eventos del calendario',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      await android.createNotificationChannel(channel);
      print('✅ Canal Android creado');
    }
  }
  
  /// Solicitar permisos en móvil
  static Future<bool> _requestMobilePermissions() async {
    if (kIsWeb) return false;
    
    try {
      if (Platform.isAndroid) {
        final android = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (android != null) {
          final granted = await android.requestNotificationsPermission();
          
          // Solicitar permisos de alarmas exactas
          try {
            await android.requestExactAlarmsPermission();
          } catch (e) {
            print('⚠️ No se pudo solicitar permiso de alarmas exactas: $e');
          }
          
          return granted ?? false;
        }
      } else if (Platform.isIOS) {
        final ios = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        
        if (ios != null) {
          final granted = await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }
      }
      
      return false;
    } catch (e) {
      print('❌ Error solicitando permisos móviles: $e');
      return false;
    }
  }
  
  /// Manejar tap en notificación móvil
  static void _onNotificationTap(NotificationResponse response) {
    print('👆 Notificación tocada: ${response.payload}');
  }
  
  /// Programar recordatorio
  static Future<bool> scheduleReminder({
    required String id,
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) {
      print('⚠️ Servicio no inicializado, inicializando...');
      final initialized = await initialize();
      if (!initialized) {
        print('❌ No se pudo inicializar el servicio');
        return false;
      }
    }
    
    // Validar que la fecha sea futura
    if (scheduledTime.isBefore(DateTime.now())) {
      print('❌ No se puede programar recordatorio en el pasado');
      return false;
    }
    
    print('📅 Programando recordatorio:');
    print('   ID: $id');
    print('   Hora: $scheduledTime');
    print('   Título: $title');
    
    try {
      if (_isWeb) {
        return await _scheduleWebReminder(id, scheduledTime, title, body);
      } else {
        return await _scheduleMobileReminder(id, scheduledTime, title, body);
      }
    } catch (e) {
      print('❌ Error programando recordatorio: $e');
      return false;
    }
  }
  
  /// Programar recordatorio en web (IndexedDB)
  static Future<bool> _scheduleWebReminder(
    String id,
    DateTime scheduledTime,
    String title,
    String body,
  ) async {
    try {
      print('🌐 Guardando recordatorio en IndexedDB...');
      
      // Guardar en IndexedDB usando JS interop
      final jsCode = '''
        (function() {
          return new Promise((resolve, reject) => {
            const request = indexedDB.open('CalendarioFamiliarDB', 1);
            
            request.onerror = () => reject(request.error);
            
            request.onupgradeneeded = (event) => {
              const db = event.target.result;
              if (!db.objectStoreNames.contains('reminders')) {
                db.createObjectStore('reminders', { keyPath: 'id' });
              }
            };
            
            request.onsuccess = () => {
              const db = request.result;
              const transaction = db.transaction('reminders', 'readwrite');
              const store = transaction.objectStore('reminders');
              
              const reminder = {
                id: '$id',
                scheduledTime: '${scheduledTime.toIso8601String()}',
                title: '$title',
                body: '$body',
                createdAt: new Date().toISOString()
              };
              
              const addRequest = store.put(reminder);
              addRequest.onsuccess = () => resolve(true);
              addRequest.onerror = () => reject(addRequest.error);
            };
          });
        })()
      ''';
      
      await js.context.callMethod('eval', [jsCode]);
      
      print('✅ Recordatorio guardado en IndexedDB');
      
      // Notificar al Service Worker
      _notifyServiceWorker();
      
      return true;
      
    } catch (e) {
      print('❌ Error guardando recordatorio web: $e');
      return false;
    }
  }
  
  /// Programar recordatorio en móvil
  static Future<bool> _scheduleMobileReminder(
    String id,
    DateTime scheduledTime,
    String title,
    String body,
  ) async {
    try {
      print('📱 Programando notificación móvil...');
      
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
      
      await _notifications.zonedSchedule(
        id.hashCode,
        title,
        body,
        tzScheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminders_channel',
            'Recordatorios',
            channelDescription: 'Recordatorios de eventos del calendario',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print('✅ Notificación móvil programada');
      return true;
      
    } catch (e) {
      print('❌ Error programando notificación móvil: $e');
      return false;
    }
  }
  
  /// Notificar al Service Worker para verificar recordatorios
  static void _notifyServiceWorker() {
    if (!kIsWeb) return;
    
    try {
      js.context.callMethod('eval', ['''
        if (navigator.serviceWorker.controller) {
          navigator.serviceWorker.controller.postMessage({
            type: 'CHECK_REMINDERS'
          });
        }
      ''']);
    } catch (e) {
      print('⚠️ No se pudo notificar al Service Worker: $e');
    }
  }
  
  /// Cancelar recordatorio
  static Future<bool> cancelReminder(String id) async {
    if (!_isInitialized) return false;
    
    try {
      if (_isWeb) {
        return await _cancelWebReminder(id);
      } else {
        return await _cancelMobileReminder(id);
      }
    } catch (e) {
      print('❌ Error cancelando recordatorio: $e');
      return false;
    }
  }
  
  /// Cancelar recordatorio web
  static Future<bool> _cancelWebReminder(String id) async {
    try {
      final jsCode = '''
        (function() {
          return new Promise((resolve, reject) => {
            const request = indexedDB.open('CalendarioFamiliarDB', 1);
            
            request.onsuccess = () => {
              const db = request.result;
              const transaction = db.transaction('reminders', 'readwrite');
              const store = transaction.objectStore('reminders');
              
              const deleteRequest = store.delete('$id');
              deleteRequest.onsuccess = () => resolve(true);
              deleteRequest.onerror = () => reject(deleteRequest.error);
            };
            
            request.onerror = () => reject(request.error);
          });
        })()
      ''';
      
      await js.context.callMethod('eval', [jsCode]);
      print('✅ Recordatorio web cancelado');
      return true;
      
    } catch (e) {
      print('❌ Error cancelando recordatorio web: $e');
      return false;
    }
  }
  
  /// Cancelar recordatorio móvil
  static Future<bool> _cancelMobileReminder(String id) async {
    try {
      await _notifications.cancel(id.hashCode);
      print('✅ Recordatorio móvil cancelado');
      return true;
    } catch (e) {
      print('❌ Error cancelando recordatorio móvil: $e');
      return false;
    }
  }
  
  /// Verificar si las notificaciones están habilitadas
  static Future<bool> areNotificationsEnabled() async {
    if (_isWeb) {
      try {
        final permission = js.context.callMethod('eval', ['Notification.permission']);
        return permission == 'granted';
      } catch (e) {
        return false;
      }
    } else {
      if (Platform.isAndroid) {
        final android = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (android != null) {
          return await android.areNotificationsEnabled() ?? false;
        }
      } else if (Platform.isIOS) {
        final ios = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (ios != null) {
          final permissions = await ios.checkPermissions();
          return permissions?.isEnabled ?? false;
        }
      }
      return false;
    }
  }
  
  /// Mostrar notificación de prueba inmediata
  static Future<void> showTestNotification() async {
    print('🧪 Mostrando notificación de prueba...');
    
    // Programar para 2 segundos en el futuro
    final testTime = DateTime.now().add(const Duration(seconds: 2));
    
    await scheduleReminder(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      scheduledTime: testTime,
      title: '🔔 Notificación de Prueba',
      body: 'El sistema de recordatorios funciona correctamente',
    );
  }
}

