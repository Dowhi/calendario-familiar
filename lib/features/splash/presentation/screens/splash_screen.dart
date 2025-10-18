import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    
    // Navegación simplificada - sin videos ni gifs
    print('🚀 Iniciando splash screen simplificado');
    
    // Navegar al calendario después de un breve delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        print('🚀 Navegando al calendario');
        try {
          context.go('/calendar');
          print('✅ Navegación exitosa');
        } catch (e) {
          print('❌ Error navegando: $e');
          // Fallback: intentar con push
          try {
            Navigator.of(context).pushReplacementNamed('/calendar');
            print('✅ Fallback exitoso');
          } catch (e2) {
            print('❌ Fallback falló: $e2');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de la app
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.calendar_today,
                size: 60,
                color: Color(0xFF1B5E20),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Título
            const Text(
              'Calendario Familiar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Subtítulo
            const Text(
              'Sincronización en tiempo real',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Indicador de carga
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            
            const SizedBox(height: 20),
            
            // Texto de carga
            const Text(
              'Cargando...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}