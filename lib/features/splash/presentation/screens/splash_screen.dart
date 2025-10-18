import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
// Eliminado: import firebase_auth (ya no se utiliza)

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;

  // Función para detectar iOS de forma confiable
  bool _isIOSDevice() {
    if (!kIsWeb) return false;
    try {
      final userAgent = html.window.navigator.userAgent;
      return userAgent.contains('iPhone') || 
             userAgent.contains('iPad') || 
             userAgent.contains('iPod');
    } catch (e) {
      print('Error detectando iOS: $e');
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    
    // SOLUCIÓN RADICAL: Para iOS Safari, bypass completo del splash
    if (kIsWeb) {
      // Detectar iOS de forma confiable
      final isIOS = _isIOSDevice();
      
      if (isIOS) {
        print('📱 iOS Safari detectado - bypass completo del splash');
        // Navegar inmediatamente sin video ni esperas
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !_hasNavigated) {
            _hasNavigated = true;
            print('🚀 Navegando directamente al calendario desde splash');
            try {
              context.go('/calendar');
              print('✅ Navegación iOS exitosa');
            } catch (e) {
              print('❌ Error navegando en iOS: $e');
              // Fallback: intentar con push
              try {
                Navigator.of(context).pushReplacementNamed('/calendar');
                print('✅ Fallback iOS exitoso');
              } catch (e2) {
                print('❌ Fallback iOS falló: $e2');
              }
            }
          }
        });
        return;
      }
    }
    
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Verificar si estamos en web y el video está disponible
      if (kIsWeb) {
        print('🌐 Web detectada - verificando disponibilidad del video');
        
        // Intentar cargar el video con timeout
        _videoController = VideoPlayerController.asset('assets/videos/splash_video.mp4');
        
        // Timeout de 5 segundos para la inicialización del video
        await _videoController.initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Timeout inicializando video');
          },
        );
        
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          
          // Reproducir el video
          await _videoController.play();
          
          // Configurar para que se repita en bucle
          _videoController.setLooping(true);
          
          // Escuchar cuando termine el video
          _videoController.addListener(_videoListener);
          
          // Navegar después de un tiempo mínimo
          _startNavigationTimer();
        }
      } else {
        // Para móvil, usar la lógica original
        _videoController = VideoPlayerController.asset('assets/videos/splash_video.mp4');
        
        await _videoController.initialize();
        
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          
          await _videoController.play();
          _videoController.setLooping(true);
          _videoController.addListener(_videoListener);
          _startNavigationTimer();
        }
      }
    } catch (e) {
      print('❌ Error inicializando video de splash: $e');
      print('🚀 Continuando sin video...');
      
      // Limpiar el controller si existe
      if (_videoController != null) {
        await _videoController.dispose();
      }
      _videoController = VideoPlayerController.asset('assets/videos/splash_video.mp4'); // Crear nuevo controller
      
      // Navegar después de un breve delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _navigateToMainApp();
        }
      });
    }
  }

  void _videoListener() {
    if (_videoController.value.position >= _videoController.value.duration) {
      // El video terminó, navegar
      _navigateToMainApp();
    }
  }

  void _startNavigationTimer() {
    // Navegar después de 3 segundos mínimo, o cuando termine el video
    Future.delayed(const Duration(seconds: 3), () {
      if (!_hasNavigated) {
        _navigateToMainApp();
      }
    });
  }

  void _navigateToMainApp() {
    if (_hasNavigated) return;
    _hasNavigated = true;

    // Esperar a que Firebase esté inicializado antes de navegar
    _waitForFirebaseAndNavigate();
  }

  Future<void> _waitForFirebaseAndNavigate() async {
    try {
      // Esperar un poco más para asegurar que Firebase esté listo
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verificar si Firebase está inicializado
      if (Firebase.apps.isNotEmpty) {
        print('✅ Firebase ya está inicializado, navegando...');
        _performNavigation();
      } else {
        print('⏳ Esperando inicialización de Firebase...');
        // Esperar hasta 3 segundos máximo (reducido de 5 segundos)
        int attempts = 0;
        while (Firebase.apps.isEmpty && attempts < 6) { // Reducido de 10 a 6 intentos
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
          print('⏳ Intento $attempts de verificar Firebase...');
        }
        
        if (Firebase.apps.isNotEmpty) {
          print('✅ Firebase inicializado después de esperar, navegando...');
          _performNavigation();
        } else {
          print('⚠️ Firebase no se inicializó, navegando de todas formas...');
          _performNavigation();
        }
      }
    } catch (e) {
      print('❌ Error verificando Firebase: $e');
      // Navegar de todas formas
      _performNavigation();
    }
  }

  void _performNavigation() {
    if (!mounted) return;
    
    // Navegar directamente al calendario
    context.go('/calendar');
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isVideoInitialized
            ? _buildVideoPlayer()
            : _buildLoadingScreen(),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return AspectRatio(
      aspectRatio: _videoController.value.aspectRatio,
      child: VideoPlayer(_videoController),
    );
  }

  Widget _buildLoadingScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo o icono de la app
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.calendar_today,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 30),
        
        // Texto de carga
        const Text(
          'Calendario Familiar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        
        // Indicador de carga
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        ),
        const SizedBox(height: 20),
        
        Text(
          kIsWeb ? 'Inicializando servicios...' : 'Cargando...',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        
        // Mensaje adicional para iOS
        if (kIsWeb) ...[
          const SizedBox(height: 10),
          const Text(
            'Preparando calendario...',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}
