// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_calendar.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FamilyCalendarImpl _$$FamilyCalendarImplFromJson(Map<String, dynamic> json) =>
    _$FamilyCalendarImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      members:
          (json['members'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$FamilyCalendarImplToJson(
  _$FamilyCalendarImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'members': instance.members,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
