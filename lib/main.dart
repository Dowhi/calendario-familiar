import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:calendario_familiar/core/firebase/firebase_options.dart';
import 'package:calendario_familiar/routing/app_router.dart';
import 'package:calendario_familiar/theme/app_theme.dart';

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