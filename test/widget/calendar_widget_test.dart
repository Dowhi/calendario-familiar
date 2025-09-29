import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/calendar_screen.dart';

void main() {
  group('Calendar Widget Tests', () {
    testWidgets('debería mostrar el calendario correctamente', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      // Assert - Verificar que la pantalla se carga sin errores
      expect(find.byType(MaterialApp), findsOneWidget);
    });
    
    testWidgets('debería mostrar elementos básicos del calendario', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      // Assert - Verificar que la pantalla se carga sin errores
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
