class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? familyId;
  final List<String> deviceTokens;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.familyId,
    this.deviceTokens = const [],
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid']?.toString() ?? '',
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

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'familyId': familyId,
      'deviceTokens': deviceTokens,
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? familyId,
    List<String>? deviceTokens,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      familyId: familyId ?? this.familyId,
      deviceTokens: deviceTokens ?? this.deviceTokens,
    );
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.familyId == familyId;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        photoUrl.hashCode ^
        familyId.hashCode;
  }
}

