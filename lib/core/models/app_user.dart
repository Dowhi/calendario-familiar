import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    String? familyId,
    @Default([]) List<String> deviceTokens,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
  
  // Usuario vacío para representar "no autenticado"
  factory AppUser.empty() => const AppUser(
    uid: '',
    email: '',
    displayName: null,
    photoUrl: null,
    familyId: null,
    deviceTokens: [],
  );
}

