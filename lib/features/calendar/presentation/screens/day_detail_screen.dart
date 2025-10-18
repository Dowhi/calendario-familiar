import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendario_familiar/core/services/calendar_data_service.dart';
import 'package:calendario_familiar/features/calendar/presentation/widgets/alarm_settings_dialog.dart';
import 'package:calendario_familiar/core/widgets/custom_icons.dart';
import 'package:calendario_familiar/core/providers/current_user_provider.dart';

class DayDetailScreen extends ConsumerStatefulWidget {
  final DateTime date;
  final String? existingText;
  final String? existingEventId;

  const DayDetailScreen({
    Key? key,
    required this.date,
    this.existingText,
    this.existingEventId,
  }) : super(key: key);

  @override
  ConsumerState<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends ConsumerState<DayDetailScreen> {
  late TextEditingController _eventTextController;
  String _selectedCategory1 = 'Ninguno';
  String _selectedCategory2 = 'Ninguno';
  String _selectedCategory3 = 'Ninguno';
  bool _isEditingEvent = false;
  
  // Lista de categorías con iconos nativos de Flutter
  final List<Map<String, dynamic>> _categories1 = [
    {'name': 'Ninguno', 'icon': Icons.not_interested},
    {'name': 'Cambio de turno', 'icon': Icons.swap_horiz},
    {'name': 'Ingreso', 'icon': Icons.euro_symbol},
    {'name': 'Importante', 'icon': Icons.warning},
    {'name': 'Festivo', 'icon': Icons.wb_sunny},
    {'name': 'Médico', 'icon': Icons.medical_services},
    {'name': 'Cumpleaños', 'icon': Icons.pets},
    {'name': 'Favorito', 'icon': Icons.star},
    {'name': 'Coche', 'icon': Icons.directions_car},
  ];
  
  final List<Map<String, dynamic>> _categories2 = [
    {'name': 'Ninguno', 'icon': Icons.not_interested},
    {'name': 'Cambio de turno', 'icon': Icons.swap_horiz},
    {'name': 'Ingreso', 'icon': Icons.euro_symbol},
    {'name': 'Importante', 'icon': Icons.warning},
    {'name': 'Festivo', 'icon': Icons.wb_sunny},
    {'name': 'Médico', 'icon': Icons.medical_services},
    {'name': 'Cumpleaños', 'icon': Icons.pets},
    {'name': 'Favorito', 'icon': Icons.star},
    {'name': 'Coche', 'icon': Icons.directions_car},
  ];
  
  final List<Map<String, dynamic>> _categories3 = [
    {'name': 'Ninguno', 'icon': Icons.not_interested},
    {'name': 'Cambio de turno', 'icon': Icons.swap_horiz},
    {'name': 'Ingreso', 'icon': Icons.euro_symbol},
    {'name': 'Importante', 'icon': Icons.warning},
    {'name': 'Festivo', 'icon': Icons.wb_sunny},
    {'name': 'Médico', 'icon': Icons.medical_services},
    {'name': 'Cumpleaños', 'icon': Icons.pets},
    {'name': 'Favorito', 'icon': Icons.star},
    {'name': 'Coche', 'icon': Icons.directions_car},
  ];

  @override
  void initState() {
    super.initState();
    
    // Inicializar el controlador con texto vacío
    _eventTextController = TextEditingController();
    
    // Cargar categorías existentes si las hay
    _loadExistingCategories();
    
    // Cargar notas existentes desde Firebase
    _loadExistingNotes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No cargar notas aquí para evitar que se sobrescriba el texto del usuario
  }

  void _loadExistingNotes() {
    // Solo cargar notas si el controlador está vacío para evitar sobrescribir texto del usuario
    if (_eventTextController.text.isNotEmpty) {
      print('📝 Controlador ya tiene texto, no cargando notas existentes');
      return;
    }
    
    final dataService = ref.read(calendarDataServiceProvider);
    final notes = dataService.getNotes();
    final dateKey = _formatDate(widget.date);
    
    // Buscar notas para este día específico
    final notesForDay = notes[dateKey] ?? [];
    
    if (notesForDay.isNotEmpty) {
      // Tomar la primera nota (asumiendo que solo hay una nota por día)
      final existingNote = notesForDay.first;
      _eventTextController.text = existingNote;
      setState(() {
        _isEditingEvent = true; // Siempre true si hay una nota existente
      });
      print('📝 Nota cargada desde Firebase: $existingNote, _isEditingEvent: $_isEditingEvent');
    } else {
      // Si no hay notas, verificar si hay texto existente (para compatibilidad)
      String? noteText = widget.existingText;
      if (noteText != null && !dataService.isPredefinedShift(noteText)) {
        _eventTextController.text = noteText;
        setState(() {
          _isEditingEvent = true; // Siempre true si hay texto existente
        });
        print('📝 Nota cargada desde existingText: $noteText, _isEditingEvent: $_isEditingEvent');
      } else {
        _eventTextController.clear();
        setState(() {
          _isEditingEvent = false; // False solo si no hay notas existentes
        });
        print('📝 No hay notas existentes para este día, _isEditingEvent: $_isEditingEvent');
      }
    }
  }

  void _loadExistingCategories() {
    final dataService = ref.read(calendarDataServiceProvider);
    final dateKey = _formatDate(widget.date);
    final categories = dataService.getDayCategoriesForDate(widget.date);
    
    setState(() {
      _selectedCategory1 = categories['category1'] ?? 'Ninguno';
      _selectedCategory2 = categories['category2'] ?? 'Ninguno';
      _selectedCategory3 = categories['category3'] ?? 'Ninguno';
    });
  }

  void _clearNoteField() {
    setState(() {
      _eventTextController.clear();
      _isEditingEvent = false;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _saveEvent() async {
    final String eventText = _eventTextController.text.trim();
    final DateTime eventDate = widget.date;
    final dataService = ref.read(calendarDataServiceProvider);

    print('🔍 DEBUG _saveEvent:');
    print('  - eventText: "$eventText"');
    print('  - eventText.isEmpty: ${eventText.isEmpty}');
    print('  - _isEditingEvent: $_isEditingEvent');
    print('  - _eventTextController.text: "${_eventTextController.text}"');

    if (eventText.isNotEmpty) {
      print('📝 Procesando texto NO vacío');
      if (_isEditingEvent) {
        // Buscar el ID de la nota existente
        final noteId = await _getExistingNoteId(eventDate, dataService);
        print('  - noteId encontrado: $noteId');
        if (noteId != null) {
          // Actualizar nota existente
          await dataService.updateNote(
            noteId: noteId,
            date: eventDate,
            title: eventText,
          );
          print('📝 Nota actualizada con ID: $noteId');
        } else {
          // Si no se encuentra el ID, crear nueva nota
          await dataService.addNote(
            date: eventDate,
            title: eventText,
          );
          print('📝 Nueva nota creada');
        }
      } else {
        // Añadir nueva nota usando el método específico
        await dataService.addNote(
          date: eventDate,
          title: eventText,
        );
        print('📝 Nueva nota creada');
      }
    } else {
      print('📝 Procesando texto VACÍO');
      // Si el texto está vacío y estamos editando una nota existente, eliminarla
      if (_isEditingEvent) {
        print('  - _isEditingEvent es true, buscando nota para eliminar');
        final noteId = await _getExistingNoteId(eventDate, dataService);
        print('  - noteId encontrado para eliminar: $noteId');
        if (noteId != null) {
          await dataService.deleteNote(
            noteId: noteId,
            date: eventDate,
          );
          print('📝 Nota eliminada con ID: $noteId');
        } else {
          print('❌ No se encontró noteId para eliminar');
        }
      } else {
        print('❌ _isEditingEvent es false, no se elimina nada');
      }
    }
    
    // Guardar categorías seleccionadas
    // Si la categoría es "Ninguno", pasar null para eliminarla
    await dataService.setDayCategory(eventDate, 'category1', _selectedCategory1 == 'Ninguno' ? null : _selectedCategory1);
    await dataService.setDayCategory(eventDate, 'category2', _selectedCategory2 == 'Ninguno' ? null : _selectedCategory2);
    await dataService.setDayCategory(eventDate, 'category3', _selectedCategory3 == 'Ninguno' ? null : _selectedCategory3);

    Navigator.of(context).pop(eventText); // Regresar el texto como resultado
  }

  Future<String?> _getExistingNoteId(DateTime date, CalendarDataService dataService) async {
    return await dataService.getExistingNoteId(date);
  }
  
  void _showAlarmDialog(BuildContext context) {
    // Obtener el texto del evento (nota)
    final eventText = _eventTextController.text.isNotEmpty 
        ? _eventTextController.text 
        : "Recordatorio";
    
    // Mostrar el diálogo de alarma con la nueva interfaz
    showDialog(
      context: context,
      builder: (context) => AlarmSettingsDialog(
        selectedDate: widget.date,
        eventText: eventText,
      ),
    );
  }

  @override
  void dispose() {
    _eventTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataService = ref.watch(calendarDataServiceProvider);
    final events = dataService.getEventsForDay(widget.date);
    final shifts = events.where((event) => dataService.isPredefinedShift(event)).toList();
    final notes = events.where((event) => !dataService.isPredefinedShift(event)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.date.day}/${widget.date.month}/${widget.date.year.toString().substring(2)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Sección de Card para introducir NOTAS
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(Icons.note_add, size: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _eventTextController,
                      decoration: InputDecoration(
                        hintText: 'Añadir nota...',
                        hintStyle: const TextStyle(fontSize: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: false,
                      ),
                      maxLines: 4,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Sección del día (número) con icono de alarma
            Row(
              children: [
                // Primer IconButton
                IconButton(
                  icon: CustomIcons.fireCloudIcon(
                    size: 40,
                    color: Colors.red,
                  ),
                  onPressed: () => _showAlarmDialog(context),
                  tooltip: 'Programar alarma',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),

                // Contenedor principal de la parte derecha: Texto y número
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                                             // TextButton con texto
                       TextButton(
                         onPressed: () => _showAlarmDialog(context),
                         child: Text(
                           'Aviso de Alarma',
                           style: TextStyle(
                             fontSize: 14,
                             fontWeight: FontWeight.bold,
                             color: Colors.red,
                           ),
                         ),
                       ),

                      // Número del día (alineado a la derecha gracias a Expanded + MainAxisAlignment.spaceBetween)
                      Text(
                        widget.date.day.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Sección de turnos
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título de la sección
                  Text(
                    'Turnos del día',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Lista de turnos con colores
                  if (shifts.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No hay turnos asignados',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...shifts.map((shiftName) {
                      final template = dataService.getShiftTemplateByName(shiftName);
                      final color = template?.colorHex != null
                          ? Color(int.parse(template!.colorHex.substring(1, 7), radix: 16) + 0xFF000000)
                          : Colors.grey;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          border: Border.all(color: color, width: 1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                shiftName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                      
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Sección de categorías - CORREGIDA PARA EVITAR OVERFLOW
            // Sección de categorías - CORREGIDA PARA EVITAR OVERFLOW
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categorías',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Usar Wrap con Flexible en lugar de Row o SizedBox
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      // Categoría 1
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.28,
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory1,
                          isExpanded: true, // 👈 importante
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                            isDense: true,
                            labelText: 'Cat. 1',
                            labelStyle: const TextStyle(fontSize: 8, color: Colors.grey),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                          ),
                          style: const TextStyle(fontSize: 9, color: Colors.black87),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategory1 = newValue ?? 'Ninguno';
                            });
                          },
                          items: _categories1.map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
                            return DropdownMenuItem<String>(
                              value: item['name'],
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (item['icon'] != null)
                                    Icon(item['icon'], size: 10, color: Colors.grey[700]),
                                  if (item['icon'] != null) const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      item['name'],
                                      style: const TextStyle(fontSize: 8, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Categoría 2
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.28,
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory2,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                            isDense: true,
                            labelText: 'Cat. 2',
                            labelStyle: const TextStyle(fontSize: 8, color: Colors.grey),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                          ),
                          style: const TextStyle(fontSize: 9, color: Colors.black87),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategory2 = newValue ?? 'Ninguno';
                            });
                          },
                          items: _categories2.map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
                            return DropdownMenuItem<String>(
                              value: item['name'],
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (item['icon'] != null)
                                    Icon(item['icon'], size: 10, color: Colors.grey[700]),
                                  if (item['icon'] != null) const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      item['name'],
                                      style: const TextStyle(fontSize: 8, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Categoría 3
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.28,
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory3,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                            isDense: true,
                            labelText: 'Cat. 3',
                            labelStyle: const TextStyle(fontSize: 8, color: Colors.grey),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                          ),
                          style: const TextStyle(fontSize: 9, color: Colors.black87),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategory3 = newValue ?? 'Ninguno';
                            });
                          },
                          items: _categories3.map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
                            return DropdownMenuItem<String>(
                              value: item['name'],
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (item['icon'] != null)
                                    Icon(item['icon'], size: 10, color: Colors.grey[700]),
                                  if (item['icon'] != null) const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      item['name'],
                                      style: const TextStyle(fontSize: 8, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // Botones Cancelar y Aceptar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    child: const Text('CANCELAR', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green[700],
                      side: BorderSide(color: Colors.green[700]!, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('ACEPTAR', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
