// ⚠️ ARCHIVO TERMINADO - NO MODIFICAR ⚠️
// Este archivo está completamente funcional y no debe modificarse
// Última modificación: [Fecha actual]
// Si necesitas cambios, consulta primero con el usuario

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:calendario_familiar/core/services/calendar_data_service.dart';

class YearSummaryScreen extends ConsumerStatefulWidget {
  
  const YearSummaryScreen({
    super.key,
    required this.year,
  });
  final int year;

  @override
  ConsumerState<YearSummaryScreen> createState() => _YearSummaryScreenState();
}

class _YearSummaryScreenState extends ConsumerState<YearSummaryScreen> {
  late CalendarDataService _dataService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService = ref.watch(calendarDataServiceProvider);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${widget.year}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Header superior con navegación de años
          _buildTopHeader(),
          
          // Grid de meses
          Expanded(
            child: _buildMonthsGrid(),
          ),
        ],
      ),
    );

  Widget _buildTopHeader() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        border: Border.all(color: Colors.transparent, width: 0),
      ),
      child: Row(
        children: [
          // Botón año anterior
          GestureDetector(
            onTap: () {
              context.pop();
              context.push('/year-summary', extra: widget.year - 1);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.year - 1}',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Botón año siguiente
          GestureDetector(
            onTap: () {
              context.pop();
              context.push('/year-summary', extra: widget.year + 1);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.year + 1}',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );

  Widget _buildMonthsGrid() => GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9, // Hacer los meses más altos para mostrar solo 6 en pantalla
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 12, // Mantener 12 meses para el scroll
      itemBuilder: (context, index) {
        final month = index + 1;
        return _buildMonthCard(month);
      },
    );

  Widget _buildMonthCard(int month) {
    final monthName = _getMonthName(month);
    final firstDayOfMonth = DateTime(widget.year, month, 1);
    final lastDayOfMonth = DateTime(widget.year, month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del mes
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              monthName.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Días de la semana
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: ['L', 'M', 'X', 'J', 'V', 'S', 'D'].map((day) => Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                )).toList(),
            ),
          ),
          
          // Días del mes
          Expanded(
            child: _buildMonthDays(firstWeekday, daysInMonth, month),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthDays(int firstWeekday, int daysInMonth, int month) {
    final totalDays = firstWeekday - 1 + daysInMonth;
    final weeks = (totalDays / 7).ceil();
    
    return Column(
      children: List.generate(weeks, (weekIndex) => Expanded(
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }
              
                             final date = DateTime(widget.year, month, dayNumber);
               final events = _dataService.getEventsForDay(date);
               final isToday = DateTime.now().day == dayNumber && 
                              DateTime.now().month == month && 
                              DateTime.now().year == widget.year;
               
               return Expanded(
                 child: Container(
                   margin: const EdgeInsets.all(0.5),
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(2),
                     border: isToday ? Border.all(color: Colors.orange, width: 1) : null,
                   ),
                   child: Stack(
                     children: [
                       // Fondo de color si hay eventos
                       if (events.isNotEmpty)
                         Positioned.fill(
                           child: _buildDayBackground(date, events),
                         ),
                       
                       // Número del día
                       Positioned(
                         top: 1,
                         left: 1,
                         child: Text(
                           dayNumber.toString(),
                           style: TextStyle(
                             fontSize: 8,
                             fontWeight: FontWeight.bold,
                             color: _getDayNumberColor(date, events, isToday),
                           ),
                         ),
                       ),
                       
                       // Contenido del día (turnos)
                       if (_hasShifts(events))
                         Positioned(
                           top: 12,
                           left: 0,
                           right: 0,
                           bottom: 0,
                           child: _buildDayContent(date, events),
                         ),
                     ],
                   ),
                 ),
               );
            }),
          ),
        )),
    );
  }

  Widget _buildDayBackground(DateTime date, List<String> events) {
    // Separar turnos y notas
    final List<Map<String, dynamic>> shifts = [];
    for (final eventTitle in events) {
      final template = _dataService.getShiftTemplateByName(eventTitle);
      if (template != null) {
        shifts.add({
          'name': template.name,
          'color': Color(int.parse(template.colorHex.substring(1, 7), radix: 16) + 0xFF000000),
        });
      }
    }
    
    // Si no hay turnos, fondo blanco
    if (shifts.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    
    // Si hay un turno, color completo
    if (shifts.length == 1) {
      return Container(
        decoration: BoxDecoration(
          color: shifts.first['color'],
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    
    // Si hay dos o más turnos, dividir la celda en mitades iguales
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        children: [
          // Mitad superior con el primer turno (50%)
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: shifts.first['color'],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(2),
                ),
              ),
            ),
          ),
          // Mitad inferior con el segundo turno (50%)
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: shifts[1]['color'],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(2),
                  bottomRight: Radius.circular(2),
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

  Widget _buildDayContent(DateTime date, List<String> events) {
    final List<Map<String, dynamic>> shifts = [];
    
    // Separar turnos
    for (final eventTitle in events) {
      if (eventTitle.isNotEmpty) {
        final template = _dataService.getShiftTemplateByName(eventTitle);
        if (template != null) {
          shifts.add({
            'text': template.name,
            'color': Color(int.parse(template.colorHex.substring(1, 7), radix: 16) + 0xFF000000),
            'textColor': Colors.white,
          });
        }
      }
    }
    
    if (shifts.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Si hay un turno, mostrar texto completo
    if (shifts.length == 1) {
      return Center(
        child: Text(
          shifts.first['text'],
          style: TextStyle(
            fontSize: 6,
            fontWeight: FontWeight.bold,
            color: shifts.first['textColor'],
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    
    // Si hay dos turnos, mostrar en mitades iguales
    return Column(
      children: [
        // Mitad superior (50%)
        Expanded(
          flex: 1,
          child: Center(
            child: Text(
              shifts.first['text'],
              style: TextStyle(
                fontSize: 5,
                fontWeight: FontWeight.bold,
                color: shifts.first['textColor'],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // Mitad inferior (50%)
        Expanded(
          flex: 1,
          child: Center(
            child: Text(
              shifts[1]['text'],
              style: TextStyle(
                fontSize: 5,
                fontWeight: FontWeight.bold,
                color: shifts[1]['textColor'],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
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
}
