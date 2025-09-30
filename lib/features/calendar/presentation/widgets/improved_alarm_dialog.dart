import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:calendario_familiar/core/services/notification_service.dart';
import 'package:calendario_familiar/core/services/notification_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImprovedAlarmDialog extends StatefulWidget {
  final DateTime selectedDate;
  final String eventText;

  const ImprovedAlarmDialog({
    Key? key,
    required this.selectedDate,
    required this.eventText,
  }) : super(key: key);

  @override
  State<ImprovedAlarmDialog> createState() => _ImprovedAlarmDialogState();
}

class _ImprovedAlarmDialogState extends State<ImprovedAlarmDialog> {
  bool _alarm1Enabled = false;
  bool _alarm2Enabled = false;
  TimeOfDay _alarm1Time = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _alarm2Time = const TimeOfDay(hour: 18, minute: 0);
  int _alarm1DaysBefore = 0;
  int _alarm2DaysBefore = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingSettings();
  }

  Future<void> _loadExistingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _alarm1Enabled = prefs.getBool('alarm_1_enabled') ?? false;
      _alarm2Enabled = prefs.getBool('alarm_2_enabled') ?? false;
      
      final alarm1Hour = prefs.getInt('alarm_1_hour') ?? 9;
      final alarm1Minute = prefs.getInt('alarm_1_minute') ?? 0;
      _alarm1Time = TimeOfDay(hour: alarm1Hour, minute: alarm1Minute);
      
      final alarm2Hour = prefs.getInt('alarm_2_hour') ?? 18;
      final alarm2Minute = prefs.getInt('alarm_2_minute') ?? 0;
      _alarm2Time = TimeOfDay(hour: alarm2Hour, minute: alarm2Minute);
      
      _alarm1DaysBefore = prefs.getInt('alarm_1_days_before') ?? 0;
      _alarm2DaysBefore = prefs.getInt('alarm_2_days_before') ?? 0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarm_1_enabled', _alarm1Enabled);
    await prefs.setBool('alarm_2_enabled', _alarm2Enabled);
    await prefs.setInt('alarm_1_hour', _alarm1Time.hour);
    await prefs.setInt('alarm_1_minute', _alarm1Time.minute);
    await prefs.setInt('alarm_2_hour', _alarm2Time.hour);
    await prefs.setInt('alarm_2_minute', _alarm2Time.minute);
    await prefs.setInt('alarm_1_days_before', _alarm1DaysBefore);
    await prefs.setInt('alarm_2_days_before', _alarm2DaysBefore);
  }

  Future<void> _scheduleAlarm(int alarmNumber, TimeOfDay time, int daysBefore) async {
    try {
      final eventDate = widget.selectedDate;
      final alarmDate = eventDate.subtract(Duration(days: daysBefore));
      final alarmDateTime = DateTime(
        alarmDate.year,
        alarmDate.month,
        alarmDate.day,
        time.hour,
        time.minute,
      );

      // Verificar que la alarma sea en el futuro
      if (alarmDateTime.isBefore(DateTime.now())) {
        throw Exception('La alarma debe ser en el futuro');
      }

      final notificationId = alarmNumber == 1 ? 1001 : 1002;
      
      await NotificationService.scheduleImmediateNotification(
        '🔔 Recordatorio: ${widget.eventText}',
        'Tu evento "${widget.eventText}" es ${daysBefore == 0 ? 'hoy' : 'en $daysBefore día${daysBefore > 1 ? 's' : ''}'} a las ${time.format(context)}',
        minutesFromNow: _calculateMinutesUntilAlarm(alarmDateTime),
      );

      print('✅ Alarma $alarmNumber programada para: $alarmDateTime');
    } catch (e) {
      print('❌ Error programando alarma $alarmNumber: $e');
      rethrow;
    }
  }

  int _calculateMinutesUntilAlarm(DateTime alarmDateTime) {
    final now = DateTime.now();
    final difference = alarmDateTime.difference(now);
    return difference.inMinutes.clamp(1, 525600); // Máximo 1 año
  }

  Future<void> _saveAndSchedule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar permisos
      final hasPermissions = await NotificationService.areNotificationsEnabled();
      if (!hasPermissions) {
        final granted = await NotificationService.requestPermissions();
        if (!granted) {
          throw Exception('Permisos de notificación denegados');
        }
      }

      // Verificar configuración global
      final notificationsEnabled = await NotificationSettingsService.areNotificationsEnabled();
      if (!notificationsEnabled) {
        throw Exception('Las notificaciones están deshabilitadas en configuración');
      }

      // Guardar configuración
      await _saveSettings();

      // Programar alarmas
      if (_alarm1Enabled) {
        await _scheduleAlarm(1, _alarm1Time, _alarm1DaysBefore);
      }

      if (_alarm2Enabled) {
        await _scheduleAlarm(2, _alarm2Time, _alarm2DaysBefore);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${_getEnabledAlarmsCount()} alarma(s) configurada(s) correctamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error configurando alarmas: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _getEnabledAlarmsCount() {
    int count = 0;
    if (_alarm1Enabled) count++;
    if (_alarm2Enabled) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.alarm, color: Colors.blue),
          const SizedBox(width: 8),
          const Text('Configurar Alarmas'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evento: ${widget.eventText}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Fecha: ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Alarma 1
            _buildAlarmCard(
              title: 'Recordatorio 1',
              enabled: _alarm1Enabled,
              time: _alarm1Time,
              daysBefore: _alarm1DaysBefore,
              onEnabledChanged: (value) => setState(() => _alarm1Enabled = value),
              onTimeChanged: (time) => setState(() => _alarm1Time = time),
              onDaysChanged: (days) => setState(() => _alarm1DaysBefore = days),
            ),
            
            const SizedBox(height: 12),
            
            // Alarma 2
            _buildAlarmCard(
              title: 'Recordatorio 2',
              enabled: _alarm2Enabled,
              time: _alarm2Time,
              daysBefore: _alarm2DaysBefore,
              onEnabledChanged: (value) => setState(() => _alarm2Enabled = value),
              onTimeChanged: (time) => setState(() => _alarm2Time = time),
              onDaysChanged: (days) => setState(() => _alarm2DaysBefore = days),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveAndSchedule,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.save, size: 18),
                    const SizedBox(width: 4),
                    Text('Guardar (${_getEnabledAlarmsCount()})'),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildAlarmCard({
    required String title,
    required bool enabled,
    required TimeOfDay time,
    required int daysBefore,
    required ValueChanged<bool> onEnabledChanged,
    required ValueChanged<TimeOfDay> onTimeChanged,
    required ValueChanged<int> onDaysChanged,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.alarm,
                  color: enabled ? Colors.blue : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onEnabledChanged,
                  activeColor: Colors.blue,
                ),
              ],
            ),
            
            if (enabled) ...[
              const SizedBox(height: 12),
              
              // Selector de tiempo
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 8),
                  Text('Hora:', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      final selectedTime = await showTimePicker(
                        context: context,
                        initialTime: time,
                      );
                      if (selectedTime != null) {
                        onTimeChanged(selectedTime);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        time.format(context),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Selector de días antes
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text('Días antes:', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: daysBefore.toDouble(),
                            min: 0,
                            max: 7,
                            divisions: 7,
                            label: daysBefore == 0 ? 'Mismo día' : '$daysBefore día${daysBefore > 1 ? 's' : ''} antes',
                            onChanged: (value) => onDaysChanged(value.round()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              Text(
                daysBefore == 0 
                  ? 'Mismo día del evento'
                  : '$daysBefore día${daysBefore > 1 ? 's' : ''} antes del evento',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
