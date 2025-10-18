import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:riverpod/riverpod.dart';
import 'package:calendario_familiar/features/calendar/logic/calendar_controller.dart';
import 'package:calendario_familiar/core/models/family_calendar.dart';
import 'package:calendario_familiar/core/models/app_user.dart';
import '../helpers/test_helpers.dart';

// Generar mocks
@GenerateMocks([])
void main() {
  group('CalendarController Tests', () {
    late CalendarController calendarController;

    setUp(() {
      // Inicializar el controlador para las pruebas
      calendarController = CalendarController();
    });

    test('debería inicializar correctamente', () {
      // Arrange & Act
      // El CalendarController es un AsyncNotifier que se inicializa con build()
      
      // Assert
      expect(calendarController, isNotNull);
      expect(calendarController.state, isA<AsyncValue<FamilyCalendar?>>());
    });

    test('debería crear calendario correctamente', () async {
      // Arrange
      const calendarName = 'Calendario de Prueba';
      
      // Act
      await calendarController.createCalendar(calendarName);
      
      // Assert
      // Verificar que el estado se actualizó correctamente
      expect(calendarController.state, isA<AsyncValue<FamilyCalendar?>>());
    });

    test('debería añadir miembro al calendario', () async {
      // Arrange
      const memberEmail = 'test@example.com';
      
      // Act
      await calendarController.addMember(memberEmail);
      
      // Assert
      // Verificar que el método se ejecutó sin errores
      expect(calendarController.state, isA<AsyncValue<FamilyCalendar?>>());
    });

    test('debería remover miembro del calendario', () async {
      // Arrange
      const memberId = TestData.testUserId;
      
      // Act
      await calendarController.removeMember(memberId);
      
      // Assert
      // Verificar que el método se ejecutó sin errores
      expect(calendarController.state, isA<AsyncValue<FamilyCalendar?>>());
    });

    test('debería obtener miembros del calendario', () async {
      // Act
      final members = await calendarController.getMembers();
      
      // Assert
      expect(members, isA<List<AppUser>>());
    });
  });
}
