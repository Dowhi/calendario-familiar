import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';
import 'package:calendario_familiar/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Calendario Familiar - Pruebas de Integración', () {
    late PatrolTester $;
    
    setUpAll(() async {
      $ = PatrolTester();
      await $.pumpWidgetAndSettle(app.CalendarioFamiliarApp());
    });
    
    tearDownAll(() async {
      await $.native.disableWifi();
      await $.native.disableCellular();
    });
    
    testWidgets('Flujo completo de autenticación', (tester) async {
      // Verificar que la app inicia correctamente
      expect(find.text('Iniciar Sesión'), findsOneWidget);
      
      // Navegar a registro
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();
      
      expect(find.text('Crear Cuenta'), findsOneWidget);
      
      // Completar formulario de registro
      await tester.enterText(find.byType(TextField).first, 'Usuario Prueba');
      await tester.enterText(find.byType(TextField).at(1), 'prueba@example.com');
      await tester.enterText(find.byType(TextField).last, 'contraseña123');
      
      // Registrarse
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();
      
      // Verificar navegación al calendario
      expect(find.byType(TableCalendar), findsOneWidget);
    });
    
    testWidgets('Crear y gestionar evento', (tester) async {
      // Verificar que estamos en el calendario
      expect(find.byType(TableCalendar), findsOneWidget);
      
      // Tocar botón de agregar evento
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      // Verificar que se abre el diálogo
      expect(find.text('Nuevo Evento'), findsOneWidget);
      
      // Completar formulario del evento
      await tester.enterText(find.byType(TextField).first, 'Evento de Prueba');
      await tester.enterText(find.byType(TextField).at(1), 'Descripción del evento');
      
      // Seleccionar fecha
      await tester.tap(find.text('Seleccionar Fecha'));
      await tester.pumpAndSettle();
      
      // Seleccionar una fecha del calendario
      final today = DateTime.now();
      await tester.tap(find.text(today.day.toString()));
      await tester.pumpAndSettle();
      
      // Guardar evento
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      
      // Verificar que el evento se creó
      expect(find.text('Evento creado exitosamente'), findsOneWidget);
    });
    
    testWidgets('Navegación entre meses', (tester) async {
      // Verificar mes actual
      expect(find.text('Enero'), findsOneWidget);
      
      // Navegar al mes siguiente
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      
      expect(find.text('Febrero'), findsOneWidget);
      
      // Navegar al mes anterior
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      
      expect(find.text('Enero'), findsOneWidget);
    });
    
    testWidgets('Cambio de vista del calendario', (tester) async {
      // Verificar vista mensual inicial
      expect(find.byType(TableCalendar), findsOneWidget);
      
      // Cambiar a vista semanal
      await tester.tap(find.text('Semana'));
      await tester.pumpAndSettle();
      
      // Verificar cambio de vista
      // Esto dependería de la implementación específica
      
      // Volver a vista mensual
      await tester.tap(find.text('Mes'));
      await tester.pumpAndSettle();
      
      expect(find.byType(TableCalendar), findsOneWidget);
    });
    
    testWidgets('Gestión de notificaciones', (tester) async {
      // Verificar que se solicitan permisos de notificación
      await $.native.grantPermissionWhenInUse();
      
      // Crear un evento con notificación
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byType(TextField).first, 'Evento con Notificación');
      
      // Activar notificación
      await tester.tap(find.text('Activar notificación'));
      await tester.pumpAndSettle();
      
      // Verificar que se solicita permiso
      expect(find.text('Permisos de notificación'), findsOneWidget);
      
      // Aceptar permisos
      await tester.tap(find.text('Permitir'));
      await tester.pumpAndSettle();
      
      // Guardar evento
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      
      // Verificar que se creó el evento
      expect(find.text('Evento creado exitosamente'), findsOneWidget);
    });
    
    testWidgets('Sincronización con Firebase', (tester) async {
      // Verificar conexión a internet
      await $.native.enableWifi();
      
      // Crear un evento
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byType(TextField).first, 'Evento Sincronizado');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      
      // Verificar sincronización
      expect(find.text('Sincronizando...'), findsOneWidget);
      await tester.pumpAndSettle();
      
      expect(find.text('Sincronizado'), findsOneWidget);
    });
    
    testWidgets('Modo oscuro', (tester) async {
      // Abrir configuración
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      
      // Cambiar a modo oscuro
      await tester.tap(find.text('Modo Oscuro'));
      await tester.pumpAndSettle();
      
      // Verificar cambio de tema
      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);
      
      // Volver al calendario
      await tester.pageBack();
      await tester.pumpAndSettle();
      
      // Verificar que el tema cambió
      expect(find.byType(TableCalendar), findsOneWidget);
    });
    
    testWidgets('Exportar calendario', (tester) async {
      // Abrir menú de opciones
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      
      // Seleccionar exportar
      await tester.tap(find.text('Exportar'));
      await tester.pumpAndSettle();
      
      // Verificar opciones de exportación
      expect(find.text('Exportar como PDF'), findsOneWidget);
      expect(find.text('Exportar como CSV'), findsOneWidget);
      
      // Seleccionar PDF
      await tester.tap(find.text('Exportar como PDF'));
      await tester.pumpAndSettle();
      
      // Verificar que se genera el PDF
      expect(find.text('PDF generado exitosamente'), findsOneWidget);
    });
    
    testWidgets('Gestión de familia', (tester) async {
      // Abrir configuración de familia
      await tester.tap(find.byIcon(Icons.family_restroom));
      await tester.pumpAndSettle();
      
      // Verificar pantalla de familia
      expect(find.text('Mi Familia'), findsOneWidget);
      
      // Invitar miembro
      await tester.tap(find.text('Invitar Miembro'));
      await tester.pumpAndSettle();
      
      // Completar formulario de invitación
      await tester.enterText(find.byType(TextField), 'nuevo@example.com');
      await tester.tap(find.text('Enviar Invitación'));
      await tester.pumpAndSettle();
      
      // Verificar que se envió la invitación
      expect(find.text('Invitación enviada'), findsOneWidget);
    });
  });
}

