import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendario_familiar/core/firebase/firebase_options_temp.dart';
import 'package:calendario_familiar/routing/app_router_temp.dart';
import 'package:calendario_familiar/theme/app_theme.dart';
import 'package:calendario_familiar/core/providers/theme_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/notification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/date_symbol_data_local.dart';

// Variable global para manejar la navegación
GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Variable para controlar si la app se abrió desde una notificación
bool openedFromNotification = false;
String pendingEventText = '';
DateTime pendingEventDate = DateTime.now();

// Variable global para el contexto de la aplicación
BuildContext? _appContext;

// =========================================================================
// Funciones de Manejo de Notificaciones (Nivel Superior)
// =========================================================================

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  handleNotificationResponse(notificationResponse);
}

void handleNotificationResponse(NotificationResponse response) {
  print('🔔 Notificación tocada: ${response.payload} (ActionId: ${response.actionId})');
  
  if (response.payload != null && response.payload!.startsWith('alarm|')) {
    final payloadParts = response.payload!.split('|');
    if (payloadParts.length >= 3) {
      final String eventText = payloadParts[1];
      final DateTime eventDate = DateTime.parse(payloadParts[2]);
      
      if (response.actionId == 'dismiss') {
        print('❌ Alarma descartada para: $eventText');
        return;
      }
      
      // Guardar datos para cuando la app se abra
      openedFromNotification = true;
      pendingEventText = eventText;
      pendingEventDate = eventDate;
      
      print('📱 Datos guardados para navegación: $eventText en $eventDate');
    }
  }
}

// =========================================================================
// Inicialización de la Aplicación
// =========================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar orientación de pantalla
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializar Firebase con configuración temporal
  String firebaseStatus = 'Inicializando...';
  try {
    await Firebase.initializeApp(
      options: TempFirebaseOptions.currentPlatform,
    );
    firebaseStatus = '✅ Firebase inicializado correctamente';
    print('✅ Firebase inicializado correctamente');
  } catch (e) {
    firebaseStatus = '❌ Error inicializando Firebase: $e';
    print('❌ Error inicializando Firebase: $e');
  }

  // Inicializar timezone
  tz.initializeTimeZones();
  
  // Inicializar notificaciones locales
  await _initializeNotifications();
  
  // Inicializar datos de localización
  await initializeDateFormatting('es_ES', null);

  runApp(ProviderScope(
    child: CalendarioFamiliarApp(initialFirebaseStatus: firebaseStatus),
  ));
}

// =========================================================================
// Inicialización de Notificaciones
// =========================================================================

Future<void> _initializeNotifications() async {
  try {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: handleNotificationResponse,
    );

    print('✅ Notificaciones locales inicializadas');
  } catch (e) {
    print('❌ Error inicializando notificaciones: $e');
  }
}

// =========================================================================
// Widget Principal de la Aplicación
// =========================================================================

class CalendarioFamiliarApp extends ConsumerWidget {
  final String initialFirebaseStatus;

  const CalendarioFamiliarApp({
    super.key,
    required this.initialFirebaseStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtener el tema actual
    final isDarkMode = ref.watch(themeProvider);
    
    // Guardar el contexto global
    _appContext = context;

    return MaterialApp.router(
      title: 'Calendario Familiar - Testing',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0), // Prevenir escalado de texto
          ),
          child: child!,
        );
      },
    );
  }
}

// =========================================================================
// Funciones de Utilidad Global
// =========================================================================

/// Obtiene el contexto global de la aplicación
BuildContext? get appContext => _appContext;

/// Navega a una ruta específica usando el contexto global
void navigateToRoute(String route) {
  if (_appContext != null) {
    GoRouter.of(_appContext!).go(route);
  }
}

/// Muestra un snackbar usando el contexto global
void showGlobalSnackBar(String message, {Color? backgroundColor}) {
  if (_appContext != null) {
    ScaffoldMessenger.of(_appContext!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
}
