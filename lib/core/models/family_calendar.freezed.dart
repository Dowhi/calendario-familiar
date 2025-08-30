// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'family_calendar.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FamilyCalendar _$FamilyCalendarFromJson(Map<String, dynamic> json) {
  return _FamilyCalendar.fromJson(json);
}

/// @nodoc
mixin _$FamilyCalendar {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<String> get members => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this FamilyCalendar to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FamilyCalendar
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FamilyCalendarCopyWith<FamilyCalendar> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FamilyCalendarCopyWith<$Res> {
  factory $FamilyCalendarCopyWith(
    FamilyCalendar value,
    $Res Function(FamilyCalendar) then,
  ) = _$FamilyCalendarCopyWithImpl<$Res, FamilyCalendar>;
  @useResult
  $Res call({
    String id,
    String name,
    List<String> members,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$FamilyCalendarCopyWithImpl<$Res, $Val extends FamilyCalendar>
    implements $FamilyCalendarCopyWith<$Res> {
  _$FamilyCalendarCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FamilyCalendar
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? members = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            members: null == members
                ? _value.members
                : members // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FamilyCalendarImplCopyWith<$Res>
    implements $FamilyCalendarCopyWith<$Res> {
  factory _$$FamilyCalendarImplCopyWith(
    _$FamilyCalendarImpl value,
    $Res Function(_$FamilyCalendarImpl) then,
  ) = __$$FamilyCalendarImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    List<String> members,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$FamilyCalendarImplCopyWithImpl<$Res>
    extends _$FamilyCalendarCopyWithImpl<$Res, _$FamilyCalendarImpl>
    implements _$$FamilyCalendarImplCopyWith<$Res> {
  __$$FamilyCalendarImplCopyWithImpl(
    _$FamilyCalendarImpl _value,
    $Res Function(_$FamilyCalendarImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FamilyCalendar
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? members = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$FamilyCalendarImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        members: null == members
            ? _value._members
            : members // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FamilyCalendarImpl implements _FamilyCalendar {
  const _$FamilyCalendarImpl({
    required this.id,
    required this.name,
    final List<String> members = const [],
    this.createdAt,
    this.updatedAt,
  }) : _members = members;

  factory _$FamilyCalendarImpl.fromJson(Map<String, dynamic> json) =>
      _$$FamilyCalendarImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  final List<String> _members;
  @override
  @JsonKey()
  List<String> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'FamilyCalendar(id: $id, name: $name, members: $members, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FamilyCalendarImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._members, _members) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    const DeepCollectionEquality().hash(_members),
    createdAt,
    updatedAt,
  );

  /// Create a copy of FamilyCalendar
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FamilyCalendarImplCopyWith<_$FamilyCalendarImpl> get copyWith =>
      __$$FamilyCalendarImplCopyWithImpl<_$FamilyCalendarImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FamilyCalendarImplToJson(this);
  }
}

abstract class _FamilyCalendar implements FamilyCalendar {
  const factory _FamilyCalendar({
    required final String id,
    required final String name,
    final List<String> members,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$FamilyCalendarImpl;

  factory _FamilyCalendar.fromJson(Map<String, dynamic> json) =
      _$FamilyCalendarImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  List<String> get members;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of FamilyCalendar
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FamilyCalendarImplCopyWith<_$FamilyCalendarImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
