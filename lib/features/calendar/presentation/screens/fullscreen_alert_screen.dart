import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Pantalla de aviso completa que se muestra cuando llega la hora del recordatorio
class FullscreenAlertScreen extends StatefulWidget {
  const FullscreenAlertScreen({
    super.key,
    required this.title,
    required this.message,
    required this.dateTime,
  });

  final String title;
  final String message;
  final DateTime dateTime;

  @override
  State<FullscreenAlertScreen> createState() => _FullscreenAlertScreenState();
}

class _FullscreenAlertScreenState extends State<FullscreenAlertScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configurar animaciones
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    // Iniciar animaciones
    _pulseController.repeat(reverse: true);
    _startShakeAnimation();
    
    // Vibrar y reproducir sonido
    _triggerAlert();
    
    // Mantener la pantalla encendida
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startShakeAnimation() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _shakeController.forward().then((_) {
          _shakeController.reverse().then((_) {
            _startShakeAnimation(); // Repetir
          });
        });
      }
    });
  }

  void _triggerAlert() {
    // Vibrar
    HapticFeedback.heavyImpact();
    
    // Repetir vibración cada 3 segundos
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        HapticFeedback.heavyImpact();
      } else {
        timer.cancel();
      }
    });
  }

  void _dismissAlert() {
    // Vibrar suavemente al cerrar
    HapticFeedback.lightImpact();
    
    // Cerrar la pantalla
    if (mounted) {
      context.pop();
    }
  }

  void _snoozeAlert() {
    // Vibrar suavemente
    HapticFeedback.lightImpact();
    
    // Cerrar y programar para 5 minutos después
    if (mounted) {
      context.pop();
      // TODO: Implementar snooze usando ReminderService
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recordatorio pospuesto por 5 minutos'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final alertDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String dateStr;
    if (alertDate == today) {
      dateStr = 'Hoy';
    } else if (alertDate == today.add(const Duration(days: 1))) {
      dateStr = 'Mañana';
    } else if (alertDate == today.subtract(const Duration(days: 1))) {
      dateStr = 'Ayer';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    return '$dateStr a las $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[900],
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.red[900]!,
                            Colors.red[800]!,
                            Colors.red[700]!,
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icono de alarma animado
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.alarm,
                              size: 60,
                              color: Colors.red,
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Título
                          Text(
                            '🚨 ALARMA',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Mensaje del recordatorio
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                const SizedBox(height: 10),
                                
                                Text(
                                  widget.message,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                const SizedBox(height: 15),
                                
                                // Fecha y hora
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _formatDateTime(widget.dateTime),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Botones de acción
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Botón Snooze
                              ElevatedButton.icon(
                                onPressed: _snoozeAlert,
                                icon: const Icon(Icons.snooze),
                                label: const Text('Posponer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              ),
                              
                              // Botón Cerrar
                              ElevatedButton.icon(
                                onPressed: _dismissAlert,
                                icon: const Icon(Icons.close),
                                label: const Text('Cerrar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Texto de ayuda
                          Text(
                            'Toca "Cerrar" para desactivar la alarma',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
