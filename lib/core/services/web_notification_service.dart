import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:calendario_familiar/core/models/app_event.dart';
import 'dart:html' as html;

/// Servicio de notificaciones web usando Firebase Cloud Messaging
class WebNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static bool _isInitialized = false;
  static String? _fcmToken;
  
  /// Inicializar el servicio de notificaciones web
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🌐 Inicializando servicio de notificaciones web...');
      
      // Verificar si estamos en web
      if (!kIsWeb) {
        print('📱 No es web - usando notificaciones locales');
        _isInitialized = true;
        return;
      }
      
      // Esperar a que Firebase esté inicializado
      await Future.delayed(const Duration(seconds: 1));
      
      // Solicitar permisos de notificación
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      print('🔔 Estado de permisos: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permisos de notificación concedidos');
        
        // Obtener token FCM
        _fcmToken = await _messaging.getToken();
        print('🎫 Token FCM obtenido: ${_fcmToken?.substring(0, 20)}...');
        
        // Guardar token en Firestore
        await _saveTokenToFirestore(_fcmToken);
        
        // Configurar manejadores de mensajes
        _setupMessageHandlers();
        
        _isInitialized = true;
        print('✅ Servicio de notificaciones web inicializado correctamente');
      } else {
        print('❌ Permisos de notificación denegados');
        _isInitialized = true; // Marcar como inicializado aunque no tenga permisos
      }
      
    } catch (e) {
      print('❌ Error inicializando servicio de notificaciones web: $e');
      _isInitialized = true; // Marcar como inicializado para evitar errores
    }
  }
  
  /// Guardar token FCM en Firestore
  static Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null || _auth.currentUser == null) return;
    
    try {
      final user = _auth.currentUser!;
      final userDoc = _firestore.collection('users').doc(user.uid);
      
      // Obtener datos actuales del usuario
      final userData = await userDoc.get();
      final currentData = userData.data() ?? {};
      
      // Obtener lista actual de device tokens
      List<String> deviceTokens = List<String>.from(currentData['deviceTokens'] ?? []);
      
      // Agregar el nuevo token si no existe
      if (!deviceTokens.contains(token)) {
        deviceTokens.add(token);
        
        // Actualizar el documento del usuario
        await userDoc.update({
          'deviceTokens': deviceTokens,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        print('✅ Token FCM guardado en Firestore');
      } else {
        print('ℹ️ Token FCM ya existe en Firestore');
      }
      
    } catch (e) {
      print('❌ Error guardando token FCM: $e');
    }
  }
  
  /// Configurar manejadores de mensajes
  static void _setupMessageHandlers() {
    // Manejar mensajes cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Mensaje recibido en primer plano: ${message.notification?.title}');
      
      // Mostrar notificación usando la API web
      if (message.notification != null) {
        _showWebNotification(
          message.notification!.title ?? 'Notificación',
          message.notification!.body ?? 'Mensaje del calendario familiar',
        );
      }
    });
    
    // Manejar mensajes cuando la app está en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📨 Mensaje abierto desde segundo plano: ${message.notification?.title}');
    });
    
    // Manejar mensajes cuando la app se abre desde una notificación
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  
  /// Mostrar notificación usando la API web nativa
  static void _showWebNotification(String title, String body) {
    if (!kIsWeb) return;
    
    try {
      // Usar la API de notificaciones web nativa con dart:html
      if (html.Notification.supported) {
        final notification = html.Notification(title, body: body, icon: '/favicon.png');
        
        notification.onClick.listen((_) {
          // html.window.focus(); // Este método no está disponible en la versión actual de dart:html
          notification.close();
        });
      }
    } catch (e) {
      print('❌ Error mostrando notificación web: $e');
    }
  }
  
  /// Verificar si las notificaciones están habilitadas
  static Future<bool> areNotificationsEnabled() async {
    if (!kIsWeb) return false;
    
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('❌ Error verificando permisos: $e');
      return false;
    }
  }
  
  /// Solicitar permisos de notificaciones
  static Future<bool> requestPermissions() async {
    if (!kIsWeb) return false;
    
    try {
      print('🔔 Solicitando permisos de notificación web...');
      
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      final granted = settings.authorizationStatus == AuthorizationStatus.authorized;
      print('🔔 Resultado de solicitud de permisos: $granted');
      
      if (granted) {
        // Obtener y guardar token
        _fcmToken = await _messaging.getToken();
        await _saveTokenToFirestore(_fcmToken);
        _isInitialized = true;
      }
      
      return granted;
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      return false;
    }
  }
  
  /// Mostrar notificación de prueba
  static Future<void> showTestNotification() async {
    if (!kIsWeb) return;
    
    try {
      print('🔔 Enviando notificación de prueba...');
      
      // Mostrar notificación web nativa
      _showWebNotification(
        '🔔 Notificación de Prueba',
        'Esta es una notificación de prueba del Calendario Familiar',
      );
      
      print('✅ Notificación de prueba enviada');
    } catch (e) {
      print('❌ Error enviando notificación de prueba: $e');
    }
  }
  
  /// Programar notificación para un evento
  static Future<void> scheduleEventNotification({
    required String eventId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    print('🌐 WebNotificationService.scheduleEventNotification llamado');
    print('   - eventId: $eventId');
    print('   - title: $title');
    print('   - scheduledTime: $scheduledTime');
    print('   - kIsWeb: $kIsWeb');
    print('   - _isInitialized: $_isInitialized');
    
    if (!kIsWeb) {
      print('⚠️ No es web, saltando');
      return;
    }
    
    if (!_isInitialized) {
      print('⚠️ WebNotificationService no está inicializado');
      return;
    }
    
    try {
      // Para web, usamos setTimeout para simular notificaciones programadas
      final now = DateTime.now();
      final delay = scheduledTime.difference(now).inMilliseconds;
      
      print('   - Delay calculado: ${delay}ms (${Duration(milliseconds: delay)})');
      
      if (delay > 0) {
        // Usar Future.delayed para simular notificación programada
        Future.delayed(Duration(milliseconds: delay), () {
          print('⏰ Ejecutando notificación programada: $title');
          _showWebNotification(title, body);
        });
        
        print('✅ Notificación web programada para: $title en ${Duration(milliseconds: delay)}');
      } else {
        print('⚠️ Delay negativo o cero, no se programará notificación');
      }
    } catch (e) {
      print('❌ Error programando notificación web: $e');
      print('   Stack trace: ${StackTrace.current}');
    }
  }
  
  /// Limpiar tokens obsoletos
  static Future<void> cleanupTokens() async {
    if (!kIsWeb || _auth.currentUser == null) return;
    
    try {
      final user = _auth.currentUser!;
      final userDoc = _firestore.collection('users').doc(user.uid);
      
      // Obtener token actual
      final currentToken = await _messaging.getToken();
      
      if (currentToken != null) {
        // Actualizar con solo el token actual
        await userDoc.update({
          'deviceTokens': [currentToken],
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        print('✅ Tokens limpiados y actualizados');
      }
    } catch (e) {
      print('❌ Error limpiando tokens: $e');
    }
  }
}

/// Manejador de mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Mensaje en segundo plano: ${message.notification?.title}');
}
