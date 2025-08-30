import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurrence.freezed.dart';
part 'recurrence.g.dart';

@freezed
class Recurrence with _$Recurrence {
  const factory Recurrence({
    @Default('none') String rule,
    int? interval,
    List<int>? byWeekdays,
    int? byMonthDay,
    DateTime? until,
  }) = _Recurrence;

  factory Recurrence.fromJson(Map<String, dynamic> json) => _$RecurrenceFromJson(json);
}

