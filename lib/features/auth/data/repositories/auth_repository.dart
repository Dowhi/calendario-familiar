import 'package:calendario_familiar/core/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final appUser = await getUserData(user.uid);
      if (appUser == null) {
        // Si el usuario de Firebase existe pero no tiene un perfil en Firestore, créalo.
        final newAppUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
          deviceTokens: [],
        );
        await _saveUserToFirestore(newAppUser);
        return newAppUser;
      }
      return appUser;
    });
  }

  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    // Nota: Esto solo devuelve una AppUser básica con datos de Firebase Auth.
    // Para datos completos de Firestore, usar getUserData.
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      deviceTokens: [], // Se llenará con getUserData
    );
  }

  /// Registro por correo electrónico y contraseña
  Future<AppUser?> signUpWithEmail(String email, String password, String displayName) async {
    try {
      print('🔐 Iniciando registro con email: $email');
      
      // Crear usuario en Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        print('❌ No se pudo crear usuario en Firebase Auth');
        return null;
      }

      print('✅ Usuario creado en Firebase Auth: ${firebaseUser.uid}');

      // Actualizar displayName en Firebase Auth
      await firebaseUser.updateDisplayName(displayName);

      // Crear objeto AppUser
      final appUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: displayName,
        photoUrl: null,
        deviceTokens: [],
        familyId: null, // Sin familia inicialmente
      );

      // Guardar usuario en Firestore
      await _saveUserToFirestore(appUser);
      
      print('✅ Usuario guardado en Firestore: ${appUser.displayName}');
      return appUser;
      
    } catch (e) {
      print('❌ Error en signUpWithEmail: $e');
      rethrow;
    }
  }

  /// Inicio de sesión por correo electrónico y contraseña
  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      print('🔐 Iniciando sesión con email: $email');
      
      // Iniciar sesión en Firebase Auth
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        print('❌ No se pudo obtener usuario de Firebase');
        return null;
      }

      print('✅ Usuario autenticado en Firebase: ${firebaseUser.uid}');

      // Obtener datos completos de Firestore
      final appUser = await getUserData(firebaseUser.uid);
      if (appUser != null) {
        print('✅ Usuario encontrado en Firestore: ${appUser.displayName}');
        return appUser;
      } else {
        print('⚠️ Usuario no encontrado en Firestore, creando perfil básico');
        // Crear perfil básico si no existe en Firestore
        final basicAppUser = AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'Usuario',
          photoUrl: firebaseUser.photoURL,
          deviceTokens: [],
          familyId: null,
        );
        await _saveUserToFirestore(basicAppUser);
        return basicAppUser;
      }
      
    } catch (e) {
      print('❌ Error en signInWithEmail: $e');
      rethrow;
    }
  }

  Future<AppUser?> signInWithGoogle() async {
    try {
      print('🔐 Iniciando Google Sign-In...');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('❌ Usuario canceló el inicio de sesión');
        return null;
      }

      print('✅ Usuario de Google seleccionado: ${googleUser.email}');
      
      // Obtener credenciales de autenticación
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión en Firebase Auth
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        print('❌ No se pudo obtener usuario de Firebase');
        return null;
      }

      print('✅ Usuario autenticado en Firebase: ${firebaseUser.uid}');

      // PRIMERO: Verificar si el usuario ya existe en Firestore por UID
      final existingUser = await getUserData(firebaseUser.uid);
      if (existingUser != null) {
        print('✅ Usuario existente encontrado por UID: ${existingUser.displayName}');
        return existingUser;
      }

      // SEGUNDO: Si no existe por UID, buscar por email para verificar si es el mismo usuario
      final userByEmail = await getUserByEmail(firebaseUser.email!);
      if (userByEmail != null) {
        print('✅ Usuario encontrado por email: ${userByEmail.displayName}');
        print('⚠️ Actualizando UID del usuario existente de ${userByEmail.uid} a ${firebaseUser.uid}');
        
        // Actualizar el UID del usuario existente al nuevo UID de Google
        final updatedUser = AppUser(
          uid: firebaseUser.uid,
          email: userByEmail.email,
          displayName: userByEmail.displayName,
          photoUrl: firebaseUser.photoURL ?? userByEmail.photoUrl,
          deviceTokens: userByEmail.deviceTokens,
          familyId: userByEmail.familyId, // Mantener la familia existente
        );
        
        // Guardar con el nuevo UID
        await _saveUserToFirestore(updatedUser);
        
        // Eliminar el documento anterior con el UID viejo
        await _firestore.collection('users').doc(userByEmail.uid).delete();
        
        print('✅ Usuario actualizado con nuevo UID y familia mantenida');
        return updatedUser;
      }

      // TERCERO: Si no existe en absoluto, crear nuevo usuario
      final appUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? 'Usuario',
        photoUrl: firebaseUser.photoURL,
        deviceTokens: [],
        familyId: null, // Sin familia inicialmente
      );

      // Guardar usuario en Firestore
      await _saveUserToFirestore(appUser);
      
      print('✅ Nuevo usuario guardado en Firestore: ${appUser.displayName}');
      return appUser;
      
    } catch (e) {
      print('❌ Error en signInWithGoogle: $e');
      rethrow;
    }
  }

  /// Verificar si un usuario tiene familia
  Future<bool> userHasFamily(String uid) async {
    try {
      final userData = await getUserData(uid);
      if (userData == null) {
        print('❌ Usuario no encontrado: $uid');
        return false;
      }
      
      // Verificar si tiene familyId
      if (userData.familyId == null || userData.familyId!.isEmpty) {
        print('🔍 Usuario ${userData.displayName} no tiene familyId');
        return false;
      }
      
      // Verificar que la familia existe y el usuario está en ella
      final familyDoc = await _firestore.collection('families').doc(userData.familyId).get();
      if (!familyDoc.exists) {
        print('❌ Familia no encontrada: ${userData.familyId}');
        return false;
      }
      
      final familyData = familyDoc.data()!;
      final members = familyData['members'] as List<dynamic>?;
      
      if (members != null && members.contains(uid)) {
        print('✅ Usuario ${userData.displayName} tiene familia válida: ${familyData['name']}');
        return true;
      } else {
        print('❌ Usuario ${userData.displayName} no está en la lista de miembros de la familia');
        return false;
      }
    } catch (e) {
      print('❌ Error verificando si usuario tiene familia: $e');
      return false;
    }
  }

  /// Obtener el rol del usuario en su familia
  Future<String?> getUserFamilyRole(String uid) async {
    try {
      final userData = await getUserData(uid);
      if (userData?.familyId == null) {
        print('❌ Usuario no tiene familia: $uid');
        return null;
      }

      // Obtener datos de la familia
      final familyDoc = await _firestore.collection('families').doc(userData!.familyId).get();
      if (!familyDoc.exists) {
        print('❌ Familia no encontrada: ${userData.familyId}');
        return null;
      }

      final familyData = familyDoc.data()!;
      final roles = familyData['roles'] as Map<String, dynamic>?;
      
      if (roles != null && roles.containsKey(uid)) {
        final role = roles[uid] as String;
        print('🔍 Usuario ${userData.displayName} tiene rol: $role');
        return role;
      }

      print('❌ Rol no encontrado para usuario: $uid');
      return null;
    } catch (e) {
      print('❌ Error obteniendo rol del usuario: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error en signOut: $e');
    }
  }

  Future<AppUser?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error obteniendo datos del usuario: $e');
      return null;
    }
  }

  /// Buscar usuario por email
  Future<AppUser?> getUserByEmail(String email) async {
    try {
      print('🔍 Buscando usuario por email: $email');
      
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final userData = AppUser.fromJson(querySnapshot.docs.first.data());
        print('✅ Usuario encontrado por email: ${userData.displayName}');
        return userData;
      }
      
      print('❌ No se encontró usuario con email: $email');
      return null;
    } catch (e) {
      print('❌ Error buscando usuario por email: $e');
      return null;
    }
  }

  Future<void> _saveUserToFirestore(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      print('Error guardando usuario en Firestore: $e');
      rethrow;
    }
  }

  Future<void> updateUserFamilyId(String uid, String? familyId) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'familyId': familyId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error actualizando familyId: $e');
      rethrow;
    }
  }

  Future<void> updateDeviceToken(String uid, String token) async {
    try {
      final userDoc = _firestore.collection('users').doc(uid);
      await userDoc.update({
        'deviceTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error actualizando device token: $e');
      rethrow;
    }
  }

  Future<void> removeDeviceToken(String uid, String token) async {
    try {
      final userDoc = _firestore.collection('users').doc(uid);
      await userDoc.update({
        'deviceTokens': FieldValue.arrayRemove([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removiendo device token: $e');
      rethrow;
    }
  }
}

