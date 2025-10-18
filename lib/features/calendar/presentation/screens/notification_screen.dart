import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendario_familiar/core/providers/theme_provider.dart';

// Importación condicional para notificaciones locales (no compatible con web)
import 'package:calendario_familiar/core/services/alarm_service.dart';
import 'package:calendario_familiar/core/models/app_event.dart';

class NotificationScreen extends ConsumerWidget {
  final String eventText;
  final DateTime eventDate;

  const NotificationScreen({
    Key? key,
    required this.eventText,
    required this.eventDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    
    // Colores adaptativos según el tema
    final primaryColor = isDarkMode ? const Color(0xFF1E3C72) : const Color(0xFF2196F3);
    final secondaryColor = isDarkMode ? const Color(0xFF2A5298) : const Color(0xFF1976D2);
    final backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final cardColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorio'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode ? [
              Colors.grey[900]!,
              Colors.grey[800]!,
            ] : [
              primaryColor,
              secondaryColor,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de notificación
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    size: 60,
                    color: primaryColor,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Título
                Text(
                  '¡Recordatorio!',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Fecha del evento
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('EEEE, d MMMM yyyy', 'es').format(eventDate),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Hora del evento
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('HH:mm').format(eventDate),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Texto del evento
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Evento:',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        eventText,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botón posponer (solo en móvil/desktop)
                    if (!kIsWeb)
                      ElevatedButton.icon(
                        onPressed: () => _postponeNotification(context),
                        icon: const Icon(Icons.snooze, size: 18),
                        label: const Text('Posponer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 3,
                        ),
                      ),
                    
                    // Botón principal
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cardColor,
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Entendido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _postponeNotification(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Posponer Recordatorio'),
          content: const Text('¿Por cuánto tiempo quieres posponer este recordatorio?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _schedulePostponedNotification(5, context);
              },
              child: const Text('5 minutos'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _schedulePostponedNotification(10, context);
              },
              child: const Text('10 minutos'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _schedulePostponedNotification(15, context);
              },
              child: const Text('15 minutos'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _schedulePostponedNotification(int minutes, BuildContext context) async {
    if (!context.mounted) return;
    
    // En web, solo mostrar mensaje (las notificaciones locales no están disponibles)
    if (kIsWeb) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('En la versión web, el recordatorio se pospondría por $minutes minutos'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    try {
      if (!kIsWeb) {
        final now = DateTime.now();
        final scheduledTime = now.add(Duration(minutes: minutes));
        final event = AppEvent(
          id: 'snooze-${scheduledTime.millisecondsSinceEpoch}',
          familyId: 'default_family', // FamilyId fijo sin autenticación
          title: 'Recordatorio pospuesto',
          description: eventText,
          dateKey: DateFormat('yyyyMMdd').format(eventDate),
          startAt: scheduledTime,
          notifyMinutesBefore: 0,
        );
        await AlarmService.scheduleAlarm(event: event, fireAt: scheduledTime, notes: eventText);
      }

      // Cerrar la pantalla actual
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recordatorio pospuesto por $minutes minutos'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error programando notificación pospuesta: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al posponer el recordatorio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
