import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:calendario_familiar/core/firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  String firebaseStatus = 'Inicializando...';
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseStatus = '✅ Firebase inicializado correctamente';
    print('✅ Firebase inicializado correctamente');
  } catch (e) {
    firebaseStatus = '❌ Error inicializando Firebase: $e';
    print('❌ Error inicializando Firebase: $e');
  }
  
  runApp(ProviderScope(
    child: MinimalApp(initialFirebaseStatus: firebaseStatus),
  ));
}

class MinimalApp extends ConsumerWidget {
  final String initialFirebaseStatus;
  
  const MinimalApp({super.key, required this.initialFirebaseStatus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Establecer el estado inicial de Firebase
    ref.read(firebaseStatusProvider.notifier).state = initialFirebaseStatus;
    
    return MaterialApp.router(
      title: 'Calendario Familiar - Fase 4',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Provider simple para el contador
final counterProvider = StateProvider<int>((ref) => 0);

// Provider para verificar estado de Firebase
final firebaseStatusProvider = StateProvider<String>((ref) => 'Inicializando...');

// Configuración de rutas básica
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/second',
      builder: (context, state) => const SecondScreen(),
    ),
  ],
);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);
    final firebaseStatus = ref.watch(firebaseStatusProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario Familiar - Fase 4'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              '¡Hola desde iPhone!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Fase 4: Firebase Core',
            ),
            const SizedBox(height: 20),
            Text(
              'Estado Firebase: $firebaseStatus',
              style: TextStyle(
                fontSize: 16,
                color: firebaseStatus.contains('✅') ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Contador: $counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.read(counterProvider.notifier).state++,
              child: const Text('Incrementar'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.read(counterProvider.notifier).state = 0,
              child: const Text('Resetear'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/second'),
              child: const Text('Ir a Segunda Pantalla'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Si ves esto, Firebase Core funciona en iPhone',
              style: TextStyle(fontSize: 16, color: Colors.green),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class SecondScreen extends ConsumerWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);
    final firebaseStatus = ref.watch(firebaseStatusProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Segunda Pantalla'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Segunda Pantalla',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Esta pantalla también usa Riverpod y Firebase',
            ),
            const SizedBox(height: 20),
            Text(
              'Estado Firebase: $firebaseStatus',
              style: TextStyle(
                fontSize: 16,
                color: firebaseStatus.contains('✅') ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Contador compartido: $counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.read(counterProvider.notifier).state++,
              child: const Text('Incrementar desde aquí'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Volver al Inicio'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Si ves esto, Firebase Core funciona entre pantallas en iPhone',
              style: TextStyle(fontSize: 16, color: Colors.green),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
