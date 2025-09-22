import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftTemplate {
  final String id;
  final String name;
  final String colorHex;
  final String startTime;
  final String endTime;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShiftTemplate({
    required this.id,
    required this.name,
    this.colorHex = '#3B82F6',
    required this.startTime,
    required this.endTime,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory ShiftTemplate.fromJson(Map<String, dynamic> json) {
    // Manejar Timestamps de Firebase correctamente
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return ShiftTemplate(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      colorHex: json['colorHex']?.toString() ?? '#3B82F6',
      startTime: json['startTime']?.toString() ?? '08:00',
      endTime: json['endTime']?.toString() ?? '16:00',
      description: json['description']?.toString(),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'startTime': startTime,
      'endTime': endTime,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ShiftTemplate copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? startTime,
    String? endTime,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShiftTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}





