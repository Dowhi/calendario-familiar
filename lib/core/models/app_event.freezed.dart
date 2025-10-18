// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AppEvent _$AppEventFromJson(Map<String, dynamic> json) {
  return _AppEvent.fromJson(json);
}

/// @nodoc
mixin _$AppEvent {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'familyId')
  String get familyId => throw _privateConstructorUsedError;
  String? get ownerId => throw _privateConstructorUsedError;
  int get userId =>
      throw _privateConstructorUsedError; // 🔹 ID del usuario que creó el evento (1-5)
  String get title => throw _privateConstructorUsedError;
  String? get notes =>
      throw _privateConstructorUsedError; // Mantener 'notes' para compatibilidad
  String? get description =>
      throw _privateConstructorUsedError; // Añadir 'description' para nueva estructura
  @JsonKey(fromJson: _eventTypeFromString, toJson: _eventTypeToString)
  EventType get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'date')
  String get dateKey => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  DateTime? get startAt =>
      throw _privateConstructorUsedError; // Mantener para compatibilidad
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  DateTime? get endAt =>
      throw _privateConstructorUsedError; // Mantener para compatibilidad
  String? get startTime =>
      throw _privateConstructorUsedError; // Hora de inicio como string "HH:mm"
  String? get endTime =>
      throw _privateConstructorUsedError; // Hora de fin como string "HH:mm"
  bool get allDay =>
      throw _privateConstructorUsedError; // Mantener para compatibilidad
  bool get isAllDay =>
      throw _privateConstructorUsedError; // Añadir para nueva estructura
  String? get colorHex => throw _privateConstructorUsedError;
  List<String> get participants => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  Recurrence? get recurrence => throw _privateConstructorUsedError;
  int get notifyMinutesBefore => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  DateTime? get deletedAt => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;

  /// Serializes this AppEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppEventCopyWith<AppEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppEventCopyWith<$Res> {
  factory $AppEventCopyWith(AppEvent value, $Res Function(AppEvent) then) =
      _$AppEventCopyWithImpl<$Res, AppEvent>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'familyId') String familyId,
      String? ownerId,
      int userId,
      String title,
      String? notes,
      String? description,
      @JsonKey(fromJson: _eventTypeFromString, toJson: _eventTypeToString)
      EventType type,
      @JsonKey(name: 'date') String dateKey,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
      DateTime? startAt,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp) DateTime? endAt,
      String? startTime,
      String? endTime,
      bool allDay,
      bool isAllDay,
      String? colorHex,
      List<String> participants,
      String? category,
      Recurrence? recurrence,
      int notifyMinutesBefore,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
      DateTime? createdAt,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
      DateTime? updatedAt,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
      DateTime? deletedAt,
      String? location});

  $RecurrenceCopyWith<$Res>? get recurrence;
}

/// @nodoc
class _$AppEventCopyWithImpl<$Res, $Val extends AppEvent>
    implements $AppEventCopyWith<$Res> {
  _$AppEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? ownerId = freezed,
    Object? userId = null,
    Object? title = null,
    Object? notes = freezed,
    Object? description = freezed,
    Object? type = null,
    Object? dateKey = null,
    Object? startAt = freezed,
    Object? endAt = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? allDay = null,
    Object? isAllDay = null,
    Object? colorHex = freezed,
    Object? participants = null,
    Object? category = freezed,
    Object? recurrence = freezed,
    Object? notifyMinutesBefore = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? deletedAt = freezed,
    Object? location = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      familyId: null == familyId
          ? _value.familyId
          : familyId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: freezed == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String?,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as EventType,
      dateKey: null == dateKey
          ? _value.dateKey
          : dateKey // ignore: cast_nullable_to_non_nullable
              as String,
      startAt: freezed == startAt
          ? _value.startAt
          : startAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endAt: freezed == endAt
          ? _value.endAt
          : endAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      startTime: freezed == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String?,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String?,
      allDay: null == allDay
          ? _value.allDay
          : allDay // ignore: cast_nullable_to_non_nullable
              as bool,
      isAllDay: null == isAllDay
          ? _value.isAllDay
          : isAllDay // ignore: cast_nullable_to_non_nullable
              as bool,
      colorHex: freezed == colorHex
          ? _value.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as String?,
      participants: null == participants
          ? _value.participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<String>,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrence: freezed == recurrence
          ? _value.recurrence
          : recurrence // ignore: cast_nullable_to_non_nullable
              as Recurrence?,
      notifyMinutesBefore: null == notifyMinutesBefore
          ? _value.notifyMinutesBefore
          : notifyMinutesBefore // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of AppEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RecurrenceCopyWith<$Res>? get recurrence {
    if (_value.recurrence == null) {
      return null;
    }

    return $RecurrenceCopyWith<$Res>(_value.recurrence!, (value) {
      return _then(_value.copyWith(recurrence: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AppEventImplCopyWith<$Res>
    implements $AppEventCopyWith<$Res> {
  factory _$$AppEventImplCopyWith(
          _$AppEventImpl value, $Res Function(_$AppEventImpl) then) =
      __$$AppEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'familyId') String familyId,
      String? ownerId,
      int userId,
      String title,
      String? notes,
      String? description,
      @JsonKey(fromJson: _eventTypeFromString, toJson: _eventTypeToString)
      EventType type,
      @JsonKey(name: 'date') String dateKey,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
      DateTime? startAt,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp) DateTime? endAt,
      String? startTime,
      String? endTime,
      bool allDay,
      bool isAllDay,
      String? colorHex,
      List<String> participants,
      String? category,
      Recurrence? recurrence,
      int notifyMinutesBefore,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
      DateTime? createdAt,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
      DateTime? updatedAt,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
      DateTime? deletedAt,
      String? location});

  @override
  $RecurrenceCopyWith<$Res>? get recurrence;
}

/// @nodoc
class __$$AppEventImplCopyWithImpl<$Res>
    extends _$AppEventCopyWithImpl<$Res, _$AppEventImpl>
    implements _$$AppEventImplCopyWith<$Res> {
  __$$AppEventImplCopyWithImpl(
      _$AppEventImpl _value, $Res Function(_$AppEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? ownerId = freezed,
    Object? userId = null,
    Object? title = null,
    Object? notes = freezed,
    Object? description = freezed,
    Object? type = null,
    Object? dateKey = null,
    Object? startAt = freezed,
    Object? endAt = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? allDay = null,
    Object? isAllDay = null,
    Object? colorHex = freezed,
    Object? participants = null,
    Object? category = freezed,
    Object? recurrence = freezed,
    Object? notifyMinutesBefore = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? deletedAt = freezed,
    Object? location = freezed,
  }) {
    return _then(_$AppEventImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      familyId: null == familyId
          ? _value.familyId
          : familyId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: freezed == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String?,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as EventType,
      dateKey: null == dateKey
          ? _value.dateKey
          : dateKey // ignore: cast_nullable_to_non_nullable
              as String,
      startAt: freezed == startAt
          ? _value.startAt
          : startAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endAt: freezed == endAt
          ? _value.endAt
          : endAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      startTime: freezed == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String?,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String?,
      allDay: null == allDay
          ? _value.allDay
          : allDay // ignore: cast_nullable_to_non_nullable
              as bool,
      isAllDay: null == isAllDay
          ? _value.isAllDay
          : isAllDay // ignore: cast_nullable_to_non_nullable
              as bool,
      colorHex: freezed == colorHex
          ? _value.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as String?,
      participants: null == participants
          ? _value._participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<String>,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrence: freezed == recurrence
          ? _value.recurrence
          : recurrence // ignore: cast_nullable_to_non_nullable
              as Recurrence?,
      notifyMinutesBefore: null == notifyMinutesBefore
          ? _value.notifyMinutesBefore
          : notifyMinutesBefore // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppEventImpl implements _AppEvent {
  const _$AppEventImpl(
      {required this.id,
      @JsonKey(name: 'familyId') required this.familyId,
      this.ownerId,
      this.userId = 1,
      required this.title,
      this.notes,
      this.description,
      @JsonKey(fromJson: _eventTypeFromString, toJson: _eventTypeToString)
      this.type = EventType.event,
      @JsonKey(name: 'date') required this.dateKey,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp) this.startAt,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp) this.endAt,
      this.startTime,
      this.endTime,
      this.allDay = false,
      this.isAllDay = true,
      this.colorHex,
      final List<String> participants = const [],
      this.category,
      this.recurrence,
      this.notifyMinutesBefore = 30,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp) this.createdAt,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp) this.updatedAt,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp) this.deletedAt,
      this.location})
      : _participants = participants;

  factory _$AppEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppEventImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'familyId')
  final String familyId;
  @override
  final String? ownerId;
  @override
  @JsonKey()
  final int userId;
// 🔹 ID del usuario que creó el evento (1-5)
  @override
  final String title;
  @override
  final String? notes;
// Mantener 'notes' para compatibilidad
  @override
  final String? description;
// Añadir 'description' para nueva estructura
  @override
  @JsonKey(fromJson: _eventTypeFromString, toJson: _eventTypeToString)
  final EventType type;
  @override
  @JsonKey(name: 'date')
  final String dateKey;
  @override
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  final DateTime? startAt;
// Mantener para compatibilidad
  @override
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  final DateTime? endAt;
// Mantener para compatibilidad
  @override
  final String? startTime;
// Hora de inicio como string "HH:mm"
  @override
  final String? endTime;
// Hora de fin como string "HH:mm"
  @override
  @JsonKey()
  final bool allDay;
// Mantener para compatibilidad
  @override
  @JsonKey()
  final bool isAllDay;
// Añadir para nueva estructura
  @override
  final String? colorHex;
  final List<String> _participants;
  @override
  @JsonKey()
  List<String> get participants {
    if (_participants is EqualUnmodifiableListView) return _participants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participants);
  }

  @override
  final String? category;
  @override
  final Recurrence? recurrence;
  @override
  @JsonKey()
  final int notifyMinutesBefore;
  @override
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  final DateTime? createdAt;
  @override
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  final DateTime? updatedAt;
  @override
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  final DateTime? deletedAt;
  @override
  final String? location;

  @override
  String toString() {
    return 'AppEvent(id: $id, familyId: $familyId, ownerId: $ownerId, userId: $userId, title: $title, notes: $notes, description: $description, type: $type, dateKey: $dateKey, startAt: $startAt, endAt: $endAt, startTime: $startTime, endTime: $endTime, allDay: $allDay, isAllDay: $isAllDay, colorHex: $colorHex, participants: $participants, category: $category, recurrence: $recurrence, notifyMinutesBefore: $notifyMinutesBefore, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.dateKey, dateKey) || other.dateKey == dateKey) &&
            (identical(other.startAt, startAt) || other.startAt == startAt) &&
            (identical(other.endAt, endAt) || other.endAt == endAt) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.allDay, allDay) || other.allDay == allDay) &&
            (identical(other.isAllDay, isAllDay) ||
                other.isAllDay == isAllDay) &&
            (identical(other.colorHex, colorHex) ||
                other.colorHex == colorHex) &&
            const DeepCollectionEquality()
                .equals(other._participants, _participants) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.recurrence, recurrence) ||
                other.recurrence == recurrence) &&
            (identical(other.notifyMinutesBefore, notifyMinutesBefore) ||
                other.notifyMinutesBefore == notifyMinutesBefore) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.location, location) ||
                other.location == location));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        familyId,
        ownerId,
        userId,
        title,
        notes,
        description,
        type,
        dateKey,
        startAt,
        endAt,
        startTime,
        endTime,
        allDay,
        isAllDay,
        colorHex,
        const DeepCollectionEquality().hash(_participants),
        category,
        recurrence,
        notifyMinutesBefore,
        createdAt,
        updatedAt,
        deletedAt,
        location
      ]);

  /// Create a copy of AppEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppEventImplCopyWith<_$AppEventImpl> get copyWith =>
      __$$AppEventImplCopyWithImpl<_$AppEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppEventImplToJson(
      this,
    );
  }
}

abstract class _AppEvent implements AppEvent {
  const factory _AppEvent(
      {required final String id,
      @JsonKey(name: 'familyId') required final String familyId,
      final String? ownerId,
      final int userId,
      required final String title,
      final String? notes,
      final String? description,
      @JsonKey(fromJson: _eventTypeFromString, toJson: _eventTypeToString)
      final EventType type,
      @JsonKey(name: 'date') required final String dateKey,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
      final DateTime? startAt,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
      final DateTime? endAt,
      final String? startTime,
      final String? endTime,
      final bool allDay,
      final bool isAllDay,
      final String? colorHex,
      final List<String> participants,
      final String? category,
      final Recurrence? recurrence,
      final int notifyMinutesBefore,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
      final DateTime? createdAt,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
      final DateTime? updatedAt,
      @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
      final DateTime? deletedAt,
      final String? location}) = _$AppEventImpl;

  factory _AppEvent.fromJson(Map<String, dynamic> json) =
      _$AppEventImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'familyId')
  String get familyId;
  @override
  String? get ownerId;
  @override
  int get userId; // 🔹 ID del usuario que creó el evento (1-5)
  @override
  String get title;
  @override
  String? get notes; // Mantener 'notes' para compatibilidad
  @override
  String? get description; // Añadir 'description' para nueva estructura
  @override
  @JsonKey(fromJson: _eventTypeFromString, toJson: _eventTypeToString)
  EventType get type;
  @override
  @JsonKey(name: 'date')
  String get dateKey;
  @override
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  DateTime? get startAt; // Mantener para compatibilidad
  @override
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  DateTime? get endAt; // Mantener para compatibilidad
  @override
  String? get startTime; // Hora de inicio como string "HH:mm"
  @override
  String? get endTime; // Hora de fin como string "HH:mm"
  @override
  bool get allDay; // Mantener para compatibilidad
  @override
  bool get isAllDay; // Añadir para nueva estructura
  @override
  String? get colorHex;
  @override
  List<String> get participants;
  @override
  String? get category;
  @override
  Recurrence? get recurrence;
  @override
  int get notifyMinutesBefore;
  @override
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  DateTime? get createdAt;
  @override
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  DateTime? get updatedAt;
  @override
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  DateTime? get deletedAt;
  @override
  String? get location;

  /// Create a copy of AppEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppEventImplCopyWith<_$AppEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
