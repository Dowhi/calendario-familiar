// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurrence.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Recurrence _$RecurrenceFromJson(Map<String, dynamic> json) {
  return _Recurrence.fromJson(json);
}

/// @nodoc
mixin _$Recurrence {
  String get rule => throw _privateConstructorUsedError;
  int? get interval => throw _privateConstructorUsedError;
  List<int>? get byWeekdays => throw _privateConstructorUsedError;
  int? get byMonthDay => throw _privateConstructorUsedError;
  DateTime? get until => throw _privateConstructorUsedError;

  /// Serializes this Recurrence to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Recurrence
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecurrenceCopyWith<Recurrence> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecurrenceCopyWith<$Res> {
  factory $RecurrenceCopyWith(
          Recurrence value, $Res Function(Recurrence) then) =
      _$RecurrenceCopyWithImpl<$Res, Recurrence>;
  @useResult
  $Res call(
      {String rule,
      int? interval,
      List<int>? byWeekdays,
      int? byMonthDay,
      DateTime? until});
}

/// @nodoc
class _$RecurrenceCopyWithImpl<$Res, $Val extends Recurrence>
    implements $RecurrenceCopyWith<$Res> {
  _$RecurrenceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Recurrence
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rule = null,
    Object? interval = freezed,
    Object? byWeekdays = freezed,
    Object? byMonthDay = freezed,
    Object? until = freezed,
  }) {
    return _then(_value.copyWith(
      rule: null == rule
          ? _value.rule
          : rule // ignore: cast_nullable_to_non_nullable
              as String,
      interval: freezed == interval
          ? _value.interval
          : interval // ignore: cast_nullable_to_non_nullable
              as int?,
      byWeekdays: freezed == byWeekdays
          ? _value.byWeekdays
          : byWeekdays // ignore: cast_nullable_to_non_nullable
              as List<int>?,
      byMonthDay: freezed == byMonthDay
          ? _value.byMonthDay
          : byMonthDay // ignore: cast_nullable_to_non_nullable
              as int?,
      until: freezed == until
          ? _value.until
          : until // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecurrenceImplCopyWith<$Res>
    implements $RecurrenceCopyWith<$Res> {
  factory _$$RecurrenceImplCopyWith(
          _$RecurrenceImpl value, $Res Function(_$RecurrenceImpl) then) =
      __$$RecurrenceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String rule,
      int? interval,
      List<int>? byWeekdays,
      int? byMonthDay,
      DateTime? until});
}

/// @nodoc
class __$$RecurrenceImplCopyWithImpl<$Res>
    extends _$RecurrenceCopyWithImpl<$Res, _$RecurrenceImpl>
    implements _$$RecurrenceImplCopyWith<$Res> {
  __$$RecurrenceImplCopyWithImpl(
      _$RecurrenceImpl _value, $Res Function(_$RecurrenceImpl) _then)
      : super(_value, _then);

  /// Create a copy of Recurrence
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rule = null,
    Object? interval = freezed,
    Object? byWeekdays = freezed,
    Object? byMonthDay = freezed,
    Object? until = freezed,
  }) {
    return _then(_$RecurrenceImpl(
      rule: null == rule
          ? _value.rule
          : rule // ignore: cast_nullable_to_non_nullable
              as String,
      interval: freezed == interval
          ? _value.interval
          : interval // ignore: cast_nullable_to_non_nullable
              as int?,
      byWeekdays: freezed == byWeekdays
          ? _value._byWeekdays
          : byWeekdays // ignore: cast_nullable_to_non_nullable
              as List<int>?,
      byMonthDay: freezed == byMonthDay
          ? _value.byMonthDay
          : byMonthDay // ignore: cast_nullable_to_non_nullable
              as int?,
      until: freezed == until
          ? _value.until
          : until // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecurrenceImpl implements _Recurrence {
  const _$RecurrenceImpl(
      {this.rule = 'none',
      this.interval,
      final List<int>? byWeekdays,
      this.byMonthDay,
      this.until})
      : _byWeekdays = byWeekdays;

  factory _$RecurrenceImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecurrenceImplFromJson(json);

  @override
  @JsonKey()
  final String rule;
  @override
  final int? interval;
  final List<int>? _byWeekdays;
  @override
  List<int>? get byWeekdays {
    final value = _byWeekdays;
    if (value == null) return null;
    if (_byWeekdays is EqualUnmodifiableListView) return _byWeekdays;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final int? byMonthDay;
  @override
  final DateTime? until;

  @override
  String toString() {
    return 'Recurrence(rule: $rule, interval: $interval, byWeekdays: $byWeekdays, byMonthDay: $byMonthDay, until: $until)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecurrenceImpl &&
            (identical(other.rule, rule) || other.rule == rule) &&
            (identical(other.interval, interval) ||
                other.interval == interval) &&
            const DeepCollectionEquality()
                .equals(other._byWeekdays, _byWeekdays) &&
            (identical(other.byMonthDay, byMonthDay) ||
                other.byMonthDay == byMonthDay) &&
            (identical(other.until, until) || other.until == until));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, rule, interval,
      const DeepCollectionEquality().hash(_byWeekdays), byMonthDay, until);

  /// Create a copy of Recurrence
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecurrenceImplCopyWith<_$RecurrenceImpl> get copyWith =>
      __$$RecurrenceImplCopyWithImpl<_$RecurrenceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecurrenceImplToJson(
      this,
    );
  }
}

abstract class _Recurrence implements Recurrence {
  const factory _Recurrence(
      {final String rule,
      final int? interval,
      final List<int>? byWeekdays,
      final int? byMonthDay,
      final DateTime? until}) = _$RecurrenceImpl;

  factory _Recurrence.fromJson(Map<String, dynamic> json) =
      _$RecurrenceImpl.fromJson;

  @override
  String get rule;
  @override
  int? get interval;
  @override
  List<int>? get byWeekdays;
  @override
  int? get byMonthDay;
  @override
  DateTime? get until;

  /// Create a copy of Recurrence
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecurrenceImplCopyWith<_$RecurrenceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
