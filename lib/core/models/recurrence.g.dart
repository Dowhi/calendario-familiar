// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecurrenceImpl _$$RecurrenceImplFromJson(Map<String, dynamic> json) =>
    _$RecurrenceImpl(
      rule: json['rule'] as String? ?? 'none',
      interval: (json['interval'] as num?)?.toInt(),
      byWeekdays: (json['byWeekdays'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      byMonthDay: (json['byMonthDay'] as num?)?.toInt(),
      until: json['until'] == null
          ? null
          : DateTime.parse(json['until'] as String),
    );

Map<String, dynamic> _$$RecurrenceImplToJson(_$RecurrenceImpl instance) =>
    <String, dynamic>{
      'rule': instance.rule,
      'interval': instance.interval,
      'byWeekdays': instance.byWeekdays,
      'byMonthDay': instance.byMonthDay,
      'until': instance.until?.toIso8601String(),
    };
