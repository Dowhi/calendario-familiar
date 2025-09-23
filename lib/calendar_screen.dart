import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:calendario_familiar/main.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final _eventController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }

  Future<void> _addEvent() async {
    if (_eventController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un evento')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firestore = ref.read(firestoreProvider);
      final selectedDay = ref.read(selectedDayProvider);
      final user = ref.read(currentUserProvider).value;
      
      await firestore.collection('calendar_events').add({
        'title': _eventController.text,
        'date': Timestamp.fromDate(selectedDay),
        'timestamp': FieldValue.serverTimestamp(),
        'user': user?.uid ?? 'anonymous',
        'userEmail': user?.email ?? 'anonymous',
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento agregado exitosamente')),
      );
      
      _eventController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(selectedDayProvider);
    final focusedDay = ref.watch(focusedDayProvider);
    final calendarFormat = ref.watch(calendarFormatProvider);
    final calendarEvents = ref.watch(calendarEventsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario - Fase 7'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Calendario Familiar',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TableCalendar<String>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: focusedDay,
                  calendarFormat: calendarFormat,
                  eventLoader: (day) {
                    return calendarEvents.when(
                      data: (events) => events
                          .where((event) {
                            final data = event.data() as Map<String, dynamic>?;
                            final eventDate = (data?['date'] as Timestamp?)?.toDate();
                            return eventDate != null &&
                                eventDate.year == day.year &&
                                eventDate.month == day.month &&
                                eventDate.day == day.day;
                          })
                          .map((event) {
                            final data = event.data() as Map<String, dynamic>?;
                            return data?['title'] ?? 'Evento';
                          })
                          .toList()
                          .cast<String>(),
                      loading: () => <String>[],
                      error: (error, stack) => <String>[],
                    );
                  },
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: const CalendarStyle(
                    outsideDaysVisible: false,
                    markersMaxCount: 3,
                    markerDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    ref.read(selectedDayProvider.notifier).state = selectedDay;
                    ref.read(focusedDayProvider.notifier).state = focusedDay;
                  },
                  onFormatChanged: (format) {
                    ref.read(calendarFormatProvider.notifier).state = format;
                  },
                  selectedDayPredicate: (day) {
                    return isSameDay(selectedDay, day);
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Fecha seleccionada: ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _eventController,
                  decoration: const InputDecoration(
                    labelText: 'Agregar evento',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _addEvent,
                    child: const Text('Agregar Evento'),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Eventos del día:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                calendarEvents.when(
                  data: (events) {
                    final dayEvents = events.where((event) {
                      final data = event.data() as Map<String, dynamic>?;
                      final eventDate = (data?['date'] as Timestamp?)?.toDate();
                      return eventDate != null &&
                          eventDate.year == selectedDay.year &&
                          eventDate.month == selectedDay.month &&
                          eventDate.day == selectedDay.day;
                    }).toList();
                    
                    if (dayEvents.isEmpty) {
                      return const Text('No hay eventos para este día');
                    }
                    
                    return Column(
                      children: dayEvents.map((event) {
                        final data = event.data() as Map<String, dynamic>?;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(data?['title'] ?? 'Sin título'),
                            subtitle: Text(
                              'Usuario: ${data?['userEmail'] ?? 'Desconocido'}',
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Error: $error'),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Volver al Inicio'),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Si ves esto, el Calendario funciona en iPhone',
                  style: TextStyle(fontSize: 16, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
