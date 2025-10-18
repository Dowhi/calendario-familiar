import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/day_detail_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/year_summary_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/statistics_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/notification_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/ringing_alarm_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/shift_template_management_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/user_management_screen.dart';
// Eliminado: import family_management_screen, family_settings_screen (ya no se utiliza)
import 'package:calendario_familiar/features/calendar/presentation/screens/advanced_reports_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/available_shifts_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/shift_configuration_screen.dart';
// Eliminado: import login_screen, email_signup_screen, password_recovery_screen (ya no se utiliza)
import 'package:calendario_familiar/features/calendar/presentation/screens/settings_screen.dart';
// Eliminado: import auth_controller (ya no se utiliza)
import 'package:calendario_familiar/core/models/shift_template.dart'; // Importar ShiftTemplate
import 'package:calendario_familiar/features/splash/presentation/screens/splash_screen.dart';
import 'package:calendario_familiar/features/splash/presentation/screens/splash_screen_alternative.dart';

// Variable global para el navigatorKey
final navigatorKey = GlobalKey<NavigatorState>();
// Estado inicial para aperturas desde notificación/alarma
bool openedFromNotification = false;
Map<String, dynamic>? initialAlarmData;

final appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) async {
    // Ya no necesitamos redirect porque initialLocation lo maneja
    return null;
  },
  routes: [
    // Ruta de splash screen
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    
    // Ruta principal del calendario
    GoRoute(
      path: '/calendar',
      builder: (context, state) => const CalendarScreen(),
    ),
    
    // Ruta raíz que redirige al calendario (para compatibilidad)
    GoRoute(
      path: '/',
      redirect: (context, state) => '/calendar',
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
    
    // Ruta para gestión de usuarios
    GoRoute(
      path: '/user-management',
      builder: (context, state) => const UserManagementScreen(),
    ),
    
    // Nueva ruta para turnos disponibles
    GoRoute(
      path: '/available-shifts',
      builder: (context, state) => const AvailableShiftsScreen(),
    ),
    
    // Nueva ruta para configuración de turnos
    GoRoute(
      path: '/shift-configuration',
      builder: (context, state) {
        final extraData = state.extra as ShiftTemplate?;
        return ShiftConfigurationScreen(shiftTemplate: extraData);
      },
    ),
    
    // Eliminado: Rutas de gestión familiar y configuración de familia (ya no se utiliza)
    
    // Nueva ruta para reportes avanzados
    GoRoute(
      path: '/advanced-reports',
      builder: (context, state) => const AdvancedReportsScreen(),
    ),
    
    // Eliminado: Rutas de login, registro y recuperación de contraseña (ya no se utiliza)
    
    // Nueva ruta para la pantalla de configuración
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
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
    // Nueva ruta: pantalla de alarma (full-screen)
    GoRoute(
      path: '/alarm',
      builder: (context, state) {
        // Soportar datos vía extra, initialAlarmData o query params
        final args = <String, dynamic>{}
          ..addAll((state.extra as Map<String, dynamic>?) ?? {})
          ..addAll(initialAlarmData ?? {})
          ..addAll(state.uri.queryParameters);

        return RingingAlarmScreen(
          title: (args['title'] as String?) ?? 'Notificación',
          notes: (args['notes'] as String?) ?? '',
          dateText: (args['dateKey'] as String?) ?? '',
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
            onPressed: () => context.go('/calendar'),
            child: const Text('Volver al inicio'),
          ),
        ],
      ),
    ),
  ),
);
