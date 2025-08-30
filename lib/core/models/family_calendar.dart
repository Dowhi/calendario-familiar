import 'package:freezed_annotation/freezed_annotation.dart';

part 'family_calendar.freezed.dart';
part 'family_calendar.g.dart';

@freezed
class FamilyCalendar with _$FamilyCalendar {
  const factory FamilyCalendar({
    required String id,
    required String name,
    @Default([]) List<String> members,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _FamilyCalendar;

  factory FamilyCalendar.fromJson(Map<String, dynamic> json) => _$FamilyCalendarFromJson(json);
}

