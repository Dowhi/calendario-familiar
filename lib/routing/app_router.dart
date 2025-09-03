import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendario_familiar/features/auth/logic/auth_controller.dart';
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
import 'package:calendario_familiar/features/auth/presentation/widgets/auth_wrapper.dart';

// Variable global para el navigatorKey
final navigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: openedFromNotification ? '/notification-screen' : '/',
  redirect: (context, state) {
    // Redirección para notificaciones
    if (openedFromNotification && state.fullPath != '/notification-screen') {
      openedFromNotification = false;
      return '/notification-screen';
    }
    
    // Redirección de autenticación
    final container = ProviderScope.containerOf(context);
    final authController = container.read(authControllerProvider.notifier);
    final currentUser = container.read(authControllerProvider);
    
    // Si estamos en login y ya estamos autenticados, ir al calendario
    if (state.fullPath == '/login' && currentUser != null) {
      return '/';
    }
    
    // Si no estamos autenticados y no estamos en login, ir a login
    if (currentUser == null && state.fullPath != '/login' && state.fullPath != '/email-signup' && state.fullPath != '/password-recovery') {
      return '/login';
    }
    
    // Si estamos autenticados, permitir acceso a todas las rutas
    return null;
  },
  routes: [
    // Ruta principal del calendario
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthWrapper(),
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
    
    // Nueva ruta para el login
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
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error 404',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Página no encontrada',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Volver al inicio'),
          ),
        ],
      ),
    ),
  ),
);

