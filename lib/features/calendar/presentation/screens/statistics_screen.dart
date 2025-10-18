import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:calendario_familiar/core/services/calendar_data_service.dart';
import 'package:collection/collection.dart'; // Import para firstWhereOrNull

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  late DateTime _selectedMonth;
  late CalendarDataService _dataService;
  String _selectedFilter = 'Mes';
  String _selectedNotesFilter = 'Próximas';
  
  // Estado para los checkboxes de turnos seleccionados
  final Map<String, bool> _selectedShifts = {};
  
  // Estado para el filtro de fechas
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  
  // Nuevos estados para las nuevas funcionalidades
  final TextEditingController _searchController = TextEditingController();
  String _selectedIcon = 'Cambio de turno';
  bool _includePastDays = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _iconSearchResults = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    // Inicializar fechas con el primer y último día del mes actual
    _startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    _endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = ref.watch(calendarDataServiceProvider);
    
    // Inicializar búsqueda por icono cuando se cargan los datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dataService.dayCategories.isNotEmpty) {
        _searchDaysByIcon();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios en el servicio de datos para actualizar la UI
    ref.listen<CalendarDataService>(calendarDataServiceProvider, (previous, next) {
      if (mounted) {
        setState(() {
          // Forzar actualización cuando cambien los datos
        });
      }
    });

    final stats = _calculateStatistics();
    final shiftCounts = stats['shiftCounts'] as Map<String, int>;
    final totalShifts = stats['totalShifts'] as int;
    final totalHours = stats['totalHours'] as int;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Barra de navegación superior
            _buildTopNavigationBar(),
            
            // Contenido principal
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Sección de Estadísticas
                    _buildStatisticsSection(shiftCounts, totalShifts, totalHours),
                    
                    const SizedBox(height: 8), // Reducido de 12 a 8
                    
                    // Sección de Notas Cercanas
                    _buildNearbyNotesSection(),
                    
                    const SizedBox(height: 8),
                    
                    // Sección de Buscar en Notas
                    _buildSearchInNotesSection(),
                    
                    const SizedBox(height: 8),
                    
                    // Sección de Buscar Días por Icono
                    _buildSearchDaysByIconSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goToPreviousMonth() {
    setState(() {
      if (_selectedFilter == 'Año') {
        _selectedMonth = DateTime(_selectedMonth.year - 1, _selectedMonth.month, 1);
      } else {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      }
      _updateDateRange();
    });
  }

  void _goToNextMonth() {
    setState(() {
      if (_selectedFilter == 'Año') {
        _selectedMonth = DateTime(_selectedMonth.year + 1, _selectedMonth.month, 1);
      } else {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      }
      _updateDateRange();
    });
  }

  void _updateDateRange() {
    print('DEBUG: _updateDateRange called. Selected Filter: $_selectedFilter, Selected Month: $_selectedMonth');
    // Actualizar el rango de fechas según el filtro seleccionado
    if (_selectedFilter == 'Mes') {
      _startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      _endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    } else if (_selectedFilter == 'Año') {
      _startDate = DateTime(_selectedMonth.year, 1, 1);
      _endDate = DateTime(_selectedMonth.year, 12, 31);
    }
    // Para 'Rango' se mantienen las fechas actuales
    setState(() {}); // Forzar la reconstrucción después de actualizar el rango de fechas
  }

  // Método para manejar la selección de turnos
  void _toggleShiftSelection(String shiftName) {
    setState(() {
      _selectedShifts[shiftName] = !(_selectedShifts[shiftName] ?? true);
    });
  }

  // Método para seleccionar fecha de inicio
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_selectedFilter == 'Rango') {
          _selectedFilter = 'Rango';
        }
      });
    }
  }

  // Método para seleccionar fecha de fin
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        if (_selectedFilter == 'Rango') {
          _selectedFilter = 'Rango';
        }
      });
    }
  }

  Map<String, dynamic> _calculateStatistics() {
    print('DEBUG: _calculateStatistics called. Start Date: $_startDate, End Date: $_endDate');
    print('DEBUG: DataService shifts: ${_dataService.shifts}');
    print('DEBUG: DataService shiftTemplates: ${_dataService.shiftTemplates.length} templates');
    
    final Map<String, int> shiftCounts = {};
    int totalShifts = 0;
    int totalHours = 0;

    // Obtener turnos del rango de fechas seleccionado
    for (final entry in _dataService.shifts.entries) {
      final dateKey = entry.key;
      final shiftsList = entry.value;
      
      try {
        final parts = dateKey.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          final shiftDate = DateTime(year, month, day);
          
          // Verificar si pertenece al rango de fechas seleccionado
          if (shiftDate.isAfter(_startDate.subtract(const Duration(days: 1))) && 
              shiftDate.isBefore(_endDate.add(const Duration(days: 1)))) {
            for (final shift in shiftsList) {
              final shiftName = shift.toString();
              shiftCounts[shiftName] = (shiftCounts[shiftName] ?? 0) + 1;
              
              // Solo sumar si el turno está seleccionado (por defecto todos están seleccionados)
              if (_selectedShifts[shiftName] ?? true) {
                totalShifts++;
                
                // Buscar la plantilla de turno para obtener las horas reales
                final shiftTemplate = _dataService.shiftTemplates.firstWhereOrNull(
                  (template) => template.name == shiftName,
                );
                
                if (shiftTemplate != null) {
                  // Usar el mismo método de cálculo que en la tabla
                  if (shiftTemplate.calculateDuration && 
                      shiftTemplate.calculatedHours != null && 
                      shiftTemplate.calculatedMinutes != null) {
                    totalHours += shiftTemplate.calculatedHours!;
                    // Los minutos se ignoran en el total para simplificar
                  } else {
                    // Fallback: calcular duración desde los horarios
                    final duration = _calculateDurationFromTemplate(shiftTemplate);
                    totalHours += duration['hours']!;
                  }
                  print('DEBUG: Turno $shiftName: ${totalHours}h (desde plantilla)');
                } else {
                  // Fallback para turnos sin plantilla
                  switch (shiftName) {
                    case 'D1':
                    case 'D2':
                      totalHours += 12;
                      break;
                    case 'Libre':
                    case 'Descanso':
                      // Libre/Descanso no suma horas
                      break;
                    default:
                      totalHours += 8; // Turnos típicos de 8 horas
                      break;
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        print('Error procesando fecha $dateKey: $e');
      }
    }
    print('DEBUG: Calculated shiftCounts: $shiftCounts');
    print('DEBUG: Total shifts: $totalShifts, Total hours: $totalHours');

    return {
      'shiftCounts': shiftCounts,
      'totalShifts': totalShifts,
      'totalHours': totalHours,
    };
  }

  String _formatMonth(DateTime date) {
    final months = [
      'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
      'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'
    ];
    return months[date.month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }

  // Calcular duración desde los horarios de una plantilla
  Map<String, int> _calculateDurationFromTemplate(shiftTemplate) {
    try {
      // Calcular duración del primer turno
      final firstDuration = _calculateTimeDifference(shiftTemplate.startTime, shiftTemplate.endTime);
      
      num totalMinutes = firstDuration;
      
      // Si es turno partido, agregar duración del segundo turno
      if (shiftTemplate.isSplitShift && 
          shiftTemplate.secondStartTime != null && 
          shiftTemplate.secondEndTime != null) {
        final secondDuration = _calculateTimeDifference(shiftTemplate.secondStartTime!, shiftTemplate.secondEndTime!);
        totalMinutes += secondDuration;
        
        // Restar tiempo de descanso
        totalMinutes -= shiftTemplate.breakTimeMinutes;
      }
      
      // Convertir a horas y minutos
      final hours = (totalMinutes ~/ 60).toInt();
      final minutes = (totalMinutes % 60).toInt();
      
      return {'hours': hours, 'minutes': minutes};
    } catch (e) {
      print('Error calculando duración desde plantilla: $e');
      return {'hours': 8, 'minutes': 0}; // Fallback a 8 horas
    }
  }

  // Calcular diferencia entre dos tiempos en minutos (mismo método que en shift_configuration_screen)
  int _calculateTimeDifference(String startTime, String endTime) {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    
    if (startParts.length != 2 || endParts.length != 2) {
      return 0;
    }
    
    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);
    
    // Convertir a minutos desde medianoche
    final startTotalMinutes = startHour * 60 + startMinute;
    final endTotalMinutes = endHour * 60 + endMinute;
    
    // Manejar turnos de 24 horas (24:00 = 1440 minutos)
    if (endTime == '24:00') {
      return (24 * 60) - startTotalMinutes;
    }
    
    // Calcular diferencia
    int difference = endTotalMinutes - startTotalMinutes;
    
    // Si el turno cruza la medianoche (endTime < startTime)
    if (difference < 0) {
      difference += 24 * 60; // Agregar 24 horas en minutos
    }
    
    // Manejar caso especial: 00:00 a 23:59 = 23h 59m (casi 24h)
    if (startTime == '00:00' && endTime == '23:59') {
      return 23 * 60 + 59; // 23 horas y 59 minutos
    }
    
    return difference;
  }


  // Método para buscar en notas
  void _searchInNotes() {
    final searchTerm = _searchController.text.trim().toLowerCase();
    if (searchTerm.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final List<Map<String, dynamic>> results = [];
    
    // Buscar en todas las notas
    for (final entry in _dataService.notes.entries) {
      final dateKey = entry.key;
      final notesList = entry.value;
      
      try {
        final parts = dateKey.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          final noteDate = DateTime(year, month, day);
          
          for (final note in notesList) {
            if (note.toString().toLowerCase().contains(searchTerm)) {
              results.add({
                'date': noteDate,
                'title': note.toString(),
                'dateKey': dateKey,
              });
            }
          }
        }
      } catch (e) {
        print('Error procesando fecha de nota $dateKey: $e');
      }
    }
    
    setState(() {
      _searchResults = results;
    });
  }

  // Método para buscar días por icono
  void _searchDaysByIcon() {
    final List<Map<String, dynamic>> results = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Solo fecha, sin hora
    
    print('🔍 Buscando días por icono: $_selectedIcon');
    print('🔍 Incluir días pasados: $_includePastDays');
    print('🔍 Total categorías disponibles: ${_dataService.dayCategories.length}');
    
    // Buscar en todas las categorías de días
    for (final entry in _dataService.dayCategories.entries) {
      final dateKey = entry.key;
      final categories = entry.value;
      
      try {
        final parts = dateKey.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          final categoryDate = DateTime(year, month, day);
          
          // Verificar si la fecha está en el rango permitido
          if (!_includePastDays) {
            // Si no incluir días pasados, solo mostrar días de hoy en adelante
            if (categoryDate.isBefore(today)) {
              print('🔍 Excluyendo día pasado: $dateKey');
              continue;
            }
          }
          // Si _includePastDays es true, incluir todos los días
          
          // Verificar si alguna categoría coincide con el icono seleccionado
          final category1 = categories['category1'];
          final category2 = categories['category2'];
          final category3 = categories['category3'];
          
          print('🔍 Verificando categorías para $dateKey: category1=$category1, category2=$category2, category3=$category3');
          
          if (category1 == _selectedIcon ||
              category2 == _selectedIcon ||
              category3 == _selectedIcon) {
            print('✅ Coincidencia encontrada para $dateKey con icono $_selectedIcon');
            results.add({
              'date': categoryDate,
              'categories': categories,
              'dateKey': dateKey,
            });
          }
        }
      } catch (e) {
        print('Error procesando fecha de categoría $dateKey: $e');
      }
    }
    
    print('🔍 Total resultados encontrados: ${results.length}');
    
    setState(() {
      _iconSearchResults = results;
    });
  }

  // Lista de iconos disponibles
  List<String> get _availableIcons => [
    'Cambio de turno',
    'Ingreso',
    'Importante',
    'Festivo',
    'Médico',
    'Cumpleaños',
    'Favorito',
    'Coche',
  ];

  Color _getShiftColor(String shiftName) {
    // Buscar la plantilla de turno correspondiente en Firebase
    final shiftTemplates = _dataService.shiftTemplates;
    final shiftTemplate = shiftTemplates.firstWhereOrNull(
      (template) => template.name == shiftName,
    );
    
    // Si se encuentra la plantilla, usar su color real
    if (shiftTemplate != null) {
      return _hexToColor(shiftTemplate.colorHex);
    }
    
    // Si no se encuentra, usar colores por defecto
    switch (shiftName) {
      case 'D1':
        return Colors.blue;
      case 'D2':
        return Colors.red;
      case 'Libre':
      case 'Descanso':
        return Colors.green;
      case 'T':
        return Colors.orange;
      case 'M':
        return Colors.grey[700]!;
      case 'N':
        return Colors.pink;
      default:
        return Colors.purple;
    }
  }

  // Método auxiliar para convertir hex a Color
  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }


  Widget _buildTopNavigationBar() {
    return Container(
      color: Colors.grey[800],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mes actual - cliqueable para navegar a calendar_screen
          GestureDetector(
            onTap: () {
              // Navegar a la pantalla de calendario
              context.push('/');
            },
            child: Text(
              _formatMonth(_selectedMonth), // Mostrar el mes actual
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Año - cliqueable para navegar a year_summary_screen
          GestureDetector(
            onTap: () {
              // Navegar a la pantalla de resumen anual
              context.push('/year-summary', extra: _selectedMonth.year);
            },
            child: Text(
              _selectedMonth.year.toString(),
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.green,
                  width: 2,
                ),
              ),
            ),
            child: const Text(
              'RESUMEN',
              style: TextStyle(
                color: Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Botón para reportes avanzados
          GestureDetector(
            onTap: () {
              context.push('/advanced-reports');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AVANZADOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(Map<String, int> shiftCounts, int totalShifts, int totalHours) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Título
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12), // Reducido de 16 a 12
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              'ESTADÍSTICAS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(6), // Reducido de 12 a 8
            child: Column(
              children: [
                // Filtros
                _buildFilterSegments(),
                
                const SizedBox(height: 6), // Reducido de 12 a 8
                
                // Filtro de fechas (solo mostrar si es Rango)
                if (_selectedFilter == 'Rango') ...[
                  _buildDateRangeFilter(),
                  const SizedBox(height: 8), // Reducido de 12 a 8
                ] else ...[
                  // Selector de mes/año
                  _buildMonthSelector(),
                  const SizedBox(height: 8), // Reducido de 12 a 8
                ],
                
                // Tabla de estadísticas
                _buildStatisticsTable(shiftCounts),
                
                const SizedBox(height: 4), // Reducido de 8 a 4
                
                // Resumen global
                _buildGlobalSummary(totalShifts, totalHours),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSegments() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildFilterSegment('Mes', _selectedFilter == 'Mes'),
          _buildFilterSegment('Año', _selectedFilter == 'Año'),
          _buildFilterSegment('Rango', _selectedFilter == 'Rango'),
        ],
      ),
    );
  }

  Widget _buildFilterSegment(String text, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = text;
            _updateDateRange();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6), // Reducido de 8 a 6 vertical
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      children: [
        Row(
          children: [
            // Flecha izquierda
            IconButton(
              onPressed: () {
                setState(() {
                  _startDate = _startDate.subtract(const Duration(days: 1));
                  _endDate = _endDate.subtract(const Duration(days: 1));
                });
              },
              icon: const Icon(Icons.chevron_left, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            
            // Filtro DESDE
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'DESDE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _selectStartDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        _formatDate(_startDate),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Filtro HASTA
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'HASTA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _selectEndDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        _formatDate(_endDate),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Flecha derecha
            IconButton(
              onPressed: () {
                setState(() {
                  _startDate = _startDate.add(const Duration(days: 1));
                  _endDate = _endDate.add(const Duration(days: 1));
                });
              },
              icon: const Icon(Icons.chevron_right, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _goToPreviousMonth,
          icon: const Icon(Icons.chevron_left, size: 24),
        ),
        Text(
          _selectedFilter == 'Año' 
            ? '${_selectedMonth.year}'
            : '${_formatMonth(_selectedMonth)} ${_selectedMonth.year}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          onPressed: _goToNextMonth,
          icon: const Icon(Icons.chevron_right, size: 24),
        ),
      ],
    );
  }

  Widget _buildStatisticsTable(Map<String, int> shiftCounts) {
    if (shiftCounts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'No hay turnos registrados para este período',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Encabezados de la tabla
        Row(
          children: [
            const Expanded(flex: 1, child: Text('Turnos',textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
            const Expanded(flex: 1, child: Text('Cantidad',textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
            const Expanded(flex: 1, child: Text('Tiempo', textAlign: TextAlign.center,style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
            const Expanded(flex: 1, child: Text('Global', textAlign: TextAlign.center,style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          ],
        ),
        
        const SizedBox(height: 4), // Reducido de 10 a 8
        
        // Filas de turnos
        ...shiftCounts.entries.map((entry) {
          final shiftName = entry.key;
          final count = entry.value;
          final color = _getShiftColor(shiftName);
          
          // Calcular horas usando la duración real de la plantilla
          int hours = 0;
          int minutes = 0;
          
          // Buscar la plantilla correspondiente
          final shiftTemplate = _dataService.shiftTemplates.firstWhereOrNull(
            (template) => template.name == shiftName
          );
          
          if (shiftTemplate != null) {
            // Usar las horas calculadas de la plantilla
            if (shiftTemplate.calculateDuration && 
                shiftTemplate.calculatedHours != null && 
                shiftTemplate.calculatedMinutes != null) {
              hours = count * shiftTemplate.calculatedHours!;
              minutes = count * shiftTemplate.calculatedMinutes!;
              
              // Convertir minutos extra a horas
              hours += minutes ~/ 60;
              minutes = minutes % 60;
            } else {
              // Fallback: calcular duración desde los horarios
              final duration = _calculateDurationFromTemplate(shiftTemplate);
              hours = count * duration['hours']!;
              minutes = count * duration['minutes']!;
              
              // Convertir minutos extra a horas
              hours += minutes ~/ 60;
              minutes = minutes % 60;
            }
          } else {
            // Fallback para turnos sin plantilla
            switch (shiftName) {
              case 'D1':
              case 'D2':
                hours = count * 12;
                break;
              case 'Libre':
              case 'Descanso':
                hours = 0;
                break;
              default:
                hours = count * 8;
                break;
            }
          }
          
          return Column(
            children: [
              _buildTableRow(
                shiftName: shiftName,
                quantity: count.toString(),
                time: '${hours}h,${minutes}m',
                color: color,
              ),
              const SizedBox(height: 4), // Reducido de 8 a 6
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTableRow({
    required String shiftName,
    required String quantity,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        // Columna de turnos con tamaño horizontal ajustado
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              shiftName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Columna de cantidad
        Expanded(
          flex: 1,
          child: Text(
            quantity,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Columna de tiempo
        Expanded(
          flex: 1,
          child: Text(
            time,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Columna de checkbox interactivo
        Expanded(
          flex: 1,
          child: Checkbox(
            value: _selectedShifts[shiftName] ?? true,
            onChanged: (value) => _toggleShiftSelection(shiftName),
            activeColor: Colors.green,
            checkColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalSummary(int totalShifts, int totalHours) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Global: $totalShifts Turnos',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Text(
            '${totalHours}h,0m',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyNotesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Título
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10), // Reducido de 16 a 12
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              'NOTAS CERCANAS (30 DÍAS)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(10), // Reducido de 16 a 12
            child: Column(
              children: [
                // Filtros de notas
                _buildNotesFilterSegments(),
                
                const SizedBox(height: 10), // Reducido de 16 a 12
                
                // Lista de notas
                _buildNotesList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesFilterSegments() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildNotesFilterSegment('Pasadas', _selectedNotesFilter == 'Pasadas'),
          _buildNotesFilterSegment('Próximas', _selectedNotesFilter == 'Próximas'),
        ],
      ),
    );
  }

  Widget _buildNotesFilterSegment(String text, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedNotesFilter = text;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesList() {
    print('DEBUG: _buildNotesList called');
    print('DEBUG: DataService notes: ${_dataService.notes}');
    
    // Calcular el rango de 30 días
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    
    final List<Map<String, dynamic>> nearbyNotes = [];
    
    // Obtener notas del rango de fechas
    for (final entry in _dataService.notes.entries) {
      final dateKey = entry.key;
      final notesList = entry.value;
      
      try {
        final parts = dateKey.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          final noteDate = DateTime(year, month, day);
          
          // Verificar si está en el rango de 30 días
          if (_selectedNotesFilter == 'Pasadas') {
            if (noteDate.isAfter(thirtyDaysAgo) && noteDate.isBefore(now)) {
              for (final note in notesList) {
                nearbyNotes.add({
                  'date': noteDate,
                  'title': note.toString(),
                  'dateKey': dateKey,
                });
              }
            }
          } else { // 'Próximas'
            if (noteDate.isAfter(now) && noteDate.isBefore(thirtyDaysFromNow)) {
              for (final note in notesList) {
                nearbyNotes.add({
                  'date': noteDate,
                  'title': note.toString(),
                  'dateKey': dateKey,
                });
              }
            }
          }
        }
      } catch (e) {
        print('Error procesando fecha de nota $dateKey: $e');
      }
    }
    
    // Ordenar por fecha
    nearbyNotes.sort((a, b) => a['date'].compareTo(b['date']));
    
    print('DEBUG: Found ${nearbyNotes.length} nearby notes');
    
    if (nearbyNotes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No hay notas cercanas',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nearbyNotes.length,
      itemBuilder: (context, index) {
        final note = nearbyNotes[index];
        final date = note['date'] as DateTime;
        final title = note['title'] as String;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Icon(
              _selectedNotesFilter == 'Pasadas' ? Icons.history : Icons.schedule,
              color: Colors.blue,
            ),
            title: Text(title),
            subtitle: Text('${date.day}/${date.month}/${date.year}'),
            trailing: Icon(
              _selectedNotesFilter == 'Pasadas' ? Icons.arrow_back : Icons.arrow_forward,
              color: Colors.grey,
            ),
          ),
        );
      },
    );
  }

  // Sección de Buscar en Notas
  Widget _buildSearchInNotesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Título
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              'BUSCAR EN NOTAS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Campo de búsqueda y botón
                Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Notas...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: (_) => _searchInNotes(),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _searchInNotes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('BUSCAR'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // Resultados de búsqueda
                if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
                  const Text(
                    'No hay datos para mostrar',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  )
                else if (_searchResults.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      final date = result['date'] as DateTime;
                      final title = result['title'] as String;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.note, color: Colors.blue),
                          title: Text(title),
                          subtitle: Text('${date.day}/${date.month}/${date.year}'),
                          trailing: const Icon(Icons.arrow_forward, color: Colors.grey),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sección de Buscar Días por Icono
  Widget _buildSearchDaysByIconSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Título
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              'BUSCAR DÍAS POR ICONO',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Dropdown de iconos y checkbox
                Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedIcon,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: _availableIcons.map((icon) {
                        return DropdownMenuItem(
                          value: icon,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getCategoryIcon(icon), size: 18),
                              const SizedBox(width: 14),
                              Flexible(
                                child: Text(
                                  icon,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedIcon = value;
                          });
                          _searchDaysByIcon();
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _includePastDays,
                          onChanged: (value) {
                            setState(() {
                              _includePastDays = value ?? false;
                            });
                            _searchDaysByIcon();
                          },
                        ),
                        const Flexible(
                          child: Text(
                            'Días pasados',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // Resultados de búsqueda por icono
                if (_iconSearchResults.isEmpty)
                  const Text(
                    'No se han encontrado días con el icono seleccionado',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _iconSearchResults.length,
                    itemBuilder: (context, index) {
                      final result = _iconSearchResults[index];
                      final date = result['date'] as DateTime;
                      final categories = result['categories'] as Map<String, dynamic>;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          leading: Icon(_getCategoryIcon(_selectedIcon), color: Colors.blue),
                          title: Text('${date.day}/${date.month}/${date.year}'),
                          subtitle: Text('Categoría: $_selectedIcon'),
                          trailing: const Icon(Icons.arrow_forward, color: Colors.grey),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método auxiliar para obtener icono de categoría
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
      case 'Cumpleaños':
        return Icons.cake; // Cambiado de pets a cake para cumpleaños
      case 'Favorito':
        return Icons.favorite;
      case 'Coche':
        return Icons.directions_car;
      default:
        return Icons.category;
    }
  }
}
