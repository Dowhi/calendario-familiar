import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:calendario_familiar/core/models/shift_template.dart';
import 'package:calendario_familiar/core/services/calendar_data_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ShiftTemplateManagementScreen extends ConsumerStatefulWidget {
  const ShiftTemplateManagementScreen({super.key});

  @override
  ConsumerState<ShiftTemplateManagementScreen> createState() => _ShiftTemplateManagementScreenState();
}

class _ShiftTemplateManagementScreenState extends ConsumerState<ShiftTemplateManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _name = '';
  String _colorHex = '#3B82F6'; // Default blue
  String _startTime = '08:00';
  String _endTime = '16:00';
  String? _description;

  void _pickColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: Color(int.parse(_colorHex.substring(1, 7), radix: 16) + 0xFF000000),
            onColorChanged: (color) {
              setState(() {
                _colorHex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
              });
            },
            enableAlpha: false,
            displayThumbColor: true,
            paletteType: PaletteType.hsvWithSaturation, // Corregido aquí
            labelTypes: const [],
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final initialTime = TimeOfDay(hour: int.parse(isStartTime ? _startTime.split(':')[0] : _endTime.split(':')[0]),
                                  minute: int.parse(isStartTime ? _startTime.split(':')[1] : _endTime.split(':')[1]));
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isStartTime) {
          _startTime = formattedTime;
        } else {
          _endTime = formattedTime;
        }
      });
    }
  }

  void _addShiftTemplate() async {
    print('🔧 _addShiftTemplate iniciado');
    
    // Verificar si estamos editando
    if (_editingTemplateId != null) {
      print('🔧 Modo edición detectado, llamando a _updateShiftTemplate');
      await _updateShiftTemplate(_editingTemplateId!);
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      print('❌ Validación del formulario falló');
      return;
    }
    
    _formKey.currentState!.save();
    
    print('🔧 Datos del formulario:');
    print('🔧 Nombre: $_name');
    print('🔧 Color: $_colorHex');
    print('🔧 Hora inicio: $_startTime');
    print('🔧 Hora fin: $_endTime');
    print('🔧 Descripción: $_description');
    
    final newTemplate = ShiftTemplate(
      id: '', // ID será generado por Firebase
      name: _name,
      colorHex: _colorHex,
      startTime: _startTime,
      endTime: _endTime,
      description: _description,
    );
    
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      await ref.read(calendarDataServiceProvider).addShiftTemplate(newTemplate);
      
      // Ocultar indicador de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Plantilla "${_name}" agregada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Limpiar el formulario para agregar otro turno
        _clearForm();
        
        // No cerrar la pantalla, dejar que se actualice automáticamente
      }
    } catch (e) {
      print('❌ Error en _addShiftTemplate: $e');
      
      // Ocultar indicador de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al agregar plantilla: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _editingTemplateId; // Variable para rastrear si estamos editando

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _editShiftTemplate(ShiftTemplate template) {
    print('🔧 _editShiftTemplate iniciado para: ${template.name}');
    
    // Cargar datos de la plantilla en el formulario
    setState(() {
      _editingTemplateId = template.id; // Marcar que estamos editando
      _name = template.name;
      _colorHex = template.colorHex;
      _startTime = template.startTime;
      _endTime = template.endTime;
      _description = template.description;
    });
    
    // Cargar datos en los controladores
    _nameController.text = template.name;
    _descriptionController.text = template.description ?? '';
    
    // Mostrar mensaje informativo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📝 Editando plantilla "${template.name}". Modifica los campos y presiona "Actualizar Plantilla".'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearForm() {
    setState(() {
      _editingTemplateId = null; // Limpiar modo edición
      _name = '';
      _colorHex = '#3B82F6';
      _startTime = '08:00';
      _endTime = '16:00';
      _description = null;
    });
    
    // Limpiar los controladores de texto
    _nameController.clear();
    _descriptionController.clear();
    
    // Limpiar también los campos del formulario visualmente
    if (_formKey.currentState != null) {
      _formKey.currentState!.reset();
    }
  }

  Future<void> _updateShiftTemplate(String templateId) async {
    print('🔧 _updateShiftTemplate iniciado para ID: $templateId');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ Validación del formulario falló');
      return;
    }
    
    _formKey.currentState!.save();
    
    final updatedTemplate = ShiftTemplate(
      id: templateId,
      name: _name,
      colorHex: _colorHex,
      startTime: _startTime,
      endTime: _endTime,
      description: _description,
    );
    
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      await ref.read(calendarDataServiceProvider).updateShiftTemplate(updatedTemplate);
      
      // Ocultar indicador de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Plantilla "${_name}" actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Limpiar el formulario
        _clearForm();
      }
    } catch (e) {
      print('❌ Error en _updateShiftTemplate: $e');
      
      // Ocultar indicador de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al actualizar plantilla: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteShiftTemplate(ShiftTemplate template) async {
    print('🔧 _deleteShiftTemplate iniciado para: ${template.name}');
    
    // Mostrar diálogo de confirmación
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Plantilla'),
        content: Text('¿Estás seguro de que quieres eliminar la plantilla "${template.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirm != true) {
      print('🔧 Eliminación cancelada por el usuario');
      return;
    }
    
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      await ref.read(calendarDataServiceProvider).deleteShiftTemplate(template.id);
      
      // Ocultar indicador de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Plantilla "${template.name}" eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error en _deleteShiftTemplate: $e');
      
      // Ocultar indicador de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al eliminar plantilla: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final calendarService = ref.watch(calendarDataServiceProvider); // Usar ref.watch

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Plantillas de Turnos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre del Turno'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese un nombre';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _name = value!;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Hora de Inicio'),
                            child: Text(_startTime),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Hora Fin'),
                            child: Text(_endTime),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                          onSaved: (value) {
                            _description = value;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _pickColor(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(int.parse(_colorHex.substring(1, 7), radix: 16) + 0xFF000000),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (_editingTemplateId != null) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearForm,
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _addShiftTemplate,
                          child: Text(_editingTemplateId != null ? 'Actualizar Plantilla de Turno' : 'Agregar Plantilla de Turno'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: calendarService.shiftTemplates.length,
                itemBuilder: (context, index) {
                  final template = calendarService.shiftTemplates[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Color(int.parse(template.colorHex.substring(1, 7), radix: 16) + 0xFF000000),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(template.name),
                      subtitle: Text('${template.startTime} - ${template.endTime}' + (template.description != null ? ' (${template.description})' : '')),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _editShiftTemplate(template);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await _deleteShiftTemplate(template);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
