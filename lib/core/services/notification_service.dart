import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:calendario_familiar/core/models/app_event.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  static const String _channelId = 'calendar_events';
  static const String _channelName = 'Eventos del Calendario';
  static const String _channelDescription = 'Notificaciones de eventos del calendario familiar';
  
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔔 Inicializando servicio de notificaciones...');
      
      // Verificar si estamos en web
      if (kIsWeb) {
        print('🌐 Ejecutándose en web - notificaciones locales no disponibles');
        _isInitialized = true;
        return;
      }
      
      // Configurar notificaciones locales para móviles
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      final bool? initialized = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      print('✅ Notificaciones inicializadas: $initialized');
      
      // Crear canal de notificaciones para Android
      if (!kIsWeb && Platform.isAndroid) {
        const androidChannel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        
        final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImpl != null) {
          await androidImpl.createNotificationChannel(androidChannel);
          print('✅ Canal de notificaciones Android creado');
          
          // Solicitar permisos en Android 13+
          try {
            final bool? granted = await androidImpl.requestNotificationsPermission();
            print('🔐 Permiso POST_NOTIFICATIONS concedido: $granted');
          } catch (e) {
            print('⚠️ Error solicitando permiso de notificaciones: $e');
          }
          
          // Solicitar permiso para alarmas exactas
          try {
            final bool? exactAlarmGranted = await androidImpl.requestExactAlarmsPermission();
            print('⏰ Permiso USE_EXACT_ALARM concedido: $exactAlarmGranted');
          } catch (e) {
            print('⚠️ Error solicitando permiso de alarmas exactas: $e');
          }
        }
      }
      
      // Configurar permisos para iOS
      if (!kIsWeb && Platform.isIOS) {
        final iosImpl = _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        
        if (iosImpl != null) {
          final bool? granted = await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
          print('🍎 Permisos iOS concedidos: $granted');
        }
      }
      
      _isInitialized = true;
      print('✅ Servicio de notificaciones inicializado completamente');
      
    } catch (e) {
      print('❌ Error inicializando notificaciones: $e');
      // No rethrow en web para evitar errores
      if (!kIsWeb) {
        rethrow;
      }
    }
  }
  
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notificación tocada: ${response.payload}');
    // Aquí puedes manejar la navegación cuando se toca una notificación
  }
  
  static Future<String?> getFCMToken() async {
    // Retornar null por ahora ya que no tenemos Firebase configurado
    return null;
  }
  
  static Future<bool> areNotificationsEnabled() async {
    try {
      if (kIsWeb) return false;
      
      if (Platform.isAndroid) {
        final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final bool? result = await androidImpl?.areNotificationsEnabled();
        return result ?? false;
      } else if (Platform.isIOS) {
        final iosImpl = _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final permissions = await iosImpl?.checkPermissions();
        // checkPermissions() retorna NotificationsEnabledOptions, no bool
        return permissions?.isEnabled ?? false;
      }
      
      return true; // Para otras plataformas, asumir que están habilitadas
    } catch (e) {
      print('Error verificando permisos de notificaciones: $e');
      return false;
    }
  }
  
  /// Solicitar permisos de notificaciones de manera robusta
  static Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) return false;
      
      if (!_isInitialized) {
        await initialize();
      }
      
      if (Platform.isAndroid) {
        final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImpl != null) {
          // Solicitar permiso básico de notificaciones
          final bool? notificationsGranted = await androidImpl.requestNotificationsPermission();
          print('🔐 Permiso de notificaciones: $notificationsGranted');
          
          // Solicitar permiso de alarmas exactas
          try {
            final bool? exactAlarmGranted = await androidImpl.requestExactAlarmsPermission();
            print('⏰ Permiso de alarmas exactas: $exactAlarmGranted');
          } catch (e) {
            print('⚠️ Error solicitando permiso de alarmas exactas: $e');
          }
          
          return notificationsGranted ?? false;
        }
      } else if (Platform.isIOS) {
        final iosImpl = _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        
        if (iosImpl != null) {
          final bool? granted = await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
          print('🍎 Permisos iOS: $granted');
          return granted ?? false;
        }
      }
      
      return true; // Para otras plataformas
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      return false;
    }
  }
  
  static Future<void> scheduleEventNotification(AppEvent event) async {
    try {
      if (kIsWeb) {
        print('🌐 En web - notificaciones locales no disponibles');
        return;
      }
      
      if (!_isInitialized) {
        print('❌ Servicio de notificaciones no inicializado');
        return;
      }
      
      if (event.notifyMinutesBefore <= 0) {
        print('❌ Minutos de notificación inválidos: ${event.notifyMinutesBefore}');
        return;
      }
      
      // Verificar que startAt no sea null
      if (event.startAt == null) {
        print('❌ Evento sin fecha de inicio: ${event.title}');
        return;
      }
      
      final notificationTime = event.startAt!.subtract(
        Duration(minutes: event.notifyMinutesBefore),
      );
      
      // Solo programar si la notificación es en el futuro
      if (notificationTime.isBefore(DateTime.now())) {
        print('❌ Tiempo de notificación en el pasado: $notificationTime');
        return;
      }
      
      final notificationId = event.id.hashCode;
      
      print('🔔 Programando notificación para: ${event.title}');
      print('⏰ Tiempo de notificación: $notificationTime');
      print('📅 Tiempo del evento: ${event.startAt}');
      
      await _localNotifications.zonedSchedule(
        notificationId,
        'Recordatorio: ${event.title}',
        event.notes?.isNotEmpty == true ? event.notes! : 'Tienes un evento programado',
        tz.TZDateTime.from(notificationTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.alarm,
            fullScreenIntent: true,
            showWhen: true,
            when: notificationTime.millisecondsSinceEpoch,
            usesChronometer: false,
            enableLights: true,
            ledColor: const Color(0xFF2196F3),
            ledOnMs: 1000,
            ledOffMs: 500,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('notification'),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
            autoCancel: true,
            ongoing: false,
            silent: false,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'notification.wav',
            badgeNumber: 1,
            threadIdentifier: 'calendar_events',
            categoryIdentifier: 'EVENT_REMINDER',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'event_${event.id}',
      );
      
      print('✅ Notificación programada exitosamente para: ${event.title}');
      
    } catch (e) {
      print('❌ Error programando notificación para ${event.title}: $e');
      rethrow;
    }
  }
  
  static Future<void> cancelEventNotification(AppEvent event) async {
    final notificationId = event.id.hashCode;
    await _localNotifications.cancel(notificationId);
  }
  
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
  
  static Future<void> showTestNotification() async {
    try {
      if (kIsWeb) {
        print('🌐 En web - notificaciones locales no disponibles');
        return;
      }
      
      if (!_isInitialized) {
        print('❌ Servicio de notificaciones no inicializado');
        return;
      }
      
      print('🔔 Enviando notificación de prueba...');
      
      await _localNotifications.show(
        999, // ID único para notificación de prueba
        '🔔 Notificación de Prueba',
        'Esta es una notificación de prueba del Calendario Familiar. Si ves esto, las notificaciones están funcionando correctamente.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.message,
            showWhen: true,
            when: DateTime.now().millisecondsSinceEpoch,
            enableLights: true,
            ledColor: const Color(0xFF4CAF50),
            ledOnMs: 1000,
            ledOffMs: 500,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
            autoCancel: true,
            ongoing: false,
            silent: false,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            badgeNumber: 1,
            threadIdentifier: 'test_notification',
            categoryIdentifier: 'TEST_NOTIFICATION',
          ),
        ),
        payload: 'test_notification',
      );
      
      print('✅ Notificación de prueba enviada correctamente');
      
    } catch (e) {
      print('❌ Error enviando notificación de prueba: $e');
      rethrow;
    }
  }
  
  // Método para programar notificación inmediata (para pruebas)
  static Future<void> scheduleImmediateNotification(String title, String body, {int minutesFromNow = 1}) async {
    try {
      if (kIsWeb) {
        print('🌐 En web - notificaciones locales no disponibles');
        return;
      }
      
      if (!_isInitialized) {
        print('❌ Servicio de notificaciones no inicializado');
        return;
      }
      
      final notificationTime = DateTime.now().add(Duration(minutes: minutesFromNow));
      final notificationId = DateTime.now().millisecondsSinceEpoch;
      
      print('🔔 Programando notificación inmediata para: $title');
      print('⏰ Tiempo: $notificationTime');
      
      await _localNotifications.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(notificationTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.alarm,
            showWhen: true,
            when: notificationTime.millisecondsSinceEpoch,
            enableLights: true,
            ledColor: const Color(0xFFFF9800),
            ledOnMs: 1000,
            ledOffMs: 500,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
            autoCancel: true,
            ongoing: false,
            silent: false,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            badgeNumber: 1,
            threadIdentifier: 'immediate_notification',
            categoryIdentifier: 'IMMEDIATE_REMINDER',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'immediate_$notificationId',
      );
      
      print('✅ Notificación inmediata programada exitosamente');
      
    } catch (e) {
      print('❌ Error programando notificación inmediata: $e');
      rethrow;
    }
  }
  
  // Método para verificar el estado de las notificaciones
  static Future<Map<String, dynamic>> getNotificationStatus() async {
    try {
      final status = <String, dynamic>{
        'initialized': _isInitialized,
        'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        'notificationsEnabled': false,
        'exactAlarmsEnabled': false,
      };
      
      if (kIsWeb) {
        status['notificationsEnabled'] = false;
        status['message'] = 'Notificaciones locales no disponibles en web';
        return status;
      }
      
      if (Platform.isAndroid) {
        final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImpl != null) {
          status['notificationsEnabled'] = await androidImpl.areNotificationsEnabled() ?? false;
          status['exactAlarmsEnabled'] = await androidImpl.canScheduleExactNotifications() ?? false;
        }
      } else if (Platform.isIOS) {
        final iosImpl = _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        
        if (iosImpl != null) {
          status['notificationsEnabled'] = await iosImpl.checkPermissions() ?? false;
        }
      } else {
        // Para Windows y otras plataformas
        status['notificationsEnabled'] = true; // Asumir que están habilitadas
      }
      
      return status;
      
    } catch (e) {
      print('❌ Error obteniendo estado de notificaciones: $e');
      return {
        'initialized': _isInitialized,
        'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        'notificationsEnabled': false,
        'exactAlarmsEnabled': false,
        'error': e.toString(),
      };
    }
  }
}

