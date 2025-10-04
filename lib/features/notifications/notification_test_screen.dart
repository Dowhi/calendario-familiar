import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:calendario_familiar/core/services/unified_reminder_service.dart';

/// Pantalla de prueba de notificaciones
class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _isLoading = false;
  final List<String> _logs = [];
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _logs.add('Inicializando servicio...');
    });
    
    final initialized = await UnifiedReminderService.initialize();
    
    setState(() {
      _isInitialized = initialized;
      _logs.add(initialized ? '✅ Servicio inicializado' : '❌ Error en inicialización');
    });
    
    if (initialized) {
      await _checkPermissions();
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _checkPermissions() async {
    final enabled = await UnifiedReminderService.areNotificationsEnabled();
    
    setState(() {
      _hasPermission = enabled;
      _logs.add(enabled ? '✅ Permisos concedidos' : '⚠️ Sin permisos');
    });
  }
  
  Future<void> _testNotification(Duration delay) async {
    setState(() {
      _logs.add('📅 Programando notificación para ${delay.inSeconds}s...');
    });
    
    final scheduledTime = DateTime.now().add(delay);
    
    final success = await UnifiedReminderService.scheduleReminder(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      scheduledTime: scheduledTime,
      title: '🔔 Prueba de Notificación',
      body: 'Esta notificación se programó para ${delay.inSeconds} segundos',
    );
    
    setState(() {
      if (success) {
        _logs.add('✅ Notificación programada correctamente');
        _logs.add('⏰ Se mostrará a las ${_formatTime(scheduledTime)}');
      } else {
        _logs.add('❌ Error programando notificación');
      }
    });
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Notificaciones'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Estado
                _buildStatusSection(),
                
                const Divider(height: 1),
                
                // Botones de prueba
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Pruebas de Notificación',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildTestButton(
                        'Notificación en 10 segundos',
                        Icons.timer_10,
                        const Duration(seconds: 10),
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildTestButton(
                        'Notificación en 30 segundos',
                        Icons.timer_3,
                        const Duration(seconds: 30),
                        Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildTestButton(
                        'Notificación en 1 minuto',
                        Icons.timer,
                        const Duration(minutes: 1),
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildTestButton(
                        'Notificación en 2 minutos',
                        Icons.timer_outlined,
                        const Duration(minutes: 2),
                        Colors.purple,
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // Log de actividad
                Expanded(
                  child: _buildLogSection(),
                ),
              ],
            ),
    );
  }
  
  Widget _buildStatusSection() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isInitialized ? Icons.check_circle : Icons.cancel,
                color: _isInitialized ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              const Text(
                'Servicio Inicializado',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(
                _hasPermission ? Icons.notifications_active : Icons.notifications_off,
                color: _hasPermission ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              const Text(
                'Permisos de Notificación',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(
                kIsWeb ? Icons.web : Icons.phone_android,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                'Plataforma: ${kIsWeb ? "PWA (Web)" : "Móvil"}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          
          if (!_hasPermission) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      kIsWeb
                          ? 'Concede permisos de notificación en tu navegador'
                          : 'Concede permisos en la configuración del sistema',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (kIsWeb) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Las notificaciones PWA funcionan incluso con la app cerrada usando Service Worker',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTestButton(String label, IconData icon, Duration delay, Color color) {
    return ElevatedButton.icon(
      onPressed: _isInitialized && _hasPermission
          ? () => _testNotification(delay)
          : null,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBackgroundColor: Colors.grey[300],
        disabledForegroundColor: Colors.grey[600],
      ),
    );
  }
  
  Widget _buildLogSection() {
    return Container(
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Log de Actividad',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                    });
                  },
                  icon: const Icon(Icons.clear, size: 16, color: Colors.white70),
                  label: const Text(
                    'Limpiar',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'Sin actividad',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[_logs.length - 1 - index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${DateTime.now().toString().substring(11, 19)} $log',
                          style: TextStyle(
                            color: log.contains('❌') ? Colors.red[300] :
                                   log.contains('✅') ? Colors.green[300] :
                                   log.contains('⚠️') ? Colors.orange[300] :
                                   Colors.white70,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

