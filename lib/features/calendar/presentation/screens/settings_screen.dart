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

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hasPermissions = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatus();
  }

  Future<void> _loadPermissionStatus() async {
    try {
      final hasPermissions = await NotificationService.areNotificationsEnabled();
      setState(() {
        _hasPermissions = hasPermissions;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error cargando estado de permisos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      print('🔧 Usuario solicitando permisos...');
      final granted = await NotificationService.requestPermissions();
      print('🔧 Resultado de solicitud de permisos: $granted');
      
      setState(() {
        _hasPermissions = granted;
      });
      
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
                    : 'Permisos de notificación necesarios para alarmas',
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
        
        const SizedBox(height: 16),
        
        // Prueba de notificaciones
        ListTile(
          leading: const Icon(Icons.notifications_active),
          title: const Text('Probar notificación'),
          subtitle: const Text('Enviar notificación de prueba'),
          trailing: IconButton(
            icon: const Icon(Icons.send),
            onPressed: _testNotification,
          ),
          onTap: _testNotification,
        ),
      ],
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
