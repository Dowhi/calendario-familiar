import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io' show Platform;
import 'dart:async';
import 'dart:js' as js;

/// Servicio simplificado de recordatorios
/// Funciona tanto en web como en móvil
class ReminderService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  static const String _channelId = 'calendar_reminders';
  static const String _channelName = 'Recordatorios del Calendario';
  static const String _channelDescription = 'Recordatorios de eventos del calendario familiar';
  
  static bool _isInitialized = false;
  
  /// Inicializar el servicio de recordatorios
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔔 Inicializando servicio de recordatorios...');
      
      // Para web, usar notificaciones web nativas
      if (kIsWeb) {
        print('🌐 Ejecutándose en web - usando notificaciones web nativas');
        _isInitialized = true;
        return;
      }
      
      // Para móviles, configurar notificaciones locales
      print('📱 Ejecutándose en móvil - configurando notificaciones locales');
      
      // Inicializar timezone
      tz.initializeTimeZones();
      
      // Configurar notificaciones locales
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
      
      final bool? initialized = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      if (initialized == true) {
        // Crear canal de notificaciones para Android
        if (Platform.isAndroid) {
          await _createAndroidNotificationChannel();
        }
        _isInitialized = true;
        print('✅ Servicio de recordatorios inicializado correctamente');
      } else {
        print('❌ Falló la inicialización de notificaciones locales');
      }
      
    } catch (e) {
      print('❌ Error inicializando servicio de recordatorios: $e');
    }
  }
  
  /// Crear canal de notificaciones para Android
  static Future<void> _createAndroidNotificationChannel() async {
    try {
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      
      final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(androidChannel);
        print('✅ Canal de notificaciones Android creado');
      }
    } catch (e) {
      print('❌ Error creando canal Android: $e');
    }
  }
  
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Recordatorio tocado: ${response.payload}');
  }
  
  /// Verificar si las notificaciones están habilitadas
  static Future<bool> areNotificationsEnabled() async {
    try {
      if (kIsWeb) {
        // Para web, verificar permisos de notificación
        return await _checkWebNotificationPermission();
      }
      
      if (!_isInitialized) {
        await initialize();
        if (!_isInitialized) return false;
      }
      
      if (Platform.isAndroid) {
        final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await androidImpl?.areNotificationsEnabled() ?? false;
      } else if (Platform.isIOS) {
        final iosImpl = _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final permissions = await iosImpl?.checkPermissions();
        return permissions?.isEnabled ?? false;
      }
      
      return false;
    } catch (e) {
      print('❌ Error verificando permisos: $e');
      return false;
    }
  }
  
  /// Solicitar permisos de notificaciones
  static Future<bool> requestPermissions() async {
    try {
      print('🔔 Solicitando permisos de notificaciones...');
      
      if (kIsWeb) {
        return await _requestWebNotificationPermission();
      }
      
      if (!_isInitialized) {
        await initialize();
        if (!_isInitialized) return false;
      }
      
      if (Platform.isAndroid) {
        final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await androidImpl?.requestNotificationsPermission() ?? false;
      } else if (Platform.isIOS) {
        final iosImpl = _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        return await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ?? false;
      }
      
      return false;
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      return false;
    }
  }
  
  /// Programar un recordatorio
  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      print('🔔 Programando recordatorio: $title para $scheduledTime');
      
      final now = DateTime.now();
      if (scheduledTime.isBefore(now)) {
        print('⚠️ La hora programada está en el pasado');
        return;
      }
      
      if (kIsWeb) {
        await _scheduleWebReminder(id, title, body, scheduledTime);
        return;
      }
      
      if (!_isInitialized) {
        await initialize();
        if (!_isInitialized) return;
      }
      
      // Para móviles, usar notificaciones locales
      final tz.TZDateTime scheduledDate = tz.TZDateTime.local(
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );
      
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.max,
            showWhen: true,
            enableLights: true,
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print('✅ Recordatorio programado correctamente');
      
    } catch (e) {
      print('❌ Error programando recordatorio: $e');
    }
  }
  
  /// Cancelar un recordatorio
  static Future<void> cancelReminder(int id) async {
    try {
      if (kIsWeb) {
        _cancelWebReminder(id);
        return;
      }
      
      await _localNotifications.cancel(id);
      print('✅ Recordatorio cancelado: $id');
    } catch (e) {
      print('❌ Error cancelando recordatorio: $e');
    }
  }
  
  /// Mostrar notificación de prueba
  static Future<void> showTestNotification() async {
    try {
      if (kIsWeb) {
        await _showWebNotification(
          '🔔 Recordatorio de Prueba',
          'Esta es una notificación de prueba del Calendario Familiar',
        );
        return;
      }
      
      if (!_isInitialized) return;
      
      await _localNotifications.show(
        999,
        '🔔 Recordatorio de Prueba',
        'Esta es una notificación de prueba del Calendario Familiar',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.max,
            showWhen: true,
            enableLights: true,
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      
      print('✅ Notificación de prueba enviada');
      
    } catch (e) {
      print('❌ Error enviando notificación de prueba: $e');
    }
  }
  
  // ===== MÉTODOS PARA WEB =====
  
  /// Verificar permisos de notificación web
  static Future<bool> _checkWebNotificationPermission() async {
    if (!kIsWeb) return false;
    
    try {
      // Usar dart:js para acceder a la API de notificaciones
      final permission = await _getWebNotificationPermission();
      return permission == 'granted';
    } catch (e) {
      print('❌ Error verificando permisos web: $e');
      return false;
    }
  }
  
  /// Solicitar permisos de notificación web
  static Future<bool> _requestWebNotificationPermission() async {
    if (!kIsWeb) return false;
    
    try {
      final permission = await _requestWebNotificationPermissionJS();
      return permission == 'granted';
    } catch (e) {
      print('❌ Error solicitando permisos web: $e');
      return false;
    }
  }
  
  /// Programar recordatorio web usando setTimeout
  static Future<void> _scheduleWebReminder(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    if (!kIsWeb) return;
    
    try {
      final now = DateTime.now();
      final delay = scheduledTime.difference(now).inMilliseconds;
      
      if (delay > 0) {
        // Usar Future.delayed para simular notificación programada
        // NOTA: Esto solo funciona mientras la pestaña esté abierta
        Future.delayed(Duration(milliseconds: delay), () {
          print('⏰ Ejecutando recordatorio web: $title');
          _showWebNotification(title, body);
        });
        
        print('✅ Recordatorio web programado para: $title en ${Duration(milliseconds: delay)}');
        print('⚠️ NOTA: El recordatorio solo funcionará mientras la pestaña esté abierta');
      } else {
        print('⚠️ La hora programada está en el pasado');
      }
    } catch (e) {
      print('❌ Error programando recordatorio web: $e');
    }
  }
  
  /// Cancelar recordatorio web
  static void _cancelWebReminder(int id) {
    // En web, no podemos cancelar recordatorios programados con Future.delayed
    // Esto es una limitación de la implementación web
    print('⚠️ No se pueden cancelar recordatorios web programados');
  }
  
  /// Mostrar notificación web
  static Future<void> _showWebNotification(String title, String body) async {
    if (!kIsWeb) return;
    
    try {
      await _showWebNotificationJS(title, body);
      print('✅ Notificación web mostrada: $title');
    } catch (e) {
      print('❌ Error mostrando notificación web: $e');
    }
  }
  
  // ===== MÉTODOS JAVASCRIPT =====
  
  /// Obtener permisos de notificación web (JavaScript)
  static Future<String> _getWebNotificationPermission() async {
    if (!kIsWeb) return 'denied';
    
    try {
      final permission = js.context['Notification']['permission'];
      return permission?.toString() ?? 'default';
    } catch (e) {
      print('❌ Error obteniendo permisos web: $e');
      return 'denied';
    }
  }
  
  /// Solicitar permisos de notificación web (JavaScript)
  static Future<String> _requestWebNotificationPermissionJS() async {
    if (!kIsWeb) return 'denied';
    
    try {
      final promise = js.context['Notification']['requestPermission']();
      final permission = await _promiseToFuture(promise);
      return permission?.toString() ?? 'denied';
    } catch (e) {
      print('❌ Error solicitando permisos web: $e');
      return 'denied';
    }
  }
  
  /// Mostrar notificación web (JavaScript)
  static Future<void> _showWebNotificationJS(String title, String body) async {
    if (!kIsWeb) return;
    
    try {
      final permission = await _getWebNotificationPermission();
      if (permission != 'granted') {
        print('⚠️ Permisos de notificación no concedidos');
        return;
      }
      
      // Crear notificación web
      final notification = js.JsObject(js.context['Notification'], [title, {
        'body': body,
        'icon': '/favicon.png',
        'badge': '/favicon.png',
        'tag': 'calendar-reminder',
        'requireInteraction': true,
      }]);
      
      // Configurar evento de click
      notification['onclick'] = js.allowInterop((event) {
        event['target']['close']();
        js.context['window']['focus']();
      });
      
      // Auto-cerrar después de 5 segundos
      Future.delayed(const Duration(seconds: 5), () {
        try {
          notification['close']();
        } catch (e) {
          // Ignorar errores al cerrar
        }
      });
      
    } catch (e) {
      print('❌ Error mostrando notificación web: $e');
    }
  }
  
  /// Convertir Promise de JavaScript a Future de Dart
  static Future<dynamic> _promiseToFuture(js.JsObject promise) {
    final completer = Completer<dynamic>();
    
    promise.callMethod('then', [
      js.allowInterop((result) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      }),
      js.allowInterop((error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      }),
    ]);
    
    return completer.future;
  }
}
