import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

// Provider para Firebase Auth
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// Provider para el usuario actual
final currentUserProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

// Provider para el estado de autenticación
final authStatusProvider = StateProvider<String>((ref) => 'Verificando...');

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
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
  ],
);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);
    final firebaseStatus = ref.watch(firebaseStatusProvider);
    final authStatus = ref.watch(authStatusProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario Familiar - Fase 5'),
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
              'Fase 5: Firebase Auth',
            ),
            const SizedBox(height: 20),
            Text(
              'Estado Firebase: $firebaseStatus',
              style: TextStyle(
                fontSize: 16,
                color: firebaseStatus.contains('✅') ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Estado Auth: $authStatus',
              style: TextStyle(
                fontSize: 16,
                color: authStatus.contains('✅') ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            currentUser.when(
              data: (user) => Text(
                user != null ? 'Usuario: ${user.email ?? user.uid}' : 'No autenticado',
                style: const TextStyle(fontSize: 14),
              ),
              loading: () => const Text('Cargando usuario...'),
              error: (error, stack) => Text('Error: $error'),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Ir a Login'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Si ves esto, Firebase Auth funciona en iPhone',
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
    final authStatus = ref.watch(authStatusProvider);
    final currentUser = ref.watch(currentUserProvider);
    
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
              'Esta pantalla también usa Riverpod, Firebase y Auth',
            ),
            const SizedBox(height: 20),
            Text(
              'Estado Firebase: $firebaseStatus',
              style: TextStyle(
                fontSize: 16,
                color: firebaseStatus.contains('✅') ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Estado Auth: $authStatus',
              style: TextStyle(
                fontSize: 16,
                color: authStatus.contains('✅') ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            currentUser.when(
              data: (user) => Text(
                user != null ? 'Usuario: ${user.email ?? user.uid}' : 'No autenticado',
                style: const TextStyle(fontSize: 14),
              ),
              loading: () => const Text('Cargando usuario...'),
              error: (error, stack) => Text('Error: $error'),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Ir a Login'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Si ves esto, Firebase Auth funciona entre pantallas en iPhone',
              style: TextStyle(fontSize: 16, color: Colors.green),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final auth = ref.read(firebaseAuthProvider);
      await auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      ref.read(authStatusProvider.notifier).state = '✅ Usuario autenticado';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login exitoso')),
      );
      
      context.go('/');
    } catch (e) {
      ref.read(authStatusProvider.notifier).state = '❌ Error de autenticación: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final auth = ref.read(firebaseAuthProvider);
      await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      ref.read(authStatusProvider.notifier).state = '✅ Usuario registrado y autenticado';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso')),
      );
      
      context.go('/');
    } catch (e) {
      ref.read(authStatusProvider.notifier).state = '❌ Error de registro: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      final auth = ref.read(firebaseAuthProvider);
      await auth.signOut();
      
      ref.read(authStatusProvider.notifier).state = '✅ Usuario deslogueado';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout exitoso')),
      );
      
      context.go('/');
    } catch (e) {
      ref.read(authStatusProvider.notifier).state = '❌ Error de logout: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login - Fase 5'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Firebase Auth Test',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              currentUser.when(
                data: (user) => Text(
                  user != null ? 'Usuario actual: ${user.email ?? user.uid}' : 'No autenticado',
                  style: const TextStyle(fontSize: 16),
                ),
                loading: () => const Text('Cargando usuario...'),
                error: (error, stack) => Text('Error: $error'),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                ElevatedButton(
                  onPressed: _signInWithEmail,
                  child: const Text('Iniciar Sesión'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _signUpWithEmail,
                  child: const Text('Registrarse'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _signOut,
                  child: const Text('Cerrar Sesión'),
                ),
              ],
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Volver al Inicio'),
              ),
              const SizedBox(height: 40),
              const Text(
                'Si ves esto, Firebase Auth funciona en iPhone',
                style: TextStyle(fontSize: 16, color: Colors.green),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
