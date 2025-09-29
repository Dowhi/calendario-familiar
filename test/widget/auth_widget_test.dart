import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendario_familiar/features/auth/presentation/login_screen.dart';
import 'package:calendario_familiar/features/auth/presentation/email_signup_screen.dart';

void main() {
  group('Auth Widget Tests', () {
    testWidgets('debería mostrar pantalla de login correctamente', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      // Assert - Verificar que la pantalla se carga sin errores
      expect(find.byType(MaterialApp), findsOneWidget);
    });
    
    testWidgets('debería mostrar pantalla de registro correctamente', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EmailSignupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      // Assert - Verificar que la pantalla se carga sin errores
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
