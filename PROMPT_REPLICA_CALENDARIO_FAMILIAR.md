# 📅 PROMPT PARA REPLICAR CALENDARIO FAMILIAR - FLUTTER WEB

## 🎯 DESCRIPCIÓN GENERAL

Crear una aplicación web Flutter completa de **Calendario Familiar** con las siguientes características:

### **Funcionalidades Principales:**
- ✅ **Autenticación**: Google Sign-In + Email/Password
- ✅ **Gestión de Familias**: Crear, unir, administrar familias
- ✅ **Calendario Interactivo**: Vista mensual con eventos, turnos y notas
- ✅ **Gestión de Turnos**: Crear, editar, eliminar turnos con plantillas
- ✅ **Notas Diarias**: Agregar notas por fecha
- ✅ **Sincronización en Tiempo Real**: Firebase Firestore
- ✅ **PWA**: Progressive Web App con manifest
- ✅ **Responsive**: Diseño adaptable a móvil y desktop

---

## 🏗️ ESTRUCTURA DEL PROYECTO

```
lib/
├── core/
│   ├── firebase/
│   │   └── firebase_config.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── family_model.dart
│   │   ├── event_model.dart
│   │   ├── shift_model.dart
│   │   ├── note_model.dart
│   │   └── alarm_model.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── family_service.dart
│   │   ├── calendar_service.dart
│   │   └── notification_service.dart
│   ├── utils/
│   │   ├── safe_conversion_utils.dart
│   │   ├── error_handler.dart
│   │   └── firebase_safe_utils.dart
│   └── widgets/
│       └── loading_widget.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── models/
│   │   │       └── auth_user_model.dart
│   │   ├── logic/
│   │   │   └── auth_controller.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   └── email_signup_screen.dart
│   │       └── widgets/
│   │           └── auth_form_widget.dart
│   ├── calendar/
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   ├── calendar_repository.dart
│   │   │   │   ├── family_repository.dart
│   │   │   │   └── shift_repository.dart
│   │   │   └── services/
│   │   │       └── calendar_data_service.dart
│   │   ├── logic/
│   │   │   ├── calendar_controller.dart
│   │   │   ├── family_controller.dart
│   │   │   └── shift_controller.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── calendar_screen.dart
│   │       │   ├── day_detail_screen.dart
│   │       │   ├── family_settings_screen.dart
│   │       │   ├── shift_template_management_screen.dart
│   │       │   └── statistics_screen.dart
│   │       └── widgets/
│   │           ├── calendar_widget.dart
│   │           ├── event_widget.dart
│   │           ├── shift_widget.dart
│   │           ├── note_widget.dart
│   │           └── alarm_dialog.dart
│   └── settings/
│       └── presentation/
│           └── screens/
│               └── settings_screen.dart
├── routing/
│   └── app_router.dart
├── theme/
│   └── app_theme.dart
└── main.dart
```

---

## 📦 DEPENDENCIAS REQUERIDAS

### **pubspec.yaml**
```yaml
name: calendario_familiar
description: Calendario familiar compartido con sincronización en tiempo real
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  
  # UI
  cupertino_icons: ^1.0.2
  go_router: ^14.8.1
  flutter_riverpod: ^2.6.1
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  
  # Firebase
  firebase_core: ^3.15.2
  cloud_firestore: ^5.6.12
  firebase_auth: ^5.7.0
  firebase_messaging: ^15.2.10
  
  # Google Sign-In
  google_sign_in: ^6.3.0
  
  # Notificaciones
  flutter_local_notifications: ^18.0.1
  
  # Utilidades
  intl: ^0.19.0
  shared_preferences: ^2.3.2
  permission_handler: ^11.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.5.4
  freezed: ^2.5.8
  json_serializable: ^6.9.5

flutter:
  uses-material-design: true
  assets:
    - assets/icons/
    - assets/images/
```

---

## 🔥 CONFIGURACIÓN FIREBASE

### **Firebase Setup:**
1. **Crear proyecto en Firebase Console**
2. **Habilitar Authentication** (Google + Email/Password)
3. **Crear Firestore Database** (modo de prueba)
4. **Configurar reglas de Firestore:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuarios pueden leer/escribir sus propios datos
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Familias: miembros pueden leer, admin puede escribir
    match /families/{familyId} {
      allow read: if request.auth != null && 
        (resource.data.members[request.auth.uid] != null || 
         request.auth.uid == resource.data.adminId);
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.adminId;
    }
    
    // Eventos: miembros de la familia pueden leer/escribir
    match /events/{eventId} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/families/$(resource.data.familyId)) &&
        get(/databases/$(database)/documents/families/$(resource.data.familyId)).data.members[request.auth.uid] != null;
    }
    
    // Turnos: miembros de la familia pueden leer/escribir
    match /shifts/{shiftId} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/families/$(resource.data.familyId)) &&
        get(/databases/$(database)/documents/families/$(resource.data.familyId)).data.members[request.auth.uid] != null;
    }
    
    // Notas: miembros de la familia pueden leer/escribir
    match /notes/{noteId} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/families/$(resource.data.familyId)) &&
        get(/databases/$(database)/documents/families/$(resource.data.familyId)).data.members[request.auth.uid] != null;
    }
    
    // Plantillas de turnos: miembros de la familia pueden leer/escribir
    match /shift_templates/{templateId} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/families/$(resource.data.familyId)) &&
        get(/databases/$(database)/documents/families/$(resource.data.familyId)).data.members[request.auth.uid] != null;
    }
  }
}
```

5. **Descargar firebase_options.dart** y colocar en `lib/firebase/`

---

## 🎨 DISEÑO Y TEMA

### **Colores Principales:**
```dart
// app_theme.dart
class AppTheme {
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
```

---

## 🔐 SISTEMA DE AUTENTICACIÓN

### **Características:**
- ✅ **Google Sign-In** integrado
- ✅ **Registro/Login con Email**
- ✅ **Gestión de sesión persistente**
- ✅ **Verificación de familia**

### **Flujo de Autenticación:**
1. **Pantalla de Login** → Google Sign-In o Email/Password
2. **Verificación de Familia** → ¿Usuario tiene familia?
3. **Si NO tiene familia** → Crear nueva familia
4. **Si SÍ tiene familia** → Acceso al calendario

---

## 👨‍👩‍👧‍👦 GESTIÓN DE FAMILIAS

### **Funcionalidades:**
- ✅ **Crear Familia**: Usuario se convierte en admin
- ✅ **Unirse a Familia**: Con código de invitación
- ✅ **Administrar Miembros**: Invitar, expulsar (solo admin)
- ✅ **Configuración de Familia**: Nombre, descripción

### **Estructura de Familia:**
```dart
class Family {
  final String id;
  final String name;
  final String description;
  final String adminId;
  final Map<String, FamilyRole> members;
  final String? invitationCode;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum FamilyRole {
  admin,
  member,
}
```

---

## 📅 SISTEMA DE CALENDARIO

### **Vista Principal:**
- ✅ **Vista Mensual** con navegación
- ✅ **Indicadores visuales** para días con eventos
- ✅ **Colores diferenciados** por tipo (turnos, notas, eventos)
- ✅ **Navegación rápida** entre meses

### **Gestión de Eventos:**
- ✅ **Crear eventos** con título, descripción, hora
- ✅ **Editar/eliminar** eventos existentes
- ✅ **Categorización** por colores
- ✅ **Alarmas** configurables

---

## 🔄 SISTEMA DE TURNOS

### **Plantillas de Turnos:**
```dart
class ShiftTemplate {
  final String id;
  final String name;
  final String description;
  final String startTime; // "08:00"
  final String endTime;   // "20:00"
  final String colorHex;  // "#FF5722"
  final String familyId;
}
```

### **Asignación de Turnos:**
- ✅ **Crear plantillas** personalizables
- ✅ **Asignar turnos** por fecha
- ✅ **Gestión de horarios** flexible
- ✅ **Colores personalizados**

---

## 📝 SISTEMA DE NOTAS

### **Características:**
- ✅ **Notas por fecha** específica
- ✅ **Texto libre** con formato básico
- ✅ **Persistencia** en Firestore
- ✅ **Sincronización** en tiempo real

---

## 🔔 NOTIFICACIONES

### **Tipos de Notificaciones:**
- ✅ **Alarmas de eventos** programables
- ✅ **Recordatorios** de turnos
- ✅ **Notificaciones push** (futuro)
- ✅ **Sistema de alertas** en la app

---

## 🌐 CONFIGURACIÓN WEB

### **PWA Setup:**
```html
<!-- web/index.html -->
<!DOCTYPE html>
<html>
<head>
  <base href="/">
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Calendario Familiar</title>
  <link rel="manifest" href="manifest.json">
  <link rel="icon" type="image/png" href="favicon.png"/>
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
```

### **Manifest.json:**
```json
{
  "name": "Calendario Familiar",
  "short_name": "Calendario",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#2196F3",
  "theme_color": "#2196F3",
  "description": "Calendario familiar para gestionar eventos y turnos",
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

---

## 🚀 COMANDOS DE DESPLIEGUE

### **Build para Web:**
```bash
flutter build web --release --base-href="/calendario-familiar/"
```

### **GitHub Pages:**
1. **Configurar repositorio** con rama `gh-pages`
2. **Copiar archivos** de `build/web/` a raíz de `gh-pages`
3. **Configurar GitHub Pages** desde rama `gh-pages`

---

## 🔧 UTILIDADES DE SEGURIDAD

### **SafeConversionUtils:**
```dart
class SafeConversionUtils {
  static String safeToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) return 'Map con ${value.length} elementos';
    if (value is List) return value.map((item) => safeToString(item)).join(', ');
    if (value is num) return value.toString();
    if (value is bool) return value ? 'true' : 'false';
    return '${value.runtimeType}';
  }
}
```

### **ErrorHandler:**
```dart
class ErrorHandler {
  static void handleError(dynamic error, [StackTrace? stackTrace]) {
    print('❌ Error: $error');
    if (stackTrace != null) {
      print('📍 Stack: $stackTrace');
    }
  }
  
  static T? safeExecute<T>(T Function() function, {T? defaultValue}) {
    try {
      return function();
    } catch (e) {
      handleError(e);
      return defaultValue;
    }
  }
}
```

---

## 📱 CARACTERÍSTICAS RESPONSIVE

### **Breakpoints:**
- **Mobile**: < 768px
- **Tablet**: 768px - 1024px  
- **Desktop**: > 1024px

### **Adaptaciones:**
- ✅ **Navegación**: Drawer en móvil, tabs en desktop
- ✅ **Calendario**: Vista compacta en móvil
- ✅ **Formularios**: Adaptados a pantalla táctil
- ✅ **Botones**: Tamaño optimizado para touch

---

## 🎯 FUNCIONALIDADES AVANZADAS

### **Estadísticas:**
- ✅ **Resumen mensual** de turnos
- ✅ **Gráficos** de participación
- ✅ **Reportes** exportables

### **Configuraciones:**
- ✅ **Tema claro/oscuro**
- ✅ **Idioma** (ES/EN)
- ✅ **Notificaciones** personalizables
- ✅ **Backup/Restore** de datos

---

## 🧪 TESTING

### **Tests Requeridos:**
- ✅ **Unit Tests** para servicios
- ✅ **Widget Tests** para componentes
- ✅ **Integration Tests** para flujos completos

---

## 📋 CHECKLIST DE IMPLEMENTACIÓN

### **Fase 1 - Setup Base:**
- [ ] Crear proyecto Flutter
- [ ] Configurar Firebase
- [ ] Implementar autenticación básica
- [ ] Crear estructura de carpetas

### **Fase 2 - Core Features:**
- [ ] Sistema de familias
- [ ] Calendario básico
- [ ] CRUD de eventos
- [ ] Sincronización Firestore

### **Fase 3 - Advanced Features:**
- [ ] Sistema de turnos
- [ ] Notas diarias
- [ ] Notificaciones
- [ ] Estadísticas

### **Fase 4 - Polish:**
- [ ] PWA setup
- [ ] Responsive design
- [ ] Testing
- [ ] Deploy

---

## 🚨 CONSIDERACIONES IMPORTANTES

### **Seguridad:**
- ✅ **Validación** de datos en cliente y servidor
- ✅ **Reglas de Firestore** restrictivas
- ✅ **Manejo seguro** de errores
- ✅ **Autenticación** obligatoria

### **Performance:**
- ✅ **Lazy loading** de datos
- ✅ **Paginación** en listas largas
- ✅ **Caché** de datos frecuentes
- ✅ **Optimización** de imágenes

### **UX/UI:**
- ✅ **Feedback visual** en todas las acciones
- ✅ **Loading states** claros
- ✅ **Error messages** informativos
- ✅ **Navegación intuitiva**

---

## 🎉 RESULTADO ESPERADO

Una aplicación web Flutter completamente funcional que permita a las familias:

1. **Crear y gestionar** sus familias
2. **Compartir calendarios** en tiempo real
3. **Coordinar turnos** y eventos
4. **Comunicarse** a través de notas
5. **Mantener sincronización** automática
6. **Acceder desde cualquier dispositivo**

**¡La aplicación debe ser robusta, segura y fácil de usar!** 🚀

