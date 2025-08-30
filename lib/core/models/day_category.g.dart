// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DayCategoryImpl _$$DayCategoryImplFromJson(Map<String, dynamic> json) =>
    _$DayCategoryImpl(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      colorHex: json['colorHex'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$DayCategoryImplToJson(_$DayCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'category': instance.category,
      'colorHex': instance.colorHex,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
