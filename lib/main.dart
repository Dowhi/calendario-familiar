import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:calendario_familiar/core/firebase/firebase_options.dart';
import 'package:calendario_familiar/routing/app_router.dart';
import 'package:calendario_familiar/theme/app_theme.dart';
import 'package:calendario_familiar/core/services/time_service.dart';
import 'package:calendario_familiar/core/services/notification_service.dart';
import 'package:calendario_familiar/core/services/notification_settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado correctamente');
  } catch (e) {
    print('❌ Error inicializando Firebase: $e');
  }
  
  // Inicializar zona horaria y notificaciones locales (solo para móvil)
  if (!kIsWeb) {
    try {
      await TimeService.initialize();
      await NotificationService.initialize();
      await NotificationSettingsService.initializeDefaultSettings();
      print('✅ TimeService, NotificationService y NotificationSettingsService inicializados');
    } catch (e) {
      print('❌ Error inicializando servicios base: $e');
    }
  } else {
    print('🌐 Ejecutándose en web - servicios de notificación no disponibles');
    // Inicializar configuraciones por defecto incluso en web
    try {
      await NotificationSettingsService.initializeDefaultSettings();
      print('✅ NotificationSettingsService inicializado para web');
    } catch (e) {
      print('❌ Error inicializando NotificationSettingsService: $e');
    }
  }
  
  runApp(const ProviderScope(child: CalendarioFamiliarApp()));
}

class CalendarioFamiliarApp extends ConsumerWidget {
  const CalendarioFamiliarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Calendario Familiar',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}