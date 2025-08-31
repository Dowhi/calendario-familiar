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

    return Scaffold(
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
          // Botón para gestionar plantillas de turnos
          IconButton(
            icon: const Icon(Icons.calendar_view_day),
            onPressed: () {
              context.push('/shift-templates');
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Calendario Familiar - Pantalla Original',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}