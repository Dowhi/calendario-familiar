import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:calendario_familiar/core/models/app_user.dart';
import 'package:calendario_familiar/features/auth/logic/auth_controller.dart';
import 'package:calendario_familiar/features/calendar/logic/calendar_controller.dart';
import 'package:calendario_familiar/core/services/calendar_data_service.dart';
import 'package:calendario_familiar/core/services/notification_service.dart';
import 'package:calendario_familiar/core/services/notification_settings_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _alarmRemindersEnabled = true;
  bool _eventRemindersEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _defaultReminderMinutes = 30;
  bool _isLoading = true;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      print('🔧 Cargando configuración de notificaciones...');
      final settings = await NotificationSettingsService.getAllSettings();
      final hasPermissions = await NotificationService.areNotificationsEnabled();
      
      print('🔧 Configuraciones cargadas: $settings');
      print('🔧 Permisos disponibles: $hasPermissions');
      
      setState(() {
        _notificationsEnabled = settings['notificationsEnabled'] as bool;
        _alarmRemindersEnabled = settings['alarmRemindersEnabled'] as bool;
        _eventRemindersEnabled = settings['eventRemindersEnabled'] as bool;
        _soundEnabled = settings['soundEnabled'] as bool;
        _vibrationEnabled = settings['vibrationEnabled'] as bool;
        _defaultReminderMinutes = settings['defaultReminderMinutes'] as int;
        _hasPermissions = hasPermissions;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error cargando configuración de notificaciones: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNotificationsEnabled(bool value) async {
    await NotificationSettingsService.setNotificationsEnabled(value);
    setState(() {
      _notificationsEnabled = value;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Notificaciones habilitadas' : 'Notificaciones deshabilitadas'),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _updateAlarmReminders(bool value) async {
    await NotificationSettingsService.setAlarmRemindersEnabled(value);
    setState(() {
      _alarmRemindersEnabled = value;
    });
  }

  Future<void> _updateEventReminders(bool value) async {
    await NotificationSettingsService.setEventRemindersEnabled(value);
    setState(() {
      _eventRemindersEnabled = value;
    });
  }

  Future<void> _updateSoundEnabled(bool value) async {
    await NotificationSettingsService.setSoundEnabled(value);
    setState(() {
      _soundEnabled = value;
    });
  }

  Future<void> _updateVibrationEnabled(bool value) async {
    await NotificationSettingsService.setVibrationEnabled(value);
    setState(() {
      _vibrationEnabled = value;
    });
  }

  Future<void> _requestPermissions() async {
    try {
      print('🔧 Usuario solicitando permisos...');
      final granted = await NotificationService.requestPermissions();
      print('🔧 Resultado de solicitud de permisos: $granted');
      
      setState(() {
        _hasPermissions = granted;
      });
      
      // Recargar configuración después de solicitar permisos
      await _loadNotificationSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(granted ? 'Permisos concedidos' : 'Permisos denegados'),
            backgroundColor: granted ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error en _requestPermissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error solicitando permisos: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _testNotification() async {
    try {
      await NotificationService.showTestNotification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notificación de prueba enviada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error enviando notificación de prueba: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _testImmediateNotification() async {
    try {
      await NotificationService.scheduleImmediateNotification(
        '🔔 Prueba de Recordatorio',
        'Esta es una notificación programada que aparecerá en 10 segundos',
        minutesFromNow: 1,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Recordatorio de prueba programado (aparecerá en 1 minuto)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error programando recordatorio: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final calendarService = ref.read(calendarDataServiceProvider);
      final events = calendarService.getAllEvents();
      final shiftTemplates = calendarService.getShiftTemplatesForExport();
      
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'events': events,
        'shiftTemplates': shiftTemplates,
      };

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'calendario_familiar_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonEncode(exportData));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Datos exportados exitosamente a: $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      // En una implementación real, aquí se abriría un file picker
      // Por ahora, mostraremos un mensaje informativo
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Importar Datos'),
            content: const Text(
              'Para importar datos, coloca el archivo JSON de respaldo en la carpeta de documentos de la aplicación y reinicia la app.',
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al importar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final calendarState = ref.watch(calendarControllerProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuración')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: user == null
          ? const Center(child: Text('No autenticado'))
          : ListView(
              children: [
                // Información del usuario
                _buildUserSection(context, ref, user),
                
                const Divider(),
                
                // Información del calendario
                _buildCalendarSection(context, ref, calendarState),
                
                const Divider(),
                
                // Configuración de notificaciones
                _buildNotificationSection(context),
                
                const Divider(),
                
                // Datos y respaldo
                _buildDataSection(context),
                
                const Divider(),
                
                // Acciones
                _buildActionsSection(context, ref),
              ],
            ),
    );
  }

  Widget _buildUserSection(BuildContext context, WidgetRef ref, AppUser user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.photoUrl != null
            ? NetworkImage(user.photoUrl!)
            : null,
        child: user.photoUrl == null
            ? Text(user.displayName?.substring(0, 1).toUpperCase() ?? 'U')
            : null,
      ),
      title: Text(user.displayName ?? 'Usuario'),
      subtitle: Text(user.email),
    );
  }

  Widget _buildCalendarSection(BuildContext context, WidgetRef ref, AsyncValue calendarState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Calendario Familiar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        calendarState.when(
          data: (calendar) {
            if (calendar == null) return const SizedBox.shrink();
            
            return Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(calendar.name),
                  subtitle: Text('${calendar.members.length} miembros'),
                ),
                ListTile(
                  leading: const Icon(Icons.group),
                  title: const Text('Gestionar miembros'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/members'),
                ),
              ],
            );
          },
          loading: () => const ListTile(
            leading: CircularProgressIndicator(),
            title: Text('Cargando calendario...'),
          ),
          error: (error, stack) => ListTile(
            leading: const Icon(Icons.error, color: Colors.red),
            title: Text('Error: $error'),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Notificaciones y Recordatorios',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Estado de permisos
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hasPermissions ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hasPermissions ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _hasPermissions ? Icons.check_circle : Icons.warning,
                color: _hasPermissions ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _hasPermissions 
                    ? 'Permisos de notificación concedidos' 
                    : 'Permisos de notificación necesarios',
                  style: TextStyle(
                    color: _hasPermissions ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!_hasPermissions)
                TextButton(
                  onPressed: _requestPermissions,
                  child: const Text('Solicitar'),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Configuración principal
        SwitchListTile(
          title: const Text('Notificaciones habilitadas'),
          subtitle: const Text('Activar/desactivar todas las notificaciones'),
          value: _notificationsEnabled,
          onChanged: _updateNotificationsEnabled,
          secondary: const Icon(Icons.notifications),
        ),
        
        // Subconfiguraciones (solo si las notificaciones están habilitadas)
        if (_notificationsEnabled) ...[
          SwitchListTile(
            title: const Text('Recordatorios de eventos'),
            subtitle: const Text('Notificaciones antes de eventos programados'),
            value: _eventRemindersEnabled,
            onChanged: _updateEventReminders,
            secondary: const Icon(Icons.event),
          ),
          
          SwitchListTile(
            title: const Text('Alarmas y recordatorios'),
            subtitle: const Text('Recordatorios personalizados y alarmas'),
            value: _alarmRemindersEnabled,
            onChanged: _updateAlarmReminders,
            secondary: const Icon(Icons.alarm),
          ),
          
          SwitchListTile(
            title: const Text('Sonido'),
            subtitle: const Text('Reproducir sonido en notificaciones'),
            value: _soundEnabled,
            onChanged: _updateSoundEnabled,
            secondary: const Icon(Icons.volume_up),
          ),
          
          SwitchListTile(
            title: const Text('Vibración'),
            subtitle: const Text('Vibrar en notificaciones'),
            value: _vibrationEnabled,
            onChanged: _updateVibrationEnabled,
            secondary: const Icon(Icons.vibration),
          ),
          
          // Recordatorio por defecto
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Recordatorio por defecto'),
            subtitle: Text('$_defaultReminderMinutes minutos antes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showReminderTimeDialog,
          ),
        ],
        
        // Pruebas
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Pruebas',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.notifications_active),
          title: const Text('Probar notificación inmediata'),
          subtitle: const Text('Enviar notificación de prueba ahora'),
          onTap: _testNotification,
        ),
        ListTile(
          leading: const Icon(Icons.schedule),
          title: const Text('Probar recordatorio programado'),
          subtitle: const Text('Programar notificación para 1 minuto'),
          onTap: _testImmediateNotification,
        ),
      ],
    );
  }

  void _showReminderTimeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recordatorio por defecto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecciona cuántos minutos antes del evento quieres recibir el recordatorio:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [15, 30, 60, 120, 240, 480, 1440].map((minutes) {
                final hours = minutes ~/ 60;
                final displayText = hours >= 24 
                  ? '${hours ~/ 24} día${hours ~/ 24 > 1 ? 's' : ''}'
                  : hours >= 1 
                    ? '${hours}h'
                    : '${minutes}m';
                
                return ChoiceChip(
                  label: Text(displayText),
                  selected: _defaultReminderMinutes == minutes,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _defaultReminderMinutes = minutes;
                      });
                      NotificationSettingsService.setDefaultReminderMinutes(minutes);
                      Navigator.of(context).pop();
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Datos y Respaldo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Exportar datos'),
          subtitle: const Text('Crear respaldo de eventos y plantillas'),
          onTap: _exportData,
        ),
        ListTile(
          leading: const Icon(Icons.upload),
          title: const Text('Importar datos'),
          subtitle: const Text('Restaurar desde un respaldo'),
          onTap: _importData,
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Acciones',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('Ayuda'),
          onTap: () {
            _showHelpDialog(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('Acerca de'),
          onTap: () {
            _showAboutDialog(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
          onTap: () => _showLogoutDialog(context, ref),
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayuda'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cómo usar el Calendario Familiar:'),
            SizedBox(height: 8),
            Text('• Toca el botón + para crear un nuevo evento'),
            Text('• Selecciona una fecha en el calendario para ver los eventos'),
            Text('• Toca un evento para editarlo'),
            Text('• Usa el menú de configuración para gestionar miembros'),
            SizedBox(height: 8),
            Text('Para más ayuda, contacta al soporte.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Calendario Familiar',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.calendar_today, size: 48),
      children: const [
        Text('Una aplicación para organizar eventos familiares compartidos.'),
        SizedBox(height: 8),
        Text('Desarrollado con Flutter y Firebase.'),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cerrar sesión: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
