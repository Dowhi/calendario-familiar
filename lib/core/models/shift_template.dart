import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftTemplate {
  final String id;
  final String name;
  final String abbreviation;
  final String colorHex;
  final String textColorHex;
  final double textSize;
  final String startTime;
  final String endTime;
  final bool isSplitShift;
  final String? secondStartTime;
  final String? secondEndTime;
  final int breakTimeMinutes;
  final bool calculateDuration;
  final int? calculatedHours;
  final int? calculatedMinutes;
  final bool alarm1Enabled;
  final bool previousDayAlarm;
  final String? alarmTime;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShiftTemplate({
    required this.id,
    required this.name,
    this.abbreviation = '',
    this.colorHex = '#3B82F6',
    this.textColorHex = '#FFFFFF',
    this.textSize = 16.0,
    required this.startTime,
    required this.endTime,
    this.isSplitShift = false,
    this.secondStartTime,
    this.secondEndTime,
    this.breakTimeMinutes = 0,
    this.calculateDuration = false,
    this.calculatedHours,
    this.calculatedMinutes,
    this.alarm1Enabled = false,
    this.previousDayAlarm = false,
    this.alarmTime,
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
      abbreviation: json['abbreviation']?.toString() ?? '',
      colorHex: json['colorHex']?.toString() ?? '#3B82F6',
      textColorHex: json['textColorHex']?.toString() ?? '#FFFFFF',
      textSize: (json['textSize'] ?? 16.0).toDouble(),
      startTime: json['startTime']?.toString() ?? '08:00',
      endTime: json['endTime']?.toString() ?? '16:00',
      isSplitShift: json['isSplitShift'] ?? false,
      secondStartTime: json['secondStartTime']?.toString(),
      secondEndTime: json['secondEndTime']?.toString(),
      breakTimeMinutes: json['breakTimeMinutes'] ?? 0,
      calculateDuration: json['calculateDuration'] ?? false,
      calculatedHours: json['calculatedHours'],
      calculatedMinutes: json['calculatedMinutes'],
      alarm1Enabled: json['alarm1Enabled'] ?? false,
      previousDayAlarm: json['previousDayAlarm'] ?? false,
      alarmTime: json['alarmTime']?.toString(),
      description: json['description']?.toString(),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'abbreviation': abbreviation,
      'colorHex': colorHex,
      'textColorHex': textColorHex,
      'textSize': textSize,
      'startTime': startTime,
      'endTime': endTime,
      'isSplitShift': isSplitShift,
      'secondStartTime': secondStartTime,
      'secondEndTime': secondEndTime,
      'breakTimeMinutes': breakTimeMinutes,
      'calculateDuration': calculateDuration,
      'calculatedHours': calculatedHours,
      'calculatedMinutes': calculatedMinutes,
      'alarm1Enabled': alarm1Enabled,
      'previousDayAlarm': previousDayAlarm,
      'alarmTime': alarmTime,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ShiftTemplate copyWith({
    String? id,
    String? name,
    String? abbreviation,
    String? colorHex,
    String? textColorHex,
    double? textSize,
    String? startTime,
    String? endTime,
    bool? isSplitShift,
    String? secondStartTime,
    String? secondEndTime,
    int? breakTimeMinutes,
    bool? calculateDuration,
    int? calculatedHours,
    int? calculatedMinutes,
    bool? alarm1Enabled,
    bool? previousDayAlarm,
    String? alarmTime,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShiftTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      colorHex: colorHex ?? this.colorHex,
      textColorHex: textColorHex ?? this.textColorHex,
      textSize: textSize ?? this.textSize,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isSplitShift: isSplitShift ?? this.isSplitShift,
      secondStartTime: secondStartTime ?? this.secondStartTime,
      secondEndTime: secondEndTime ?? this.secondEndTime,
      breakTimeMinutes: breakTimeMinutes ?? this.breakTimeMinutes,
      calculateDuration: calculateDuration ?? this.calculateDuration,
      calculatedHours: calculatedHours ?? this.calculatedHours,
      calculatedMinutes: calculatedMinutes ?? this.calculatedMinutes,
      alarm1Enabled: alarm1Enabled ?? this.alarm1Enabled,
      previousDayAlarm: previousDayAlarm ?? this.previousDayAlarm,
      alarmTime: alarmTime ?? this.alarmTime,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}





