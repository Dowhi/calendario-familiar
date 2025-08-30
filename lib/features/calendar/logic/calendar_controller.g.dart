// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$calendarStreamHash() => r'4557be6401bbdd674610d342958c96b163544c94';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [calendarStream].
@ProviderFor(calendarStream)
const calendarStreamProvider = CalendarStreamFamily();

/// See also [calendarStream].
class CalendarStreamFamily extends Family<AsyncValue<FamilyCalendar?>> {
  /// See also [calendarStream].
  const CalendarStreamFamily();

  /// See also [calendarStream].
  CalendarStreamProvider call(String calendarId) {
    return CalendarStreamProvider(calendarId);
  }

  @override
  CalendarStreamProvider getProviderOverride(
    covariant CalendarStreamProvider provider,
  ) {
    return call(provider.calendarId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'calendarStreamProvider';
}

/// See also [calendarStream].
class CalendarStreamProvider
    extends AutoDisposeStreamProvider<FamilyCalendar?> {
  /// See also [calendarStream].
  CalendarStreamProvider(String calendarId)
    : this._internal(
        (ref) => calendarStream(ref as CalendarStreamRef, calendarId),
        from: calendarStreamProvider,
        name: r'calendarStreamProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$calendarStreamHash,
        dependencies: CalendarStreamFamily._dependencies,
        allTransitiveDependencies:
            CalendarStreamFamily._allTransitiveDependencies,
        calendarId: calendarId,
      );

  CalendarStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.calendarId,
  }) : super.internal();

  final String calendarId;

  @override
  Override overrideWith(
    Stream<FamilyCalendar?> Function(CalendarStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CalendarStreamProvider._internal(
        (ref) => create(ref as CalendarStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        calendarId: calendarId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<FamilyCalendar?> createElement() {
    return _CalendarStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CalendarStreamProvider && other.calendarId == calendarId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, calendarId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CalendarStreamRef on AutoDisposeStreamProviderRef<FamilyCalendar?> {
  /// The parameter `calendarId` of this provider.
  String get calendarId;
}

class _CalendarStreamProviderElement
    extends AutoDisposeStreamProviderElement<FamilyCalendar?>
    with CalendarStreamRef {
  _CalendarStreamProviderElement(super.provider);

  @override
  String get calendarId => (origin as CalendarStreamProvider).calendarId;
}

String _$calendarControllerHash() =>
    r'5c20a7750c59ffeb6d4a89cc973c8726ec454e5f';

/// See also [CalendarController].
@ProviderFor(CalendarController)
final calendarControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      CalendarController,
      FamilyCalendar?
    >.internal(
      CalendarController.new,
      name: r'calendarControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$calendarControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CalendarController = AutoDisposeAsyncNotifier<FamilyCalendar?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
