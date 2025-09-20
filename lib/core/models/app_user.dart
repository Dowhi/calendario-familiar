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

  factory AppUser.fromJson(Map<String, dynamic> json) {
    try {
      return _$AppUserFromJson(json);
    } catch (e) {
      print('❌ Error en AppUser.fromJson: $e');
      print('🔍 JSON problemático: $json');
      
      // Crear usuario con valores seguros
      return AppUser(
        uid: json['uid']?.toString() ?? 'unknown',
        email: json['email']?.toString() ?? '',
        displayName: json['displayName']?.toString(),
        photoUrl: json['photoUrl']?.toString(),
        familyId: json['familyId']?.toString(),
        deviceTokens: (json['deviceTokens'] as List<dynamic>?)
            ?.map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList() ?? [],
      );
    }
  }
  
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

