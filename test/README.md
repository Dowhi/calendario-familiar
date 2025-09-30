# 🧪 Guía de Pruebas - Calendario Familiar

Esta guía explica cómo ejecutar y mantener las pruebas del proyecto Calendario Familiar usando TestSprite.

## 📋 Índice

- [Configuración Inicial](#configuración-inicial)
- [Tipos de Pruebas](#tipos-de-pruebas)
- [Ejecutar Pruebas](#ejecutar-pruebas)
- [Estructura de Archivos](#estructura-de-archivos)
- [Mejores Prácticas](#mejores-prácticas)
- [Solución de Problemas](#solución-de-problemas)

## 🚀 Configuración Inicial

### Requisitos Previos

- Flutter SDK (>=3.4.0)
- Dart SDK
- Dispositivo físico o emulador para pruebas de integración
- TestSprite configurado

### Instalación de Dependencias

```bash
flutter pub get
```

### Generar Mocks (si es necesario)

```bash
flutter packages pub run build_runner build
```

## 🧪 Tipos de Pruebas

### 1. Pruebas Unitarias (`test/unit/`)

Prueban funciones y clases individuales de forma aislada.

```bash
flutter test test/unit/
```

**Ejemplos:**
- Extensiones de DateTime
- Utilidades de formato
- Validaciones de datos
- Lógica de negocio

### 2. Pruebas de Widget (`test/widget/`)

Prueban componentes de UI individuales.

```bash
flutter test test/widget/
```

**Ejemplos:**
- Pantallas de autenticación
- Componentes del calendario
- Formularios de eventos
- Navegación entre pantallas

### 3. Pruebas de Integración (`integration_test/`)

Prueban flujos completos de la aplicación.

```bash
flutter test integration_test/
```

**Ejemplos:**
- Flujo de registro/login
- Creación y gestión de eventos
- Sincronización con Firebase
- Navegación completa

### 4. Pruebas End-to-End (`test/e2e/`)

Pruebas automatizadas que simulan interacciones reales del usuario.

```bash
flutter test test/e2e/
```

**Ejemplos:**
- Flujos completos de usuario
- Sincronización en tiempo real
- Gestión de permisos
- Exportación de datos

## 🏃‍♂️ Ejecutar Pruebas

### Scripts Automatizados

#### Windows
```bash
scripts\run_tests.bat [comando]
```

#### Linux/Mac
```bash
./scripts/run_tests.sh [comando]
```

### Comandos Disponibles

| Comando | Descripción |
|---------|-------------|
| `(sin argumentos)` | Ejecuta todas las pruebas |
| `unit` | Solo pruebas unitarias |
| `widget` | Solo pruebas de widget |
| `integration` | Solo pruebas de integración |
| `e2e` | Solo pruebas end-to-end |
| `coverage` | Pruebas con cobertura de código |
| `clean` | Limpiar archivos de prueba |
| `help` | Mostrar ayuda |

### Ejemplos de Uso

```bash
# Ejecutar todas las pruebas
./scripts/run_tests.sh

# Solo pruebas unitarias
./scripts/run_tests.sh unit

# Con cobertura de código
./scripts/run_tests.sh coverage

# Limpiar archivos temporales
./scripts/run_tests.sh clean
```

### Usando TestSprite Directamente

```bash
# Ejecutar todas las pruebas
dart test/test_sprite_runner.dart

# Pruebas específicas
dart test/test_sprite_runner.dart unit
dart test/test_sprite_runner.dart widget
dart test/test_sprite_runner.dart integration
dart test/test_sprite_runner.dart e2e

# Modo CI/CD
dart test/test_sprite_runner.dart ci

# Con cobertura
dart test/test_sprite_runner.dart coverage
```

## 📁 Estructura de Archivos

```
test/
├── README.md                    # Esta guía
├── test_sprite_config.yaml     # Configuración de TestSprite
├── test_sprite_runner.dart     # Ejecutor principal
├── helpers/
│   └── test_helpers.dart       # Funciones auxiliares
├── unit/
│   └── date_time_ext_test.dart # Pruebas de extensiones
├── widget/
│   ├── calendar_widget_test.dart
│   └── auth_widget_test.dart
└── e2e/
    └── calendar_e2e_test.dart

integration_test/
└── app_integration_test.dart

scripts/
├── run_tests.bat              # Script para Windows
└── run_tests.sh               # Script para Linux/Mac
```

## 🎯 Mejores Prácticas

### 1. Nomenclatura de Pruebas

```dart
testWidgets('debería mostrar el calendario correctamente', (tester) async {
  // Arrange
  // Act  
  // Assert
});
```

### 2. Organización de Pruebas

```dart
group('Calendar Widget Tests', () {
  setUp(() {
    // Configuración común
  });
  
  tearDown(() {
    // Limpieza
  });
  
  testWidgets('test específico', (tester) async {
    // Prueba individual
  });
});
```

### 3. Usar Helpers

```dart
import '../../helpers/test_helpers.dart';

testWidgets('ejemplo', (tester) async {
  await tester.pumpWidget(createTestWidget(const MyWidget()));
  await pumpAndSettle(tester);
  expectTextExists('Texto esperado');
});
```

### 4. Datos de Prueba

```dart
// Usar datos consistentes
final testEvent = createTestEventData();
final testUser = createTestUserData();
```

### 5. Mocks y Stubs

```dart
// Generar mocks automáticamente
@GenerateMocks([AuthService, CalendarService])
void main() {}

// Usar en las pruebas
final mockAuth = MockAuthService();
when(mockAuth.signIn(any)).thenAnswer((_) async => testUser);
```

## 🔧 Configuración Avanzada

### Firebase Emulator

Para pruebas que requieren Firebase:

```yaml
# test/test_sprite_config.yaml
firebase:
  test_mode: true
  emulator:
    enabled: true
    auth_port: 9099
    firestore_port: 8080
```

### Notificaciones

```yaml
notifications:
  enabled: true
  test_permissions: true
```

### Dispositivos de Prueba

```yaml
devices:
  android:
    - name: "Pixel 7"
      api_level: 33
  ios:
    - name: "iPhone 14"
      ios_version: "16.0"
```

## 🐛 Solución de Problemas

### Error: "No se encontró pubspec.yaml"

```bash
# Asegúrate de estar en el directorio raíz del proyecto
cd /ruta/al/proyecto/calendario_familiar
```

### Error: "Flutter no está instalado"

```bash
# Verificar instalación de Flutter
flutter doctor
```

### Error: "Dependencias faltantes"

```bash
# Actualizar dependencias
flutter pub get
flutter pub upgrade
```

### Error: "Mocks no generados"

```bash
# Generar mocks
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Error: "Emulador no encontrado"

```bash
# Listar emuladores disponibles
flutter emulators

# Iniciar emulador específico
flutter emulators --launch <emulator_id>
```

### Error: "Firebase no configurado"

```bash
# Verificar configuración de Firebase
firebase projects:list
firebase use <project_id>
```

## 📊 Reportes y Métricas

### Cobertura de Código

```bash
# Generar reporte de cobertura
./scripts/run_tests.sh coverage

# Ver reporte HTML
open coverage/html/index.html
```

### Reportes de TestSprite

Los reportes se generan automáticamente en `test_reports/`:

- `test_reports/html/index.html` - Reporte visual
- `test_reports/json/results.json` - Datos JSON
- `test_reports/junit/results.xml` - Formato JUnit

## 🤝 Contribuir

### Agregar Nuevas Pruebas

1. Crea el archivo de prueba en el directorio apropiado
2. Sigue las convenciones de nomenclatura
3. Usa los helpers disponibles
4. Documenta casos complejos
5. Ejecuta las pruebas antes de hacer commit

### Actualizar Configuración

1. Modifica `test_sprite_config.yaml`
2. Actualiza esta documentación
3. Prueba la nueva configuración
4. Comunica cambios al equipo

## 📞 Soporte

Para problemas o preguntas:

1. Revisa esta documentación
2. Consulta los logs de error
3. Verifica la configuración de TestSprite
4. Contacta al equipo de desarrollo

---

**¡Feliz testing! 🧪✨**

