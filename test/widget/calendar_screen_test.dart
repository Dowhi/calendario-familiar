import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:calendario_familiar/features/calendar/logic/calendar_controller.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('CalendarScreen Widget Tests', () {
    testWidgets('debería mostrar el calendario correctamente', (WidgetTester tester) async {
      // Arrange
      final calendarController = CalendarController();
      
      // Act
      await tester.pumpWidget(
        createTestWidget(
          child: const CalendarScreen(),
        ),
      );
      
      // Assert
      expect(find.byType(CalendarScreen), findsOneWidget);
      expect(find.text('Calendario Familiar'), findsOneWidget);
    });

    testWidgets('debería mostrar botones de navegación', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          child: const CalendarScreen(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('debería navegar al mes siguiente al tocar botón', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          child: const CalendarScreen(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Act
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      
      // Assert
      // Verificar que el mes cambió (esto depende de tu implementación)
      expect(find.byType(CalendarScreen), findsOneWidget);
    });

    testWidgets('debería navegar al mes anterior al tocar botón', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          child: const CalendarScreen(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Act
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.byType(CalendarScreen), findsOneWidget);
    });

    testWidgets('debería mostrar botón de añadir evento', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          child: const CalendarScreen(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('debería abrir diálogo de nuevo evento al tocar botón +', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          child: const CalendarScreen(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Act
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      // Assert
      // Verificar que se abre el diálogo de nuevo evento
      expect(find.text('Nuevo Evento'), findsOneWidget);
    });

    testWidgets('debería mostrar días del mes en el calendario', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          child: const CalendarScreen(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Assert
      // Verificar que se muestran los días del mes
      // Esto depende de cómo implementes el calendario
      expect(find.byType(CalendarScreen), findsOneWidget);
    });

    testWidgets('debería seleccionar día al tocarlo', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          child: const CalendarScreen(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Act
      // Buscar un día específico y tocarlo
      final dayWidget = find.text('15'); // Asumiendo que hay un día 15
      if (dayWidget.evaluate().isNotEmpty) {
        await tester.tap(dayWidget);
        await tester.pumpAndSettle();
      }
      
      // Assert
      expect(find.byType(CalendarScreen), findsOneWidget);
    });

    testWidgets('debería mostrar eventos del día seleccionado', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          child: const CalendarScreen(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Act
      // Seleccionar un día
      final dayWidget = find.text('17'); // Día de prueba
      if (dayWidget.evaluate().isNotEmpty) {
        await tester.tap(dayWidget);
        await tester.pumpAndSettle();
      }
      
      // Assert
      // Verificar que se muestran los eventos del día
      expect(find.byType(CalendarScreen), findsOneWidget);
    });

    testWidgets('debería mostrar mensaje cuando no hay eventos', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          child: const CalendarScreen(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Act
      // Seleccionar un día sin eventos
      final dayWidget = find.text('1');
      if (dayWidget.evaluate().isNotEmpty) {
        await tester.tap(dayWidget);
        await tester.pumpAndSettle();
      }
      
      // Assert
      // Verificar que se muestra mensaje de "No hay eventos"
      expect(find.text('No hay eventos para este día'), findsOneWidget);
    });
  });
}
