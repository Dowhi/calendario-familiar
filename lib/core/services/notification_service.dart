import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:calendario_familiar/core/models/app_event.dart';
import 'package:calendario_familiar/core/services/web_notification_service.dart';

/// Servicio simplificado de notificaciones locales
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  static const String _channelId = 'calendar_events';
  static const String _channelName = 'Eventos del Calendario';
  static const String _channelDescription = 'Notificaciones de eventos del calendario familiar';
  
  static bool _isInitialized = false;
  
  /// Inicializar el servicio de notificaciones
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔔 Inicializando servicio de notificaciones...');
      
      // Verificar si estamos en web
      if (kIsWeb) {
        print('🌐 Ejecutándose en web - inicializando servicio web');
        await WebNotificationService.initialize();
        _isInitialized = true;
        return;
      }
      
      // Configurar notificaciones locales para móviles
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
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
      
      if (initialized == false) {
        print('❌ Falló la inicialización básica de notificaciones');
        _isInitialized = false;
        return;
      }
      
      // Crear canal de notificaciones para Android
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
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        enableLights: true,
      );
      
      final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(androidChannel);
        print('✅ Canal de notificaciones Android creado exitosamente');
      } else {
        print('❌ No se pudo obtener AndroidFlutterLocalNotificationsPlugin');
      }
    } catch (e) {
      print('❌ Error creando canal Android: $e');
    }
  }
  
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notificación tocada: ${response.payload}');
  }
  
  /// Verificar si las notificaciones están habilitadas
  static Future<bool> areNotificationsEnabled() async {
    try {
      if (kIsWeb) {
        return await WebNotificationService.areNotificationsEnabled();
      }
      
      if (!_isInitialized) {
        await initialize();
        if (!_isInitialized) {
          return false;
        }
      }
      
      if (Platform.isAndroid) {
        final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImpl != null) {
          final bool? result = await androidImpl.areNotificationsEnabled();
          return result ?? false;
        }
      } else if (Platform.isIOS) {
        final iosImpl = _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        
        if (iosImpl != null) {
          final permissions = await iosImpl.checkPermissions();
          return permissions?.isEnabled ?? false;
        }
      }
      
      return false;
    } catch (e) {
      print('❌ Error verificando permisos de notificaciones: $e');
      return false;
    }
  }
  
  /// Solicitar permisos de notificaciones
  static Future<bool> requestPermissions() async {
    try {
      print('🔔 Solicitando permisos...');
      
      if (kIsWeb) {
        return await WebNotificationService.requestPermissions();
      }
      
      if (!_isInitialized) {
        await initialize();
        if (!_isInitialized) {
          return false;
        }
      }
      
      if (Platform.isAndroid) {
        final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImpl != null) {
          final bool? notificationsGranted = await androidImpl.requestNotificationsPermission();
          
          // Intentar solicitar permiso de alarmas exactas
          try {
            await androidImpl.requestExactAlarmsPermission();
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
          return granted ?? false;
        }
      }
      
      return false;
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      return false;
    }
  }
  
  /// Programar una notificación para un evento
  static Future<void> scheduleEventNotification(AppEvent event) async {
    try {
      if (kIsWeb || !_isInitialized) {
        return;
      }
      
      if (event.notifyMinutesBefore <= 0 || event.startAt == null) {
        return;
      }
      
      final notificationTime = event.startAt!.subtract(Duration(minutes: event.notifyMinutesBefore));
      
      if (notificationTime.isBefore(DateTime.now())) {
        return;
      }
      
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);
      
      await _localNotifications.zonedSchedule(
        event.id.hashCode,
        '📅 ${event.title}',
        'El evento comenzará en ${event.notifyMinutesBefore} minutos',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.event,
            showWhen: true,
            enableLights: true,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print('✅ Notificación programada para: ${event.title}');
      
    } catch (e) {
      print('❌ Error programando notificación: $e');
    }
  }
  
  /// Cancelar notificación de un evento
  static Future<void> cancelEventNotification(AppEvent event) async {
    try {
      if (kIsWeb) return;
      await _localNotifications.cancel(event.id.hashCode);
      print('✅ Notificación cancelada para evento: ${event.title}');
    } catch (e) {
      print('❌ Error cancelando notificación: $e');
    }
  }
  
  /// Cancelar todas las notificaciones
  static Future<void> cancelAllNotifications() async {
    try {
      if (kIsWeb) return;
      await _localNotifications.cancelAll();
      print('✅ Todas las notificaciones canceladas');
    } catch (e) {
      print('❌ Error cancelando todas las notificaciones: $e');
    }
  }
  
  /// Mostrar notificación de prueba
  static Future<void> showTestNotification() async {
    try {
      if (kIsWeb) {
        await WebNotificationService.showTestNotification();
        return;
      }
      
      if (!_isInitialized) {
        return;
      }
      
      await _localNotifications.show(
        999,
        '🔔 Notificación de Prueba',
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
            fullScreenIntent: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
      );
      
      print('✅ Notificación de prueba enviada');
      
    } catch (e) {
      print('❌ Error enviando notificación de prueba: $e');
    }
  }
}
