import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:calendario_familiar/features/calendar/presentation/screens/notification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:calendario_familiar/main.dart';

class AlarmDialog extends StatefulWidget {
  final DateTime selectedDate;
  final String eventText;
  final GlobalKey<NavigatorState> navigatorKey;

  const AlarmDialog({
    super.key,
    required this.selectedDate,
    required this.eventText,
    required this.navigatorKey,
  });

  @override
  State<AlarmDialog> createState() => _AlarmDialogState();
}

class _AlarmDialogState extends State<AlarmDialog> {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  bool _alarm1Enabled = false;
  bool _alarm2Enabled = false;
  TimeOfDay _alarm1Time = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _alarm2Time = const TimeOfDay(hour: 18, minute: 0);
  int _alarm1DaysBefore = 0;
  int _alarm2DaysBefore = 0;
  String _alarm1Sound = 'Sonido por defecto';
  String _alarm2Sound = 'Sonido por defecto';

  bool _hasExistingAlarm1 = false;
  bool _hasExistingAlarm2 = false;
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
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

    } catch (e) {
      print('Error inicializando notificaciones: $e');
    }
  }

  Future<void> _loadExistingAlarms() async {
    try {
      print('🔍 Cargando alarmas para: ${widget.selectedDate}');
      final eventDateKey = '${widget.selectedDate.year}${widget.selectedDate.month.toString().padLeft(2, '0')}${widget.selectedDate.day.toString().padLeft(2, '0')}';
      print('🔍 Clave de fecha: $eventDateKey');

      final alarm1Doc = await FirebaseFirestore.instance
          .collection('alarms')
          .doc('${eventDateKey}_alarm_1')
          .get();

      final alarm2Doc = await FirebaseFirestore.instance
          .collection('alarms')
          .doc('${eventDateKey}_alarm_2')
          .get();

      print('🔍 Alarma 1 existe: ${alarm1Doc.exists}');
      print('🔍 Alarma 2 existe: ${alarm2Doc.exists}');

      if (alarm1Doc.exists) {
        final alarmData = alarm1Doc.data()!;
        print('🔍 Datos alarma 1: $alarmData');
        setState(() {
          _alarm1Enabled = alarmData['enabled'] ?? false;
          _hasExistingAlarm1 = true;
          _alarm1Time = TimeOfDay(
            hour: alarmData['hour'] ?? 9,
            minute: alarmData['minute'] ?? 0,
          );
          _alarm1DaysBefore = alarmData['daysBefore'] ?? 0;
          _alarm1Sound = alarmData['sound'] ?? 'Sonido por defecto';
        });
        print('🔍 Alarma 1 cargada: ${_alarm1Time.hour}:${_alarm1Time.minute}');
      }

      if (alarm2Doc.exists) {
        final alarmData = alarm2Doc.data()!;
        print('🔍 Datos alarma 2: $alarmData');
        setState(() {
          _alarm2Enabled = alarmData['enabled'] ?? false;
          _hasExistingAlarm2 = true;
          _alarm2Time = TimeOfDay(
            hour: alarmData['hour'] ?? 18,
            minute: alarmData['minute'] ?? 0,
          );
          _alarm2DaysBefore = alarmData['daysBefore'] ?? 0;
          _alarm2Sound = alarmData['sound'] ?? 'Sonido por defecto';
        });
        print('🔍 Alarma 2 cargada: ${_alarm2Time.hour}:${_alarm2Time.minute}');
      }

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      print('❌ Error cargando alarmas: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        String errorMessage = 'Error cargando alarmas';
        if (e.toString().contains('permission-denied')) {
          errorMessage = 'Error de permisos en Firebase. Verifica las reglas de Firestore.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Ver instrucciones',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error de Permisos'),
                    content: const Text(
                        'Las reglas de Firestore no permiten acceso a la colección de alarmas. '
                            'Necesitas actualizar las reglas en la consola de Firebase. '
                            'Revisa el archivo ACTUALIZAR_REGLAS_FIRESTORE.md para las instrucciones.'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Entendido'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveAlarmConfiguration() async {
    try {
      print('💾 Guardando configuración de alarmas en Firebase...');

      if (_alarm1Enabled) {
        await _saveSingleAlarmConfiguration(true);
      }

      if (_alarm2Enabled) {
        await _saveSingleAlarmConfiguration(false);
      }

      print('✅ Configuración de alarmas guardada exitosamente');

    } catch (e) {
      print('❌ Error guardando configuración de alarmas: $e');
      rethrow;
    }
  }

  Future<void> _saveSingleAlarmConfiguration(bool isAlarm1) async {
    try {
      final eventDateKey = '${widget.selectedDate.year}${widget.selectedDate.month.toString().padLeft(2, '0')}${widget.selectedDate.day.toString().padLeft(2, '0')}';
      final alarmKey = 'alarm_${isAlarm1 ? "1" : "2"}';

      final alarmConfig = {
        'eventDate': eventDateKey,
        'hour': isAlarm1 ? _alarm1Time.hour : _alarm2Time.hour,
        'minute': isAlarm1 ? _alarm1Time.minute : _alarm2Time.minute,
        'daysBefore': isAlarm1 ? _alarm1DaysBefore : _alarm2DaysBefore,
        'sound': isAlarm1 ? _alarm1Sound : _alarm2Sound,
        'enabled': isAlarm1 ? _alarm1Enabled : _alarm2Enabled,
        'eventText': widget.eventText,
        'createdAt': FieldValue.serverTimestamp(),
        'deviceId': 'shared',
      };

      print('💾 Guardando alarma ${isAlarm1 ? "1" : "2"}: $alarmConfig');

      await FirebaseFirestore.instance
          .collection('alarms')
          .doc('${eventDateKey}_${alarmKey}')
          .set(alarmConfig);

      print('✅ Alarma ${isAlarm1 ? "1" : "2"} guardada exitosamente');

    } catch (e) {
      print('❌ Error guardando alarma: $e');

      if (mounted) {
        String errorMessage = 'Error guardando alarma';
        if (e.toString().contains('permission-denied')) {
          errorMessage = 'Error de permisos: No se puede guardar la alarma en Firebase. Verifica las reglas de Firestore.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      throw e;
    }
  }

  Future<void> _scheduleNotification(DateTime scheduledDate, String eventText) async {
    try {
      print('🔔 Programando alarma simple...');

      final now = DateTime.now();
      if (scheduledDate.isBefore(now)) {
        print('⚠️ Fecha en el pasado, ajustando a 10 segundos en el futuro');
        scheduledDate = now.add(const Duration(seconds: 10));
      }

      final alarmId = scheduledDate.millisecondsSinceEpoch ~/ 1000;

      await _notifications.cancel(alarmId);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
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
        actions: [
          const AndroidNotificationAction('open_screen', '🔔 Abrir Alarma'),
          const AndroidNotificationAction('dismiss', '❌ Descartar'),
        ],
      );

      const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notifications.zonedSchedule(
        alarmId,
        '🔔 ¡Es hora de tu evento!',
        'Evento: $eventText',
        tz.TZDateTime.from(scheduledDate, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'notification_screen|eventText:$eventText|autoOpen:true',
      );

      print('✅ Alarma programada exitosamente:');
      print('   - ID: $alarmId');
      print('   - Para: $scheduledDate');
      print('   - Evento: $eventText');
      print('   - Modo: exactAllowWhileIdle + fullScreenIntent');

    } catch (e) {
      print('❌ Error programando alarma: $e');
      rethrow;
    }
  }

  void _openNotificationScreen(String eventText, DateTime eventDate) {
    try {
      if (widget.navigatorKey.currentState != null) {
        widget.navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => NotificationScreen(
              eventText: eventText,
              eventDate: eventDate,
            ),
          ),
        );
        print('✅ Pantalla de notificación abierta');
      } else {
        print('❌ Navigator no disponible');
      }
    } catch (e) {
      print('❌ Error abriendo pantalla de notificación: $e');
    }
  }

  Future<void> _selectTime(BuildContext context, bool isAlarm1) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isAlarm1 ? _alarm1Time : _alarm2Time,
    );
    if (picked != null) {
      setState(() {
        if (isAlarm1) {
          _alarm1Time = picked;
        } else {
          _alarm2Time = picked;
        }
      });

      try {
        await _saveSingleAlarmConfiguration(isAlarm1);
        print('✅ Hora de alarma ${isAlarm1 ? "1" : "2"} actualizada en Firebase');
      } catch (e) {
        print('❌ Error guardando hora en Firebase: $e');
      }
    }
  }

  Future<void> _selectDaysBefore(BuildContext context, Function(int) onChanged, int currentValue) async {
    final List<int> options = [0, 1, 2, 3, 7];
    final int? selected = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Días de anticipación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((days) {
              return ListTile(
                title: Text(days == 0
                    ? 'Mismo día'
                    : days == 1
                    ? '1 día antes'
                    : '$days días antes'),
                onTap: () => Navigator.of(context).pop(days),
              );
            }).toList(),
          ),
        );
      },
    );

    if (selected != null) {
      onChanged(selected);

      bool isAlarm1 = selected != _alarm1DaysBefore;

      try {
        await _saveSingleAlarmConfiguration(isAlarm1);
        print('✅ Días de anticipación de alarma ${isAlarm1 ? "1" : "2"} actualizados en Firebase');
      } catch (e) {
        print('❌ Error guardando días en Firebase: $e');
      }
    }
  }

  Future<void> _testNotification() async {
    try {
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
      );

      final NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notifications.show(
        0,
        '🧪 Notificación de prueba',
        'Evento: ${widget.eventText}',
        platformChannelSpecifics,
      );
    } catch (e) {
      print('Error en notificación de prueba: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: _isLoading
            ? Container(
          height: 200,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
              strokeWidth: 3,
            ),
          ),
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header moderno
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.alarm,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configurar Alarmas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Programa recordatorios para tu evento',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildModernAlarmCard(
                        title: 'Primera Alarma',
                        subtitle: 'Recordatorio principal',
                        icon: Icons.notifications_active,
                        color: const Color(0xFF4CAF50),
                        enabled: _alarm1Enabled,
                        time: _alarm1Time,
                        daysBefore: _alarm1DaysBefore,
                        sound: _alarm1Sound,
                        hasExistingAlarm: _hasExistingAlarm1,
                        onEnabledChanged: (value) => setState(() => _alarm1Enabled = value!),
                        onTimeChanged: () => _selectTime(context, true),
                        onDaysBeforeChanged: (value) => setState(() => _alarm1DaysBefore = value),
                        onSoundChanged: (value) => setState(() => _alarm1Sound = value),
                      ),

                      const SizedBox(height: 20),

                      _buildModernAlarmCard(
                        title: 'Segunda Alarma',
                        subtitle: 'Recordatorio adicional',
                        icon: Icons.notification_add,
                        color: const Color(0xFF2196F3),
                        enabled: _alarm2Enabled,
                        time: _alarm2Time,
                        daysBefore: _alarm2DaysBefore,
                        sound: _alarm2Sound,
                        hasExistingAlarm: _hasExistingAlarm2,
                        onEnabledChanged: (value) => setState(() => _alarm2Enabled = value!),
                        onTimeChanged: () => _selectTime(context, false),
                        onDaysBeforeChanged: (value) => setState(() => _alarm2DaysBefore = value),
                        onSoundChanged: (value) => setState(() => _alarm2Sound = value),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Botones de acción modernos
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await _saveAlarmConfiguration();
                          Navigator.of(context).pop();
                        } catch (e) {
                          print('❌ Error guardando configuración: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Guardar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildModernAlarmCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool enabled,
    required TimeOfDay time,
    required int daysBefore,
    required String sound,
    bool hasExistingAlarm = false,
    required Function(bool?) onEnabledChanged,
    required VoidCallback onTimeChanged,
    required Function(int) onDaysBeforeChanged,
    required Function(String) onSoundChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled ? color.withOpacity(0.3) : Colors.grey.shade200,
          width: enabled ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header de la tarjeta
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (hasExistingAlarm)
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
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 1.2,
                  child: Switch(
                    value: enabled,
                    onChanged: onEnabledChanged,
                    activeColor: color,
                    activeTrackColor: color.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),

          // Configuraciones (solo visible si está habilitada)
          if (enabled) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey.shade200,
                    margin: const EdgeInsets.only(bottom: 20),
                  ),

                  // Fila de configuraciones
                  Row(
                    children: [
                      // Selector de hora
                      Expanded(
                        child: _buildConfigTile(
                          icon: Icons.schedule,
                          label: 'Hora',
                          value: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                          onTap: onTimeChanged,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Selector de días
                      Expanded(
                        child: _buildConfigTile(
                          icon: Icons.calendar_today,
                          label: 'Anticipación',
                          value: daysBefore == 0
                              ? 'Mismo día'
                              : daysBefore == 1
                              ? '1 día antes'
                              : '$daysBefore días antes',
                          onTap: () => _selectDaysBefore(context, onDaysBeforeChanged, daysBefore),
                          color: color,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Selector de sonido
                  _buildConfigTile(
                    icon: Icons.music_note,
                    label: 'Sonido',
                    value: sound,
                    onTap: () => onSoundChanged('Sonido por defecto'),
                    color: color,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfigTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required Color color,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}