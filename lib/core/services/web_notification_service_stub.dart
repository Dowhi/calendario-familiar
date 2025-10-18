import 'package:calendario_familiar/core/models/app_event.dart';

/// Stub para notificaciones web en plataformas no web
class WebNotificationService {
  static Future<void> initialize() async {
    // No hacer nada en plataformas móviles
  }

  static Future<bool> areNotificationsEnabled() async {
    return false;
  }

  static Future<bool> requestPermissions() async {
    return false;
  }

  static Future<void> scheduleEventNotification({
    required String eventId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // No hacer nada en plataformas móviles
  }

  static Future<void> cancelEventNotification(AppEvent event) async {
    // No hacer nada en plataformas móviles
  }

  static Future<void> cancelAllNotifications() async {
    // No hacer nada en plataformas móviles
  }

  static Future<void> showTestNotification() async {
    // No hacer nada en plataformas móviles
  }
}

