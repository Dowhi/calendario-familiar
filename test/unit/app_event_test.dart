import 'package:flutter_test/flutter_test.dart';
import 'package:calendario_familiar/core/models/app_event.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('AppEvent Tests', () {
    test('debería crear AppEvent correctamente', () {
      // Arrange
      const testEvent = AppEvent(
        id: TestData.testEventId,
        familyId: TestData.testFamilyId,
        title: 'Evento de prueba',
        description: 'Descripción del evento',
        dateKey: '2025-09-17',
        startTime: '10:00',
        endTime: '11:00',
        isAllDay: false,
      );

      // Assert
      expect(testEvent.id, equals(TestData.testEventId));
      expect(testEvent.familyId, equals(TestData.testFamilyId));
      expect(testEvent.title, equals('Evento de prueba'));
      expect(testEvent.description, equals('Descripción del evento'));
      expect(testEvent.dateKey, equals('2025-09-17'));
      expect(testEvent.startTime, equals('10:00'));
      expect(testEvent.endTime, equals('11:00'));
      expect(testEvent.isAllDay, equals(false));
    });

    test('debería crear AppEvent con valores por defecto', () {
      // Arrange
      const testEvent = AppEvent(
        id: TestData.testEventId,
        familyId: TestData.testFamilyId,
        title: 'Evento simple',
        dateKey: '2025-09-17',
      );

      // Assert
      expect(testEvent.type, equals(EventType.event));
      expect(testEvent.isAllDay, equals(true));
      expect(testEvent.allDay, equals(false));
      expect(testEvent.participants, equals([]));
      expect(testEvent.notifyMinutesBefore, equals(30));
    });

    test('debería crear AppEvent de tipo nota', () {
      // Arrange
      const testEvent = AppEvent(
        id: TestData.testEventId,
        familyId: TestData.testFamilyId,
        title: 'Nota importante',
        dateKey: '2025-09-17',
        type: EventType.note,
      );

      // Assert
      expect(testEvent.type, equals(EventType.note));
      expect(testEvent.title, equals('Nota importante'));
    });

    test('debería crear AppEvent de tipo turno', () {
      // Arrange
      const testEvent = AppEvent(
        id: TestData.testEventId,
        familyId: TestData.testFamilyId,
        title: 'Turno de noche',
        dateKey: '2025-09-17',
        type: EventType.shift,
        startTime: '22:00',
        endTime: '06:00',
      );

      // Assert
      expect(testEvent.type, equals(EventType.shift));
      expect(testEvent.title, equals('Turno de noche'));
      expect(testEvent.startTime, equals('22:00'));
      expect(testEvent.endTime, equals('06:00'));
    });

    test('debería crear AppEvent con participantes', () {
      // Arrange
      final participants = ['user1', 'user2', 'user3'];
      final testEvent = AppEvent(
        id: TestData.testEventId,
        familyId: TestData.testFamilyId,
        title: 'Reunión de equipo',
        dateKey: '2025-09-17',
        participants: participants,
      );

      // Assert
      expect(testEvent.participants, equals(participants));
      expect(testEvent.participants.length, equals(3));
    });

    test('debería crear AppEvent con color personalizado', () {
      // Arrange
      const testEvent = AppEvent(
        id: TestData.testEventId,
        familyId: TestData.testFamilyId,
        title: 'Evento con color',
        dateKey: '2025-09-17',
        colorHex: '#FF5733',
      );

      // Assert
      expect(testEvent.colorHex, equals('#FF5733'));
    });

    test('debería crear AppEvent con ubicación', () {
      // Arrange
      const testEvent = AppEvent(
        id: TestData.testEventId,
        familyId: TestData.testFamilyId,
        title: 'Reunión en oficina',
        dateKey: '2025-09-17',
        location: 'Oficina principal, Sala de juntas',
      );

      // Assert
      expect(testEvent.location, equals('Oficina principal, Sala de juntas'));
    });

    test('debería crear AppEvent con notificación personalizada', () {
      // Arrange
      const testEvent = AppEvent(
        id: TestData.testEventId,
        familyId: TestData.testFamilyId,
        title: 'Evento con notificación',
        dateKey: '2025-09-17',
        notifyMinutesBefore: 60,
      );

      // Assert
      expect(testEvent.notifyMinutesBefore, equals(60));
    });
  });
}
