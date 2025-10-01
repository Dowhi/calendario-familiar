import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendario_familiar/core/services/calendar_data_service.dart';
import 'package:calendario_familiar/core/services/pdf_service.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

class AdvancedReportsScreen extends ConsumerStatefulWidget {
  const AdvancedReportsScreen({super.key});

  @override
  ConsumerState<AdvancedReportsScreen> createState() => _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends ConsumerState<AdvancedReportsScreen> {
  late CalendarDataService _dataService;
  
  // Estados para filtros
  String _selectedReportType = 'Turnos por Período';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Set<String> _selectedShiftTypes = {'Todos'};
  String _selectedCategory = 'Todas';
  String _selectedSummaryType = 'Por Turnos';
  bool _isShiftTypesExpanded = false;
  
  // Estados para resultados
  Map<String, dynamic> _reportData = {};
  bool _isLoading = false;
  
  // Tipos de reportes disponibles
  final List<String> _reportTypes = [
    'Turnos por Período',
    'Horas Trabajadas',
    'Categorías por Día',
    'Notas y Eventos',
    'Productividad',
    'Ausencias',
    'Resumen por Meses',
  ];
  
  // Tipos de turnos disponibles
  List<String> get _shiftTypes => ['Todos', ..._dataService.shiftTemplates.map((t) => t.name)];
  
  // Verificar si todos los turnos están seleccionados
  bool get _isAllSelected => _selectedShiftTypes.contains('Todos') || _selectedShiftTypes.length == _shiftTypes.length - 1;
  
  // Categorías disponibles
  List<String> get _categories => [
    'Todas',
    'Cambio de turno',
    'Ingreso',
    'Importante',
    'Festivo',
    'Médico',
    'Cumpleaños',
    'Favorito',
    'Coche',
  ];

  // Tipos de resumen disponibles
  List<String> get _summaryTypes => [
    'Por Turnos',
    'Por Horas',
  ];

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = ref.watch(calendarDataServiceProvider);
  }

  void _generateReport() {
    setState(() {
      _isLoading = true;
    });

    // Simular procesamiento
    Future.delayed(const Duration(milliseconds: 500), () {
             switch (_selectedReportType) {
         case 'Turnos por Período':
           _generateShiftsReport();
           break;
         case 'Horas Trabajadas':
           _generateHoursReport();
           break;
         case 'Categorías por Día':
           _generateCategoriesReport();
           break;
         case 'Notas y Eventos':
           _generateNotesReport();
           break;
         case 'Productividad':
           _generateProductivityReport();
           break;
         case 'Ausencias':
           _generateAbsencesReport();
           break;
         case 'Resumen por Meses':
           _generateMonthlySummaryReport();
           break;
       }
      
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _generateShiftsReport() {
    final Map<String, int> shiftCounts = {};
    int totalShifts = 0;
    
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
          
          if (shiftDate.isAfter(_startDate.subtract(const Duration(days: 1))) && 
              shiftDate.isBefore(_endDate.add(const Duration(days: 1)))) {
            
                         for (final shift in shiftsList) {
               if (_selectedShiftTypes.contains('Todos') || _selectedShiftTypes.contains(shift)) {
                 shiftCounts[shift] = (shiftCounts[shift] ?? 0) + 1;
                 totalShifts++;
               }
             }
          }
        }
      } catch (e) {
        print('Error procesando fecha $dateKey: $e');
      }
    }
    
    _reportData = {
      'type': 'shifts',
      'data': shiftCounts,
      'total': totalShifts,
      'period': '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
    };
  }

  void _generateHoursReport() {
    final Map<String, int> hoursByShift = {};
    int totalHours = 0;
    
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
          
          if (shiftDate.isAfter(_startDate.subtract(const Duration(days: 1))) && 
              shiftDate.isBefore(_endDate.add(const Duration(days: 1)))) {
            
                         for (final shift in shiftsList) {
               if (_selectedShiftTypes.contains('Todos') || _selectedShiftTypes.contains(shift)) {
                 final shiftTemplate = _dataService.shiftTemplates.firstWhereOrNull(
                   (template) => template.name == shift,
                 );
                
                int hours = 8; // Default
                if (shiftTemplate != null) {
                  final startTime = shiftTemplate.startTime;
                  final endTime = shiftTemplate.endTime;
                  
                  try {
                    final startParts = startTime.split(':');
                    final endParts = endTime.split(':');
                    
                    if (startParts.length == 2 && endParts.length == 2) {
                      final startHour = int.parse(startParts[0]);
                      final startMinute = int.parse(startParts[1]);
                      final endHour = int.parse(endParts[0]);
                      final endMinute = int.parse(endParts[1]);
                      
                      int shiftHours = endHour - startHour;
                      int minutes = endMinute - startMinute;
                      
                      if (minutes < 0) {
                        shiftHours -= 1;
                        minutes += 60;
                      }
                      
                      if (shiftHours < 0) {
                        shiftHours += 24;
                      }
                      
                      hours = shiftHours;
                    }
                  } catch (e) {
                    print('Error calculando horas para turno $shift: $e');
                  }
                }
                
                hoursByShift[shift] = (hoursByShift[shift] ?? 0) + hours;
                totalHours += hours;
              }
            }
          }
        }
      } catch (e) {
        print('Error procesando fecha $dateKey: $e');
      }
    }
    
    _reportData = {
      'type': 'hours',
      'data': hoursByShift,
      'total': totalHours,
      'period': '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
    };
  }

  void _generateCategoriesReport() {
    final Map<String, int> categoryCounts = {};
    int totalDays = 0;
    
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
          
          if (categoryDate.isAfter(_startDate.subtract(const Duration(days: 1))) && 
              categoryDate.isBefore(_endDate.add(const Duration(days: 1)))) {
            
            totalDays++;
            
            for (final category in categories.values) {
              if (category != null && category != 'Ninguno') {
                if (_selectedCategory == 'Todas' || category == _selectedCategory) {
                  categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
                }
              }
            }
          }
        }
      } catch (e) {
        print('Error procesando fecha $dateKey: $e');
      }
    }
    
    _reportData = {
      'type': 'categories',
      'data': categoryCounts,
      'totalDays': totalDays,
      'period': '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
    };
  }

  void _generateNotesReport() {
    final Map<String, int> notesByDay = {};
    int totalNotes = 0;
    
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
          
          if (noteDate.isAfter(_startDate.subtract(const Duration(days: 1))) && 
              noteDate.isBefore(_endDate.add(const Duration(days: 1)))) {
            
            notesByDay[dateKey] = notesList.length;
            totalNotes += notesList.length;
          }
        }
      } catch (e) {
        print('Error procesando fecha $dateKey: $e');
      }
    }
    
    _reportData = {
      'type': 'notes',
      'data': notesByDay,
      'total': totalNotes,
      'period': '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
    };
  }

  void _generateProductivityReport() {
    // Reporte de productividad basado en días con eventos vs días vacíos
    int daysWithEvents = 0;
    int totalDays = 0;
    
    final startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final endDate = DateTime(_endDate.year, _endDate.month, _endDate.day);
    
    for (DateTime date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      totalDays++;
      
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final hasEvents = _dataService.shifts.containsKey(dateKey) || 
                       _dataService.notes.containsKey(dateKey) ||
                       _dataService.dayCategories.containsKey(dateKey);
      
      if (hasEvents) {
        daysWithEvents++;
      }
    }
    
    final productivityPercentage = totalDays > 0 ? (daysWithEvents / totalDays * 100).round() : 0;
    
    _reportData = {
      'type': 'productivity',
      'daysWithEvents': daysWithEvents,
      'totalDays': totalDays,
      'productivityPercentage': productivityPercentage,
      'period': '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
    };
  }

  void _generateAbsencesReport() {
    // Reporte de ausencias (días sin eventos)
    final List<String> absentDays = [];
    int totalAbsentDays = 0;
    
    final startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final endDate = DateTime(_endDate.year, _endDate.month, _endDate.day);
    
    for (DateTime date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final hasEvents = _dataService.shifts.containsKey(dateKey) || 
                       _dataService.notes.containsKey(dateKey) ||
                       _dataService.dayCategories.containsKey(dateKey);
      
      if (!hasEvents) {
        absentDays.add(DateFormat('dd/MM/yyyy').format(date));
        totalAbsentDays++;
      }
    }
    
         _reportData = {
       'type': 'absences',
       'absentDays': absentDays,
       'totalAbsentDays': totalAbsentDays,
       'period': '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
     };
   }

     void _generateMonthlySummaryReport() {
    // Reporte de resumen por meses con turnos o horas
    final Map<String, Map<String, int>> monthlyData = {};
    final List<String> months = [];
    
    // Obtener todos los meses en el rango de fechas
    final startDate = DateTime(_startDate.year, _startDate.month, 1);
    final endDate = DateTime(_endDate.year, _endDate.month + 1, 0);
    
    for (DateTime date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = DateTime(date.year, date.month + 1, 1)) {
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final monthName = DateFormat('MMMM yyyy', 'es_ES').format(date);
      
      if (!months.contains(monthName)) {
        months.add(monthName);
        monthlyData[monthKey] = {};
      }
    }
    
    // Procesar turnos por mes
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
          
          if (shiftDate.isAfter(_startDate.subtract(const Duration(days: 1))) && 
              shiftDate.isBefore(_endDate.add(const Duration(days: 1)))) {
            
            final monthKey = '$year-${month.toString().padLeft(2, '0')}';
            
                         for (final shift in shiftsList) {
               if (_selectedShiftTypes.contains('Todos') || _selectedShiftTypes.contains(shift)) {
                 if (_selectedSummaryType == 'Por Turnos') {
                   // Contar turnos
                   monthlyData[monthKey]![shift] = (monthlyData[monthKey]![shift] ?? 0) + 1;
                 } else {
                   // Calcular horas
                   final shiftTemplate = _dataService.shiftTemplates.firstWhereOrNull(
                     (template) => template.name == shift,
                   );
                  
                  int hours = 8; // Default
                  if (shiftTemplate != null) {
                    final startTime = shiftTemplate.startTime;
                    final endTime = shiftTemplate.endTime;
                    
                    try {
                      final startParts = startTime.split(':');
                      final endParts = endTime.split(':');
                      
                      if (startParts.length == 2 && endParts.length == 2) {
                        final startHour = int.parse(startParts[0]);
                        final startMinute = int.parse(startParts[1]);
                        final endHour = int.parse(endParts[0]);
                        final endMinute = int.parse(endParts[1]);
                        
                        int shiftHours = endHour - startHour;
                        int minutes = endMinute - startMinute;
                        
                        if (minutes < 0) {
                          shiftHours -= 1;
                          minutes += 60;
                        }
                        
                        if (shiftHours < 0) {
                          shiftHours += 24;
                        }
                        
                        hours = shiftHours;
                      }
                    } catch (e) {
                      print('Error calculando horas para turno $shift: $e');
                    }
                  }
                  
                  monthlyData[monthKey]![shift] = (monthlyData[monthKey]![shift] ?? 0) + hours;
                }
              }
            }
          }
        }
      } catch (e) {
        print('Error procesando fecha $dateKey: $e');
      }
    }
    
    // Obtener todos los tipos de turnos únicos
    final Set<String> allShiftTypes = {};
    for (final monthData in monthlyData.values) {
      allShiftTypes.addAll(monthData.keys);
    }
    final List<String> shiftTypes = allShiftTypes.toList()..sort();
    
    _reportData = {
      'type': 'monthly_summary',
      'months': months,
      'shiftTypes': shiftTypes,
      'monthlyData': monthlyData,
      'summaryType': _selectedSummaryType,
      'period': '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
    };
  }

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
      });
      _generateReport();
    }
  }

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
      });
      _generateReport();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.grey[100],
             appBar: AppBar(
         title: const Text('Reportes'),
         backgroundColor: Colors.grey[800],
         foregroundColor: Colors.white,
                   actions: [
            if (_reportData.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: _showPdfPreview,
                tooltip: 'Vista previa PDF',
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _exportToPdf,
                tooltip: 'Descargar PDF',
              ),
            ],
          ],
       ),
      body: SafeArea(
        child: Column(
          children: [
            // Filtros
            _buildFiltersSection(),
            
            // Contenido del reporte
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildReportContent(),
            ),
          ],
        ),
      ),
    );

  Widget _buildFiltersSection() => Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                     Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               const Text(
                 'Filtros ',
                 style: TextStyle(
                   fontSize: 16,
                   fontWeight: FontWeight.bold,
                 ),
               ),
             ],
           ),
          const SizedBox(height: 16),
          
          // Tipo de reporte
          DropdownButtonFormField<String>(
            value: _selectedReportType,
            decoration: const InputDecoration(
              labelText: 'Tipo de Reporte',
              border: OutlineInputBorder(),
            ),
            items: _reportTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedReportType = value;
                });
                _generateReport();
              }
            },
          ),
          
          const SizedBox(height: 12),
          
          // Rango de fechas
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectStartDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fecha Inicio',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_startDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _selectEndDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fecha Fin',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_endDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
                                 // Filtros adicionales según el tipo de reporte
            if (_selectedReportType == 'Turnos por Período' || _selectedReportType == 'Horas Trabajadas') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botón para expandir/colapsar
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isShiftTypesExpanded = !_isShiftTypesExpanded;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tipos de Turno',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedShiftTypes.contains('Todos') 
                                    ? 'Todos los turnos' 
                                    : '${_selectedShiftTypes.length} turno${_selectedShiftTypes.length != 1 ? 's' : ''} seleccionado${_selectedShiftTypes.length != 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            _isShiftTypesExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Contenido expandible
                  if (_isShiftTypesExpanded) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          // Botón "Seleccionar Todos"
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (_isAllSelected) {
                                  _selectedShiftTypes.clear();
                                } else {
                                  _selectedShiftTypes = _shiftTypes.toSet();
                                }
                              });
                              _generateReport();
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _isAllSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _isAllSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedShiftTypes = _shiftTypes.toSet();
                                        } else {
                                          _selectedShiftTypes.clear();
                                        }
                                      });
                                      _generateReport();
                                    },
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const Text(
                                    'Seleccionar Todos',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Lista de turnos individuales
                          ..._shiftTypes.where((type) => type != 'Todos').map((type) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (_selectedShiftTypes.contains(type)) {
                                    _selectedShiftTypes.remove(type);
                                    _selectedShiftTypes.remove('Todos');
                                  } else {
                                    _selectedShiftTypes.add(type);
                                    // Si todos los turnos están seleccionados, agregar "Todos"
                                    if (_selectedShiftTypes.length == _shiftTypes.length - 1) {
                                      _selectedShiftTypes.add('Todos');
                                    }
                                  }
                                });
                                _generateReport();
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedShiftTypes.contains(type) ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _selectedShiftTypes.contains(type),
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedShiftTypes.add(type);
                                            // Si todos los turnos están seleccionados, agregar "Todos"
                                            if (_selectedShiftTypes.length == _shiftTypes.length - 1) {
                                              _selectedShiftTypes.add('Todos');
                                            }
                                          } else {
                                            _selectedShiftTypes.remove(type);
                                            _selectedShiftTypes.remove('Todos');
                                          }
                                        });
                                        _generateReport();
                                      },
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    Text(type),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          
                     if (_selectedReportType == 'Categorías por Día') ...[
             DropdownButtonFormField<String>(
               value: _selectedCategory,
               decoration: const InputDecoration(
                 labelText: 'Categoría',
                 border: OutlineInputBorder(),
               ),
               items: _categories.map((category) {
                 return DropdownMenuItem(
                   value: category,
                   child: Text(category),
                 );
               }).toList(),
               onChanged: (value) {
                 if (value != null) {
                   setState(() {
                     _selectedCategory = value;
                   });
                   _generateReport();
                 }
               },
             ),
           ],
           
           if (_selectedReportType == 'Resumen por Meses') ...[
             DropdownButtonFormField<String>(
               value: _selectedSummaryType,
               decoration: const InputDecoration(
                 labelText: 'Resumen por',
                 border: OutlineInputBorder(),
               ),
               items: _summaryTypes.map((type) {
                 return DropdownMenuItem(
                   value: type,
                   child: Text(type),
                 );
               }).toList(),
               onChanged: (value) {
                 if (value != null) {
                   setState(() {
                     _selectedSummaryType = value;
                   });
                   _generateReport();
                 }
               },
             ),
           ],
        ],
      ),
    );

  Widget _buildReportContent() {
    if (_reportData.isEmpty) {
      return const Center(
        child: Text(
          'Selecciona un tipo de reporte para comenzar',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Encabezado del reporte
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedReportType,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Período: ${_reportData['period']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Contenido específico del reporte
            _buildReportSpecificContent(),
          ],
        ),
      ),
    );
  }

     Widget _buildReportSpecificContent() {
     final reportType = _reportData['type'] as String?;
     
     switch (reportType) {
       case 'shifts':
         return _buildShiftsReportContent();
       case 'hours':
         return _buildHoursReportContent();
       case 'categories':
         return _buildCategoriesReportContent();
       case 'notes':
         return _buildNotesReportContent();
       case 'productivity':
         return _buildProductivityReportContent();
       case 'absences':
         return _buildAbsencesReportContent();
       case 'monthly_summary':
         return _buildMonthlySummaryReportContent();
       default:
         return const SizedBox.shrink();
     }
   }

  Widget _buildShiftsReportContent() {
    final data = _reportData['data'] as Map<String, int>;
    final total = _reportData['total'] as int;
    
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resumen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Total: $total turnos',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...data.entries.map((entry) {
            final percentage = total > 0 ? (entry.value / total * 100).round() : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${entry.value}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '$percentage%',
                      textAlign: TextAlign.end,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHoursReportContent() {
    final data = _reportData['data'] as Map<String, int>;
    final total = _reportData['total'] as int;
    
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Horas por Turno',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Total: ${total}h',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...data.entries.map((entry) {
            final percentage = total > 0 ? (entry.value / total * 100).round() : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${entry.value}h',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '$percentage%',
                      textAlign: TextAlign.end,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoriesReportContent() {
    final data = _reportData['data'] as Map<String, int>;
    final totalDays = _reportData['totalDays'] as int;
    
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categorías',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Total días: $totalDays',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...data.entries.map((entry) {
            final percentage = totalDays > 0 ? (entry.value / totalDays * 100).round() : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${entry.value}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '$percentage%',
                      textAlign: TextAlign.end,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNotesReportContent() {
    final data = _reportData['data'] as Map<String, int>;
    final total = _reportData['total'] as int;
    
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notas por Día',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Total: $total notas',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...data.entries.take(10).map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${entry.value} notas',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )),
                     if (data.length > 10)
             Padding(
               padding: const EdgeInsets.only(top: 8),
               child: Text(
                 '... y ${data.length - 10} días más',
                 style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildProductivityReportContent() {
    final daysWithEvents = _reportData['daysWithEvents'] as int;
    final totalDays = _reportData['totalDays'] as int;
    final productivityPercentage = _reportData['productivityPercentage'] as int;
    
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Productividad',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Indicador de productividad
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getProductivityColor(productivityPercentage),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '$productivityPercentage%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Productividad',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Estadísticas detalladas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Días con Eventos',
                  '$daysWithEvents',
                  Icons.event,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Días Totales',
                  '$totalDays',
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAbsencesReportContent() {
    final absentDays = _reportData['absentDays'] as List<String>;
    final totalAbsentDays = _reportData['totalAbsentDays'] as int;
    
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sin Eventos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Total: $totalAbsentDays días',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (absentDays.isNotEmpty) ...[
            const Text(
              'Fechas sin eventos:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...absentDays.take(10).map((date) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $date',
                  style: const TextStyle(color: Colors.grey),
                ),
              )),
                         if (absentDays.length > 10)
               Padding(
                 padding: const EdgeInsets.only(top: 8),
                 child: Text(
                   '... y ${absentDays.length - 10} días más',
                   style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                 ),
               ),
          ] else ...[
            const Text(
              '¡Excelente! No hay días sin eventos en este período.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryReportContent() {
    final months = _reportData['months'] as List<String>;
    final shiftTypes = _reportData['shiftTypes'] as List<String>;
    final monthlyData = _reportData['monthlyData'] as Map<String, Map<String, int>>;
    final summaryType = _reportData['summaryType'] as String? ?? 'Por Turnos';
    
    // Calcular totales por columna
    final Map<String, int> columnTotals = {};
    for (final shiftType in shiftTypes) {
      columnTotals[shiftType] = 0;
      for (final monthData in monthlyData.values) {
        columnTotals[shiftType] = columnTotals[shiftType]! + (monthData[shiftType] ?? 0);
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meses - $summaryType',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Total: ${months.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tabla de resumen mensual
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              dataTextStyle: const TextStyle(fontSize: 13),
              columns: [
                const DataColumn(label: Text('Mes')),
                ...shiftTypes.map((shiftType) => DataColumn(
                  label: Text(shiftType),
                )),
              ],
              rows: [
                // Filas de datos por mes
                ...months.map((monthName) {
                  // Encontrar el monthKey correspondiente
                  String? monthKey;
                  for (final entry in monthlyData.entries) {
                    final date = DateTime.parse('${entry.key}-01');
                    final formattedMonth = DateFormat('MMMM yyyy', 'es_ES').format(date);
                    if (formattedMonth == monthName) {
                      monthKey = entry.key;
                      break;
                    }
                  }
                  
                  final monthData = monthKey != null ? monthlyData[monthKey]! : <String, int>{};
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(monthName)),
                      ...shiftTypes.map((shiftType) => DataCell(
                        Text(monthData[shiftType]?.toString() ?? '0'),
                      )),
                    ],
                  );
                }),
                
                // Fila de totales
                DataRow(
                  color: WidgetStateProperty.all(Colors.grey[100]),
                  cells: [
                    const DataCell(
                      Text(
                        'TOTAL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ...shiftTypes.map((shiftType) => DataCell(
                      Text(
                        columnTotals[shiftType]?.toString() ?? '0',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

     Color _getProductivityColor(int percentage) {
     if (percentage >= 80) return Colors.green;
     if (percentage >= 60) return Colors.orange;
     return Colors.red;
   }

   Future<void> _showPdfPreview() async {
     try {
       await PdfService.showPdfPreview(
         reportType: _selectedReportType,
         reportData: _reportData,
         period: _reportData['period'] ?? '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
       );
     } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Error al mostrar vista previa: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     }
   }

   Future<void> _exportToPdf() async {
     try {
       final filePath = await PdfService.generateReportPdf(
         reportType: _selectedReportType,
         reportData: _reportData,
         period: _reportData['period'] ?? '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
       );
       
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('PDF guardado en: $filePath'),
             backgroundColor: Colors.green,
             duration: const Duration(seconds: 5),
             action: SnackBarAction(
               label: 'OK',
               textColor: Colors.white,
               onPressed: () {},
             ),
           ),
         );
       }
     } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Error al generar PDF: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     }
   }
 }
