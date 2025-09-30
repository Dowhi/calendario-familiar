import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:calendario_familiar/main.dart';
import 'package:calendario_familiar/core/services/auth_service.dart';
import 'package:calendario_familiar/core/services/calendar_service.dart';
import 'package:calendario_familiar/core/services/notification_service.dart';

// Genera mocks automáticamente
@GenerateMocks([
  AuthService,
  CalendarService,
  NotificationService,
])
void main() {}

/// Helper para crear un widget de prueba con ProviderScope
Widget createTestWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: child,
      theme: ThemeData.light(),
    ),
  );
}

/// Helper para crear la app completa en modo de prueba
Widget createTestApp() {
  return const ProviderScope(
    child: CalendarioFamiliarApp(),
  );
}

/// Helper para esperar a que se complete la animación
Future<void> pumpAndSettle(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// Helper para simular un tap en un elemento
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await pumpAndSettle(tester);
}

/// Helper para buscar texto y verificar que existe
void expectTextExists(String text) {
  expect(find.text(text), findsOneWidget);
}

/// Helper para verificar que un widget existe
void expectWidgetExists(Widget widget) {
  expect(find.byWidget(widget), findsOneWidget);
}

/// Helper para verificar que un widget no existe
void expectWidgetNotExists(Widget widget) {
  expect(find.byWidget(widget), findsNothing);
}

/// Helper para simular scroll
Future<void> scrollToAndSettle(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 500.0);
  await pumpAndSettle(tester);
}

/// Helper para simular entrada de texto
Future<void> enterTextAndSettle(WidgetTester tester, Finder finder, String text) async {
  await tester.enterText(finder, text);
  await pumpAndSettle(tester);
}

/// Helper para verificar que un diálogo está abierto
void expectDialogOpen(String title) {
  expect(find.text(title), findsOneWidget);
  expect(find.byType(AlertDialog), findsOneWidget);
}

/// Helper para cerrar un diálogo
Future<void> closeDialog(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.close));
  await pumpAndSettle(tester);
}

/// Helper para simular navegación hacia atrás
Future<void> goBack(WidgetTester tester) async {
  await tester.pageBack();
  await pumpAndSettle(tester);
}

/// Helper para verificar el estado de carga
void expectLoadingState() {
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
}

/// Helper para verificar que no hay estado de carga
void expectNotLoadingState() {
  expect(find.byType(CircularProgressIndicator), findsNothing);
}

/// Helper para simular una fecha específica
void mockCurrentDate(DateTime date) {
  // Esto se puede usar con paquetes como clock para mockear fechas
  // clock.withClock(Clock.fixed(date));
}

/// Helper para crear datos de prueba del calendario
Map<String, dynamic> createTestEventData() {
  return {
    'id': 'test_event_1',
    'title': 'Evento de Prueba',
    'description': 'Descripción del evento de prueba',
    'startDate': DateTime.now().toIso8601String(),
    'endDate': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    'isAllDay': false,
    'color': 0xFF2196F3,
    'userId': 'test_user_1',
  };
}

/// Helper para crear datos de usuario de prueba
Map<String, dynamic> createTestUserData() {
  return {
    'id': 'test_user_1',
    'email': 'test@example.com',
    'name': 'Usuario de Prueba',
    'photoUrl': null,
    'familyId': 'test_family_1',
  };
}

/// Helper para crear datos de familia de prueba
Map<String, dynamic> createTestFamilyData() {
  return {
    'id': 'test_family_1',
    'name': 'Familia de Prueba',
    'members': ['test_user_1'],
    'createdAt': DateTime.now().toIso8601String(),
  };
}

/// Helper para verificar permisos de notificación
Future<bool> checkNotificationPermission() async {
  // Mock implementation para pruebas
  return true;
}

/// Helper para simular notificación recibida
Future<void> simulateNotificationReceived(String title, String body) async {
  // Mock implementation para pruebas
  print('Notificación simulada: $title - $body');
}

/// Helper para limpiar datos de prueba
Future<void> cleanupTestData() async {
  // Mock implementation para limpiar datos de prueba
  print('Limpiando datos de prueba...');
}

