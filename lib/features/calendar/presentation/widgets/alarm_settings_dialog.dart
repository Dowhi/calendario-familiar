import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Estado de los recordatorios
  bool _alarm1Enabled = false;
  bool _alarm2Enabled = false;
  TimeOfDay _alarm1Time = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _alarm2Time = const TimeOfDay(hour: 18, minute: 0);
  int _alarm1DaysBefore = 0;
  int _alarm2DaysBefore = 0;
  
  bool _isLoading = true;
  bool _isSaving = false;

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
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _notifications.initialize(initSettings);

      // Crear canal de notificaciones para Android
      const channel = AndroidNotificationChannel(
        'event_reminders',
        'Recordatorios de eventos',
        description: 'Notificaciones para recordar eventos del calendario',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      print('Error inicializando notificaciones: $e');
    }
  }

  Future<void> _loadExistingAlarms() async {
    try {
      final eventDateKey = _formatDateKey(widget.selectedDate);
      final userId = _auth.currentUser?.uid;

      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Cargar alarma 1
      final alarm1Doc = await _firestore
          .collection('alarms')
          .doc('${eventDateKey}_alarm_1')
          .get();

      if (alarm1Doc.exists && alarm1Doc.data() != null) {
        final data = alarm1Doc.data()!;
        _alarm1Enabled = data['enabled'] ?? false;
        _alarm1Time = TimeOfDay(
          hour: data['hour'] ?? 8,
          minute: data['minute'] ?? 0,
        );
        _alarm1DaysBefore = data['daysBefore'] ?? 0;
      }

      // Cargar alarma 2
      final alarm2Doc = await _firestore
          .collection('alarms')
          .doc('${eventDateKey}_alarm_2')
          .get();

      if (alarm2Doc.exists && alarm2Doc.data() != null) {
        final data = alarm2Doc.data()!;
        _alarm2Enabled = data['enabled'] ?? false;
        _alarm2Time = TimeOfDay(
          hour: data['hour'] ?? 18,
          minute: data['minute'] ?? 0,
        );
        _alarm2DaysBefore = data['daysBefore'] ?? 0;
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
      final userId = _auth.currentUser?.uid;

      if (userId == null) {
        _showError('Usuario no autenticado');
        return;
      }

      // Guardar/eliminar alarma 1
      if (_alarm1Enabled) {
        await _saveAlarm(1, eventDateKey, userId, _alarm1Time, _alarm1DaysBefore);
      } else {
        await _deleteAlarm(1, eventDateKey);
      }

      // Guardar/eliminar alarma 2
      if (_alarm2Enabled) {
        await _saveAlarm(2, eventDateKey, userId, _alarm2Time, _alarm2DaysBefore);
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
      await _scheduleNotification(alarmNumber, alarmDateTime);
    } else {
      print('⚠️ Alarma $alarmNumber en el pasado, no se programará');
    }
  }

  Future<void> _deleteAlarm(int alarmNumber, String eventDateKey) async {
    await _firestore
        .collection('alarms')
        .doc('${eventDateKey}_alarm_$alarmNumber')
        .delete();
    await _notifications.cancel(alarmNumber);
  }

  Future<void> _scheduleNotification(int alarmId, DateTime scheduledDate) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'event_reminders',
        'Recordatorios de eventos',
        channelDescription: 'Notificaciones para recordar eventos del calendario',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
      );

      final details = NotificationDetails(android: androidDetails);

      await _notifications.zonedSchedule(
        alarmId,
        '🔔 Recordatorio',
        widget.eventText,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('✅ Notificación programada para: $scheduledDate');
    } catch (e) {
      print('❌ Error programando notificación: $e');
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
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
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
                  const Text(
                    'Configurar Alarmas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                        icon: Icons.notifications,
                        color: Colors.green,
                        enabled: _alarm1Enabled,
                        time: _alarm1Time,
                        daysBefore: _alarm1DaysBefore,
                        onToggle: () => setState(() => _alarm1Enabled = !_alarm1Enabled),
                        onTimeSelect: () => _selectTime(true),
                        onDaysSelect: () => _selectDaysBefore(true),
                      ),

                      const SizedBox(height: 16),

                      // Recordatorio 2
                      _buildAlarmCard(
                        title: 'Recordatorio 2',
                        icon: Icons.notifications,
                        color: Colors.grey,
                        enabled: _alarm2Enabled,
                        time: _alarm2Time,
                        daysBefore: _alarm2DaysBefore,
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
    required IconData icon,
    required Color color,
    required bool enabled,
    required TimeOfDay time,
    required int daysBefore,
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
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: enabled ? Colors.black87 : Colors.grey,
                    ),
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
                      const SizedBox(width: 12),
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
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.edit, size: 16, color: color),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Día
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 12),
                      const Text(
                        'Día:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: onDaysSelect,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _getDayText(daysBefore),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_drop_down,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
