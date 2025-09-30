import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar la configuración de notificaciones
class NotificationSettingsService {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _alarmRemindersEnabledKey = 'alarm_reminders_enabled';
  static const String _eventRemindersEnabledKey = 'event_reminders_enabled';
  static const String _defaultReminderMinutesKey = 'default_reminder_minutes';
  static const String _soundEnabledKey = 'notification_sound_enabled';
  static const String _vibrationEnabledKey = 'notification_vibration_enabled';

  /// Verificar si las notificaciones están habilitadas globalmente
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  /// Habilitar/deshabilitar notificaciones globalmente
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  /// Verificar si las alarmas/recordatorios están habilitados
  static Future<bool> areAlarmRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_alarmRemindersEnabledKey) ?? true;
  }

  /// Habilitar/deshabilitar alarmas/recordatorios
  static Future<void> setAlarmRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_alarmRemindersEnabledKey, enabled);
  }

  /// Verificar si los recordatorios de eventos están habilitados
  static Future<bool> areEventRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_eventRemindersEnabledKey) ?? true;
  }

  /// Habilitar/deshabilitar recordatorios de eventos
  static Future<void> setEventRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_eventRemindersEnabledKey, enabled);
  }

  /// Obtener minutos por defecto para recordatorios
  static Future<int> getDefaultReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_defaultReminderMinutesKey) ?? 30; // 30 minutos por defecto
  }

  /// Establecer minutos por defecto para recordatorios
  static Future<void> setDefaultReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultReminderMinutesKey, minutes);
  }

  /// Verificar si el sonido está habilitado
  static Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  /// Habilitar/deshabilitar sonido
  static Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  /// Verificar si la vibración está habilitada
  static Future<bool> isVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  /// Habilitar/deshabilitar vibración
  static Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, enabled);
  }

  /// Obtener toda la configuración de notificaciones
  static Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'notificationsEnabled': await areNotificationsEnabled(),
      'alarmRemindersEnabled': await areAlarmRemindersEnabled(),
      'eventRemindersEnabled': await areEventRemindersEnabled(),
      'defaultReminderMinutes': await getDefaultReminderMinutes(),
      'soundEnabled': await isSoundEnabled(),
      'vibrationEnabled': await isVibrationEnabled(),
    };
  }

  /// Restablecer configuración por defecto
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, true);
    await prefs.setBool(_alarmRemindersEnabledKey, true);
    await prefs.setBool(_eventRemindersEnabledKey, true);
    await prefs.setInt(_defaultReminderMinutesKey, 30);
    await prefs.setBool(_soundEnabledKey, true);
    await prefs.setBool(_vibrationEnabledKey, true);
  }
}
