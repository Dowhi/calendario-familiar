import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:calendario_familiar/core/services/reminder_service.dart';

/// Diálogo simplificado para configurar recordatorios
class SimpleAlarmDialog extends StatefulWidget {
  const SimpleAlarmDialog({
    super.key,
    required this.selectedDate,
    required this.eventText,
  });

  final DateTime selectedDate;
  final String eventText;

  @override
  State<SimpleAlarmDialog> createState() => _SimpleAlarmDialogState();
}

class _SimpleAlarmDialogState extends State<SimpleAlarmDialog> {
  TimeOfDay _alarmTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = false;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted = await ReminderService.areNotificationsEnabled();
    setState(() {
      _permissionsGranted = granted;
    });
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await ReminderService.requestPermissions();
      setState(() {
        _permissionsGranted = granted;
      });

      if (!granted) {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      _showErrorDialog('Error solicitando permisos de notificaciones');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setAlarm() async {
    if (!_permissionsGranted) {
      await _requestPermissions();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Calcular la fecha y hora del recordatorio
      final alarmDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _alarmTime.hour,
        _alarmTime.minute,
      );

      // Verificar que la hora no esté en el pasado
      final now = DateTime.now();
      if (alarmDateTime.isBefore(now)) {
        _showErrorDialog('La hora seleccionada está en el pasado');
        return;
      }

      // Programar el recordatorio
      await ReminderService.scheduleReminder(
        id: widget.selectedDate.hashCode,
        title: '📅 Recordatorio',
        body: widget.eventText.isNotEmpty 
            ? widget.eventText 
            : 'Recordatorio para ${_formatDate(widget.selectedDate)}',
        scheduledTime: alarmDateTime,
      );

      // Mostrar confirmación
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb 
                  ? 'Recordatorio programado para ${_formatDateTime(alarmDateTime)}\n⚠️ Solo funcionará mientras la pestaña esté abierta'
                  : 'Recordatorio programado para ${_formatDateTime(alarmDateTime)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ Error programando recordatorio: $e');
      _showErrorDialog('Error programando el recordatorio');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showTestNotification() async {
    try {
      await ReminderService.showTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificación de prueba enviada'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error enviando notificación de prueba');
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos Requeridos'),
        content: Text(
          kIsWeb
              ? 'Para recibir recordatorios, necesitas permitir las notificaciones en tu navegador.\n\n'
                '1. Haz clic en el ícono de notificaciones en la barra de direcciones\n'
                '2. Selecciona "Permitir" para este sitio\n'
                '3. Recarga la página'
              : 'Para recibir recordatorios, necesitas permitir las notificaciones en la configuración de la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} a las ${_alarmTime.format(context)}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurar Recordatorio'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Información del evento
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha: ${_formatDate(widget.selectedDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (widget.eventText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Evento: ${widget.eventText}'),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Estado de permisos
          if (!_permissionsGranted) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Permisos de notificación requeridos',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Selector de hora
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Hora del recordatorio'),
            subtitle: Text(_alarmTime.format(context)),
            onTap: _selectTime,
          ),
          
          // Información sobre limitaciones web
          if (kIsWeb) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'En web, el recordatorio solo funcionará mientras la pestaña esté abierta',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        if (!_permissionsGranted)
          TextButton(
            onPressed: _isLoading ? null : _requestPermissions,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Solicitar Permisos'),
          ),
        if (_permissionsGranted) ...[
          TextButton(
            onPressed: _isLoading ? null : _showTestNotification,
            child: const Text('Probar'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _setAlarm,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Programar'),
          ),
        ],
      ],
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime,
    );
    
    if (picked != null && picked != _alarmTime) {
      setState(() {
        _alarmTime = picked;
      });
    }
  }
}
