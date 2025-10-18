import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// Eliminado: import app_user, auth_controller (ya no se utiliza)
// Eliminado: import calendar_controller (ya no se utiliza)
import 'package:calendario_familiar/core/services/calendar_data_service.dart';
import 'package:calendario_familiar/core/services/notification_service.dart';
import 'package:calendario_familiar/core/providers/text_size_provider.dart';
import 'package:calendario_familiar/core/providers/theme_provider.dart';
import 'package:calendario_familiar/core/services/alarm_service.dart';
import 'package:calendario_familiar/core/models/app_event.dart';

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
  
  Future<void> _requestBatteryOptimizationDisable() async {
    try {
      if (Platform.isAndroid) {
        // Abrir la configuración de optimización de batería
        final status = await Permission.ignoreBatteryOptimizations.status;
        
        if (status.isDenied) {
          await Permission.ignoreBatteryOptimizations.request();
        }
        
        // Abrir la configuración del sistema para que el usuario lo haga manualmente
        await openAppSettings();
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('⚠️ IMPORTANTE'),
              content: const Text(
                'Para que las alarmas funcionen con la app cerrada:\n\n'
                '1. En la pantalla que se abrió, busca "Batería" o "Battery"\n'
                '2. Selecciona "Sin restricciones" o "No optimizar"\n'
                '3. También busca "Inicio automático" y actívalo\n\n'
                'Sin esto, Android cancelará las alarmas.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error solicitando exclusión de batería: $e');
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
    // Eliminado: referencias a authController y calendarController (ya no se utiliza)

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
      body: ListView(
        children: [
          // Eliminado: sección de usuario (ya no se utiliza)
          
          // Eliminado: sección de calendario familiar (ya no se utiliza)
          
          // Configuración de apariencia
          _buildAppearanceSection(context),
          
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

  // Eliminado: _buildUserSection (ya no se utiliza)

  // Eliminado: _buildCalendarSection - movido a _buildAppearanceSection (ya no se utiliza)
  
  Widget _buildAppearanceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Apariencia',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Control de tamaño de texto de eventos
        Consumer(
          builder: (context, ref, child) {
            final eventTextSize = ref.watch(eventTextSizeProvider);
            return ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Tamaño del texto de eventos'),
              subtitle: Text('${eventTextSize.round()} puntos'),
              trailing: SizedBox(
                width: 100,
                child: Slider(
                  value: eventTextSize,
                  min: 8.0,
                  max: 24.0,
                  divisions: 16,
                  activeColor: Colors.teal,
                  inactiveColor: Colors.grey[300],
                  onChanged: (value) {
                    ref.read(eventTextSizeProvider.notifier).setTextSize(value);
                  },
                ),
              ),
            );
          },
        ),
        // Control de tema claro/oscuro
        Consumer(
          builder: (context, ref, child) {
            final isDarkMode = ref.watch(themeProvider);
            return SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: const Text('Modo oscuro'),
              subtitle: Text(isDarkMode ? 'Activado' : 'Desactivado'),
              value: isDarkMode,
              onChanged: (value) {
                ref.read(themeProvider.notifier).setTheme(value);
              },
            );
          },
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
        ListTile(
          leading: const Icon(Icons.alarm_on),
          title: const Text('Probar alarma (5s)'),
          subtitle: const Text('Programa una alarma de prueba en 5 segundos'),
          onTap: () async {
            print('🚨 BOTÓN DE ALARMA PRESIONADO');
            try {
              final now = DateTime.now().add(const Duration(seconds: 5));
              print('🚨 Hora programada: $now');
              final demo = AppEvent(
                id: 'demo-alarm-5s',
                familyId: 'default_family', // FamilyId fijo sin autenticación
                title: 'Alarma de prueba (5s)',
                dateKey: '${now.year}-${now.month}-${now.day}',
              );
              print('🚨 Evento creado: ${demo.title}');
              await AlarmService.scheduleAlarm(event: demo, fireAt: now, notes: 'Demostración de 5 segundos');
              print('🚨 AlarmService.scheduleAlarm completado');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alarma programada en 5 segundos')),
                );
              }
            } catch (e, stackTrace) {
              print('🚨 ERROR al programar alarma: $e');
              print('🚨 StackTrace: $stackTrace');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al programar alarma: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.alarm_on),
          title: const Text('Probar alarma (30s)'),
          subtitle: const Text('Programa una alarma de prueba en 30 segundos'),
          onTap: () async {
            print('🚨 BOTÓN DE ALARMA PRESIONADO');
            try {
              final now = DateTime.now().add(const Duration(seconds: 30));
              print('🚨 Hora programada: $now');
              final demo = AppEvent(
                id: 'demo-alarm-30s',
                familyId: 'default_family', // FamilyId fijo sin autenticación
                title: 'Alarma de prueba (30s)',
                dateKey: '${now.year}-${now.month}-${now.day}',
              );
              print('🚨 Evento creado: ${demo.title}');
              await AlarmService.scheduleAlarm(event: demo, fireAt: now, notes: 'Demostración de 30 segundos');
              print('🚨 AlarmService.scheduleAlarm completado');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alarma programada en 30 segundos')),
                );
              }
            } catch (e, stackTrace) {
              print('🚨 ERROR al programar alarma: $e');
              print('🚨 StackTrace: $stackTrace');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al programar alarma: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.alarm),
          title: const Text('Ver pantalla de alarma (INMEDIATO)'),
          subtitle: const Text('Abre la pantalla de alarma directamente'),
          onTap: () {
            context.go('/alarm?title=Prueba%20Inmediata&notes=Esta%20es%20una%20prueba&dateKey=2025-10-12');
          },
        ),
        ListTile(
          leading: const Icon(Icons.battery_alert),
          title: const Text('Desactivar optimización de batería'),
          subtitle: const Text('NECESARIO para que funcionen las alarmas'),
          trailing: const Icon(Icons.open_in_new),
          onTap: _requestBatteryOptimizationDisable,
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
        // Eliminado: botón de cerrar sesión (ya no se utiliza)
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

  // Eliminado: _showLogoutDialog (ya no se utiliza)
}
