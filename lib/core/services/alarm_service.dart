import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:calendario_familiar/core/models/app_event.dart';
import 'package:calendario_familiar/core/services/android_alarm_helper.dart';
import 'package:calendario_familiar/routing/app_router.dart';
import 'package:go_router/go_router.dart';

/// Servicio de alarmas multiplataforma
/// - Android: usa AndroidAlarmManagerPlus para garantizar ejecución en segundo plano y
///   flutter_local_notifications con `fullScreenIntent` para abrir la app como pantalla de alarma.
/// - iOS: programa notificaciones locales con sonido. iOS no permite abrir UI automáticamente;
///   el usuario debe tocar la notificación (comentado aquí para claridad).
/// - Windows: muestra notificación nativa si la app está en ejecución (limitación del ecosistema).
class AlarmService {
  static final FlutterLocalNotificationsPlugin _ln = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String _channelId = 'alarm_channel';
  static const String _channelName = 'Alarmas';
  static const String _channelDescription = 'Alarmas de eventos programados';

  /// Debe llamarse en `main()`
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await AndroidAlarmManager.initialize();
      }

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const init = InitializationSettings(android: androidInit, iOS: iosInit);
      await _ln.initialize(init, onDidReceiveNotificationResponse: _onTap);

      // Canal Android para notificaciones de alarma (full screen)
      final android = _ln.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ));
        
        // Solicitar permiso para usar full screen intent (Android 10+)
        final hasFullScreenPermission = await android.canScheduleExactNotifications();
        // ignore: avoid_print
        print('🔔 Permiso de full screen intent: $hasFullScreenPermission');
      }

      _initialized = true;
      // ignore: avoid_print
      print('✅ AlarmService inicializado');
    } catch (e) {
      // No propagar para evitar romper el arranque
      // ignore: avoid_print
      print('❌ Error inicializando AlarmService: $e');
    }
  }

  /// Programa una alarma exacta para un `AppEvent`.
  /// `fireAt` es la hora exacta en local time.
  static Future<void> scheduleAlarm({
    required AppEvent event,
    required DateTime fireAt,
    String? notes,
  }) async {
    // ignore: avoid_print
    print('🚨 AlarmService.scheduleAlarm INICIADO para evento: ${event.title} a las $fireAt');
    
    if (!_initialized) await initialize();

    if (kIsWeb) {
      // En web usamos notificaciones programadas locales y AlarmService
      print('🌐 Programando alarma para web...');
      // ignore: avoid_print
      print('🚨 Plataforma WEB detectada, programando notificación web');
      
      try {
        // Calcular tiempo hasta la alarma
        final timeUntilAlarm = fireAt.difference(DateTime.now());
        print('🚨 Tiempo hasta alarma: ${timeUntilAlarm.inSeconds} segundos');
        
        if (timeUntilAlarm.inSeconds <= 0) {
          print('🚨 Alarma en el pasado, mostrando inmediatamente');
          await showImmediateAlarm(
            id: event.id,
            title: event.title,
            notes: notes ?? event.notes ?? 'Es la hora del evento',
            dateKey: event.dateKey,
          );
        } else {
          // Programar notificación simple con Timer
          print('🚨 Programando notificación web para ${timeUntilAlarm.inSeconds} segundos');
          
          // Usar Timer simple de Dart
          Timer(Duration(seconds: timeUntilAlarm.inSeconds), () {
            print('🚨 WEB ALARM DISPARADA: ${event.title}');
            
            // Mostrar notificación inmediata
            showImmediateAlarm(
              id: event.id,
              title: event.title,
              notes: notes ?? event.notes ?? 'Es la hora del evento',
              dateKey: event.dateKey,
            );
            
            // Navegar a la pantalla de alarma
            _navigateToAlarmScreen(event.title, notes ?? event.notes ?? 'Es la hora del evento', event.dateKey);
          });
          
          print('✅ Timer web programado exitosamente para ${timeUntilAlarm.inSeconds} segundos');
        }
      } catch (e) {
        print('❌ Error programando alarma web: $e');
        // Fallback: mostrar notificación inmediata
        await showImmediateAlarm(
          id: event.id,
          title: event.title,
          notes: notes ?? event.notes ?? 'Es la hora del evento',
          dateKey: event.dateKey,
        );
      }
      return;
    }

    if (Platform.isAndroid) {
      // Calcular si la alarma es dentro de los próximos 5 minutos
      final timeUntilAlarm = fireAt.difference(DateTime.now());
      final startServiceNow = timeUntilAlarm.inMinutes <= 5;
      
      if (startServiceNow) {
        // 🔥 INICIAR FOREGROUND SERVICE solo si la alarma es pronto
        try {
          const platform = MethodChannel('com.juancarlos.calendariofamiliar/foreground_service');
          await platform.invokeMethod('startForegroundService');
          // ignore: avoid_print
          print('✅ Foreground Service iniciado (alarma en ${timeUntilAlarm.inMinutes} minutos)');
        } catch (e) {
          // ignore: avoid_print
          print('❌ Error iniciando Foreground Service: $e');
        }
      } else {
        // Programar el inicio del servicio 5 minutos antes de la alarma
        final serviceStartTime = fireAt.subtract(const Duration(minutes: 5));
        try {
          await AndroidAlarmManager.oneShotAt(
            serviceStartTime,
            'wake_service_${event.id}'.hashCode,
            _startServiceCallback,
            exact: true,
            wakeup: true,
            allowWhileIdle: true,
          );
          // ignore: avoid_print
          print('✅ Foreground Service programado para iniciarse a las $serviceStartTime');
        } catch (e) {
          // ignore: avoid_print
          print('❌ Error programando wake service: $e');
        }
      }
      
      // 🔥 MÉTODO PRINCIPAL: Usar AlarmManager DIRECTO con Activity
      try {
        final directOk = await AndroidAlarmHelper.scheduleDirectAlarm(
          fireAt: fireAt,
          id: '${event.id}_${fireAt.millisecondsSinceEpoch}',
          title: event.title,
          notes: notes ?? event.notes ?? '',
          dateKey: event.dateKey,
        );
        // ignore: avoid_print
        print('✅ Alarma directa programada: $directOk');
      } catch (e) {
        // ignore: avoid_print
        print('❌ Error programando alarma directa: $e');
      }
      
      // Sin respaldos duplicados: evitamos colisiones con la Activity nativa
    } else {
      // iOS/Windows/macOS: programar notificación local (iOS no autoabre interfaz).
      await _ln.zonedSchedule(
        event.id.hashCode,
        '⏰ ${event.title}',
        'Es la hora del evento',
        tz.TZDateTime.from(fireAt, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload:
            'alarm|id=${event.id}|title=${event.title}|notes=${notes ?? event.notes ?? ''}|dateKey=${event.dateKey}',
      );
    }
  }

  /// Cancela una alarma por ID de evento.
  static Future<void> cancelAlarm(String eventId) async {
    if (!_initialized) await initialize();
    try {
      await _ln.cancel(eventId.hashCode);
    } catch (_) {}
  }

  /// Muestra una notificación de alarma con intento de pantalla completa.
  static Future<void> showImmediateAlarm({
    required String id,
    required String title,
    required String notes,
    String? dateKey,
  }) async {
    if (!_initialized) await initialize();
    await _ln.show(
      id.hashCode,
      '⏰ $title',
      notes.isEmpty ? 'Es la hora del evento' : notes,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      payload:
          'alarm|id=$id|title=$title|notes=$notes|dateKey=${dateKey ?? ''}',
    );
  }

  /// Handler cuando el usuario toca la notificación o cuando Android lanza full-screen intent.
  static void _onTap(NotificationResponse response) {
    final payload = response.payload ?? '';
    print('🔔 AlarmService._onTap llamado con payload: $payload');
    
    if (payload.startsWith('alarm|')) {
      final data = _decodePayload(payload);
      print('🔔 Datos decodificados: $data');
      
      openedFromNotification = true;
      initialAlarmData = data;
      
      // Intentar navegar inmediatamente si la app está activa
      if (navigatorKey.currentState != null && navigatorKey.currentState!.context.mounted) {
        try {
          final uri = Uri(path: '/alarm', queryParameters: data.map((k, v) => MapEntry(k, '$v')));
          print('🔔 Navegando a: ${uri.toString()}');
          navigatorKey.currentState!.context.go(uri.toString());
          print('✅ Navegación exitosa');
        } catch (e) {
          print('❌ Error navegando: $e');
          // Fallback: usar el método de navegación directa
          _navigateToAlarmScreen(data['title'] ?? 'Alarma', data['notes'] ?? '', data['dateKey'] ?? '');
        }
      } else {
        print('⚠️ Navigator no disponible, navegación diferida');
        // La navegación se manejará en app_router.dart cuando la app se inicialice
      }
    } else {
      print('⚠️ Payload no es de alarma: $payload');
    }
  }

  static Map<String, dynamic> _decodePayload(String payload) {
    // Formato: alarm|id=..|title=..|notes=..|dateKey=..
    final parts = payload.split('|');
    final map = <String, String>{};
    for (final p in parts.skip(1)) {
      final i = p.indexOf('=');
      if (i > 0) map[p.substring(0, i)] = Uri.decodeComponent(p.substring(i + 1));
    }
    return {
      'id': map['id'] ?? '',
      'title': map['title'] ?? 'Aviso',
      'notes': map['notes'] ?? '',
      'dateKey': map['dateKey'] ?? '',
    };
  }

  /// Navega a la pantalla de alarma
  static void _navigateToAlarmScreen(String title, String notes, String dateKey) {
    try {
      print('🚨 Intentando navegar a pantalla de alarma...');
      
      if (navigatorKey.currentState != null && navigatorKey.currentState!.context.mounted) {
        navigatorKey.currentState!.context.go(
          Uri(path: '/alarm', queryParameters: {
            'title': title,
            'notes': notes,
            'dateKey': dateKey,
          }).toString(),
        );
        print('✅ Navegación a pantalla de alarma exitosa');
      } else {
        print('❌ Navigator no está disponible, usando fallback');
        // Fallback: usar window.location
        _navigateToAlarmFallback(title, notes, dateKey);
      }
    } catch (e) {
      print('❌ Error navegando a pantalla de alarma: $e');
      // Fallback: usar window.location
      _navigateToAlarmFallback(title, notes, dateKey);
    }
  }

  /// Fallback para navegar a la pantalla de alarma usando window.location
  static void _navigateToAlarmFallback(String title, String notes, String dateKey) {
    if (!kIsWeb) return;
    
    try {
      print('🚨 Usando fallback de navegación...');
      
      // Crear URL con parámetros
      final uri = Uri(path: '/alarm', queryParameters: {
        'title': title,
        'notes': notes,
        'dateKey': dateKey,
      });
      
      // Usar JavaScript para navegar
      // ignore: avoid_print
      print('🚨 Navegando a: ${uri.toString()}');
      
      // En Flutter web, podemos usar html.window.location
      // Pero por simplicidad, vamos a usar un enfoque diferente
      // Intentar navegar usando el router de Flutter después de un delay
      Timer(const Duration(milliseconds: 100), () {
        if (navigatorKey.currentState != null && navigatorKey.currentState!.context.mounted) {
          try {
            navigatorKey.currentState!.context.go(uri.toString());
            print('✅ Navegación fallback exitosa');
          } catch (e) {
            print('❌ Error en navegación fallback: $e');
          }
        }
      });
      
    } catch (e) {
      print('❌ Error en fallback de navegación: $e');
    }
  }
}

/// Callback para iniciar el Foreground Service
@pragma('vm:entry-point')
void _startServiceCallback() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    const platform = MethodChannel('com.juancarlos.calendariofamiliar/foreground_service');
    await platform.invokeMethod('startForegroundService');
    print('✅ Foreground Service iniciado desde callback');
  } catch (e) {
    print('❌ Error iniciando servicio desde callback: $e');
  }
}

/// Callback disparado por Android AlarmManager. Debe ser estático y con entry-point.
@pragma('vm:entry-point')
void _androidAlarmCallback(int id, Map<String, dynamic> params) async {
  print('🚨 _androidAlarmCallback ejecutado con id=$id, params=$params');
  
  // Asegurar binding para usar plugins
  WidgetsFlutterBinding.ensureInitialized();
  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(const InitializationSettings(android: androidInit));

  final title = (params['title'] as String?) ?? 'Aviso';
  final eventId = (params['id'] as String?) ?? '$id';
  final notes = (params['notes'] as String?) ?? '';
  final dateKey = (params['dateKey'] as String?) ?? '';

  print('🚨 Mostrando notificación: $title');

  await plugin.show(
    eventId.hashCode,
    '⏰ $title',
    notes.isEmpty ? 'Es la hora del evento' : notes,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        AlarmService._channelId,
        AlarmService._channelName,
        channelDescription: AlarmService._channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        playSound: true,
        enableVibration: true,
      ),
    ),
    payload: 'alarm|id=$eventId|title=$title|notes=$notes|dateKey=$dateKey',
  );
  
  print('✅ Notificación mostrada exitosamente');
}


