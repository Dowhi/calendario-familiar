// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ShiftTemplateImpl _$$ShiftTemplateImplFromJson(Map<String, dynamic> json) =>
    _$ShiftTemplateImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['colorHex'] as String? ?? '#3B82F6',
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      description: json['description'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ShiftTemplateImplToJson(_$ShiftTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'colorHex': instance.colorHex,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'description': instance.description,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
