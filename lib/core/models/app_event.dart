import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa Firestore para Timestamp
import 'recurrence.dart';

part 'app_event.freezed.dart';
part 'app_event.g.dart';

enum EventType { event, note, shift }

// Convertidores de Timestamp a DateTime
DateTime? _fromTimestamp(dynamic timestamp) {
  print('🔍 _fromTimestamp llamado con: $timestamp (tipo: ${timestamp.runtimeType})');
  
  if (timestamp == null) return null;
  
  if (timestamp is Timestamp) {
    print('🔍 Es Timestamp, convirtiendo a DateTime');
    return timestamp.toDate();
  }
  
  if (timestamp is Map<String, dynamic>) {
    print('🔍 Es Map, contenido: $timestamp');
    // Si es un Map (como los datos de Firestore), intentar extraer la fecha
    if (timestamp.containsKey('seconds')) {
      final seconds = timestamp['seconds'] as int;
      final nanoseconds = timestamp['nanoseconds'] as int? ?? 0;
      print('🔍 Creando Timestamp con seconds: $seconds, nanoseconds: $nanoseconds');
      return Timestamp(seconds, nanoseconds).toDate();
    }
  }
  
  // Si es un String, intentar parsearlo como DateTime
  if (timestamp is String) {
    try {
      print('🔍 Es String, parseando como DateTime');
      return DateTime.parse(timestamp);
    } catch (e) {
      print('❌ Error parseando fecha desde string: $timestamp');
      return null;
    }
  }
  
  print('❌ Formato de fecha no reconocido: $timestamp (tipo: ${timestamp.runtimeType})');
  return null;
}

Timestamp? _toTimestamp(DateTime? dateTime) => dateTime != null ? Timestamp.fromDate(dateTime) : null;

// Convertidor para EventType desde string
EventType _eventTypeFromString(String value) {
  switch (value.toLowerCase()) {
    case 'note':
      return EventType.note;
    case 'shift':
      return EventType.shift;
    case 'event':
    default:
      return EventType.event;
  }
}

String _eventTypeToString(EventType type) {
  switch (type) {
    case EventType.note:
      return 'note';
    case EventType.shift:
      return 'shift';
    case EventType.event:
      return 'event';
  }
}

@freezed
class AppEvent with _$AppEvent {
  const factory AppEvent({
    required String id,
    @JsonKey(name: 'familyId') required String familyId,
    String? ownerId,
    @Default(1) int userId, // 🔹 ID del usuario que creó el evento (1-5)
    required String title,
    String? notes, // Mantener 'notes' para compatibilidad
    String? description, // Añadir 'description' para nueva estructura
    @JsonKey(fromJson: _eventTypeFromString, toJson: _eventTypeToString) 
    @Default(EventType.event) EventType type,
    @JsonKey(name: 'date') required String dateKey,
    @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp) DateTime? startAt, // Mantener para compatibilidad
    @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp) DateTime? endAt,   // Mantener para compatibilidad
    String? startTime, // Hora de inicio como string "HH:mm"
    String? endTime,   // Hora de fin como string "HH:mm"
    @Default(false) bool allDay, // Mantener para compatibilidad
    @Default(true) bool isAllDay, // Añadir para nueva estructura
    String? colorHex,
    @Default([]) List<String> participants,
    String? category,
    Recurrence? recurrence,
    @Default(30) int notifyMinutesBefore,
    @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp) DateTime? createdAt,
    @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp) DateTime? updatedAt,
    @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp) DateTime? deletedAt,
    String? location,
  }) = _AppEvent;

  factory AppEvent.fromJson(Map<String, dynamic> json) => _$AppEventFromJson(json);
}

