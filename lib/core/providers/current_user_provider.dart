import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calendario_familiar/core/models/local_user.dart';

/// Proveedor del ID del usuario activo actual
final currentUserIdProvider = StateNotifierProvider<CurrentUserIdNotifier, int>((ref) {
  return CurrentUserIdNotifier();
});

/// Proveedor del usuario activo completo
final currentUserProvider = Provider<LocalUser>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return getUserById(userId);
});

/// Notifier para gestionar el usuario actual
class CurrentUserIdNotifier extends StateNotifier<int> {
  static const String _storageKey = 'current_user_id';
  
  CurrentUserIdNotifier() : super(1) {
    _loadCurrentUser();
  }

  /// Carga el usuario guardado en SharedPreferences
  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getInt(_storageKey);
      if (savedUserId != null && savedUserId >= 1 && savedUserId <= 5) {
        state = savedUserId;
      }
    } catch (e) {
      print('Error cargando usuario actual: $e');
    }
  }

  /// Cambia el usuario actual y lo guarda
  Future<void> setCurrentUser(int userId) async {
    if (userId >= 1 && userId <= 5) {
      state = userId;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_storageKey, userId);
      } catch (e) {
        print('Error guardando usuario actual: $e');
      }
    }
  }
}

