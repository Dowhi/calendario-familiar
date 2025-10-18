import 'package:flutter/material.dart';
import 'package:calendario_familiar/core/models/local_user.dart';

/// 🎯 Servicio helper para gestión de usuarios y eventos
/// Proporciona métodos útiles para trabajar con el sistema de usuarios locales
class EventUserService {
  
  /// Obtener el color del usuario por ID
  static Color getUserColor(int userId) {
    return getUserById(userId).color;
  }
  
  /// Obtener el nombre del usuario por ID
  static String getUserName(int userId) {
    return getUserById(userId).name;
  }
  
  /// Verificar si un evento pertenece a un usuario específico
  static bool isEventOwnedByUser(int eventUserId, int currentUserId) {
    return eventUserId == currentUserId;
  }
  
  /// Obtener todos los IDs de usuarios disponibles
  static List<int> getAllUserIds() {
    return localUsers.map((user) => user.id).toList();
  }
  
  /// Validar que un userId sea válido (1-5)
  static bool isValidUserId(int userId) {
    return userId >= 1 && userId <= 5;
  }
  
  /// Obtener un usuario por color (útil para UI)
  static LocalUser? getUserByColor(Color color) {
    try {
      return localUsers.firstWhere((user) => user.color == color);
    } catch (e) {
      return null;
    }
  }
  
  /// Obtener descripción completa del evento con usuario
  static String getEventDescription(String title, int userId) {
    final userName = getUserName(userId);
    return '$title — $userName';
  }
  
  /// Obtener estilo de texto para un evento según su usuario
  static TextStyle getEventTextStyle({
    required int userId,
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: getUserColor(userId),
    );
  }
  
  /// Obtener color de fondo para un card de evento
  static Color getEventCardColor(int userId, {double opacity = 0.2}) {
    return getUserColor(userId).withOpacity(opacity);
  }
}

