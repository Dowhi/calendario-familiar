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
import 'package:calendario_familiar/features/auth/presentation/login_screen_temp.dart';
import 'package:calendario_familiar/features/auth/presentation/email_signup_screen.dart';
import 'package:calendario_familiar/features/settings/presentation/screens/settings_screen.dart';
import 'package:calendario_familiar/main_temp.dart';
import 'package:calendario_familiar/features/auth/presentation/password_recovery_screen.dart';
import 'package:calendario_familiar/features/auth/logic/auth_controller_temp.dart';

// Variable global para el navigatorKey
final navigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/', // Cambiado para que inicie en la ruta principal por defecto
  redirect: (context, state) async {
    // Primero, manejar la redirección por notificaciones si aplica
    if (openedFromNotification && state.fullPath != '/notification-screen') {
      openedFromNotification = false;
      print('➡️ Redirigiendo por notificación a /notification-screen');
      return '/notification-screen';
    }

    // Obtener el proveedor de Riverpod para AuthController
    final container = ProviderScope.containerOf(context);
    final authController = container.read(authControllerTempProvider.notifier);
    
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

    print('🔍 Estado de autenticación en redirect: isAuthenticated=$isAuthenticated, hasFamily=$hasFamily, isAuthRoute=$isAuthRoute, currentPath=${state.matchedLocation}');

    // Si el usuario no está autenticado y no está en una ruta de autenticación, redirigir al login
    if (!isAuthenticated && !isAuthRoute) {
      print('🔍 Usuario no autenticado y no ruta de auth, redirigiendo a /login');
      return '/login';
    }

    // Si el usuario está autenticado pero no tiene familia y no está en gestión de familia, redirigir a gestión de familia
    if (isAuthenticated && !hasFamily && state.matchedLocation != '/family-management') {
      print('🔍 Usuario autenticado sin familia, redirigiendo a /family-management');
      return '/family-management';
    }

    // Si el usuario está autenticado y tiene familia, y está en login, redirigir al calendario
    if (isAuthenticated && hasFamily && loggingIn) {
      print('🔍 Usuario autenticado con familia en login, redirigiendo a /');
      return '/';
    }

    print('🔍 No se requiere redirección. Ruta actual: ${state.matchedLocation}');
    return null; // No redirigir
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const CalendarScreen(),
    ),
    GoRoute(
      path: '/day-detail/:date',
      builder: (context, state) {
        final date = state.pathParameters['date']!;
        return DayDetailScreen(date: DateTime.parse(date));
      },
    ),
    GoRoute(
      path: '/year-summary/:year',
      builder: (context, state) {
        final year = int.parse(state.pathParameters['year']!);
        return YearSummaryScreen(year: year);
      },
    ),
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsScreen(),
    ),
    GoRoute(
      path: '/notification-screen',
      builder: (context, state) => NotificationScreen(
        eventText: pendingEventText,
        eventDate: pendingEventDate,
      ),
    ),
    GoRoute(
      path: '/shift-template-management',
      builder: (context, state) => const ShiftTemplateManagementScreen(),
    ),
    GoRoute(
      path: '/family-management',
      builder: (context, state) => const FamilyManagementScreen(),
    ),
    GoRoute(
      path: '/family-settings',
      builder: (context, state) => const FamilySettingsScreen(),
    ),
    GoRoute(
      path: '/advanced-reports',
      builder: (context, state) => const AdvancedReportsScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreenTemp(),
    ),
    GoRoute(
      path: '/email-signup',
      builder: (context, state) => const EmailSignupScreen(),
    ),
    GoRoute(
      path: '/password-recovery',
      builder: (context, state) => const PasswordRecoveryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
