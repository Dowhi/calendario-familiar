import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Añadir esta importación
import 'package:calendario_familiar/core/firebase/firebase_options.dart';
import 'package:calendario_familiar/core/services/calendar_data_service.dart';
import 'package:calendario_familiar/routing/app_router.dart';
import 'package:calendario_familiar/theme/app_theme.dart';
import 'package:calendario_familiar/core/providers/theme_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/notification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';
import 'dart:io' show Platform;
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
        print('🔇 Notificación de alarma descartada');
        return;
      }
      
      if (response.actionId == null || response.actionId == 'open_screen') {
        openedFromNotification = true;
        pendingEventText = eventText;
        pendingEventDate = eventDate;
        print('🔔 Marcado para abrir pantalla automáticamente desde handleNotificationResponse: $pendingEventText');
        
        // _tryOpenNotificationScreen(); // Eliminado, GoRouter ahora maneja la navegación inicial

      } else {
        print('❌ Payload de alarma malformado en handleNotificationResponse: ${response.payload}');
      }
    } else {
      print('❓ Payload no reconocido en handleNotificationResponse: ${response.payload}');
    }
  }
}

// Este método ya no se usa directamente desde _handleNotificationResponse
// ahora la navegación inicial la gestiona GoRouter.
// Se mantiene por si se necesita una lógica similar en el futuro,
// pero no será llamado directamente por las notificaciones.
void _tryOpenNotificationScreen() {
  print('🔔 _tryOpenNotificationScreen llamado. Pending: $pendingEventText');
  
  if (pendingEventText.isEmpty) {
    print('⚠️ No hay evento pendiente para abrir.');
    return;
  }

  final Map<String, dynamic> extraData = {
    'eventText': pendingEventText,
    'eventDate': pendingEventDate,
  };

  // Primer intento inmediato
  if (navigatorKey.currentState?.context != null) {
    navigatorKey.currentState!.context.go('/notification-screen', extra: extraData);
    print('✅ Pantalla de alarma abierta automáticamente en primer intento: $pendingEventText');
    // Resetear las variables una vez que la pantalla se ha abierto
    pendingEventText = '';
    pendingEventDate = DateTime.now();
    openedFromNotification = false;
    return;
  }
  
  print('⏳ Navigator no disponible en _tryOpenNotificationScreen, reintentando en 1 segundo...');
  
  // Segundo intento después de 1 segundo
  Future.delayed(const Duration(seconds: 1), () {
    if (navigatorKey.currentState?.context != null) {
      navigatorKey.currentState!.context.go('/notification-screen', extra: extraData);
      print('✅ Pantalla de alarma abierta automáticamente en segundo intento: $pendingEventText');
      // Resetear las variables
      pendingEventText = '';
      pendingEventDate = DateTime.now();
      openedFromNotification = false;
      return;
    }
    
    print('⏳ Navigator aún no disponible en _tryOpenNotificationScreen, reintentando en 2 segundos...');
    
    // Tercer intento después de 2 segundos más
    Future.delayed(const Duration(seconds: 2), () {
      if (navigatorKey.currentState?.context != null) {
        navigatorKey.currentState!.context.go('/notification-screen', extra: extraData);
        print('✅ Pantalla de alarma abierta automáticamente en tercer intento: $pendingEventText');
        // Resetear las variables
        pendingEventText = '';
        pendingEventDate = DateTime.now();
        openedFromNotification = false;
      } else {
        print('❌ No se pudo abrir la pantalla de alarma automáticamente después de múltiples intentos.');
      }
    });
  });
}

// Método para programar alarmas nativas en Android
// Esta función ya no se usa, se eliminó en favor de flutter_local_notifications
// Future<void> scheduleNativeAlarm(DateTime scheduledDate, String eventText) async {
//   if (Platform.isAndroid) {
//     try {
//       const platform = MethodChannel('com.juancarlos.calendariofamiliar/alarm');
//       final alarmTime = scheduledDate.millisecondsSinceEpoch;
//       
//       await platform.invokeMethod('scheduleAlarm', {
//         'alarmTime': alarmTime,
//         'eventText': eventText,
//       });
//       
//       print('✅ Alarma nativa programada para: $scheduledDate');
//     } catch (e) {
//       print('❌ Error programando alarma nativa: $e');
//     }
//   }
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Obtener detalles de lanzamiento si la app se abrió desde una notificación
  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await notificationsPlugin.getNotificationAppLaunchDetails();
  
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    final String? payload = notificationAppLaunchDetails!.notificationResponse?.payload;
    
    if (payload != null && payload.startsWith('alarm|')) {
      final payloadParts = payload.split('|');
      if (payloadParts.length >= 3) {
        openedFromNotification = true;
        pendingEventText = payloadParts[1];
        pendingEventDate = DateTime.parse(payloadParts[2]);
        print('🔔 App lanzada desde notificación al inicio. Evento pendiente: $pendingEventText');
      } else {
        print('❌ Payload de alarma malformado al inicio de la app: $payload');
      }
    } else {
      print('❓ Payload no reconocido al inicio de la app: $payload');
    }
  }

  // Inicializar timezone para las notificaciones
  tz.initializeTimeZones();
  print('✅ Timezone inicializado para notificaciones');
  
  // Inicializar localización para DateFormat
  await initializeDateFormatting('es_ES', null);
  print('✅ Localización inicializada para DateFormat');
  
  // Inicializar Firebase
  try {
    // Verificar si Firebase ya está inicializado
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase inicializado correctamente');
    } else {
      print('✅ Firebase ya estaba inicializado');
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      print('✅ Firebase ya está inicializado (ignorando error de duplicado)');
    } else {
      print('❌ Error inicializando Firebase: $e');
      print('💡 Verifica que hayas configurado las claves correctas en firebase_options.dart');
    }
  }
  
  // Initialize FlutterLocalNotificationsPlugin
  await _initializeNotifications();

  // await CalendarDataService().initialize(); // Eliminado: CalendarDataService se gestiona por Riverpod

  // Ensure that the initial route is handled correctly
  
  // Inicializar listener de alarmas de Firebase
  _initializeFirebaseAlarmListener();
  
  // Inicializar verificación de alarmas programadas
  _initializeAlarmChecker();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> _initializeNotifications() async {
  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  
  await notifications.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: handleNotificationResponse,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  // Configurar el canal de notificaciones para alarmas
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'event_reminders',
    'Recordatorios de eventos',
    description: 'Notificaciones para recordar eventos del calendario',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
    showBadge: true,
  );
  
  await notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  
  // Solicitar permisos de notificaciones
  await _requestNotificationPermissions();
  
  print('✅ Notificaciones inicializadas');
}

// Solicitar permisos de notificaciones
Future<void> _requestNotificationPermissions() async {
  if (Platform.isAndroid) {
    // Solicitar permiso de notificaciones (Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    
    // Verificar si tenemos permisos de alarmas exactas
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
    
    print('🔐 Permisos de notificaciones solicitados');
  }
}

void _showAlarmNotification(String eventText, DateTime eventDate) async {
  try {
    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'event_reminders',
      'Recordatorios de eventos',
      channelDescription: 'Notificaciones para recordar eventos del calendario',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      showWhen: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      timeoutAfter: 60000,
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: Color(0xFF2196F3),
      enableLights: true,
      ledColor: Color(0xFF2196F3),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await notifications.show(
      9999,
      '🔔 ¡Es hora de tu evento!',
      'Evento: $eventText',
      platformChannelSpecifics,
      payload: 'alarm|$eventText|${eventDate.toIso8601String()}',
    );
    
    print('✅ Notificación de alarma mostrada');
    
  } catch (e) {
    print('❌ Error mostrando notificación: $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    
    // Usar el nuevo router con Riverpod que incluye verificación de autenticación
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'Calendario Familiar',
      theme: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Guardar el contexto de la aplicación para uso global
        _appContext = context;
        return child!;
      },
    );
  }
}

void _initializeFirebaseAlarmListener() {
  // Listener en tiempo real para alarmas de Firebase
  FirebaseFirestore.instance
      .collection('alarms')
      .snapshots()
      .listen((snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
        final alarmData = change.doc.data();
        if (alarmData != null) {
          _scheduleAlarmFromFirebase(alarmData, change.doc.id);
        }
      }
    }
  });
  
  print('✅ Listener de alarmas de Firebase inicializado');
}

void _initializeAlarmChecker() {
  // Verificar alarmas programadas cada 30 segundos
  Timer.periodic(const Duration(seconds: 30), (timer) {
    _checkScheduledAlarms();
  });
  
  // También verificar inmediatamente al iniciar
  _checkScheduledAlarms();
  
  print('✅ Verificador de alarmas programadas inicializado');
}

Future<void> _checkScheduledAlarms() async {
  try {
    final now = DateTime.now();
    final today = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    
    // Buscar alarmas para hoy
    final alarmsSnapshot = await FirebaseFirestore.instance
        .collection('alarms')
        .where('eventDate', isEqualTo: today)
        .get();
    
    for (final doc in alarmsSnapshot.docs) {
      final alarmData = doc.data();
      final enabled = alarmData['enabled'] as bool? ?? false;
      
      if (!enabled) continue;
      
      final hour = alarmData['hour'] as int;
      final minute = alarmData['minute'] as int;
      final eventText = alarmData['eventText'] as String;
      final eventDate = alarmData['eventDate'] as String;
      
      // Verificar si es el momento de la alarma (con un margen de 1 minuto)
      if ((now.hour == hour && now.minute == minute) || 
          (now.hour == hour && now.minute == minute + 1) ||
          (now.hour == hour && now.minute == minute - 1)) {
        
        // Parsear la fecha del evento
        final year = int.parse(eventDate.substring(0, 4));
        final month = int.parse(eventDate.substring(4, 6));
        final day = int.parse(eventDate.substring(6, 8));
        final eventDateTime = DateTime(year, month, day);
        
        // Marcar que la app se abrió desde una notificación
        openedFromNotification = true;
        pendingEventText = eventText;
        pendingEventDate = eventDateTime;
        
        // Mostrar notificación
        _showAlarmNotification(eventText, eventDateTime);
        
        // Solo procesar una alarma a la vez
        break;
      }
    }
  } catch (e) {
    print('❌ Error verificando alarmas: $e');
  }
}

Future<void> _scheduleAlarmFromFirebase(Map<String, dynamic> alarmData, String docId) async {
  try {
    final eventDate = alarmData['eventDate'] as String;
    final hour = alarmData['hour'] as int;
    final minute = alarmData['minute'] as int;
    final daysBefore = alarmData['daysBefore'] as int;
    final eventText = alarmData['eventText'] as String;
    final enabled = alarmData['enabled'] as bool? ?? false;
    
    if (!enabled) return;
    
    // Parsear fecha del evento
    final year = int.parse(eventDate.substring(0, 4));
    final month = int.parse(eventDate.substring(4, 6));
    final day = int.parse(eventDate.substring(6, 8));
    
    // Calcular fecha de notificación
    final eventDateTime = DateTime(year, month, day);
    final notificationDate = eventDateTime.subtract(Duration(days: daysBefore));
    final notificationDateTime = DateTime(
      notificationDate.year,
      notificationDate.month,
      notificationDate.day,
      hour,
      minute,
    );
    
    // Verificar que no esté en el pasado
    if (notificationDateTime.isBefore(DateTime.now())) {
      return;
    }
    
    // Programar notificación local
    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
    final alarmId = docId.hashCode;
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'event_reminders',
      'Recordatorios de eventos',
      channelDescription: 'Notificaciones para recordar eventos del calendario',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('alarm_sound'),
      showWhen: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      timeoutAfter: 30000,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: const Color(0xFF2196F3),
      enableLights: true,
      ledColor: const Color(0xFF2196F3),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await notifications.zonedSchedule(
      alarmId,
      '🔔 Recordatorio de evento',
      'Evento: $eventText',
      tz.TZDateTime.from(notificationDateTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'alarm|$eventText|${eventDateTime.toIso8601String()}',
    );
    
    print('✅ Alarma programada: $eventText para $notificationDateTime');
    
  } catch (e) {
    print('❌ Error programando alarma: $e');
  }
}
