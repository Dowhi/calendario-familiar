import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/day_detail_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/year_summary_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/statistics_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/notification_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/shift_template_management_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/family_management_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/family_settings_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/advanced_reports_screen.dart';
import 'package:calendario_familiar/features/auth/presentation/login_screen.dart';
import 'package:calendario_familiar/features/auth/presentation/email_signup_screen.dart';
import 'package:calendario_familiar/features/settings/presentation/screens/settings_screen.dart';
import 'package:calendario_familiar/main.dart';
import 'package:calendario_familiar/features/auth/presentation/password_recovery_screen.dart';
import 'package:calendario_familiar/features/auth/logic/auth_controller.dart'; // Importar AuthController

// Variable global para el navigatorKey
final navigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/login', // Cambiado de 'openedFromNotification ? '/notification-screen' : '/' a '/login'
  redirect: (context, state) async {
    // Primero, manejar la redirección por notificaciones si aplica
    if (openedFromNotification && state.fullPath != '/notification-screen') {
      openedFromNotification = false;
      print('➡️ Redirigiendo por notificación a /notification-screen');
      return '/notification-screen';
    }

    // Obtener el proveedor de Riverpod para AuthController
    final container = ProviderScope.containerOf(context);
    final authController = container.read(authControllerProvider.notifier);
    
    // Forzar verificación del usuario actual
    final appUser = await authController.refreshCurrentUser();
    print('🔍 Usuario actual en redirect: $appUser');

    final isAuthenticated = appUser != null && appUser.uid.isNotEmpty;
    final hasFamily = isAuthenticated && (appUser?.familyId != null && appUser!.familyId!.isNotEmpty);

    final loggingIn = state.matchedLocation == '/login';
    final creatingAccount = state.matchedLocation == '/email-signup';
    final recoveringPassword = state.matchedLocation == '/password-recovery';

    // Rutas permitidas para usuarios no autenticados
    final bool isAuthRoute = loggingIn || creatingAccount || recoveringPassword;

    print(' Estado de autenticación en redirect: isAuthenticated=$isAuthenticated, hasFamily=$hasFamily, isAuthRoute=$isAuthRoute, currentPath=${state.matchedLocation}');

    // Si no está autenticado y no está en una ruta de autenticación, ir a login
    if (!isAuthenticated && !isAuthRoute) {
      print('➡️ Usuario no autenticado y no en ruta de auth, redirigiendo a /login');
      return '/login';
    }

    // Si está autenticado, pero no tiene familia y no está en la gestión familiar, ir a gestión familiar
    if (isAuthenticated && !hasFamily && state.matchedLocation != '/family-management') {
      print('➡️ Usuario autenticado sin familia y no en gestión familiar, redirigiendo a /family-management');
      return '/family-management';
    }

    // Si está autenticado y tiene familia, y está en una ruta de autenticación o gestión familiar, ir al calendario
    if (isAuthenticated && hasFamily && (isAuthRoute || state.matchedLocation == '/family-management')) {
      print('➡️ Usuario autenticado con familia, redirigiendo a /');
      return '/';
    }

    // Para cualquier otro caso, no redirigir
    print('✅ No se requiere redirección. Ruta actual: ${state.matchedLocation}');
    return null;
  },
  routes: [
    // Ruta principal del calendario - DIRECTO
    GoRoute(
      path: '/',
      builder: (context, state) => const CalendarScreen(),
    ),
    
    // Ruta de detalle del día
    GoRoute(
      path: '/day-detail',
      builder: (context, state) {
        final extraData = state.extra as Map<String, dynamic>?;
        if (extraData == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Datos no proporcionados para DayDetailScreen')),
          );
        }
        
        final date = extraData['date'] as DateTime?;
        final existingText = extraData['existingText'] as String?;
        final existingEventId = extraData['existingEventId'] as String?;
        
        if (date == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Fecha no proporcionada para DayDetailScreen')),
          );
        }
        
        return DayDetailScreen(
          date: date,
          existingText: existingText,
          existingEventId: existingEventId,
        );
      },
    ),
    
    // Ruta del resumen anual
    GoRoute(
      path: '/year-summary',
      builder: (context, state) {
        final year = state.extra as int? ?? DateTime.now().year;
        return YearSummaryScreen(year: year);
      },
    ),
    
    // Ruta de estadísticas
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsScreen(),
    ),
    
    // Nueva ruta para la gestión de plantillas de turnos
    GoRoute(
      path: '/shift-templates',
      builder: (context, state) => const ShiftTemplateManagementScreen(),
    ),
    
    // Nueva ruta para la gestión familiar
    GoRoute(
      path: '/family-management',
      builder: (context, state) => const FamilyManagementScreen(),
    ),
    
    // Nueva ruta para la configuración de familia
    GoRoute(
      path: '/family-settings',
      builder: (context, state) => const FamilySettingsScreen(),
    ),
    
    // Nueva ruta para reportes avanzados
    GoRoute(
      path: '/advanced-reports',
      builder: (context, state) => const AdvancedReportsScreen(),
    ),
    
    // Ruta de login para la pantalla de inicio de sesión
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    
    // Nueva ruta para el registro por email
    GoRoute(
      path: '/email-signup',
      builder: (context, state) => const EmailSignupScreen(),
    ),
    
    // Nueva ruta para la pantalla de configuración
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    
    // Nueva ruta para recuperación de contraseña
    GoRoute(
      path: '/password-recovery',
      builder: (context, state) => const PasswordRecoveryScreen(),
    ),
    
    // Ruta para pantalla de notificaciones
    GoRoute(
      path: '/notification-screen',
      builder: (context, state) {
        final extraData = state.extra as Map<String, dynamic>?;
        if (extraData == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Datos no proporcionados para NotificationScreen')),
          );
        }
        
        final eventText = extraData['eventText'] as String?;
        final eventDate = extraData['eventDate'] as DateTime?;
        
        if (eventText == null || eventDate == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Datos de evento no proporcionados')),
          );
        }
        
        return NotificationScreen(
          eventText: eventText,
          eventDate: eventDate,
        );
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: ${state.error}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Volver al inicio'),
          ),
        ],
      ),
    ),
  ),
);
