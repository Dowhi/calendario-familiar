import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:calendario_familiar/core/models/shift_template.dart';
import 'package:calendario_familiar/core/services/firestore_service.dart';
// Eliminado: import auth_controller (ya no se utiliza)

class AvailableShiftsScreen extends ConsumerStatefulWidget {
  const AvailableShiftsScreen({super.key});

  @override
  ConsumerState<AvailableShiftsScreen> createState() => _AvailableShiftsScreenState();
}

class _AvailableShiftsScreenState extends ConsumerState<AvailableShiftsScreen> {
  List<ShiftTemplate> _shiftTemplates = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadShiftTemplates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar turnos cuando se regrese de otra pantalla
    _loadShiftTemplates();
  }

  Future<void> _loadShiftTemplates() async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      // Eliminado: obtención de familyId desde authController (ya no se utiliza)
      final familyId = 'default_family'; // FamilyId fijo sin autenticación

      final shiftsData = await firestoreService.getShiftTemplates(familyId: familyId);
      
      List<ShiftTemplate> firebaseShifts = [];
      if (shiftsData.isNotEmpty) {
        firebaseShifts = shiftsData
            .map((data) => ShiftTemplate.fromJson(data))
            .toList();
      }
      
      // Si no hay turnos en Firebase, usar los de ejemplo
      if (firebaseShifts.isEmpty) {
        firebaseShifts = _getExampleShiftTemplates();
      }
      
      if (mounted) {
        setState(() {
          _shiftTemplates = firebaseShifts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando turnos de Firebase: $e');
      if (mounted) {
        setState(() {
          _shiftTemplates = _getExampleShiftTemplates();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando turnos de Firebase: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  List<ShiftTemplate> _getExampleShiftTemplates() {
    return [
      const ShiftTemplate(
        id: '1',
        name: 'Nuevo',
        abbreviation: 'F.A.',
        colorHex: '#B71C1C',
        textColorHex: '#FFFFFF',
        textSize: 16.0,
        startTime: '08:00',
        endTime: '16:00',
        description: 'Turno nuevo para implementar',
      ),
      const ShiftTemplate(
        id: '2',
        name: 'S. Santa',
        abbreviation: 'S.Santa',
        colorHex: '#1976D2',
        textColorHex: '#FFFFFF',
        textSize: 16.0,
        startTime: '06:00',
        endTime: '14:00',
        description: 'Turno de Semana Santa',
      ),
      const ShiftTemplate(
        id: '3',
        name: 'Feria',
        abbreviation: 'Feria',
        colorHex: '#2196F3',
        textColorHex: '#FFFFFF',
        textSize: 16.0,
        startTime: '10:00',
        endTime: '18:00',
        description: 'Turno de feria',
      ),
      const ShiftTemplate(
        id: '4',
        name: 'Descanso',
        abbreviation: 'Descanso',
        colorHex: '#388E3C',
        textColorHex: '#FFFFFF',
        textSize: 16.0,
        startTime: '00:00',
        endTime: '00:00',
        description: 'Día de descanso',
      ),
      const ShiftTemplate(
        id: '5',
        name: 'D1',
        abbreviation: 'D1',
        colorHex: '#1976D2',
        textColorHex: '#FFFFFF',
        textSize: 16.0,
        startTime: '08:00',
        endTime: '20:00',
        description: 'Día 1 - Turno diurno',
      ),
      const ShiftTemplate(
        id: '6',
        name: 'D2',
        abbreviation: 'D2',
        colorHex: '#D32F2F',
        textColorHex: '#FFFFFF',
        textSize: 16.0,
        startTime: '20:00',
        endTime: '08:00',
        description: 'Día 2 - Turno nocturno',
      ),
      const ShiftTemplate(
        id: '7',
        name: 'Tarde',
        abbreviation: 'T',
        colorHex: '#FF9800',
        textColorHex: '#FFFFFF',
        textSize: 16.0,
        startTime: '14:00',
        endTime: '22:00',
        description: 'Turno de tarde',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_downward, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'TURNOS DISPONIBLES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'CREAR TURNO NUEVO',
                    Icons.add,
                    () {
                      context.push('/shift-configuration');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'IMPORTAR TURNOS...',
                    Icons.upload,
                    () {
                      // TODO: Implementar importación de turnos
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Función en desarrollo')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de turnos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _shiftTemplates.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.work_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay turnos disponibles',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Crea tu primer turno',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _shiftTemplates.length,
                        itemBuilder: (context, index) {
                          final template = _shiftTemplates[index];
                          return _buildShiftItem(template);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftItem(ShiftTemplate template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getShiftColor(template),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              _getShiftAbbreviation(template),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          template.abbreviation.isNotEmpty ? template.abbreviation : template.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${template.startTime} - ${template.endTime}',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert, color: Colors.grey[400]),
          onPressed: () {
            _showShiftOptions(template);
          },
        ),
        onTap: () {
          context.push('/shift-configuration', extra: template);
        },
      ),
    );
  }

  Color _getShiftColor(ShiftTemplate template) {
    // Usar el color real del template en lugar de generar uno automáticamente
    try {
      return Color(int.parse(template.colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      // Si hay error al parsear el color, usar color por defecto
      print('❌ Error parseando color ${template.colorHex}: $e');
      return Colors.grey;
    }
  }

  String _getShiftAbbreviation(ShiftTemplate template) {
    // Usar la abreviatura del template si existe
    if (template.abbreviation.isNotEmpty) {
      return template.abbreviation;
    }
    
    // Fallback: generar abreviatura basada en el nombre
    final name = template.name.toLowerCase();
    if (name.contains('d1') || name.contains('día 1')) return 'D1';
    if (name.contains('d2') || name.contains('día 2')) return 'D2';
    if (name.contains('libre')) return 'L';
    if (name.contains('feria')) return 'Feria';
    if (name.contains('santa')) return 'S.Santa';
    if (name.contains('descanso')) return 'Descanso';
    if (name.contains('tarde')) return 'T';
    if (name.contains('nuevo')) return 'F.A.';
    
    // Abreviación por defecto (primeras letras)
    return template.name.length > 8 
        ? template.name.substring(0, 8).toUpperCase()
        : template.name.toUpperCase();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showShiftOptions(ShiftTemplate template) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[800],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text('Editar', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Navegar a la pantalla de configuración con el template para editar
                context.push('/shift-configuration', extra: template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.white),
              title: const Text('Duplicar', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar duplicación
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función en desarrollo')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(template);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showShiftDetails(ShiftTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: Text(
          template.name,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (template.description != null && template.description!.isNotEmpty)
              Text(
                template.description!,
                style: TextStyle(color: Colors.grey[300]),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${template.startTime} - ${template.endTime}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.palette, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _getShiftColor(template),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Color: ${_getShiftColor(template).toString()}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ShiftTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text(
          'Eliminar Turno',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar el turno "${template.name}"?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteShift(template);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteShift(ShiftTemplate template) async {
    // Mostrar diálogo de opciones de eliminación
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text(
          'Eliminar Turno',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Qué quieres eliminar del turno "${template.name}"?',
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            const Text(
              '• Solo la plantilla: Elimina únicamente la plantilla del turno',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Plantilla y turnos asignados: Elimina la plantilla y todos los turnos ya asignados en el calendario',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'template_only'),
            child: const Text('Solo plantilla', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'template_and_shifts'),
            child: const Text('Plantilla y turnos', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == null || result == 'cancel') {
      return;
    }

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      
      if (result == 'template_only') {
        // Eliminar solo la plantilla (sin limpiar turnos asignados)
        await firestoreService.deleteShiftTemplateOnly(template.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Plantilla "${template.name}" eliminada (turnos asignados conservados)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (result == 'template_and_shifts') {
        // Eliminar plantilla y limpiar turnos asignados
        await firestoreService.deleteShiftTemplate(template.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Plantilla "${template.name}" y todos los turnos asignados eliminados'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      setState(() {
        _shiftTemplates.removeWhere((t) => t.id == template.id);
      });
      
    } catch (e) {
      print('❌ Error eliminando turno de Firebase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error eliminando turno de Firebase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
