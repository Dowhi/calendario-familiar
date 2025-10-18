import 'package:flutter/material.dart';
import 'package:calendario_familiar/core/models/app_event.dart';
import 'package:calendario_familiar/core/services/event_user_service.dart';

/// 🔧 Extensiones útiles para AppEvent
extension AppEventExtensions on AppEvent {
  
  /// Obtener el color del usuario creador
  Color get userColor => EventUserService.getUserColor(userId);
  
  /// Obtener el nombre del usuario creador
  String get userName => EventUserService.getUserName(userId);
  
  /// Verificar si el evento pertenece a un usuario específico
  bool belongsToUser(int currentUserId) {
    return EventUserService.isEventOwnedByUser(userId, currentUserId);
  }
  
  /// Obtener estilo de texto para el evento
  TextStyle getTextStyle({double fontSize = 12, FontWeight? fontWeight}) {
    return EventUserService.getEventTextStyle(
      userId: userId,
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.normal,
    );
  }
  
  /// Obtener color de fondo para el evento
  Color getCardColor({double opacity = 0.2}) {
    return EventUserService.getEventCardColor(userId, opacity: opacity);
  }
  
  /// Descripción completa con usuario
  String get descriptionWithUser {
    final desc = description ?? notes ?? '';
    return EventUserService.getEventDescription(title, userId);
  }
  
  /// Verificar si debe programar alarma para un usuario específico
  bool shouldScheduleAlarmFor(int currentUserId) {
    return belongsToUser(currentUserId) && startAt != null && notifyMinutesBefore > 0;
  }
}

