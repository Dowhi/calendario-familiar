import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';

class NotificationScreen extends StatefulWidget {
  final String eventText;
  final DateTime eventDate;

  const NotificationScreen({
    super.key,
    required this.eventText,
    required this.eventDate,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isAlarmSilenced = false;
  bool _isExiting = false;
  Timer? _vibrationTimer;

  @override
  void initState() {
    super.initState();
    _startAlarm();
  }

  @override
  void dispose() {
    _vibrationTimer?.cancel();
    super.dispose();
  }

  void _startAlarm() {
    // Vibración inicial fuerte
    HapticFeedback.heavyImpact();
    
    // Repetir vibración cada 2 segundos
    _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isAlarmSilenced) {
        HapticFeedback.heavyImpact();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                border: Border(
                  bottom: BorderSide(
                    color: Colors.teal,
                    width: 2,
                  ),
                ),
              ),
              child: const Text(
                'NOTIFICACIÓN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Contenido principal
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Reloj analógico y fecha/hora
                    Row(
                      children: [
                        // Reloj analógico
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            painter: ClockPainter(),
                            size: const Size(120, 120),
                          ),
                        ),
                        
                        const SizedBox(width: 20),
                        
                        // Fecha y hora digital
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HOY: ${widget.eventDate.day}/${widget.eventDate.month}/${widget.eventDate.year.toString().substring(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Texto del evento
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Text(
                        'Evento: ${widget.eventText}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Sliders
                    Column(
                      children: [
                        // Slider para silenciar alarma
                        _buildSlider(
                          icon: Icons.notifications_off,
                          text: 'Deslizar para silenciar alarma >>>',
                                                     onSlide: () {
                             setState(() {
                               _isAlarmSilenced = true;
                             });
                             // Detener la vibración
                             _vibrationTimer?.cancel();
                             HapticFeedback.lightImpact();
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(
                                 content: Text('🔇 Alarma silenciada'),
                                 duration: Duration(seconds: 2),
                               ),
                             );
                           },
                          isCompleted: _isAlarmSilenced,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Slider para salir
                        _buildSlider(
                          icon: Icons.close,
                          text: 'Deslizar para salir >>>',
                          onSlide: () {
                            setState(() {
                              _isExiting = true;
                            });
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                          isCompleted: _isExiting,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required IconData icon,
    required String text,
    required VoidCallback onSlide,
    required bool isCompleted,
  }) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (details.delta.dx > 10 && !isCompleted) {
          onSlide();
        }
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isCompleted ? Colors.green[100] : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isCompleted ? Colors.green : Colors.black,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Flecha con icono
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.black,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Texto
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isCompleted ? Colors.green[700] : Colors.grey[600],
                ),
              ),
            ),
            
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

// Pintor personalizado para el reloj analógico
class ClockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // Dibujar círculo exterior
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, radius, paint);
    
    // Dibujar marcadores de horas
    for (int i = 0; i < 12; i++) {
      final angle = i * 30 * 3.14159 / 180;
      final startRadius = radius - 8;
      final endRadius = radius - 2;
      
      final startPoint = Offset(
        center.dx + startRadius * cos(angle),
        center.dy + startRadius * sin(angle),
      );
      
      final endPoint = Offset(
        center.dx + endRadius * cos(angle),
        center.dy + endRadius * sin(angle),
      );
      
      canvas.drawLine(startPoint, endPoint, paint);
    }
    
    // Dibujar manecillas
    final now = DateTime.now();
    final hourAngle = (now.hour % 12 + now.minute / 60) * 30 * 3.14159 / 180;
    final minuteAngle = now.minute * 6 * 3.14159 / 180;
    
    // Manecilla de las horas
    final hourHandPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    final hourHandEnd = Offset(
      center.dx + (radius * 0.5) * cos(hourAngle),
      center.dy + (radius * 0.5) * sin(hourAngle),
    );
    
    canvas.drawLine(center, hourHandEnd, hourHandPaint);
    
    // Manecilla de los minutos
    final minuteHandPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final minuteHandEnd = Offset(
      center.dx + (radius * 0.7) * cos(minuteAngle),
      center.dy + (radius * 0.7) * sin(minuteAngle),
    );
    
    canvas.drawLine(center, minuteHandEnd, minuteHandPaint);
    
    // Punto central
    final centerPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 3, centerPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
