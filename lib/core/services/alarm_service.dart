import 'package:shared_preferences/shared_preferences.dart';
import 'package:calendario_familiar/core/services/notification_service.dart';
import 'package:calendario_familiar/core/services/notification_settings_service.dart';

/// Servicio para gestionar alarmas y recordatorios
class AlarmService {
  static const String _alarmsPrefix = 'alarm_';
  static const String _enabledKey = '_enabled';
  static const String _hourKey = '_hour';
  static const String _minuteKey = '_minute';
  static const String _daysBeforeKey = '_days_before';
  static const String _eventTextKey = '_event_text';
  static const String _eventDateKey = '_event_date';

  /// Configurar una alarma para un evento
  static Future<bool> scheduleAlarmForEvent({
    required String eventId,
    required String eventText,
    required DateTime eventDate,
    required int alarmNumber,
    required int hour,
    required int minute,
    required int daysBefore,
  }) async {
    try {
      // Verificar configuración global
      final notificationsEnabled = await NotificationSettingsService.areNotificationsEnabled();
      if (!notificationsEnabled) {
        print('❌ Notificaciones deshabilitadas globalmente');
        return false;
      }

      final alarmRemindersEnabled = await NotificationSettingsService.areAlarmRemindersEnabled();
      if (!alarmRemindersEnabled) {
        print('❌ Recordatorios de alarma deshabilitados');
        return false;
      }

      // Verificar permisos
      final hasPermissions = await NotificationService.areNotificationsEnabled();
      if (!hasPermissions) {
        print('❌ Sin permisos de notificación');
        return false;
      }

      // Calcular fecha y hora de la alarma
      final alarmDate = eventDate.subtract(Duration(days: daysBefore));
      final alarmDateTime = DateTime(
        alarmDate.year,
        alarmDate.month,
        alarmDate.day,
        hour,
        minute,
      );

      // Verificar que la alarma sea en el futuro
      if (alarmDateTime.isBefore(DateTime.now())) {
        print('❌ La alarma debe ser en el futuro');
        return false;
      }

      // Programar la notificación
      final notificationId = _generateNotificationId(eventId, alarmNumber);
      final minutesUntilAlarm = alarmDateTime.difference(DateTime.now()).inMinutes;

      await NotificationService.scheduleImmediateNotification(
        '🔔 Recordatorio: $eventText',
        _generateAlarmMessage(eventText, daysBefore, hour, minute),
        minutesFromNow: minutesUntilAlarm.clamp(1, 525600), // Máximo 1 año
      );

      // Guardar configuración local
      await _saveAlarmConfiguration(
        eventId: eventId,
        alarmNumber: alarmNumber,
        eventText: eventText,
        eventDate: eventDate,
        hour: hour,
        minute: minute,
        daysBefore: daysBefore,
      );

      print('✅ Alarma $alarmNumber programada para: $alarmDateTime');
      return true;
    } catch (e) {
      print('❌ Error programando alarma: $e');
      return false;
    }
  }

  /// Cancelar una alarma específica
  static Future<void> cancelAlarm(String eventId, int alarmNumber) async {
    try {
      final notificationId = _generateNotificationId(eventId, alarmNumber);
      await NotificationService.cancelEventNotification(
        _createTempEventForCancellation(notificationId),
      );
      
      // Limpiar configuración local
      await _removeAlarmConfiguration(eventId, alarmNumber);
      
      print('✅ Alarma $alarmNumber cancelada para evento $eventId');
    } catch (e) {
      print('❌ Error cancelando alarma: $e');
    }
  }

  /// Obtener configuración de alarmas para un evento
  static Future<Map<String, dynamic>?> getAlarmConfiguration(String eventId, int alarmNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_alarmsPrefix}${eventId}_$alarmNumber';
      
      final enabled = prefs.getBool('${key}${_enabledKey}');
      if (enabled == null || !enabled) return null;

      return {
        'enabled': enabled,
        'hour': prefs.getInt('${key}${_hourKey}') ?? 9,
        'minute': prefs.getInt('${key}${_minuteKey}') ?? 0,
        'daysBefore': prefs.getInt('${key}${_daysBeforeKey}') ?? 0,
        'eventText': prefs.getString('${key}${_eventTextKey}') ?? '',
        'eventDate': DateTime.tryParse(prefs.getString('${key}${_eventDateKey}') ?? '') ?? DateTime.now(),
      };
    } catch (e) {
      print('❌ Error obteniendo configuración de alarma: $e');
      return null;
    }
  }

  /// Obtener todas las alarmas configuradas
  static Future<List<Map<String, dynamic>>> getAllAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final alarmKeys = keys.where((key) => key.startsWith(_alarmsPrefix) && key.endsWith(_enabledKey));
      
      final alarms = <Map<String, dynamic>>[];
      
      for (final key in alarmKeys) {
        final baseKey = key.replaceAll(_enabledKey, '');
        final parts = baseKey.replaceFirst(_alarmsPrefix, '').split('_');
        
        if (parts.length >= 2) {
          final eventId = parts.sublist(0, parts.length - 1).join('_');
          final alarmNumber = int.tryParse(parts.last) ?? 1;
          
          final config = await getAlarmConfiguration(eventId, alarmNumber);
          if (config != null) {
            alarms.add({
              'eventId': eventId,
              'alarmNumber': alarmNumber,
              ...config,
            });
          }
        }
      }
      
      return alarms;
    } catch (e) {
      print('❌ Error obteniendo todas las alarmas: $e');
      return [];
    }
  }

  /// Limpiar alarmas expiradas
  static Future<void> cleanupExpiredAlarms() async {
    try {
      final alarms = await getAllAlarms();
      final now = DateTime.now();
      
      for (final alarm in alarms) {
        final eventDate = alarm['eventDate'] as DateTime;
        final daysBefore = alarm['daysBefore'] as int;
        final hour = alarm['hour'] as int;
        final minute = alarm['minute'] as int;
        
        final alarmDate = eventDate.subtract(Duration(days: daysBefore));
        final alarmDateTime = DateTime(
          alarmDate.year,
          alarmDate.month,
          alarmDate.day,
          hour,
          minute,
        );
        
        // Si la alarma ya pasó, cancelarla
        if (alarmDateTime.isBefore(now)) {
          await cancelAlarm(alarm['eventId'] as String, alarm['alarmNumber'] as int);
        }
      }
      
      print('✅ Limpieza de alarmas expiradas completada');
    } catch (e) {
      print('❌ Error limpiando alarmas expiradas: $e');
    }
  }

  /// Probar alarma inmediata
  static Future<bool> testAlarm(String eventText) async {
    try {
      final notificationsEnabled = await NotificationSettingsService.areNotificationsEnabled();
      if (!notificationsEnabled) {
        return false;
      }

      await NotificationService.scheduleImmediateNotification(
        '🧪 Prueba de Alarma',
        'Recordatorio de prueba para: $eventText',
        minutesFromNow: 1,
      );

      print('✅ Alarma de prueba programada');
      return true;
    } catch (e) {
      print('❌ Error programando alarma de prueba: $e');
      return false;
    }
  }

  // Métodos privados

  static String _generateNotificationId(String eventId, int alarmNumber) {
    return '${eventId}_alarm_$alarmNumber'.hashCode.toString();
  }

  static String _generateAlarmMessage(String eventText, int daysBefore, int hour, int minute) {
    final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    final daysStr = daysBefore == 0 
      ? 'hoy' 
      : 'en $daysBefore día${daysBefore > 1 ? 's' : ''}';
    
    return 'Tu evento "$eventText" es $daysStr a las $timeStr';
  }

  static Future<void> _saveAlarmConfiguration({
    required String eventId,
    required int alarmNumber,
    required String eventText,
    required DateTime eventDate,
    required int hour,
    required int minute,
    required int daysBefore,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_alarmsPrefix}${eventId}_$alarmNumber';
    
    await prefs.setBool('${key}${_enabledKey}', true);
    await prefs.setInt('${key}${_hourKey}', hour);
    await prefs.setInt('${key}${_minuteKey}', minute);
    await prefs.setInt('${key}${_daysBeforeKey}', daysBefore);
    await prefs.setString('${key}${_eventTextKey}', eventText);
    await prefs.setString('${key}${_eventDateKey}', eventDate.toIso8601String());
  }

  static Future<void> _removeAlarmConfiguration(String eventId, int alarmNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_alarmsPrefix}${eventId}_$alarmNumber';
    
    await prefs.remove('${key}${_enabledKey}');
    await prefs.remove('${key}${_hourKey}');
    await prefs.remove('${key}${_minuteKey}');
    await prefs.remove('${key}${_daysBeforeKey}');
    await prefs.remove('${key}${_eventTextKey}');
    await prefs.remove('${key}${_eventDateKey}');
  }

  static dynamic _createTempEventForCancellation(int notificationId) {
    // Crear un evento temporal solo para cancelar la notificación
    // Esto es necesario porque cancelEventNotification requiere un AppEvent
    return {
      'id': notificationId.toString(),
      'title': 'temp',
      'startAt': DateTime.now(),
      'notifyMinutesBefore': 0,
    };
  }
}
