import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/day_detail_screen.dart';
import 'package:calendario_familiar/core/services/calendar_data_service.dart';
import 'package:calendario_familiar/core/providers/text_size_provider.dart';
import 'package:calendario_familiar/core/models/local_user.dart';
import 'package:calendario_familiar/core/providers/current_user_provider.dart';
import 'package:calendario_familiar/core/services/event_user_service.dart';
import 'package:calendario_familiar/features/calendar/presentation/widgets/user_selector_widget.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  bool _isPaintMode = false;
  String? _selectedPaintOption;

  DateTime get _currentMonth => DateTime.now();

  late final CalendarDataService _dataService;

  final Map<String, Map<String, String?>> _dayCategories = {};

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
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    print('📱 CalendarScreen inicializada');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = ref.watch(calendarDataServiceProvider);
  }

  @override
  Widget build(BuildContext context) {
    final calendarService = ref.watch(calendarDataServiceProvider);

    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('My Calendar'),
          actions: [
            PopupMenuButton<int>(
              icon: const Icon(Icons.person),
              tooltip: 'Seleccionar Usuario',
              onSelected: (userId) {
                ref.read(currentUserIdProvider.notifier).setCurrentUser(userId);
                final user = localUsers.firstWhere((u) => u.id == userId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Usuario activo: ${user.name}'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: user.color,
                  ),
                );
              },
              itemBuilder: (context) => localUsers.map((user) {
                final currentUserId = ref.watch(currentUserIdProvider);
                final isSelected = user.id == currentUserId;
                return PopupMenuItem<int>(
                  value: user.id,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: user.color,
                          shape: BoxShape.circle,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 12)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        user.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? user.color : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                context.push('/settings');
              },
            ),
          ],
        ),
        body: Column(
          children: [
            RepaintBoundary(child: _buildTopBar()),
            RepaintBoundary(child: _buildCalendarHeader()),
            Expanded(
              child: RepaintBoundary(child: _buildCalendar()),
            ),
            if (!_isPaintMode) RepaintBoundary(child: _buildBottomButtons()),
          ],
        ),
        bottomNavigationBar: _isPaintMode ? RepaintBoundary(child: _buildPaintBar(calendarService)) : null,
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        border: Border.all(color: Colors.transparent, width: 0),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        border: Border.all(color: Colors.transparent, width: 0),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
              });
            },
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const Spacer(),
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
              });
            },
            icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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

    final totalDays = firstWeekday - 1 + daysInMonth;
    final weeks = (totalDays / 7).ceil();

    return Column(
      children: [
        Expanded(
          child: Column(
            children: List.generate(weeks, (weekIndex) {
              return Expanded(
                child: Row(
                  children: List.generate(7, (dayIndex) {
                    final dayNumber = weekIndex * 7 + dayIndex - (firstWeekday - 1) + 1;

                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(0.5),
                          constraints: const BoxConstraints(minHeight: 80),
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
          _applyPaintToDay(date);
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedDay = date;
              });
            }
          });

          String? existingText;
          String? existingEventId;
          final events = _dataService.getEventsForDay(date);
          if (events.isNotEmpty) {
            final firstEventTitle = events.first;
            final appEvent = await _dataService.getAppEventByTitleAndDate(firstEventTitle, date);
            if (appEvent != null) {
              existingText = appEvent.title;
              existingEventId = appEvent.id;
            }
          }

          final result = await context.push(
            '/day-detail',
            extra: {
              'date': date,
              'existingText': existingText,
              'existingEventId': existingEventId,
            },
          );

          if (result != null && result is String) {
            setState(() {
              // No es necesario actualizar _dataService aquí, ya se hizo en DayDetailScreen
            });
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.all(0.5),
        constraints: const BoxConstraints(minHeight: 80),
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
            if (events.isNotEmpty)
              Positioned.fill(
                child: _buildDayBackground(date, events),
              ),

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

            if (!_hasShifts(events))
              Positioned(
                top: 20,
                left: 2,
                right: 2,
                child: _buildNotes(date, events),
              ),

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

  Widget _buildPaintBar(CalendarDataService calendarService) {
    return Container(
      color: Colors.red[700],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 25, minHeight: 25),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPaintOption = 'borrar';
                      });
                    },
                    child: Container(
                      width: 45,
                      height: 40,
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
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                  ...calendarService.shiftTemplates.map((template) {
                    final isSelected = _selectedPaintOption == template.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPaintOption = template.id;
                        });
                      },
                      child: Container(
                        width: 45,
                        height: 40,
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
                              fontSize: 11,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 24,
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
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: Text(
                  _isPaintMode ? 'PINTANDO...' : 'PINTAR',
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SizedBox(
              height: 24,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/user-management');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: const Text(
                  'EDITAR',
                  style: TextStyle(fontSize: 9),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SizedBox(
              height: 24,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/available-shifts');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: const Text(
                  'TURNOS',
                  style: TextStyle(fontSize: 9),
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

      final existingEvents = _dataService.getEventsForDay(date);
      bool hasSameShift = false;

      for (final event in existingEvents) {
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

    final dateKey = _formatDate(date);
    final notes = _dataService.getNotes()[dateKey] ?? [];

    if (shifts.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    if (shifts.length == 1) {
      final backgroundColor = shifts.first['color'] as Color;
      final textColor = shifts.first['textColor'] as Color;
      final textSize = shifts.first['textSize'] as double;
      
      String displayText;
      if (notes.isNotEmpty) {
        displayText = notes.first;
      } else {
        displayText = shifts.first['name'];
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
                fontSize: textSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
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
                    notes.isNotEmpty ? notes.first : shifts.first['name'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: (shifts.first['textSize'] as double) * 0.7,
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
                    shifts[1]['name'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: (shifts[1]['textSize'] as double) * 0.7,
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

    for (final eventTitle in events) {
      final template = _dataService.getShiftTemplateByName(eventTitle);
      if (template != null) {
        return Colors.white;
      }
    }

    return Colors.black;
  }

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

  Widget _buildNotes(DateTime date, List<String> events) {
    final dateKey = _formatDate(date);
    final rawNotes = _dataService.getNotes()[dateKey] ?? [];

    if (rawNotes.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final notes = <String>[];
    for (final rawNote in rawNotes) {
      if (rawNote.contains('\n')) {
        final splitNotes = rawNote.split('\n').where((note) => note.trim().isNotEmpty).toList();
        notes.addAll(splitNotes);
      } else if (rawNote.contains(' ') && rawNote.split(' ').length == 2) {
        final parts = rawNote.split(' ');
        for (final part in parts) {
          final trimmed = part.trim();
          if (trimmed.isNotEmpty) {
            notes.add(trimmed);
          }
        }
      } else {
        notes.add(rawNote);
      }
    }

    return Consumer(
      builder: (context, ref, child) {
        final eventTextSize = ref.watch(eventTextSizeProvider);
        
        final userIds = <int>[];
        for (final note in notes) {
          int userId;
          if (rawNotes.any((rawNote) => rawNote.contains('\n')) || 
              rawNotes.any((rawNote) => rawNote.contains(' ') && rawNote.split(' ').length == 2)) {
            userId = _assignUserIdBasedOnContent(note);
          } else {
            userId = _dataService.getUserIdForEvent(date, note);
          }
          userIds.add(userId);
        }
        final hasMultipleNotes = notes.length > 1;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    notes.first,
                    style: EventUserService.getEventTextStyle(
                      userId: _dataService.getUserIdForEvent(date, notes.first),
                      fontSize: eventTextSize,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: hasMultipleNotes ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            if (hasMultipleNotes) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  if (notes.length >= 2)
                    Expanded(
                      child: Text(
                        notes[1],
                        style: EventUserService.getEventTextStyle(
                          userId: _dataService.getUserIdForEvent(date, notes[1]),
                          fontSize: eventTextSize * 0.85,
                          fontWeight: FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  
                  const SizedBox(width: 4),
                  
                  if (notes.length > 2)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${notes.length - 2}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  int _assignUserIdBasedOnContent(String note) {
    final content = note.toLowerCase().trim();
    
    if (content.contains('pedro')) {
      return 3;
    }
    if (content.contains('maría') || content.contains('maria')) {
      return 2;
    }
    if (content.contains('juan')) {
      return 1;
    }
    if (content.contains('lucía') || content.contains('lucia')) {
      return 4;
    }
    if (content.contains('ana')) {
      return 5;
    }
    
    return ref.read(currentUserIdProvider);
  }
}