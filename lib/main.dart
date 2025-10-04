import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:calendario_familiar/core/firebase/firebase_options.dart';
import 'package:calendario_familiar/routing/app_router.dart';
import 'package:calendario_familiar/theme/app_theme.dart';
import 'package:calendario_familiar/core/services/time_service.dart';
import 'package:calendario_familiar/core/services/notification_service.dart';
import 'package:calendario_familiar/core/providers/theme_provider.dart';

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
  
  // Inicializar zona horaria y notificaciones
  try {
    if (!kIsWeb) {
      await TimeService.initialize();
      print('✅ TimeService inicializado');
    }
    
    // Inicializar notificaciones en todas las plataformas
    await NotificationService.initialize();
    print('✅ NotificationService inicializado');
  } catch (e) {
    print('❌ Error inicializando servicios base: $e');
  }
  
  runApp(const ProviderScope(child: CalendarioFamiliarApp()));
}

class CalendarioFamiliarApp extends ConsumerWidget {
  const CalendarioFamiliarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'Calendario Familiar',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}