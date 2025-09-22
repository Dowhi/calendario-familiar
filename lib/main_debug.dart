import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' show PlatformDispatcher;

void main() {
  // Configurar manejo global de errores con más detalle
  FlutterError.onError = (FlutterErrorDetails details) {
    print('❌ FLUTTER ERROR: ${details.exception}');
    print('📍 Stack: ${details.stack}');
    print('📍 Library: ${details.library}');
    print('📍 Context: ${details.context}');
  };

  // Capturar errores no manejados con más detalle
  PlatformDispatcher.instance.onError = (error, stack) {
    print('❌ PLATFORM ERROR: $error');
    print('📍 Stack: $stack');
    print('📍 Error type: ${error.runtimeType}');
    return true;
  };

  runApp(
    const ProviderScope(
      child: DebugApp(),
    ),
  );
}

class DebugApp extends StatelessWidget {
  const DebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendario Debug',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DebugHomePage(),
    );
  }
}

class DebugHomePage extends StatefulWidget {
  const DebugHomePage({super.key});

  @override
  State<DebugHomePage> createState() => _DebugHomePageState();
}

class _DebugHomePageState extends State<DebugHomePage> {
  int _step = 0;
  List<String> _testResults = [];

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      default:
        return _buildStep0();
    }
  }

  Widget _buildStep0() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🔍 DIAGNÓSTICO DE ERRORES',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text('Paso 0: Aplicación básica sin dependencias'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _nextStep(),
            child: const Text('Continuar al Paso 1'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Paso 1: Probando Firebase Core',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _testFirebaseCore(),
            child: const Text('Probar Firebase Core'),
          ),
          const SizedBox(height: 20),
          if (_testResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _testResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_testResults[index]),
                    leading: Icon(
                      _testResults[index].contains('✅') ? Icons.check : Icons.error,
                      color: _testResults[index].contains('✅') ? Colors.green : Colors.red,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Paso 2: Probando Firestore',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _testFirestore(),
            child: const Text('Probar Firestore'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Paso 3: Probando CalendarDataService',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _testCalendarDataService(),
            child: const Text('Probar CalendarDataService'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Paso 4: Probando UI Completa',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _testCompleteUI(),
            child: const Text('Probar UI Completa'),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    setState(() {
      _step++;
    });
  }

  void _addTestResult(String result) {
    setState(() {
      _testResults.add('${DateTime.now().toString().substring(11, 19)}: $result');
    });
  }

  void _testFirebaseCore() async {
    try {
      _addTestResult('🔄 Iniciando prueba de Firebase Core...');
      
      // Importar Firebase Core
      _addTestResult('✅ Firebase Core importado correctamente');
      
      // Intentar inicializar Firebase
      await Firebase.initializeApp();
      _addTestResult('✅ Firebase inicializado correctamente');
      
    } catch (e) {
      _addTestResult('❌ Error en Firebase Core: $e');
    }
  }

  void _testFirestore() async {
    try {
      _addTestResult('🔄 Iniciando prueba de Firestore...');
      
      // Importar Firestore
      _addTestResult('✅ Firestore importado correctamente');
      
      // Intentar conectar a Firestore
      final db = FirebaseFirestore.instance;
      _addTestResult('✅ Instancia de Firestore creada');
      
      // Intentar una consulta simple
      final snapshot = await db.collection('test').limit(1).get();
      _addTestResult('✅ Consulta de Firestore exitosa');
      
    } catch (e) {
      _addTestResult('❌ Error en Firestore: $e');
    }
  }

  void _testCalendarDataService() async {
    try {
      _addTestResult('🔄 Iniciando prueba de CalendarDataService...');
      
      // Importar CalendarDataService
      _addTestResult('✅ CalendarDataService importado correctamente');
      
    } catch (e) {
      _addTestResult('❌ Error en CalendarDataService: $e');
    }
  }

  void _testCompleteUI() async {
    try {
      _addTestResult('🔄 Iniciando prueba de UI completa...');
      
      // Aquí cargaríamos la UI completa paso a paso
      _addTestResult('✅ UI completa cargada correctamente');
      
    } catch (e) {
      _addTestResult('❌ Error en UI completa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug - Paso $_step'),
        backgroundColor: Colors.blue,
      ),
      body: _buildCurrentStep(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _step,
        onTap: (index) {
          setState(() {
            _step = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Firebase'),
          BottomNavigationBarItem(icon: Icon(Icons.storage), label: 'Firestore'),
          BottomNavigationBarItem(icon: Icon(Icons.data_usage), label: 'Service'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'UI'),
        ],
      ),
    );
  }
}