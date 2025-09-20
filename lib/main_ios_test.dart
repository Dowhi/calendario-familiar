import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async' show runZonedGuarded;

/// Versión mínima de prueba para iOS
/// Solo muestra un texto simple para verificar que la PWA carga
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar manejo global de errores para iOS
  FlutterError.onError = (FlutterErrorDetails details) {
    print('❌ Flutter Error: ${details.exception}');
    print('📍 Stack: ${details.stack}');
  };
  
  // Ejecutar con manejo de errores globales
  runZonedGuarded(() {
    runApp(
      const ProviderScope(
        child: IOSTestApp(),
      ),
    );
  }, (error, stackTrace) {
    print('❌ Uncaught error: $error');
    print('📍 Stack trace: $stackTrace');
  });
}

class IOSTestApp extends StatelessWidget {
  const IOSTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iOS Test App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const IOSTestHomePage(),
    );
  }
}

class IOSTestHomePage extends StatefulWidget {
  const IOSTestHomePage({super.key});

  @override
  State<IOSTestHomePage> createState() => _IOSTestHomePageState();
}

class _IOSTestHomePageState extends State<IOSTestHomePage> {
  int _counter = 0;
  String _status = 'Cargando...';

  @override
  void initState() {
    super.initState();
    
    // Simular carga
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _status = '✅ iOS Test App funcionando correctamente';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('iOS Test App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.phone_iphone,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 32),
            const Text(
              'Hola iOS!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Contador de prueba:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_counter',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _counter++;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Incrementar',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: const Text(
                'Si ves esta pantalla, la PWA está funcionando en iOS. El problema anterior era de Firebase/rendering.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
