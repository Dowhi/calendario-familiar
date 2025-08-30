import 'package:freezed_annotation/freezed_annotation.dart';

part 'family.freezed.dart';
part 'family.g.dart';

enum FamilyRole { admin, member }

@freezed
class Family with _$Family {
  const factory Family({
    required String id,
    required String name,
    required String code, // Código de invitación de la familia
    required String password, // Contraseña de la familia (solo visible para admin)
    required String createdBy,
    required List<String> members, // UIDs de los miembros
    @Default({}) Map<String, String> roles, // Map<UID, Role>
    @JsonKey(fromJson: _timestampToDateTime, toJson: _dateTimeToTimestamp) DateTime? createdAt,
    @JsonKey(fromJson: _timestampToDateTime, toJson: _dateTimeToTimestamp) DateTime? updatedAt,
  }) = _Family;

  factory Family.fromJson(Map<String, dynamic> json) => _$FamilyFromJson(json);
}

// Funciones auxiliares para conversión de fechas
DateTime? _timestampToDateTime(dynamic timestamp) {
  if (timestamp == null) return null;
  if (timestamp is DateTime) return timestamp;
  if (timestamp is String) {
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }
  // Si es Timestamp de Firebase
  try {
    return timestamp.toDate();
  } catch (e) {
    return null;
  }
}

dynamic _dateTimeToTimestamp(DateTime? dateTime) {
  return dateTime?.toIso8601String();
}

