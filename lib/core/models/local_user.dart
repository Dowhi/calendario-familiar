import 'package:flutter/material.dart';

/// Modelo de usuario local predefinido
class LocalUser {
  final int id;
  final String name;
  final Color color;

  const LocalUser({
    required this.id,
    required this.name,
    required this.color,
  });

  /// Convertir a Map para Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorValue': color.value, // Guardar el valor del color como int
    };
  }

  /// Crear desde Map de Firebase
  factory LocalUser.fromJson(Map<String, dynamic> json) {
    return LocalUser(
      id: json['id'] ?? 1,
      name: json['name'] ?? 'Usuario',
      color: Color(json['colorValue'] ?? Colors.blue.value),
    );
  }

  /// Crear copia con nuevos valores
  LocalUser copyWith({
    int? id,
    String? name,
    Color? color,
  }) {
    return LocalUser(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }
}

/// Lista de usuarios locales predefinidos (mutable para permitir edición)
List<LocalUser> localUsers = [
  LocalUser(id: 1, name: 'Usuario 1', color: Colors.blue),
  LocalUser(id: 2, name: 'Usuario 2', color: Colors.green),
  LocalUser(id: 3, name: 'Usuario 3', color: Colors.orange),
  LocalUser(id: 4, name: 'Usuario 4', color: Colors.purple),
  LocalUser(id: 5, name: 'Usuario 5', color: Colors.red),
];

/// Helper para obtener un usuario por ID
LocalUser getUserById(int userId) {
  return localUsers.firstWhere(
    (user) => user.id == userId,
    orElse: () => localUsers.first, // Fallback al primer usuario
  );
}

/// Helper para obtener el color de un usuario
Color getUserColor(int userId) {
  return getUserById(userId).color;
}

