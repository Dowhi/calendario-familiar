import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:calendario_familiar/core/models/family_calendar.dart';
import 'package:calendario_familiar/core/models/app_user.dart';
import 'package:calendario_familiar/features/calendar/data/repositories/calendar_repository.dart';
import 'package:calendario_familiar/features/auth/logic/auth_controller.dart';

part 'calendar_controller.g.dart';

@riverpod
class CalendarController extends _$CalendarController {
  late final CalendarRepository _calendarRepository;
  
  @override
  Future<FamilyCalendar?> build() async {
    _calendarRepository = CalendarRepository();
    
    final user = ref.read(authControllerProvider);
    
    if (user?.familyId != null) {
      return await _calendarRepository.getCalendar(user!.familyId!);
    }
    
    return null;
  }
  
  Future<void> createCalendar(String name) async {
    final user = ref.read(authControllerProvider);
    
    if (user == null) return;
    
    try {
      final calendar = await _calendarRepository.createCalendar(name, user.uid);
      
      // Actualizar el usuario con el nuevo familyId
      await ref.read(authControllerProvider.notifier).updateUserFamilyId(calendar.id);
      
      state = AsyncValue.data(calendar);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> addMember(String email) async {
    final calendar = state.value;
    if (calendar == null) return;
    
    try {
      final user = await _calendarRepository.findUserByEmail(email);
      if (user == null) {
        throw Exception('Usuario no encontrado');
      }
      
      await _calendarRepository.addMember(calendar.id, user.uid);
      
      // Recargar el calendario
      final updatedCalendar = await _calendarRepository.getCalendar(calendar.id);
      state = AsyncValue.data(updatedCalendar);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> removeMember(String memberId) async {
    final calendar = state.value;
    if (calendar == null) return;
    
    try {
      await _calendarRepository.removeMember(calendar.id, memberId);
      
      // Recargar el calendario
      final updatedCalendar = await _calendarRepository.getCalendar(calendar.id);
      state = AsyncValue.data(updatedCalendar);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<List<AppUser>> getMembers() async {
    final calendar = state.value;
    if (calendar == null) return [];
    
    try {
      return await _calendarRepository.getCalendarMembers(calendar.id);
    } catch (e) {
      print('Error obteniendo miembros: $e');
      return [];
    }
  }
}

@riverpod
Stream<FamilyCalendar?> calendarStream(CalendarStreamRef ref, String calendarId) {
  final repository = CalendarRepository();
  return repository.getCalendarStream(calendarId);
}

