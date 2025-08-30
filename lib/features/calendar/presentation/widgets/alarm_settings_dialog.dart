import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:calendario_familiar/core/utils/responsive_layout.dart';

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

  bool _alarm1Enabled = false;
  bool _alarm2Enabled = false;
  TimeOfDay _alarm1Time = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _alarm2Time = const TimeOfDay(hour: 18, minute: 0);
  int _alarm1DaysOffset = 0; // 0 = mismo día, -1 = día anterior, etc.
  int _alarm2DaysOffset = 0;
  DateTime? _alarm1CustomDate; // Para fecha personalizada
  DateTime? _alarm2CustomDate; // Para fecha personalizada
  String _alarm1Sound = 'Sonido por defecto';
  String _alarm2Sound = 'Sonido por defecto';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadExistingAlarms();
  }

  Future<void> _initializeNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

      await _notifications.initialize(initializationSettings);

      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        'event_reminders',
        'Recordatorios de eventos',
        description: 'Notificaciones para recordar eventos del calendario',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      print('Error inicializando notificaciones: $e');
    }
  }

  Future<void> _loadExistingAlarms() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final eventDateKey = _formatDateKey(widget.selectedDate);
      final userId = _auth.currentUser?.uid;

      if (userId == null) {
        print('Usuario no autenticado');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Cargar alarma 1
      final alarm1Doc = await _firestore
          .collection('alarms')
          .doc('${eventDateKey}_alarm_1')
          .get();

      // Cargar alarma 2
      final alarm2Doc = await _firestore
          .collection('alarms')
          .doc('${eventDateKey}_alarm_2')
          .get();

      // Procesar datos de alarma 1
      if (alarm1Doc.exists && alarm1Doc.data() != null) {
        final alarm1Data = alarm1Doc.data()!;
        setState(() {
          _alarm1Enabled = alarm1Data['enabled'] ?? false;
          _alarm1Time = TimeOfDay(
            hour: alarm1Data['hour'] ?? 8,
            minute: alarm1Data['minute'] ?? 0,
          );
          _alarm1DaysOffset = alarm1Data['daysOffset'] ?? 0;
          _alarm1CustomDate = alarm1Data['customDate'] != null
              ? DateTime.parse(alarm1Data['customDate'])
              : null;
          _alarm1Sound = alarm1Data['sound'] ?? 'Sonido por defecto';
        });
      } else {
        // Valores por defecto para alarma 1
        setState(() {
          _alarm1Enabled = false;
          _alarm1Time = const TimeOfDay(hour: 8, minute: 0);
          _alarm1DaysOffset = 0;
          _alarm1Sound = 'Sonido por defecto';
        });
      }

      // Procesar datos de alarma 2
      if (alarm2Doc.exists && alarm2Doc.data() != null) {
        final alarm2Data = alarm2Doc.data()!;
        setState(() {
          _alarm2Enabled = alarm2Data['enabled'] ?? false;
          _alarm2Time = TimeOfDay(
            hour: alarm2Data['hour'] ?? 18,
            minute: alarm2Data['minute'] ?? 0,
          );
          _alarm2DaysOffset = alarm2Data['daysOffset'] ?? 0;
          _alarm2CustomDate = alarm2Data['customDate'] != null
              ? DateTime.parse(alarm2Data['customDate'])
              : null;
          _alarm2Sound = alarm2Data['sound'] ?? 'Sonido por defecto';
        });
      } else {
        // Valores por defecto para alarma 2
        setState(() {
          _alarm2Enabled = false;
          _alarm2Time = const TimeOfDay(hour: 18, minute: 0);
          _alarm2DaysOffset = 0;
          _alarm2Sound = 'Sonido por defecto';
        });
      }

      print('✅ Alarmas cargadas correctamente');
    } catch (e) {
      print('❌ Error cargando alarmas: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(bool isAlarm1) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: isAlarm1 ? _alarm1Time : _alarm2Time,
    );

    if (pickedTime != null) {
      setState(() {
        if (isAlarm1) {
          _alarm1Time = pickedTime;
          _alarm1Enabled = true;
        } else {
          _alarm2Time = pickedTime;
          _alarm2Enabled = true;
        }
      });
    }
  }

  Future<void> _selectCustomDate(bool isAlarm1) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isAlarm1 ? (_alarm1CustomDate ?? widget.selectedDate) : (_alarm2CustomDate ?? widget.selectedDate),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        if (isAlarm1) {
          _alarm1CustomDate = pickedDate;
          _alarm1DaysOffset = -999; // Valor especial para indicar fecha personalizada
          _alarm1Enabled = true;
        } else {
          _alarm2CustomDate = pickedDate;
          _alarm2DaysOffset = -999; // Valor especial para indicar fecha personalizada
          _alarm2Enabled = true;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatCustomDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _saveAlarms() async {
    try {
      final eventDateKey = _formatDateKey(widget.selectedDate);
      final userId = _auth.currentUser?.uid;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado')),
        );
        return;
      }

      // Guardar alarma 1 solo si está habilitada
      if (_alarm1Enabled) {
        await _firestore.collection('alarms').doc('${eventDateKey}_alarm_1').set({
          'userId': userId,
          'eventDate': eventDateKey,
          'eventText': widget.eventText,
          'enabled': _alarm1Enabled,
          'hour': _alarm1Time.hour,
          'minute': _alarm1Time.minute,
          'daysOffset': _alarm1DaysOffset,
          'customDate': _alarm1CustomDate?.toIso8601String(),
          'sound': _alarm1Sound,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Programar notificación local
        await _scheduleNotification(
          1,
          _calculateAlarmDateTime(_alarm1Time, _alarm1DaysOffset, _alarm1CustomDate),
          widget.eventText,
        );
      } else {
        // Eliminar alarma 1 si no está habilitada
        await _firestore.collection('alarms').doc('${eventDateKey}_alarm_1').delete();
        await _notifications.cancel(1);
      }

      // Guardar alarma 2 solo si está habilitada
      if (_alarm2Enabled) {
        await _firestore.collection('alarms').doc('${eventDateKey}_alarm_2').set({
          'userId': userId,
          'eventDate': eventDateKey,
          'eventText': widget.eventText,
          'enabled': _alarm2Enabled,
          'hour': _alarm2Time.hour,
          'minute': _alarm2Time.minute,
          'daysOffset': _alarm2DaysOffset,
          'customDate': _alarm2CustomDate?.toIso8601String(),
          'sound': _alarm2Sound,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Programar notificación local
        await _scheduleNotification(
          2,
          _calculateAlarmDateTime(_alarm2Time, _alarm2DaysOffset, _alarm2CustomDate),
          widget.eventText,
        );
      } else {
        // Eliminar alarma 2 si no está habilitada
        await _firestore.collection('alarms').doc('${eventDateKey}_alarm_2').delete();
        await _notifications.cancel(2);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarmas guardadas correctamente')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      print('Error guardando alarmas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando alarmas: $e')),
      );
    }
  }

  DateTime _calculateAlarmDateTime(TimeOfDay time, int daysOffset, DateTime? customDate) {
    DateTime alarmDate;

    if (daysOffset == -999 && customDate != null) {
      // Fecha personalizada
      alarmDate = DateTime(
        customDate.year,
        customDate.month,
        customDate.day,
        time.hour,
        time.minute,
      );
    } else {
      // Fecha relativa al evento
      final DateTime eventDate = widget.selectedDate;
      alarmDate = DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day + daysOffset,
        time.hour,
        time.minute,
      );
    }

    return alarmDate;
  }

  Future<void> _scheduleNotification(int alarmId, DateTime scheduledDate, String eventText) async {
    try {
      // Verificar que la fecha no esté en el pasado
      final now = DateTime.now();
      if (scheduledDate.isBefore(now)) {
        print('⚠️ Fecha en el pasado, no se programará la alarma');
        return;
      }

      // ID único para la alarma
      final notificationId = '${scheduledDate.millisecondsSinceEpoch}_$alarmId'.hashCode;

      // Cancelar alarmas anteriores con el mismo ID
      await _notifications.cancel(notificationId);

      // Configuración de la notificación
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'event_reminders',
        'Recordatorios de eventos',
        channelDescription: 'Notificaciones para recordar eventos del calendario',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        showWhen: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        timeoutAfter: 60000,
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: const Color(0xFF2196F3),
        enableLights: true,
        ledColor: const Color(0xFF2196F3),
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      final NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

      // Programar notificación
      await _notifications.zonedSchedule(
        notificationId,
        '🔔 Recordatorio',
        eventText,
        tz.TZDateTime.from(scheduledDate, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('✅ Notificación programada para: $scheduledDate');
    } catch (e) {
      print('❌ Error programando notificación: $e');
    }
  }

  Widget _buildAlarmCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required VoidCallback onToggle,
    required TimeOfDay time,
    required VoidCallback onTimeSelect,
    required int daysOffset,
    required ValueChanged<int?> onDaysOffsetChanged,
    required DateTime? customDate,
    required VoidCallback onCustomDateSelect,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isEnabled ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header de la tarjeta
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isEnabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isEnabled ? color : Colors.grey,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 1.1,
                  child: Switch(
                    value: isEnabled,
                    onChanged: (value) => onToggle(),
                    activeColor: color,
                    activeTrackColor: color.withOpacity(0.3),
                    inactiveTrackColor: Colors.grey.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),

          // Configuración (solo si está habilitada)
          if (isEnabled) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Hora
                  _buildConfigRow(
                    icon: Icons.access_time_rounded,
                    label: 'Hora:',
                    child: InkWell(
                      onTap: onTimeSelect,
                      borderRadius: BorderRadius.circular(12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTimeOfDay(time),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Icon(
                              Icons.edit_rounded,
                              color: color,
                              size: 16.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // Días offset
                  _buildConfigRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Día:',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: daysOffset,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: color),
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                          ),
                          items: [
                            const DropdownMenuItem(
                                value: 0,
                                child: Text('Mismo día del evento')
                            ),
                            const DropdownMenuItem(
                                value: -1,
                                child: Text('1 día antes')
                            ),
                            const DropdownMenuItem(
                                value: -2,
                                child: Text('2 días antes')
                            ),
                            const DropdownMenuItem(
                                value: -3,
                                child: Text('3 días antes')
                            ),
                            const DropdownMenuItem(
                                value: -5,
                                child: Text('5 días antes')
                            ),
                            const DropdownMenuItem(
                                value: -999,
                                child: Text('📅 Fecha personalizada')
                            ),
                          ],
                          onChanged: onDaysOffsetChanged,
                        ),
                      ),
                    ),
                  ),

                  // Fecha personalizada
                  if (daysOffset == -999 && customDate != null) ...[
                    const SizedBox(height: 16.0),
                    _buildConfigRow(
                      icon: Icons.event_rounded,
                      label: 'Fecha',
                      child: InkWell(
                        onTap: onCustomDateSelect,
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatCustomDate(customDate),
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              const Icon(
                                Icons.edit_rounded,
                                color: Colors.orange,
                                size: 16.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfigRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(
            icon,
            size: 16.0,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 12.0),
        SizedBox(
          width: 60.0,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(child: child),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(6.0),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20.0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del diálogo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade600,
                    Colors.deepPurple.shade700,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(24.0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 24.0,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configurar Alarmas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contenido del diálogo
            Container(
              constraints: const BoxConstraints(maxHeight: 500.0),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10.0),
                child: _isLoading
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                        ),
                        SizedBox(height: 16.0),
                        Text(
                          'Cargando configuración...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : Column(
                  children: [
                    // Información del evento


                    // Alarma 1
                    _buildAlarmCard(
                      title: 'Recordatorio 1',
                      icon: Icons.notifications_rounded,
                      color: Colors.green,
                      isEnabled: _alarm1Enabled,
                      onToggle: () {
                        setState(() {
                          _alarm1Enabled = !_alarm1Enabled;
                        });
                      },
                      time: _alarm1Time,
                      onTimeSelect: () => _selectTime(true),
                      daysOffset: _alarm1DaysOffset,
                      onDaysOffsetChanged: (value) {
                        setState(() {
                          _alarm1DaysOffset = value ?? 0;
                          if (value == -999) {
                            _selectCustomDate(true);
                          }
                        });
                      },
                      customDate: _alarm1CustomDate,
                      onCustomDateSelect: () => _selectCustomDate(true),
                    ),

                    // Alarma 2
                    _buildAlarmCard(
                      title: 'Recordatorio 2',
                      icon: Icons.notification_add_rounded,
                      color: Colors.orange,
                      isEnabled: _alarm2Enabled,
                      onToggle: () {
                        setState(() {
                          _alarm2Enabled = !_alarm2Enabled;
                        });
                      },
                      time: _alarm2Time,
                      onTimeSelect: () => _selectTime(false),
                      daysOffset: _alarm2DaysOffset,
                      onDaysOffsetChanged: (value) {
                        setState(() {
                          _alarm2DaysOffset = value ?? 0;
                          if (value == -999) {
                            _selectCustomDate(false);
                          }
                        });
                      },
                      customDate: _alarm2CustomDate,
                      onCustomDateSelect: () => _selectCustomDate(false),
                    ),
                  ],
                ),
              ),
            ),

            // Botones de acción
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        backgroundColor: Colors.grey.shade50,
                        foregroundColor: Colors.grey.shade700,
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveAlarms,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 2.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.save_rounded,
                            size: 20.0,
                          ),
                          const SizedBox(width: 8.0),
                          const Text(
                            'Guardar',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
}