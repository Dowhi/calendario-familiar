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
        requestAlertPermission: false, // No solicitar permisos durante inicialización
        requestBadgePermission: false,
        requestSoundPermission: false,
        requestCriticalPermission: false,
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
      
      if (!initialized!) {
        print('❌ Falló la inicialización básica de notificaciones');
        _isInitialized = false;
        return;
      }
      
      // Crear canal de notificaciones para Android PRIMERO
      if (Platform.isAndroid) {
        await _createAndroidNotificationChannel();
      }
      
      _isInitialized = true;
      print('✅ Servicio de notificaciones completamente inicializado');
      
    } catch (e) {
      print('❌ Error inicializando servicio de notificaciones: $e');
      _isInitialized = false;
    }
  }
  
  /// Crear canal de notificaciones para Android
  static Future<void> _createAndroidNotificationChannel() async {
    try {
      print('🤖 Creando canal de notificaciones Android...');
      
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
        print('✅ Canal de notificaciones Android creado exitosamente');
        
        // Verificar que el canal se creó correctamente
        try {
          final channels = await androidImpl.getNotificationChannels();
          if (channels != null) {
            print('📋 Canales disponibles: ${channels.map((c) => c.id).toList()}');
          } else {
            print('📋 No se pudieron obtener los canales (null)');
          }
        } catch (e) {
          print('⚠️ No se pudieron obtener los canales: $e');
        }
      } else {
        print('❌ No se pudo obtener AndroidFlutterLocalNotificationsPlugin');
      }
    } catch (e) {
      print('❌ Error creando canal Android: $e');
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
      print('🔍 Verificando estado de permisos...');
      
      if (kIsWeb) {
        print('🌐 En web - permisos no disponibles');
        return false;
      }
      
      if (!_isInitialized) {
        print('⚠️ Servicio no inicializado, intentando inicializar...');
        await initialize();
        if (!_isInitialized) {
          print('❌ No se pudo inicializar el servicio');
          return false;
        }
      }
      
      print('📱 Verificando permisos en: ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "Otro"}');
      
      if (Platform.isAndroid) {
        final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImpl != null) {
          try {
            final bool? result = await androidImpl.areNotificationsEnabled();
            print('🤖 Estado permisos Android: $result');
            return result ?? false;
          } catch (e) {
            print('❌ Error verificando permisos Android: $e');
            return false;
          }
        } else {
          print('❌ Android implementation no encontrada para verificación');
        }
      } else if (Platform.isIOS) {
        final iosImpl = _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        
        if (iosImpl != null) {
          try {
            final permissions = await iosImpl.checkPermissions();
            final result = permissions?.isEnabled ?? false;
            print('🍎 Estado permisos iOS: $result');
            return result;
          } catch (e) {
            print('❌ Error verificando permisos iOS: $e');
            return false;
          }
        } else {
          print('❌ iOS implementation no encontrada para verificación');
        }
      }
      
      print('⚠️ Plataforma no soportada para verificación de permisos');
      return false;
    } catch (e) {
      print('❌ Error verificando permisos de notificaciones: $e');
      return false;
    }
  }
  
  /// Solicitar permisos de notificaciones de manera robusta
  static Future<bool> requestPermissions() async {
    try {
      print('🔔 Iniciando solicitud de permisos...');
      
      if (kIsWeb) {
        print('🌐 Ejecutándose en web - permisos no disponibles');
        return false;
      }
      
      if (!_isInitialized) {
        print('⚠️ Servicio no inicializado, inicializando...');
        await initialize();
        if (!_isInitialized) {
          print('❌ No se pudo inicializar el servicio');
          return false;
        }
      }
      
      print('📱 Plataforma detectada: ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "Otro"}');
      
      if (Platform.isAndroid) {
        final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImpl != null) {
          print('🤖 Android implementation encontrada, solicitando permisos...');
          
          // Solicitar permiso básico de notificaciones
          try {
            final bool? notificationsGranted = await androidImpl.requestNotificationsPermission();
            print('🔐 Permiso de notificaciones: $notificationsGranted');
            
            // Solicitar permiso de alarmas exactas
            try {
              final bool? exactAlarmGranted = await androidImpl.requestExactAlarmsPermission();
              print('⏰ Permiso de alarmas exactas: $exactAlarmGranted');
            } catch (e) {
              print('⚠️ Error solicitando permiso de alarmas exactas: $e');
            }
            
            final result = notificationsGranted ?? false;
            print('✅ Resultado final de permisos Android: $result');
            return result;
          } catch (e) {
            print('❌ Error solicitando permisos Android: $e');
            return false;
          }
        } else {
          print('❌ Android implementation no encontrada');
        }
      } else if (Platform.isIOS) {
        final iosImpl = _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        
        if (iosImpl != null) {
          print('🍎 iOS implementation encontrada, solicitando permisos...');
          try {
            final bool? granted = await iosImpl.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
              critical: true,
            );
            print('🍎 Permisos iOS: $granted');
            return granted ?? false;
          } catch (e) {
            print('❌ Error solicitando permisos iOS: $e');
            return false;
          }
        } else {
          print('❌ iOS implementation no encontrada');
        }
      }
      
      print('⚠️ No se pudo determinar la plataforma o implementation');
      return false;
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
      
      if (event.notifyMinutesBefore <= 0 || event.startAt == null) {
        print('⚠️ Evento sin recordatorio configurado o fecha de inicio');
        return;
      }
      
      print('📅 Programando notificación para evento: ${event.title}');
      
      final notificationTime = event.startAt!.subtract(Duration(minutes: event.notifyMinutesBefore));
      
      // Verificar que la notificación sea en el futuro
      if (notificationTime.isBefore(DateTime.now())) {
        print('⚠️ La notificación está en el pasado, no se programará');
        return;
      }
      
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);
      
      await _localNotifications.zonedSchedule(
        event.id.hashCode,
        '📅 ${event.title}',
        'El evento "${event.title}" comenzará en ${event.notifyMinutesBefore} minutos',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.event,
            showWhen: true,
            when: scheduledDate.millisecondsSinceEpoch,
            enableLights: true,
            ledColor: const Color(0xFF4CAF50),
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            badgeNumber: 1,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      print('✅ Notificación programada para: ${event.title} a las $scheduledDate');
      
    } catch (e) {
      print('❌ Error programando notificación: $e');
    }
  }
  
  static Future<void> cancelEventNotification(AppEvent event) async {
    try {
      if (kIsWeb) {
        print('🌐 En web - notificaciones locales no disponibles');
        return;
      }
      
      await _localNotifications.cancel(event.id.hashCode);
      print('✅ Notificación cancelada para evento: ${event.title}');
      
    } catch (e) {
      print('❌ Error cancelando notificación: $e');
    }
  }
  
  static Future<void> cancelAllNotifications() async {
    try {
      if (kIsWeb) {
        print('🌐 En web - notificaciones locales no disponibles');
        return;
      }
      
      await _localNotifications.cancelAll();
      print('✅ Todas las notificaciones canceladas');
      
    } catch (e) {
      print('❌ Error cancelando todas las notificaciones: $e');
    }
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
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            badgeNumber: 1,
          ),
        ),
      );
      
      print('✅ Notificación de prueba enviada');
      
    } catch (e) {
      print('❌ Error enviando notificación de prueba: $e');
    }
  }
  
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
      
      print('⏰ Programando notificación inmediata en $minutesFromNow minutos...');
      
      final notificationTime = DateTime.now().add(Duration(minutes: minutesFromNow));
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);
      
      await _localNotifications.zonedSchedule(
        998, // ID único para notificación programada de prueba
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
            showWhen: true,
            when: scheduledDate.millisecondsSinceEpoch,
            enableLights: true,
            ledColor: const Color(0xFF2196F3),
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            badgeNumber: 1,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print('✅ Notificación programada para: $title a las $scheduledDate');
      
    } catch (e) {
      print('❌ Error programando notificación inmediata: $e');
    }
  }
}
