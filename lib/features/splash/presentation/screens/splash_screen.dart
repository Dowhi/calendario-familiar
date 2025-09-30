import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Inicializar el video
      _videoController = VideoPlayerController.asset('assets/videos/splash_video.mp4');
      
      await _videoController.initialize();
      
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
    } catch (e) {
      print('❌ Error inicializando video de splash: $e');
      // Si hay error con el video, navegar inmediatamente
      _navigateToMainApp();
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

    // Verificar si el usuario está autenticado
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // Usuario autenticado, ir al calendario
      context.go('/calendar');
    } else {
      // Usuario no autenticado, ir al login
      context.go('/login');
    }
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
        
        const Text(
          'Cargando...',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
