# Plan de Testing Incremental para iPhone

## 🎯 Objetivo
Identificar qué funcionalidad específica causa problemas en iPhone, agregando características una por una.

## 📱 Versión Mínima Actual
**URL**: https://dowhi.github.io/calendario-familiar/

**Características**:
- ✅ App Flutter básica sin dependencias complejas
- ✅ Solo Material Design y cupertino_icons
- ✅ Contador simple con botón
- ✅ Sin Firebase, Riverpod, Go Router, etc.
- ✅ HTML mínimo sin scripts complejos

## 🧪 Plan de Testing Incremental

### Fase 1: Verificar Versión Mínima ✅
- [ ] **Probar en iPhone**: Abrir la URL y verificar que carga
- [ ] **Verificar funcionalidad**: El contador debe funcionar
- [ ] **Verificar PWA**: Debe poder instalarse como app

**Si falla**: El problema está en la configuración básica de Flutter Web en iOS
**Si funciona**: Continuar con Fase 2

### Fase 2: Agregar Navegación Básica
**Archivos a modificar**:
- `lib/main.dart`: Agregar navegación simple
- `pubspec.yaml`: Agregar `go_router: ^16.1.0`

**Características a agregar**:
- [ ] Navegación entre 2 pantallas simples
- [ ] AppBar con botón de navegación
- [ ] Sin autenticación ni Firebase

**Test**: Verificar que la navegación funciona en iPhone

### Fase 3: Agregar Gestión de Estado
**Archivos a modificar**:
- `pubspec.yaml`: Agregar `flutter_riverpod: ^2.3.6`
- `lib/main.dart`: Agregar ProviderScope

**Características a agregar**:
- [ ] Estado simple con Riverpod
- [ ] Contador que persiste entre pantallas
- [ ] Sin Firebase

**Test**: Verificar que el estado funciona en iPhone

### Fase 4: Agregar Firebase Core
**Archivos a modificar**:
- `pubspec.yaml`: Agregar `firebase_core: ^3.15.2`
- `web/index.html`: Agregar script de Firebase
- `lib/main.dart`: Inicializar Firebase

**Características a agregar**:
- [ ] Inicialización de Firebase
- [ ] Sin autenticación ni Firestore
- [ ] Solo verificar que Firebase se conecta

**Test**: Verificar que Firebase se inicializa en iPhone

### Fase 5: Agregar Firebase Auth
**Archivos a modificar**:
- `pubspec.yaml`: Agregar `firebase_auth: ^5.7.0`
- `lib/main.dart`: Agregar pantalla de login simple

**Características a agregar**:
- [ ] Login básico con email/contraseña
- [ ] Sin Firestore ni otras funcionalidades
- [ ] Solo autenticación

**Test**: Verificar que el login funciona en iPhone

### Fase 6: Agregar Firestore
**Archivos a modificar**:
- `pubspec.yaml`: Agregar `cloud_firestore: ^5.6.12`
- `lib/main.dart`: Agregar operaciones básicas de Firestore

**Características a agregar**:
- [ ] Crear/leer documentos simples
- [ ] Sin notificaciones ni funcionalidades complejas
- [ ] Solo CRUD básico

**Test**: Verificar que Firestore funciona en iPhone

### Fase 7: Agregar Calendario
**Archivos a modificar**:
- `pubspec.yaml`: Agregar `table_calendar: ^3.0.9`
- `lib/main.dart`: Agregar widget de calendario

**Características a agregar**:
- [ ] Widget de calendario básico
- [ ] Sin eventos ni funcionalidades complejas
- [ ] Solo mostrar calendario

**Test**: Verificar que el calendario se renderiza en iPhone

### Fase 8: Agregar Funcionalidades Completas
**Archivos a modificar**:
- Restaurar todas las dependencias originales
- Restaurar código completo

**Características a agregar**:
- [ ] Todas las funcionalidades originales
- [ ] Notificaciones
- [ ] Gestión familiar
- [ ] Estadísticas

## 🔍 Criterios de Éxito por Fase

### ✅ Funciona Correctamente
- La app carga sin errores
- Las funcionalidades responden
- No hay pantalla en blanco
- No hay errores en consola

### ❌ Falla
- Pantalla en blanco
- Errores en consola
- App no responde
- Crashes

## 📋 Comandos para Cada Fase

```bash
# 1. Modificar archivos según la fase
# 2. Compilar
flutter clean
flutter pub get
flutter build web --release --base-href=/calendario-familiar/

# 3. Copiar a docs
robocopy build/web docs /MIR

# 4. Commit y push
git add .
git commit -m "Fase X: [descripción]"
git push origin main

# 5. Probar en iPhone
# 6. Reportar resultados
```

## 🚨 Problemas Conocidos en iOS

### Service Worker
- iOS Safari tiene problemas con service workers
- Solución: Usar `--pwa-strategy=offline-first`

### Firebase
- iOS puede tener problemas con CORS
- Solución: Verificar configuración de Firebase

### CanvasKit
- iOS puede tener problemas con WebGL
- Solución: Usar renderer HTML

### Notificaciones
- iOS requiere HTTPS y permisos específicos
- Solución: Configurar correctamente

## 📞 Próximos Pasos

1. **Probar versión mínima en iPhone**
2. **Reportar resultados** (funciona/no funciona)
3. **Continuar con Fase 2** si la mínima funciona
4. **Investigar configuración básica** si la mínima falla

¿La versión mínima funciona en tu iPhone?
