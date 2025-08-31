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
          // Aquí iría el contenido del calendario
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 100, color: Colors.blue),
                  const SizedBox(height: 20),
                  const Text(
                    '¡Calendario Familiar Funcionando!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'La aplicación está lista para usar',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Aquí iría la lógica del calendario
                    },
                    child: const Text('Comenzar a usar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}