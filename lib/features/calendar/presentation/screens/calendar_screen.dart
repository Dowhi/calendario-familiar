import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/day_detail_screen.dart';
import 'package:calendario_familiar/core/services/calendar_data_service.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  bool _isPaintMode = false;
  String? _selectedPaintOption; // Ahora almacena el ID o nombre de la plantilla

  // Inicializar con el mes actual
  DateTime get _currentMonth => DateTime.now();

  // Servicios
  late final CalendarDataService _dataService;

  // Mapa para almacenar categorías por día
  final Map<String, Map<String, String?>> _dayCategories = {};

  // Método para obtener el icono de la categoría
  IconData? _getCategoryIcon(String? category) {
    switch (category) {
      case 'Cambio de turno':
        return Icons.swap_horiz;
      case 'Ingreso':
        return Icons.attach_money;
      case 'Importante':
        return Icons.priority_high;
      case 'Festivo':
        return Icons.celebration;
      case 'Médico':
        return Icons.medical_services;
      case 'Mascota':
        return Icons.pets;
      case 'Favorito':
        return Icons.favorite;
      case 'Coche':
        return Icons.directions_car;
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Inicializar con el mes actual
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();

    // _dataService se inicializa en didChangeDependencies o build
    // No es necesario un listener aquí directamente, ya que usaremos ref.watch
    print('📱 CalendarScreen inicializada');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = ref.watch(calendarDataServiceProvider); // Inicializar _dataService aquí
  }

  @override
  void dispose() {
    // No es necesario remover listener si usamos ref.watch
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calendarService = ref.watch(calendarDataServiceProvider);

    // Optimización para iOS: usar RepaintBoundary para evitar re-renders innecesarios
    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          elevation: 0, // Eliminar sombra del AppBar
          title: const Text('My Calendar'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                context.push('/settings');
              },
            ),
            // Botón para gestionar plantillas de turnos - REMOVIDO (funcionalidad movida a botón TURNOS inferior)
            // Botón Turno2 - Lista de turnos disponibles
            IconButton(
              icon: const Icon(Icons.work),
              onPressed: () {
                context.push('/available-shifts');
              },
            ),
            // Nuevo botón para gestionar la familia
            IconButton(
              icon: const Icon(Icons.group),
              onPressed: () {
                print('🔧 Botón Familia presionado - intentando navegar a /family-management');
                try {
                  context.push('/family-management');
                  print('✅ Navegación a /family-management exitosa');
                } catch (e) {
                  print('❌ Error en navegación a /family-management: $e');
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Header superior
            RepaintBoundary(child: _buildTopBar()),

            // Header del calendario
            RepaintBoundary(child: _buildCalendarHeader()),

            // Calendario - usar Flexible en lugar de Expanded
            Flexible(
              child: RepaintBoundary(child: _buildCalendar()),
            ),

            // Botones inferiores - solo mostrar cuando no esté en modo pintar
            if (!_isPaintMode) RepaintBoundary(child: _buildBottomButtons()),
          ],
        ),
        bottomNavigationBar: _isPaintMode ? RepaintBoundary(child: _buildPaintBar(calendarService)) : null,
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reducido de 8 a 4
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        border: Border.all(color: Colors.transparent, width: 0), // Eliminar cualquier borde
      ),
      child: Row(
        children: [
                  const Text(
                    'Calendario',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          const Spacer(),
          // Año clickeable para ir al resumen anual
          GestureDetector(
            onTap: () {
              context.push('/year-summary', extra: _focusedDay.year);
            },
            child: Text(
              _currentMonth.year.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          // RESUMEN clickeable para estadísticas
          GestureDetector(
            onTap: () {
              context.push('/statistics');
            },
            child: const Text(
              'RESUMEN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1), // Reducido de 2 a 1
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        border: Border.all(color: Colors.transparent, width: 0), // Eliminar cualquier borde
      ),
      child: Row(
        children: [
          // Botón anterior
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
              });
            },
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20), // Reducido de 24 a 20
            padding: const EdgeInsets.all(4), // Reducir padding del botón
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32), // Reducir tamaño mínimo
          ),
          const Spacer(),
          // Título del mes y año (clickeable para ir al mes actual)
          GestureDetector(
            onTap: () {
              setState(() {
                _focusedDay = DateTime.now();
              });
            },
            child: Text(
              '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20, // Aumentado de 14 a 20
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          // Botón siguiente
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
              });
            },
            icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20), // Reducido de 24 a 20
            padding: const EdgeInsets.all(4), // Reducir padding del botón
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32), // Reducir tamaño mínimo
          ),
        ],
      ),
    );
  }



  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    // Calcular cuántas semanas necesitamos
    final totalDays = firstWeekday - 1 + daysInMonth;
    final weeks = (totalDays / 7).ceil();

    return Column(
      children: [
        // Días del mes
        Expanded(
          child: Column(
            children: List.generate(weeks, (weekIndex) {
              return Expanded(
                child: Row(
                  children: List.generate(7, (dayIndex) {
                    final dayNumber = weekIndex * 7 + dayIndex - (firstWeekday - 1) + 1;

                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      // Día vacío
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(0.5),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                        ),
                      );
                    }

                    final date = DateTime(_focusedDay.year, _focusedDay.month, dayNumber);
                    return Expanded(
                      child: _buildDayCell(date),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime date) {
    // Optimización para iOS: usar variables locales para evitar recálculos
    final now = DateTime.now();
    final isSelected = _selectedDay.day == date.day &&
        _selectedDay.month == date.month &&
        _selectedDay.year == date.year;
    final isToday = now.day == date.day &&
        now.month == date.month &&
        now.year == date.year;

    final dateKey = _formatDate(date);
    final events = _dataService.getEventsForDay(date);
    final dayCategories = _dataService.getDayCategoriesForDate(date);

    return GestureDetector(
      onTap: () async {
        if (_isPaintMode && _selectedPaintOption != null) {
          // Modo pintar: aplicar el color y texto seleccionado
          _applyPaintToDay(date);
        } else {
          // Modo normal: seleccionar día y navegar
          // Optimización para iOS: usar addPostFrameCallback para evitar bloqueos
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedDay = date;
              });
            }
          });

          // Obtener el texto y el ID del evento existente para el día
          String? existingText;
          String? existingEventId;
          final events = _dataService.getEventsForDay(date);
          if (events.isNotEmpty) {
            final firstEventTitle = events.first; // Asumir que el primer evento es la nota principal
            final appEvent = await _dataService.getAppEventByTitleAndDate(firstEventTitle, date);
            if (appEvent != null) {
              existingText = appEvent.title;
              existingEventId = appEvent.id;
            }
          }

          // Navegar a la DayDetailScreen y pasar la fecha, el texto y el ID del evento existente
          final result = await context.push(
            '/day-detail',
            extra: {
              'date': date,
              'existingText': existingText,
              'existingEventId': existingEventId,
            },
          );

          if (result != null && result is String) {
            // Si se devolvió un resultado (el nuevo texto del evento), actualizar la UI
            // La lógica de guardado ya se maneja en _saveEvent en DayDetailScreen
            // Aquí solo necesitamos forzar una reconstrucción del calendario
            setState(() {
              // No es necesario actualizar _dataService aquí, ya se hizo en DayDetailScreen
            });
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(2),
          boxShadow: isToday ? [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ] : null,
        ),
        child: Stack(
          children: [
            // Fondo de color si hay eventos
            if (events.isNotEmpty)
              Positioned.fill(
                child: _buildDayBackground(date, events),
              ),

            // Número del día (siempre visible en la esquina superior izquierda)
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: isToday ? BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ) : null,
                child: Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getDayNumberColor(date, events, isToday),
                  ),
                ),
              ),
            ),

            // Notas del día - mostrar debajo del número del día (solo si no hay turnos)
            if (!_hasShifts(events))
              Positioned(
                top: 20, // Dejar espacio para el número del día
                left: 2,
                right: 2,
                child: _buildNotes(date, events),
              ),



            // Iconos de categorías en la esquina izquierda inferior
            if (dayCategories.isNotEmpty)
              Positioned(
                bottom: 1,
                left: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dayCategories['category1'] != null && dayCategories['category1'] != 'Ninguno')
                      Icon(
                        _getCategoryIcon(dayCategories['category1']),
                        size: 12,
                        color: Colors.grey[700],
                      ),
                    if (dayCategories['category2'] != null && dayCategories['category2'] != 'Ninguno')
                      Icon(
                        _getCategoryIcon(dayCategories['category2']),
                        size: 12,
                        color: Colors.grey[700],
                      ),
                    if (dayCategories['category3'] != null && dayCategories['category3'] != 'Ninguno')
                      Icon(
                        _getCategoryIcon(dayCategories['category3']),
                        size: 12,
                        color: Colors.grey[700],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleColorCell(String eventTitle, Color bgColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(1),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Text(
            eventTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildDualColorCell(List<Map<String, dynamic>> displayEvents) {
    return Column(
      children: [
        // Mitad superior
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: displayEvents[0]['color'],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(1),
                topRight: Radius.circular(1),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.0),
                child: Text(
                  displayEvents[0]['text'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: displayEvents[0]['textColor'],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        // Mitad inferior
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: displayEvents[1]['color'],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(1),
                bottomRight: Radius.circular(1),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.0),
                child: Text(
                  displayEvents[1]['text'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: displayEvents[1]['textColor'],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaintBar(CalendarDataService calendarService) {
    return Container(
      color: Colors.red[700],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reducir padding vertical
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flecha para ocultar
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isPaintMode = false;
                    _selectedPaintOption = null;
                  });
                },
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 18, // Reducir tamaño
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 25, minHeight: 25), // Reducir tamaño
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 2), // Reducir espacio
          // Opciones de pintar en una sola fila
          SizedBox(
            height: 50, // Aumentar altura para botones más altos
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Tarjeta de borrar
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPaintOption = 'borrar';
                      });
                    },
                    child: Container(
                      width: 45, // Mantener ancho
                      height: 40, // Aumentar altura del botón borrar
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: _selectedPaintOption == 'borrar' ? Colors.black : Colors.grey[400]!,
                          width: _selectedPaintOption == 'borrar' ? 2 : 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.clear,
                          color: Colors.red,
                          size: 14, // Reducir tamaño
                        ),
                      ),
                    ),
                  ),
                  // Opciones de pintar (plantillas de turnos)
                  ...calendarService.shiftTemplates.map((template) {
                    final isSelected = _selectedPaintOption == template.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPaintOption = template.id; // Usar el ID de la plantilla
                        });
                      },
                      child: Container(
                        width: 45, // Mantener ancho
                        height: 40, // Aumentar altura de los botones de turnos
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: Color(int.parse(template.colorHex.substring(1, 7), radix: 16) + 0xFF000000),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey[400]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            template.abbreviation.isNotEmpty ? template.abbreviation : template.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11, // Aumentar tamaño de fuente para botones más altos
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      color: Colors.grey[800],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Reducir padding vertical
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 24, // Reducir altura
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isPaintMode = !_isPaintMode;
                    if (!_isPaintMode) {
                      _selectedPaintOption = null;
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPaintMode ? Colors.orange[700] : Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero, // Sin padding interno
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: Text(
                  _isPaintMode ? 'PINTANDO...' : 'PINTAR',
                  style: const TextStyle(fontSize: 9), // Texto más pequeño
                ),
              ),
            ),
          ),
          const SizedBox(width: 4), // Espacio mínimo
          Expanded(
            child: SizedBox(
              height: 24, // Reducir altura
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función EDITAR')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero, // Sin padding interno
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: const Text(
                  'EDITAR',
                  style: TextStyle(fontSize: 9), // Texto más pequeño
                ),
              ),
            ),
          ),
          const SizedBox(width: 4), // Espacio mínimo
          Expanded(
            child: SizedBox(
              height: 24, // Reducir altura
              child: ElevatedButton(
                onPressed: () {
                  context.push('/available-shifts');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero, // Sin padding interno
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: const Text(
                  'TURNOS',
                  style: TextStyle(fontSize: 9), // Texto más pequeño
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyPaintToDay(DateTime date) async {
    print('🔧 _applyPaintToDay iniciado');
    print('🔧 date: $date');
    print('🔧 _selectedPaintOption: $_selectedPaintOption');

    if (_selectedPaintOption == null) {
      print('❌ No hay opción de pintura seleccionada');
      return;
    }

    if (_selectedPaintOption == 'borrar') {
      print('🔧 Modo borrar activado');
      // Obtener eventos existentes antes de borrar
      final existingEvents = _dataService.getEventsForDay(date);

      if (existingEvents.isEmpty) {
        print('❌ No hay eventos para borrar');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay eventos para borrar'),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }

      // Eliminar de Firebase primero
      try {
        await _dataService.deleteAllEventsForDay(date);
        print('✅ Eventos eliminados de Firebase para ${date.day}');
      } catch (e) {
        print('❌ Error eliminando eventos de Firebase: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al borrar de Firebase'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Solo borrar localmente si Firebase fue exitoso
      setState(() {
        _dataService.clearDayEvents(date);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Día ${date.day} borrado completamente'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      print('🔧 Aplicando plantilla de turno');
      // Aplicar color/texto seleccionado
      final selectedTemplate = _dataService.getShiftTemplateById(_selectedPaintOption!);

      if (selectedTemplate == null) {
        print('❌ Plantilla de turno no encontrada para ID: $_selectedPaintOption');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plantilla de turno no encontrada'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      print('🔧 Plantilla encontrada: ${selectedTemplate.name}');

      // Verificar si ya hay un turno del mismo tipo
      final existingEvents = _dataService.getEventsForDay(date);
      bool hasSameShift = false;

      for (final event in existingEvents) {
        // Si ya existe el mismo turno, no permitir duplicar
        if (event == selectedTemplate.name) {
          hasSameShift = true;
          break;
        }
      }

      if (hasSameShift) {
        print('❌ Ya existe el turno ${selectedTemplate.name} en este día');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ya existe el turno ${selectedTemplate.name} en este día'),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      try {
        print('🔧 Agregando evento: ${selectedTemplate.name}');
        await _dataService.addEvent(
          date: date,
          title: selectedTemplate.name,
          color: selectedTemplate.colorHex,
        );

        setState(() {
          // La UI se actualizará automáticamente por notifyListeners()
        });

        print('✅ Turno agregado exitosamente');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Turno ${selectedTemplate.name} agregado al día ${date.day}'),
            duration: const Duration(seconds: 1),
          ),
        );
      } catch (e) {
        print('❌ Error agregando evento: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aplicar turno: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'Enero';
      case 2: return 'Febrero';
      case 3: return 'Marzo';
      case 4: return 'Abril';
      case 5: return 'Mayo';
      case 6: return 'Junio';
      case 7: return 'Julio';
      case 8: return 'Agosto';
      case 9: return 'Septiembre';
      case 10: return 'Octubre';
      case 11: return 'Noviembre';
      case 12: return 'Diciembre';
      default: return '';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildDayBackground(DateTime date, List<String> events) {
    // Separar turnos y notas
    List<Map<String, dynamic>> shifts = [];
    for (final eventTitle in events) {
      final template = _dataService.getShiftTemplateByName(eventTitle);
      if (template != null) {
        shifts.add({
          'name': template.abbreviation.isNotEmpty ? template.abbreviation : template.name,
          'color': Color(int.parse(template.colorHex.substring(1, 7), radix: 16) + 0xFF000000),
          'textColor': Color(int.parse(template.textColorHex.substring(1, 7), radix: 16) + 0xFF000000),
          'textSize': template.textSize,
        });
      }
    }

    // Obtener las notas para esta fecha
    final dateKey = _formatDate(date);
    final notes = _dataService.getNotes()[dateKey] ?? [];

    // Si no hay turnos, fondo blanco
    if (shifts.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    // Si hay un turno, color completo ocupando toda la celda con texto centrado
    if (shifts.length == 1) {
      final backgroundColor = shifts.first['color'] as Color;
      final textColor = shifts.first['textColor'] as Color;
      final textSize = shifts.first['textSize'] as double;
      
      // Si hay notas, mostrar la nota en lugar del nombre del turno
      String displayText;
      if (notes.isNotEmpty) {
        displayText = notes.first; // Mostrar la primera nota
      } else {
        displayText = shifts.first['name']; // Mostrar el nombre del turno
      }
      
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Text(
              displayText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: textSize, // Usar el tamaño del template
                fontWeight: FontWeight.bold,
                color: textColor, // Usar el color del template
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    // Si hay dos o más turnos, dividir la celda horizontalmente 50% cada uno con textos centrados
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Mitad superior con el primer turno (50%)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: shifts.first['color'],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.0),
                  child: Text(
                    // Si hay notas, mostrar la nota en lugar del nombre del turno
                    notes.isNotEmpty ? notes.first : shifts.first['name'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: (shifts.first['textSize'] as double) * 0.7, // Reducir tamaño para dos turnos
                      fontWeight: FontWeight.bold,
                      color: shifts.first['textColor'] as Color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          // Mitad inferior con el segundo turno (50%)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: shifts[1]['color'],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.0),
                  child: Text(
                    // Si hay notas, mostrar la nota en lugar del nombre del turno (solo en la mitad inferior)
                    notes.isNotEmpty ? notes.first : shifts[1]['name'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: (shifts[1]['textSize'] as double) * 0.7, // Reducir tamaño para dos turnos
                      fontWeight: FontWeight.bold,
                      color: shifts[1]['textColor'] as Color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDayNumberColor(DateTime date, List<String> events, bool isToday) {
    if (isToday) return Colors.white;

    // Verificar si hay turnos
    for (final eventTitle in events) {
      final template = _dataService.getShiftTemplateByName(eventTitle);
      if (template != null) {
        return Colors.white; // Número blanco sobre fondo de color de turno
      }
    }

    return Colors.black; // Número negro por defecto
  }

  // Función para calcular el color de texto apropiado según el color de fondo
  Color _getContrastTextColor(Color backgroundColor) {
    // Calcular el brillo del color de fondo
    final luminance = backgroundColor.computeLuminance();
    
    // Si el fondo es claro, usar texto oscuro; si es oscuro, usar texto claro
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  // Función para obtener un color de texto que contraste bien con el fondo
  Color _getHighContrastTextColor(Color backgroundColor) {
    // Calcular el brillo del color de fondo
    final luminance = backgroundColor.computeLuminance();
    
    // Si el fondo es muy claro, usar negro
    if (luminance > 0.7) {
      return Colors.black;
    }
    // Si el fondo es muy oscuro, usar blanco
    else if (luminance < 0.3) {
      return Colors.white;
    }
    // Para colores intermedios, usar un color que contraste bien
    else {
      // Usar un color que sea opuesto en el círculo cromático
      final hsl = HSLColor.fromColor(backgroundColor);
      final oppositeHue = (hsl.hue + 180) % 360;
      return HSLColor.fromAHSL(1.0, oppositeHue, 1.0, 0.2).toColor();
    }
  }

  // Verifica si hay turnos en los eventos
  bool _hasShifts(List<String> events) {
    for (final eventTitle in events) {
      if (eventTitle.isNotEmpty) {
        final template = _dataService.getShiftTemplateByName(eventTitle);
        if (template != null) {
          return true;
        }
      }
    }
    return false;
  }

  // Construye el widget de texto de notas (sin Positioned)
  Widget _buildNotes(DateTime date, List<String> events) {
    final dateKey = _formatDate(date);
    final notes = _dataService.getNotes()[dateKey] ?? [];
    
    if (notes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      notes.first,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.normal,
        color: Colors.black87,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDayContent(DateTime date, List<String> events) {
    List<Map<String, dynamic>> shifts = [];
    List<String> notes = [];

    // Separar turnos y notas
    for (final eventTitle in events) {
      if (eventTitle.isNotEmpty) {
        final template = _dataService.getShiftTemplateByName(eventTitle);
        if (template != null) {
          shifts.add({
            'text': template.abbreviation.isNotEmpty ? template.abbreviation : template.name,
            'color': Color(int.parse(template.colorHex.substring(1, 7), radix: 16) + 0xFF000000),
            'textColor': Colors.white,
          });
        } else {
          // Es una nota
          notes.add(eventTitle);
        }
      }
    }

    // Obtener las notas para esta fecha desde el servicio
    final dateKey = _formatDate(date);
    final dateNotes = _dataService.getNotes()[dateKey] ?? [];
    if (dateNotes.isNotEmpty) {
      notes = dateNotes; // Usar las notas del servicio en lugar de las de events
    }

    // Si hay turnos, mostrar los nombres de los turnos
    if (shifts.isNotEmpty) {
      Widget turnoWidget;
      if (shifts.length == 1) {
        // Un solo turno - mostrar el nombre centrado
        final backgroundColor = shifts.first['color'] as Color;
        final textColor = _getHighContrastTextColor(backgroundColor);
        
        turnoWidget = Container(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Text(
                // Si hay notas, mostrar solo el texto de las notas (no el nombre del turno)
                notes.isNotEmpty ? notes.first : shifts.first['text'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12, // Aumentado de 10 a 12
                  fontWeight: FontWeight.bold,
                  color: textColor, // Color dinámico según el fondo
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      } else {
        // Dos turnos - dividir verticalmente los nombres y centrar cada uno
        turnoWidget = Column(
          children: [
            // Mitad superior con el primer turno
            Expanded(
              child: Container(
                width: double.infinity,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.0),
                    child: Text(
                      // Si hay notas, mostrar solo el texto de las notas (no el nombre del turno)
                      notes.isNotEmpty ? notes.first : shifts.first['text'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10, // Aumentado de 8 a 10
                        fontWeight: FontWeight.bold,
                        color: _getHighContrastTextColor(shifts.first['color'] as Color),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
            // Mitad inferior con el segundo turno
            Expanded(
              child: Container(
                width: double.infinity,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.0),
                    child: Text(
                      // Si hay notas, mostrar solo el texto de las notas (no el nombre del turno)
                      notes.isNotEmpty ? notes.first : shifts[1]['text'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10, // Aumentado de 8 a 10
                        fontWeight: FontWeight.bold,
                        color: _getHighContrastTextColor(shifts[1]['color'] as Color),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }

      // Si también hay notas, mostrarlas en la parte inferior
      if (notes.isNotEmpty) {
        return Column(
          children: [
            Expanded(
              flex: 3,
              child: turnoWidget,
            ),
            // Notas en la parte inferior
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Center(
                  child: Text(
                    notes.first, // Solo mostrar la primera nota
                    style: const TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.normal,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      }

      return turnoWidget;
    }

    // Si solo hay notas (sin turnos)
    if (notes.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Text(
            notes.first,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.normal,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
