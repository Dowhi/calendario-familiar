import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:calendario_familiar/core/firebase/firebase_options.dart';
import 'package:calendario_familiar/calendar_screen.dart';

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

// Provider para Firestore
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Provider para el estado de Firestore
final firestoreStatusProvider = StateProvider<String>((ref) => 'Verificando...');

// Provider para documentos de prueba
final testDocumentsProvider = StreamProvider<List<DocumentSnapshot>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('test_documents').snapshots().map((snapshot) => snapshot.docs);
});

// Provider para el calendario
final selectedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());
final focusedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());
final calendarFormatProvider = StateProvider<CalendarFormat>((ref) => CalendarFormat.month);

// Provider para eventos del calendario
final calendarEventsProvider = StreamProvider<List<DocumentSnapshot>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('calendar_events').snapshots().map((snapshot) => snapshot.docs);
});

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
    GoRoute(
      path: '/firestore',
      builder: (context, state) => const FirestoreScreen(),
    ),
    GoRoute(
      path: '/calendar',
      builder: (context, state) => const CalendarScreen(),
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
    final firestoreStatus = ref.watch(firestoreStatusProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario Familiar - Fase 7'),
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
              '¡Hola desde iPhone!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Fase 7: Calendario',
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
            Text(
              'Estado Firestore: $firestoreStatus',
              style: TextStyle(
                fontSize: 16,
                color: firestoreStatus.contains('✅') ? Colors.green : Colors.orange,
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/firestore'),
              child: const Text('Ir a Firestore'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/calendar'),
              child: const Text('Ir a Calendario'),
            ),
            const SizedBox(height: 40),
                const Text(
                  'Si ves esto, Firestore funciona en iPhone',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
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
      ),
    );
  }
}

class FirestoreScreen extends ConsumerStatefulWidget {
  const FirestoreScreen({super.key});

  @override
  ConsumerState<FirestoreScreen> createState() => _FirestoreScreenState();
}

class _FirestoreScreenState extends ConsumerState<FirestoreScreen> {
  final _textController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _addDocument() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un texto')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.collection('test_documents').add({
        'text': _textController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'user': ref.read(currentUserProvider).value?.uid ?? 'anonymous',
      });
      
      ref.read(firestoreStatusProvider.notifier).state = '✅ Documento agregado';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento agregado exitosamente')),
      );
      
      _textController.clear();
    } catch (e) {
      ref.read(firestoreStatusProvider.notifier).state = '❌ Error: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final testDocuments = ref.watch(testDocumentsProvider);
    final firestoreStatus = ref.watch(firestoreStatusProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore - Fase 6'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Firestore Test',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  'Estado Firestore: $firestoreStatus',
                  style: TextStyle(
                    fontSize: 16,
                    color: firestoreStatus.contains('✅') ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: 'Texto del documento',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _addDocument,
                    child: const Text('Agregar Documento'),
                  ),
                const SizedBox(height: 30),
                const Text(
                  'Documentos existentes:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                testDocuments.when(
                  data: (docs) => docs.isEmpty
                      ? const Text('No hay documentos')
                      : Column(
                          children: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>?;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(data?['text'] ?? 'Sin texto'),
                                subtitle: Text(
                                  'Usuario: ${data?['user'] ?? 'Desconocido'}',
                                ),
                                trailing: Text(
                                  data?['timestamp'] != null
                                      ? 'Hace un momento'
                                      : 'Sin fecha',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Error: $error'),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Volver al Inicio'),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Si ves esto, Firestore funciona en iPhone',
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
