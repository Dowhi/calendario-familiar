import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:calendario_familiar/core/models/app_event.dart';
import 'package:calendario_familiar/core/services/web_notification_service_stub.dart'
  if (dart.library.html) 'package:calendario_familiar/core/services/web_notification_service.dart';
import 'package:calendario_familiar/core/services/alarm_service.dart';

/// 🔹 Variable global para almacenar el currentUserId durante la programación de alarmas
/// Esto se establece antes de llamar a scheduleEventNotification
int? _currentSchedulingUserId;

/// Servicio simplificado de notificaciones locales
typedef NotificationTapCallback = Future<void> Function(String? payload);

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  static const String _channelId = 'calendar_events';
  static const String _channelName = 'Eventos del Calendario';
  static const String _channelDescription = 'Notificaciones de eventos del calendario familiar';
  
  static bool _isInitialized = false;
  static NotificationTapCallback? _onSelectNotificationCallback;
  
  /// Inicializar el servicio de notificaciones
  static Future<void> initialize({NotificationTapCallback? onSelectNotification}) async {
    if (_isInitialized) return;
    _onSelectNotificationCallback = onSelectNotification;
    
    try {
      print('🔔 Inicializando servicio de notificaciones...');
      
      // Verificar si estamos en web
      if (kIsWeb) {
        print('🌐 Ejecutándose en web - inicializando servicio web');
        await WebNotificationService.initialize();
        _isInitialized = true;
        return;
      }
      
      // Configurar notificaciones locales para móviles
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: false,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      final bool? initialized = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse: _onNotificationTappedBackground,
      );
      
      print('✅ Notificaciones inicializadas: $initialized');
      
      if (initialized == false) {
        print('❌ Falló la inicialización básica de notificaciones');
        _isInitialized = false;
        return;
      }
      
      // Crear canal de notificaciones para Android
      if (Platform.isAndroid) {
        await _createAndroidNotificationChannel();
      }
      
      _isInitialized = true;
      print('✅ Servicio de notificaciones completamente inicializado');
      
    } catch (e) {
      print('❌ Error inicializando servicio de notificaciones: $e');
      _isInitialized = false;
    }
  }
  
  /// Crear canal de notificaciones para Android
  static Future<void> _createAndroidNotificationChannel() async {
    try {
      print('🤖 Creando canal de notificaciones Android...');
      
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        enableLights: true,
      );
      
      final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(androidChannel);
        print('✅ Canal de notificaciones Android creado exitosamente');
      } else {
        print('❌ No se pudo obtener AndroidFlutterLocalNotificationsPlugin');
      }
    } catch (e) {
      print('❌ Error creando canal Android: $e');
    }
  }
  
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notificación tocada: ${response.payload}');
    _onSelectNotificationCallback?.call(response.payload);
    // Extraer información del payload
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        // Soporta payloads antiguos y nuevos (alarm|...)
        final payload = response.payload!;
        if (payload.startsWith('alarm|')) {
          // Abrir pantalla de alarma directamente
          // Nota: la navegación en frío se maneja en app_router mediante `openedFromNotification`.
        }
      } catch (e) {
        print('❌ Error procesando payload de notificación: $e');
      }
    }
  }

  @pragma('vm:entry-point')
  static void _onNotificationTappedBackground(NotificationResponse response) {
    print('🔔 Notificación tocada (background): ${response.payload}');
    _onSelectNotificationCallback?.call(response.payload);
  }

  /// Obtener detalles de lanzamiento por notificación (app terminada)
  static Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async {
    if (kIsWeb) return null;
    return _localNotifications.getNotificationAppLaunchDetails();
  }
  
  /// Verificar si las notificaciones están habilitadas
  static Future<bool> areNotificationsEnabled() async {
    try {
      if (kIsWeb) {
        return await WebNotificationService.areNotificationsEnabled();
      }
      
      if (!_isInitialized) {
        await initialize();
        if (!_isInitialized) {
          return false;
        }
      }
      
      if (Platform.isAndroid) {
        final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImpl != null) {
          final bool? result = await androidImpl.areNotificationsEnabled();
          return result ?? false;
        }
      } else if (Platform.isIOS) {
        final iosImpl = _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        
        if (iosImpl != null) {
          final permissions = await iosImpl.checkPermissions();
          return permissions?.isEnabled ?? false;
        }
      }
      
      return false;
    } catch (e) {
      print('❌ Error verificando permisos de notificaciones: $e');
      return false;
    }
  }
  
  /// Solicitar permisos de notificaciones
  static Future<bool> requestPermissions() async {
    try {
      print('🔔 Solicitando permisos...');
      
      if (kIsWeb) {
        return await WebNotificationService.requestPermissions();
      }
      
      if (!_isInitialized) {
        await initialize();
        if (!_isInitialized) {
          return false;
        }
      }
      
      if (Platform.isAndroid) {
        final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImpl != null) {
          final bool? notificationsGranted = await androidImpl.requestNotificationsPermission();
          
          // Intentar solicitar permiso de alarmas exactas
          try {
            await androidImpl.requestExactAlarmsPermission();
          } catch (e) {
            print('⚠️ Error solicitando permiso de alarmas exactas: $e');
          }
          
          return notificationsGranted ?? false;
        }
      } else if (Platform.isIOS) {
        final iosImpl = _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        
        if (iosImpl != null) {
          final bool? granted = await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
          return granted ?? false;
        }
      }
      
      return false;
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      return false;
    }
  }
  
  /// 🔹 Establecer el userId actual para filtrado de notificaciones
  static void setCurrentUserId(int userId) {
    _currentSchedulingUserId = userId;
  }

  /// Programar una notificación para un evento
  /// 🎯 Solo programa la alarma si el evento pertenece al usuario actual
  static Future<void> scheduleEventNotification(AppEvent event, {int? currentUserId}) async {
    try {
      print('🔔 scheduleEventNotification llamado');
      print('   📌 Evento: ${event.title}');
      print('   🆔 Event ID: ${event.id}');
      print('   👤 Creado por: Usuario ${event.userId}');
      print('   ⏰ Notificar ${event.notifyMinutesBefore} min antes');
      print('   📅 Fecha: ${event.startAt}');
      
      // 🔹 FILTRO CRÍTICO: Solo programar si el evento fue creado por el usuario actual
      final activeUserId = currentUserId ?? _currentSchedulingUserId;
      
      if (activeUserId == null) {
        print('⚠️ No hay usuario activo definido - omitiendo notificación');
        return;
      }
      
      if (event.userId != activeUserId) {
        print('🚫 NOTIFICACIÓN OMITIDA');
        print('   ❌ Evento creado por usuario ${event.userId}');
        print('   ✓ Usuario actual es ${activeUserId}');
        print('   💡 Solo el creador recibe la alarma');
        return; // No programar la notificación
      }
      
      print('✅ Usuario activo coincide con creador - programando alarma');
      print('   👤 Usuario ${activeUserId} recibirá la notificación');
      
      // Validaciones básicas
      if (event.startAt == null) {
        print('⚠️ Evento sin fecha de inicio');
        throw Exception('El evento debe tener una fecha de inicio');
      }
      
      // Usar la hora exacta del evento (sin minutos de anticipación)
      final notificationTime = event.startAt!;
      print('   - Tiempo calculado para la notificación: $notificationTime');
      
      final now = DateTime.now();
      if (notificationTime.isBefore(now)) {
        print('⚠️ Notificación en el pasado, no se programará');
        print('   - Hora actual: $now');
        print('   - Diferencia: ${notificationTime.difference(now).inMinutes} minutos');
        throw Exception('No se pueden programar notificaciones en el pasado');
      }
      
      // Para web, usar servicio web de notificaciones
      if (kIsWeb) {
        try {
          final webPermissions = await WebNotificationService.areNotificationsEnabled();
          if (!webPermissions) {
            print('⚠️ Permisos de notificación web no concedidos - solicitando permisos');
            final granted = await WebNotificationService.requestPermissions();
            if (!granted) {
              print('⚠️ Permisos denegados - continuando sin notificación web');
              // No lanzar excepción, continuar con el flujo normal
            } else {
              print('✅ Permisos de notificación web concedidos');
            }
          }
          
          // Intentar programar notificación web
          try {
            await WebNotificationService.scheduleEventNotification(
              eventId: event.id,
              title: '📅 ${event.title}',
              body: 'El evento comenzará en ${event.notifyMinutesBefore} minutos',
              scheduledTime: notificationTime,
            );
            print('✅ Notificación web programada para: ${event.title}');
          } catch (e) {
            print('⚠️ Error programando notificación web: $e - continuando sin notificación web');
          }
          
          // Continuar con el flujo normal para AlarmService
        } catch (e) {
          print('⚠️ Error con notificaciones web: $e - continuando sin notificación web');
        }
      }
      
      // Para móviles, verificar inicialización
      if (!_isInitialized) {
        print('⚠️ NotificationService no inicializado, inicializando...');
        await initialize();
        if (!_isInitialized) {
          print('❌ No se pudo inicializar NotificationService');
          throw Exception('No se pudo inicializar el servicio de notificaciones');
        }
      }
      
      // Verificar permisos de notificación en tiempo real
      final permissionsEnabled = await areNotificationsEnabled();
      
      if (!permissionsEnabled) {
        print('⚠️ Permisos de notificación no concedidos');
        throw Exception('Se requieren permisos de notificación. Por favor, actívalos en la configuración de la aplicación.');
      }
      
      print('✅ Permisos de notificación verificados');
      
      // Asegurarse de usar la zona horaria local correctamente
      final tz.TZDateTime scheduledDate = tz.TZDateTime.local(
        notificationTime.year,
        notificationTime.month,
        notificationTime.day,
        notificationTime.hour,
        notificationTime.minute,
      );
      
      // 🔥 USAR EL CÓDIGO DEL BOTÓN DE TEST QUE FUNCIONABA
      print('🚨 APLICANDO CÓDIGO DEL BOTÓN DE TEST QUE FUNCIONABA');
      print('🚨 Hora programada: $notificationTime');
      print('🚨 Evento: ${event.title}');
      
      // Crear evento temporal como en el botón de test
      final tempEvent = AppEvent(
        id: event.id,
        familyId: event.familyId,
        title: event.title,
        dateKey: event.dateKey,
        startAt: notificationTime, // Usar la hora exacta de la notificación
        notifyMinutesBefore: event.notifyMinutesBefore,
        notes: event.notes,
        userId: event.userId,
      );
      
      print('🚨 Evento temporal creado: ${tempEvent.title}');
      
      // Usar AlarmService.scheduleAlarm directamente como en el botón de test
      await AlarmService.scheduleAlarm(
        event: tempEvent, 
        fireAt: notificationTime, 
        notes: 'El evento comenzará en ${event.notifyMinutesBefore} minutos'
      );
      print('🚨 AlarmService.scheduleAlarm completado');
      
      print('✅ Alarma programada usando el código del botón de test que funcionaba');
      
    } catch (e) {
      print('❌ Error programando notificación: $e');
    }
  }
  
  /// Cancelar notificación de un evento
  static Future<void> cancelEventNotification(AppEvent event) async {
    try {
      if (kIsWeb) return;
      await _localNotifications.cancel(event.id.hashCode);
      print('✅ Notificación cancelada para evento: ${event.title}');
    } catch (e) {
      print('❌ Error cancelando notificación: $e');
    }
  }
  
  /// Cancelar todas las notificaciones
  static Future<void> cancelAllNotifications() async {
    try {
      if (kIsWeb) return;
      await _localNotifications.cancelAll();
      print('✅ Todas las notificaciones canceladas');
    } catch (e) {
      print('❌ Error cancelando todas las notificaciones: $e');
    }
  }
  
  /// Mostrar notificación de prueba
  static Future<void> showTestNotification() async {
    try {
      print('🧪 Intentando mostrar notificación de prueba...');
      
      if (kIsWeb) {
        await WebNotificationService.showTestNotification();
        return;
      }
      
      // Verificar inicialización
      if (!_isInitialized) {
        print('⚠️ Servicio no inicializado, inicializando...');
        await initialize();
        if (!_isInitialized) {
          throw Exception('No se pudo inicializar el servicio de notificaciones');
        }
      }
      
      // Verificar permisos
      final hasPermissions = await areNotificationsEnabled();
      print('🔔 Estado de permisos: $hasPermissions');
      
      if (!hasPermissions) {
        print('⚠️ Solicitando permisos...');
        final granted = await requestPermissions();
        if (!granted) {
          throw Exception('Permisos de notificación denegados');
        }
      }
      
      print('✅ Todo listo, enviando notificación...');
      
      await _localNotifications.show(
        999,
        '🔔 Notificación de Prueba',
        'Si ves esto, las notificaciones funcionan correctamente! ✅',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.max,
            showWhen: true,
            enableLights: true,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
      );
      
      print('✅ Notificación de prueba enviada correctamente');
      
    } catch (e) {
      print('❌ Error enviando notificación de prueba: $e');
      rethrow;
    }
  }
}
