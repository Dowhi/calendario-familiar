import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/day_detail_screen.dart';
import 'package:calendario_familiar/core/services/calendar_data_service.dart';
import 'package:table_calendar/table_calendar.dart';

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

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Calendario Familiar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_view_day),
            onPressed: () {
              context.push('/shift-templates');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendario
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              
              // Navegar al detalle del día
              context.push('/day-detail', extra: {
                'date': selectedDay,
                'existingText': null,
                'existingEventId': null,
              });
            },
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: Colors.red),
            ),
          ),
          
          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/day-detail', extra: {
                      'date': _selectedDay,
                      'existingText': null,
                      'existingEventId': null,
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Evento'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/statistics');
                  },
                  icon: const Icon(Icons.analytics),
                  label: const Text('Estadísticas'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/year-summary');
                  },
                  icon: const Icon(Icons.summarize),
                  label: const Text('Resumen'),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/day-detail', extra: {
            'date': DateTime.now(),
            'existingText': null,
            'existingEventId': null,
          });
        },
        backgroundColor: const Color(0xFF1B5E20),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}