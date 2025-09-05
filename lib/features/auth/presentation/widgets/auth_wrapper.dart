import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:calendario_familiar/features/auth/logic/auth_controller.dart';
import 'package:calendario_familiar/features/auth/presentation/login_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/calendar_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    
    // Mostrar pantalla de carga mientras se verifica la autenticación
    if (authState == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verificando autenticación...'),
            ],
          ),
        ),
      );
    }
    
    // Si hay usuario autenticado (uid no está vacío), mostrar el calendario
    if (authState.uid.isNotEmpty) {
      return const CalendarScreen();
    }
    
    // Si no hay usuario autenticado (uid está vacío), mostrar el login
    return const LoginScreen();
  }
}
