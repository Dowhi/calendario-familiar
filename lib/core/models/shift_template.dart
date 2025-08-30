import 'package:freezed_annotation/freezed_annotation.dart';

part 'shift_template.freezed.dart';
part 'shift_template.g.dart';

@freezed
class ShiftTemplate with _$ShiftTemplate {
  const factory ShiftTemplate({
    required String id,
    required String name,
    @Default('#3B82F6') String colorHex, // Color por defecto (azul)
    required String startTime, // Formato "HH:mm"
    required String endTime,   // Formato "HH:mm"
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ShiftTemplate;

  factory ShiftTemplate.fromJson(Map<String, dynamic> json) => _$ShiftTemplateFromJson(json);
}





