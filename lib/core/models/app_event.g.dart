// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppEventImpl _$$AppEventImplFromJson(Map<String, dynamic> json) =>
    _$AppEventImpl(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      ownerId: json['ownerId'] as String?,
      userId: (json['userId'] as num?)?.toInt() ?? 1,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      description: json['description'] as String?,
      type: json['type'] == null
          ? EventType.event
          : _eventTypeFromString(json['type'] as String),
      dateKey: json['date'] as String,
      startAt: _fromTimestamp(json['startAt']),
      endAt: _fromTimestamp(json['endAt']),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      allDay: json['allDay'] as bool? ?? false,
      isAllDay: json['isAllDay'] as bool? ?? true,
      colorHex: json['colorHex'] as String?,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      category: json['category'] as String?,
      recurrence: json['recurrence'] == null
          ? null
          : Recurrence.fromJson(json['recurrence'] as Map<String, dynamic>),
      notifyMinutesBefore: (json['notifyMinutesBefore'] as num?)?.toInt() ?? 30,
      createdAt: _fromTimestamp(json['createdAt']),
      updatedAt: _fromTimestamp(json['updatedAt']),
      deletedAt: _fromTimestamp(json['deletedAt']),
      location: json['location'] as String?,
    );

Map<String, dynamic> _$$AppEventImplToJson(_$AppEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'familyId': instance.familyId,
      'ownerId': instance.ownerId,
      'userId': instance.userId,
      'title': instance.title,
      'notes': instance.notes,
      'description': instance.description,
      'type': _eventTypeToString(instance.type),
      'date': instance.dateKey,
      'startAt': _toTimestamp(instance.startAt),
      'endAt': _toTimestamp(instance.endAt),
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'allDay': instance.allDay,
      'isAllDay': instance.isAllDay,
      'colorHex': instance.colorHex,
      'participants': instance.participants,
      'category': instance.category,
      'recurrence': instance.recurrence,
      'notifyMinutesBefore': instance.notifyMinutesBefore,
      'createdAt': _toTimestamp(instance.createdAt),
      'updatedAt': _toTimestamp(instance.updatedAt),
      'deletedAt': _toTimestamp(instance.deletedAt),
      'location': instance.location,
    };
