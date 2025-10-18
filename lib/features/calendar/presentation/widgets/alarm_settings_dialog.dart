import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Eliminado: import firebase_auth (ya no se utiliza)
import 'package:calendario_familiar/core/services/notification_service.dart';
import 'package:calendario_familiar/core/services/alarm_service.dart';
import 'package:calendario_familiar/core/models/app_event.dart';

/// Diálogo simple para configurar alarmas/recordatorios
class AlarmSettingsDialog extends StatefulWidget {
  final DateTime selectedDate;
  final String eventText;

  const AlarmSettingsDialog({
    Key? key,
    required this.selectedDate,
    required this.eventText,
  }) : super(key: key);

  @override
  State<AlarmSettingsDialog> createState() => _AlarmSettingsDialogState();
}

class _AlarmSettingsDialogState extends State<AlarmSettingsDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Eliminado: FirebaseAuth ya no se utiliza

  // Estado de los recordatorios
  bool _alarm1Enabled = false;
  bool _alarm2Enabled = false;
  TimeOfDay _alarm1Time = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _alarm2Time = const TimeOfDay(hour: 18, minute: 0);
  int _alarm1DaysBefore = 0;
  int _alarm2DaysBefore = 0;
  int _alarm1MinutesBefore = 0; // Sin minutos de anticipación
  int _alarm2MinutesBefore = 0; // Sin minutos de anticipación
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasExistingAlarm1 = false;
  bool _hasExistingAlarm2 = false;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    await _initializeNotifications();
    await _loadExistingAlarms();
  }

  Future<void> _initializeNotifications() async {
    // Ya no necesitamos inicializar aquí, usamos NotificationService
    print('Usando NotificationService centralizado');
  }

  Future<void> _loadExistingAlarms() async {
    try {
      final eventDateKey = _formatDateKey(widget.selectedDate);
      final userId = 'default_user'; // Usuario fijo sin autenticación

      // Cargar alarma 1
      final alarm1Doc = await _firestore
          .collection('alarms')
          .doc('${eventDateKey}_alarm_1')
          .get();

      if (alarm1Doc.exists && alarm1Doc.data() != null) {
        final data = alarm1Doc.data()!;
        setState(() {
          _alarm1Enabled = data['enabled'] ?? false;
          _alarm1Time = TimeOfDay(
            hour: data['hour'] ?? 8,
            minute: data['minute'] ?? 0,
          );
          _alarm1DaysBefore = data['daysBefore'] ?? 0;
          _alarm1MinutesBefore = data['minutesBefore'] ?? 5;
          _hasExistingAlarm1 = true;
        });
      }

      // Cargar alarma 2
      final alarm2Doc = await _firestore
          .collection('alarms')
          .doc('${eventDateKey}_alarm_2')
          .get();

      if (alarm2Doc.exists && alarm2Doc.data() != null) {
        final data = alarm2Doc.data()!;
        setState(() {
          _alarm2Enabled = data['enabled'] ?? false;
          _alarm2Time = TimeOfDay(
            hour: data['hour'] ?? 18,
            minute: data['minute'] ?? 0,
          );
          _alarm2DaysBefore = data['daysBefore'] ?? 0;
          _alarm2MinutesBefore = data['minutesBefore'] ?? 10;
          _hasExistingAlarm2 = true;
        });
      }
    } catch (e) {
      print('Error cargando alarmas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  String _getDayText(int daysBefore) {
    switch (daysBefore) {
      case 0:
        return 'Mismo día del evento';
      case 1:
        return '1 día antes';
      case 2:
        return '2 días antes';
      case 3:
        return '3 días antes';
      case 7:
        return '1 semana antes';
      default:
        return '$daysBefore días antes';
    }
  }

  // Método _selectMinutesBefore eliminado

  Future<void> _selectTime(bool isAlarm1) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isAlarm1 ? _alarm1Time : _alarm2Time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: isAlarm1 ? Colors.green : Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isAlarm1) {
          _alarm1Time = picked;
          _alarm1Enabled = true;
        } else {
          _alarm2Time = picked;
          _alarm2Enabled = true;
        }
      });
    }
  }

  Future<void> _selectDaysBefore(bool isAlarm1) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Días de anticipación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDayOption(0),
            _buildDayOption(1),
            _buildDayOption(2),
            _buildDayOption(3),
            _buildDayOption(7),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isAlarm1) {
          _alarm1DaysBefore = result;
        } else {
          _alarm2DaysBefore = result;
        }
      });
    }
  }

  Widget _buildDayOption(int days) {
    return ListTile(
      title: Text(_getDayText(days)),
      onTap: () => Navigator.of(context).pop(days),
    );
  }

  Future<void> _saveAlarms() async {
    setState(() => _isSaving = true);

    try {
      final eventDateKey = _formatDateKey(widget.selectedDate);
      final userId = 'default_user'; // Usuario fijo sin autenticación

      // Guardar/eliminar alarma 1
      if (_alarm1Enabled) {
        await _saveAlarm(1, eventDateKey, userId, _alarm1Time, _alarm1DaysBefore, _alarm1MinutesBefore);
      } else {
        await _deleteAlarm(1, eventDateKey);
      }

      // Guardar/eliminar alarma 2
      if (_alarm2Enabled) {
        await _saveAlarm(2, eventDateKey, userId, _alarm2Time, _alarm2DaysBefore, _alarm2MinutesBefore);
      } else {
        await _deleteAlarm(2, eventDateKey);
      }

      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Alarmas guardadas correctamente'),
            backgroundColor: Colors.green,
          ),
      );
      Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Error guardando alarmas: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveAlarm(
    int alarmNumber,
    String eventDateKey,
    String userId,
    TimeOfDay time,
    int daysBefore,
    int minutesBefore,
  ) async {
    // Guardar en Firebase
    await _firestore
        .collection('alarms')
        .doc('${eventDateKey}_alarm_$alarmNumber')
        .set({
      'userId': userId,
      'eventDate': eventDateKey,
      'eventText': widget.eventText,
      'enabled': true,
      'hour': time.hour,
      'minute': time.minute,
      'daysBefore': daysBefore,
      'minutesBefore': minutesBefore,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Calcular fecha y hora de la alarma
    final alarmDate = widget.selectedDate.subtract(Duration(days: daysBefore));
    final alarmDateTime = DateTime(
      alarmDate.year,
      alarmDate.month,
      alarmDate.day,
        time.hour,
        time.minute,
      );

    // Verificar que la alarma sea en el futuro
    if (alarmDateTime.isAfter(DateTime.now())) {
      // Programar notificación local
      await _scheduleNotification(alarmNumber, alarmDateTime, minutesBefore);
    } else {
      print('⚠️ Alarma $alarmNumber en el pasado, no se programará');
    }
  }

  Future<void> _deleteAlarm(int alarmNumber, String eventDateKey) async {
    try {
      // Eliminar de Firebase
      await _firestore
          .collection('alarms')
          .doc('${eventDateKey}_alarm_$alarmNumber')
          .delete();
      
      // Cancelar solo la notificación específica de esta alarma
      final eventId = 'alarm_${alarmNumber}_$eventDateKey';
      final tempEvent = AppEvent(
        id: eventId,
        familyId: 'default_family', // FamilyId fijo sin autenticación
        title: widget.eventText,
        dateKey: eventDateKey,
      );
      
      await NotificationService.cancelEventNotification(tempEvent);
      print('✅ Notificación de alarma $alarmNumber cancelada correctamente');
    } catch (e) {
      print('❌ Error eliminando alarma $alarmNumber: $e');
    }
  }

  Future<void> _scheduleNotification(int alarmId, DateTime scheduledDate, int minutesBefore) async {
    try {
      print('🔔 Programando notificación de alarma #$alarmId para: $scheduledDate');
      print('   - Texto del evento: ${widget.eventText}');
      print('   - Fecha del evento: ${widget.selectedDate}');
      print('   - Fecha programada de la alarma: $scheduledDate');
      print('   - Minutos de anticipación configurados: $minutesBefore');
      
      // 🔥 CORRECCIÓN: NO restar aquí, el NotificationService ya maneja los minutos
      print('   - Usando fecha exacta: $scheduledDate');
      print('   - El servicio manejará los $minutesBefore minutos de anticipación');
      
      // Crear un evento temporal como en el botón de test (30s)
      final tempEvent = AppEvent(
        id: 'alarm_${alarmId}_${_formatDateKey(widget.selectedDate)}',
        familyId: 'default_family',
        title: widget.eventText,
        dateKey: _formatDateKey(widget.selectedDate),
        startAt: scheduledDate,
        notifyMinutesBefore: minutesBefore,
      );

      // Usar AlarmService.scheduleAlarm directamente (misma ruta que botón 30s)
      await AlarmService.scheduleAlarm(
        event: tempEvent,
        fireAt: scheduledDate,
        notes: minutesBefore > 0
            ? 'El evento comenzará en $minutesBefore minutos'
            : (tempEvent.title ?? 'Es la hora del evento'),
      );

      print('✅ Alarma #$alarmId programada con AlarmService para: $scheduledDate');
    } catch (e) {
      print('❌ Error programando notificación #$alarmId: $e');
      print('   Stack trace: ${StackTrace.current}');
      
      // Mostrar mensaje educativo al usuario
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Text('Problema con Notificaciones'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage),
                const SizedBox(height: 16),
                const Text(
                  'La alarma se guardó, pero no se pudo programar la notificación.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Solicitar permisos
                  final granted = await NotificationService.requestPermissions();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(granted 
                          ? '✅ Permisos concedidos' 
                          : '❌ Permisos denegados'),
                        backgroundColor: granted ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Activar Permisos'),
              ),
            ],
          ),
        );
      }
      
      rethrow;
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
      ),
    );
  }
  }

  Future<void> _testNotification() async {
    try {
      await NotificationService.showTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🧪 Notificación de prueba enviada'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error enviando notificación de prueba: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6C63FF), Color(0xFF5A52FF)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configurar Alarmas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Programa recordatorios para tu evento',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Botón de prueba de notificación
                      IconButton(
                        onPressed: _testNotification,
                        icon: const Icon(Icons.science, color: Colors.white),
                        tooltip: 'Probar notificación',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Contenido
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )
            else
              Flexible(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                      // Recordatorio 1
                    _buildAlarmCard(
                      title: 'Recordatorio 1',
                      subtitle: 'Recordatorio principal',
                        icon: Icons.notifications,
                      color: Colors.green,
                        enabled: _alarm1Enabled,
                      time: _alarm1Time,
                        daysBefore: _alarm1DaysBefore,
                        minutesBefore: _alarm1MinutesBefore,
                        hasExistingAlarm: _hasExistingAlarm1,
                        onToggle: () => setState(() => _alarm1Enabled = !_alarm1Enabled),
                      onTimeSelect: () => _selectTime(true),
                        onDaysSelect: () => _selectDaysBefore(true),
                      ),

                      const SizedBox(height: 16),

                      // Recordatorio 2
                    _buildAlarmCard(
                      title: 'Recordatorio 2',
                      subtitle: 'Recordatorio adicional',
                        icon: Icons.notifications,
                        color: Colors.blue,
                        enabled: _alarm2Enabled,
                      time: _alarm2Time,
                        daysBefore: _alarm2DaysBefore,
                        minutesBefore: _alarm2MinutesBefore,
                        hasExistingAlarm: _hasExistingAlarm2,
                        onToggle: () => setState(() => _alarm2Enabled = !_alarm2Enabled),
                      onTimeSelect: () => _selectTime(false),
                        onDaysSelect: () => _selectDaysBefore(false),
                    ),
                  ],
                ),
              ),
            ),

            // Botones
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAlarms,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.save, size: 20),
                                SizedBox(width: 8),
                                Text('Guardar'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool enabled,
    required TimeOfDay time,
    required int daysBefore,
    required int minutesBefore,
    required bool hasExistingAlarm,
    required VoidCallback onToggle,
    required VoidCallback onTimeSelect,
    required VoidCallback onDaysSelect,
  }) {
    final effectiveColor = enabled ? color : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header con toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: enabled ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: effectiveColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: enabled ? Colors.black87 : Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (hasExistingAlarm && enabled)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ACTIVA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: (_) => onToggle(),
                  activeColor: color,
                ),
              ],
            ),
          ),

          // Configuración (solo si está activado)
          if (enabled) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Hora
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            const Text(
                              'Hora:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: onTimeSelect,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: color.withOpacity(0.3)),
                                ),
                                child: Text(
                                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Día
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            const Text(
                              'Día:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Flexible(
                              child: InkWell(
                                onTap: onDaysSelect,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _getDayText(daysBefore),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Sección de minutos antes eliminada
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
