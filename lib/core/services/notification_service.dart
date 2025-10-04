import 'package:flutter/foundation.dart';
import 'package:calendario_familiar/core/models/app_event.dart';
import 'package:calendario_familiar/core/services/reminder_service.dart';

/// Servicio simplificado de notificaciones locales
/// Wrapper alrededor de ReminderService para mantener compatibilidad
class NotificationService {
  
  /// Inicializar el servicio de notificaciones
  static Future<void> initialize() async {
    await ReminderService.initialize();
  }
  
  /// Verificar si las notificaciones están habilitadas
  static Future<bool> areNotificationsEnabled() async {
    return await ReminderService.areNotificationsEnabled();
  }
  
  /// Solicitar permisos de notificaciones
  static Future<bool> requestPermissions() async {
    return await ReminderService.requestPermissions();
  }
  
  /// Programar una notificación para un evento
  static Future<void> scheduleEventNotification(AppEvent event) async {
    try {
      print('🔔 Programando notificación para evento: ${event.title}');
      
      // Validaciones básicas
      if (event.startAt == null) {
        print('⚠️ Evento sin fecha de inicio');
        return;
      }
      
      // Asegurar que los minutos de anticipación sean positivos
      final notifyMinutes = event.notifyMinutesBefore.abs();
      if (notifyMinutes == 0) {
        print('⚠️ Los minutos de anticipación no pueden ser cero');
        return;
      }
      
      final notificationTime = event.startAt!.subtract(Duration(minutes: notifyMinutes));
      final now = DateTime.now();
      
      if (notificationTime.isBefore(now)) {
        print('⚠️ Notificación en el pasado, no se programará');
        return;
      }
      
      await ReminderService.scheduleReminder(
        id: event.id.hashCode,
        title: '📅 ${event.title}',
        body: 'El evento comenzará en ${event.notifyMinutesBefore} minutos',
        scheduledTime: notificationTime,
      );
      
      print('✅ Notificación programada para: ${event.title}');
      
    } catch (e) {
      print('❌ Error programando notificación: $e');
    }
  }
  
  /// Cancelar notificación de un evento
  static Future<void> cancelEventNotification(AppEvent event) async {
    await ReminderService.cancelReminder(event.id.hashCode);
  }
  
  /// Cancelar todas las notificaciones
  static Future<void> cancelAllNotifications() async {
    // En la nueva implementación, no hay un método para cancelar todas
    // Las notificaciones se cancelan individualmente
    print('⚠️ cancelAllNotifications no está implementado en la nueva versión');
  }
  
  /// Mostrar notificación de prueba
  static Future<void> showTestNotification() async {
    await ReminderService.showTestNotification();
  }
}
