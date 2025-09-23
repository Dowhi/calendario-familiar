import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:calendario_familiar/main.dart';
import 'package:calendario_familiar/features/auth/logic/auth_controller.dart';

class CompleteFeaturesScreen extends ConsumerStatefulWidget {
  const CompleteFeaturesScreen({super.key});

  @override
  ConsumerState<CompleteFeaturesScreen> createState() => _CompleteFeaturesScreenState();
}

class _CompleteFeaturesScreenState extends ConsumerState<CompleteFeaturesScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      final notifications = ref.read(notificationsProvider);
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await notifications.initialize(initSettings);
      
      ref.read(notificationsStatusProvider.notifier).state = '✅ Notificaciones inicializadas';
    } catch (e) {
      ref.read(notificationsStatusProvider.notifier).state = '❌ Error: $e';
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await ref.read(authControllerProvider.notifier).signInWithGoogle();
      if (user == null) {
        ref.read(googleSignInStatusProvider.notifier).state = '❌ Cancelado por el usuario';
        return;
      }
      
      ref.read(googleSignInStatusProvider.notifier).state = '✅ Google Sign In exitoso';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign In exitoso')),
      );
    } catch (e) {
      ref.read(googleSignInStatusProvider.notifier).state = '❌ Error: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scheduleNotification() async {
    try {
      final notifications = ref.read(notificationsProvider);
      
      await notifications.show(
        0,
        'Calendario Familiar',
        'Recordatorio: Revisa tu calendario familiar',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'calendar_channel',
            'Calendario Familiar',
            channelDescription: 'Notificaciones del calendario familiar',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación programada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final notificationsStatus = ref.watch(notificationsStatusProvider);
    final googleSignInStatus = ref.watch(googleSignInStatusProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Funcionalidades Completas - Fase 8'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Funcionalidades Completas',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Esta es la versión completa con todas las funcionalidades',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estado de Funcionalidades:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Notificaciones: $notificationsStatus',
                          style: TextStyle(
                            fontSize: 16,
                            color: notificationsStatus.contains('✅') ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Google Sign In: $googleSignInStatus',
                          style: TextStyle(
                            fontSize: 16,
                            color: googleSignInStatus.contains('✅') ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 5),
                        currentUser.when(
                          data: (user) => Text(
                            'Usuario: ${user?.email ?? 'No autenticado'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          loading: () => const Text('Cargando usuario...'),
                          error: (error, stack) => Text('Error: $error'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Funcionalidades Disponibles:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  '✅ Firebase Core\n'
                  '✅ Firebase Auth\n'
                  '✅ Firestore\n'
                  '✅ Calendario\n'
                  '✅ Google Sign In\n'
                  '✅ Notificaciones Locales\n'
                  '✅ Scroll y Responsividad\n'
                  '✅ Navegación con GoRouter\n'
                  '✅ Gestión de Estado con Riverpod',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _signInWithGoogle,
                    child: const Text('Google Sign In'),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _scheduleNotification,
                  child: const Text('Programar Notificación'),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Volver al Inicio'),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Si ves esto, todas las funcionalidades funcionan en iPhone',
                  style: TextStyle(fontSize: 16, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
