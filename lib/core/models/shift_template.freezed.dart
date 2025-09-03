// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ShiftTemplate _$ShiftTemplateFromJson(Map<String, dynamic> json) {
  return _ShiftTemplate.fromJson(json);
}

/// @nodoc
mixin _$ShiftTemplate {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get colorHex =>
      throw _privateConstructorUsedError; // Color por defecto (azul)
  String get startTime => throw _privateConstructorUsedError; // Formato "HH:mm"
  String get endTime => throw _privateConstructorUsedError; // Formato "HH:mm"
  String? get description => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ShiftTemplateCopyWith<ShiftTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShiftTemplateCopyWith<$Res> {
  factory $ShiftTemplateCopyWith(
          ShiftTemplate value, $Res Function(ShiftTemplate) then) =
      _$ShiftTemplateCopyWithImpl<$Res, ShiftTemplate>;
  @useResult
  $Res call(
      {String id,
      String name,
      String colorHex,
      String startTime,
      String endTime,
      String? description,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$ShiftTemplateCopyWithImpl<$Res, $Val extends ShiftTemplate>
    implements $ShiftTemplateCopyWith<$Res> {
  _$ShiftTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? colorHex = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? description = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      colorHex: null == colorHex
          ? _value.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ShiftTemplateImplCopyWith<$Res>
    implements $ShiftTemplateCopyWith<$Res> {
  factory _$$ShiftTemplateImplCopyWith(
          _$ShiftTemplateImpl value, $Res Function(_$ShiftTemplateImpl) then) =
      __$$ShiftTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String colorHex,
      String startTime,
      String endTime,
      String? description,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$ShiftTemplateImplCopyWithImpl<$Res>
    extends _$ShiftTemplateCopyWithImpl<$Res, _$ShiftTemplateImpl>
    implements _$$ShiftTemplateImplCopyWith<$Res> {
  __$$ShiftTemplateImplCopyWithImpl(
      _$ShiftTemplateImpl _value, $Res Function(_$ShiftTemplateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? colorHex = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? description = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ShiftTemplateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      colorHex: null == colorHex
          ? _value.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ShiftTemplateImpl implements _ShiftTemplate {
  const _$ShiftTemplateImpl(
      {required this.id,
      required this.name,
      this.colorHex = '#3B82F6',
      required this.startTime,
      required this.endTime,
      this.description,
      this.createdAt,
      this.updatedAt});

  factory _$ShiftTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShiftTemplateImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final String colorHex;
// Color por defecto (azul)
  @override
  final String startTime;
// Formato "HH:mm"
  @override
  final String endTime;
// Formato "HH:mm"
  @override
  final String? description;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'ShiftTemplate(id: $id, name: $name, colorHex: $colorHex, startTime: $startTime, endTime: $endTime, description: $description, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShiftTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.colorHex, colorHex) ||
                other.colorHex == colorHex) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, colorHex, startTime,
      endTime, description, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ShiftTemplateImplCopyWith<_$ShiftTemplateImpl> get copyWith =>
      __$$ShiftTemplateImplCopyWithImpl<_$ShiftTemplateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShiftTemplateImplToJson(
      this,
    );
  }
}

abstract class _ShiftTemplate implements ShiftTemplate {
  const factory _ShiftTemplate(
      {required final String id,
      required final String name,
      final String colorHex,
      required final String startTime,
      required final String endTime,
      final String? description,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$ShiftTemplateImpl;

  factory _ShiftTemplate.fromJson(Map<String, dynamic> json) =
      _$ShiftTemplateImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get colorHex;
  @override // Color por defecto (azul)
  String get startTime;
  @override // Formato "HH:mm"
  String get endTime;
  @override // Formato "HH:mm"
  String? get description;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$ShiftTemplateImplCopyWith<_$ShiftTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
