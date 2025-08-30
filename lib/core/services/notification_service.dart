import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:calendario_familiar/core/models/app_event.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  static const String _channelId = 'calendar_events';
  static const String _channelName = 'Eventos del Calendario';
  static const String _channelDescription = 'Notificaciones de eventos del calendario familiar';
  
  static Future<void> initialize() async {
    try {
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
      
      final bool? initialized = await _localNotifications.initialize(initSettings);
      print('Notificaciones inicializadas: $initialized');
      
      // Crear canal de notificaciones para Android
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
          
      print('Canal de notificaciones creado correctamente');
    } catch (e) {
      print('Error inicializando notificaciones: $e');
      rethrow;
    }
  }
  
  static Future<String?> getFCMToken() async {
    // Retornar null por ahora ya que no tenemos Firebase configurado
    return null;
  }
  
  static Future<bool> areNotificationsEnabled() async {
    try {
      final bool? result = await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return result ?? false;
    } catch (e) {
      print('Error verificando permisos de notificaciones: $e');
      return false;
    }
  }
  
  static Future<void> scheduleEventNotification(AppEvent event) async {
    if (event.notifyMinutesBefore <= 0) return;
    
    // Verificar que startAt no sea null
    if (event.startAt == null) return;
    
    final notificationTime = event.startAt!.subtract(
      Duration(minutes: event.notifyMinutesBefore),
    );
    
    // Solo programar si la notificación es en el futuro
    if (notificationTime.isBefore(DateTime.now())) return;
    
    final notificationId = event.id.hashCode;
    
    await _localNotifications.zonedSchedule(
      notificationId,
      'Recordatorio: ${event.title}',
      event.notes ?? 'Tienes un evento programado',
      tz.TZDateTime.from(notificationTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
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
      await _localNotifications.show(
        0,
        'Notificación de prueba',
        'Esta es una notificación de prueba del Calendario Familiar',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      print('Notificación de prueba enviada correctamente');
    } catch (e) {
      print('Error enviando notificación de prueba: $e');
      rethrow;
    }
  }
}

