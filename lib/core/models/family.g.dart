// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FamilyImpl _$$FamilyImplFromJson(Map<String, dynamic> json) => _$FamilyImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  code: json['code'] as String,
  password: json['password'] as String,
  createdBy: json['createdBy'] as String,
  members: (json['members'] as List<dynamic>).map((e) => e as String).toList(),
  roles:
      (json['roles'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  createdAt: _timestampToDateTime(json['createdAt']),
  updatedAt: _timestampToDateTime(json['updatedAt']),
);

Map<String, dynamic> _$$FamilyImplToJson(_$FamilyImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'password': instance.password,
      'createdBy': instance.createdBy,
      'members': instance.members,
      'roles': instance.roles,
      'createdAt': _dateTimeToTimestamp(instance.createdAt),
      'updatedAt': _dateTimeToTimestamp(instance.updatedAt),
    };
