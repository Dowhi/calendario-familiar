import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// Helper para programar alarmas en Android usando AlarmManager nativo
class AndroidAlarmHelper {
  static const platform = MethodChannel('com.juancarlos.calendariofamiliar/alarm');
  static const eventChannel = EventChannel('com.juancarlos.calendariofamiliar/alarm_events');
  
  static Stream<Map<String, dynamic>>? _alarmStream;
  
  /// Stream para escuchar eventos de alarma en tiempo real
  static Stream<Map<String, dynamic>> get alarmStream {
    _alarmStream ??= eventChannel.receiveBroadcastStream().map((dynamic event) {
      print('🔔 Evento de alarma recibido desde EventChannel: $event');
      return Map<String, dynamic>.from(event as Map);
    });
    return _alarmStream!;
  }
  
  /// Obtiene los datos de alarma desde el intent nativo (si la app se abrió desde una alarma)
  static Future<Map<String, dynamic>?> getAlarmData() async {
    if (!Platform.isAndroid) return null;
    
    try {
      final Map<dynamic, dynamic>? data = await platform.invokeMethod('getAlarmData');
      if (data != null) {
        return {
          'title': data['title'] as String,
          'notes': data['notes'] as String,
          'dateKey': data['dateKey'] as String,
        };
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo datos de alarma: $e');
      return null;
    }
  }
  
  /// Programa una alarma directa usando AlarmManager nativo
  static Future<bool> scheduleDirectAlarm({
    required DateTime fireAt,
    required String id,
    required String title,
    required String notes,
    required String dateKey,
  }) async {
    if (!Platform.isAndroid) return false;
    
    try {
      final int idHash = id.hashCode;
      final int triggerTimeMillis = fireAt.millisecondsSinceEpoch;
      
      final bool result = await platform.invokeMethod('scheduleDirectAlarm', {
        'triggerTimeMillis': triggerTimeMillis,
        'id': idHash,
        'title': title,
        'notes': notes,
        'dateKey': dateKey,
      });
      
      print('✅ Alarma directa programada vía MethodChannel (id=$idHash, result=$result)');
      return result;
    } catch (e) {
      print('❌ Error programando alarma directa: $e');
      return false;
    }
  }
}

