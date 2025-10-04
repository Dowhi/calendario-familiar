# Guía de Notificaciones y Recordatorios

## Resumen

Esta aplicación implementa un sistema de recordatorios que funciona tanto en **Flutter Web (PWA)** como en **móviles (Android/iOS)**. La implementación es simple, funcional y respeta las limitaciones de cada plataforma.

## Arquitectura

### Servicios Principales

- **`ReminderService`**: Servicio principal que maneja recordatorios en todas las plataformas
- **`NotificationService`**: Wrapper de compatibilidad que delega a `ReminderService`
- **`SimpleAlarmDialog`**: Interfaz simplificada para configurar recordatorios

### Plataformas Soportadas

#### Flutter Web (PWA)
- **Tecnología**: API nativa de notificaciones del navegador (`dart:js`)
- **Limitación**: Los recordatorios solo funcionan mientras la pestaña esté abierta
- **Permisos**: Requiere permiso del usuario para mostrar notificaciones
- **Compatibilidad**: Chrome, Firefox, Safari, Edge (con HTTPS)

#### Flutter Móvil (Android/iOS)
- **Tecnología**: `flutter_local_notifications` con `timezone`
- **Funcionalidad**: Recordatorios programados que funcionan en background
- **Permisos**: Notificaciones locales automáticas
- **Compatibilidad**: Android 4.1+, iOS 10+

## Cómo Usar

### 1. Configurar un Recordatorio

1. Abre un día en el calendario
2. Escribe una nota o evento
3. Haz clic en el botón de alarma (🔔)
4. Selecciona la hora del recordatorio
5. Haz clic en "Programar"

### 2. Probar Notificaciones

1. En el diálogo de recordatorio, haz clic en "Probar"
2. Deberías ver una notificación inmediata
3. Si no aparece, verifica los permisos

### 3. Verificar Permisos

#### En Web:
1. Busca el ícono de notificaciones en la barra de direcciones
2. Debe mostrar "Permitir" o "Bloquear"
3. Si está bloqueado, haz clic y selecciona "Permitir"
4. Recarga la página

#### En Móvil:
1. Ve a Configuración > Aplicaciones > Calendario Familiar
2. Verifica que las notificaciones estén habilitadas
3. Si no, habilítalas manualmente

## Limitaciones

### Flutter Web (PWA)

⚠️ **Limitación Principal**: Los recordatorios programados solo funcionan mientras la pestaña del navegador esté abierta.

**¿Por qué?**
- Los navegadores no permiten que las PWA ejecuten código en background
- `setTimeout()` y `setInterval()` se pausan cuando la pestaña no está activa
- No hay Service Workers para notificaciones programadas sin servidor

**Soluciones Alternativas:**
- Usar notificaciones push con Firebase (requiere servidor)
- Implementar Service Worker con background sync (limitado)
- Usar notificaciones inmediatas cuando el usuario esté activo

### Flutter Móvil

✅ **Funcionalidad Completa**: Los recordatorios funcionan correctamente en background.

**Características:**
- Notificaciones programadas exactas
- Funcionan con la app cerrada
- Respeta el modo "No molestar"
- Integración con el sistema de notificaciones

## Diagnóstico de Problemas

### Las notificaciones no aparecen

#### En Web:
1. **Verificar HTTPS**: Las notificaciones web requieren HTTPS
2. **Verificar permisos**: Debe estar en "Permitir"
3. **Verificar pestaña activa**: La pestaña debe estar abierta
4. **Verificar consola**: Revisar errores en DevTools

#### En Móvil:
1. **Verificar permisos**: Notificaciones habilitadas en configuración
2. **Verificar batería**: Algunos dispositivos pausan apps en background
3. **Verificar modo avión**: Desactivar si está activo
4. **Verificar logs**: Revisar logs de la app

### Código de Diagnóstico

```dart
// Verificar estado de permisos
final enabled = await ReminderService.areNotificationsEnabled();
print('Notificaciones habilitadas: $enabled');

// Solicitar permisos
final granted = await ReminderService.requestPermissions();
print('Permisos concedidos: $granted');

// Probar notificación
await ReminderService.showTestNotification();
```

## Implementación Técnica

### Estructura de Archivos

```
lib/
├── core/services/
│   ├── reminder_service.dart          # Servicio principal
│   └── notification_service.dart      # Wrapper de compatibilidad
├── features/calendar/presentation/widgets/
│   └── simple_alarm_dialog.dart       # Interfaz de usuario
└── main.dart                          # Inicialización
```

### Flujo de Datos

1. **Usuario configura recordatorio** → `SimpleAlarmDialog`
2. **Diálogo valida datos** → `ReminderService.scheduleReminder()`
3. **Servicio detecta plataforma** → Web o Móvil
4. **Web**: `Future.delayed()` + API de notificaciones
5. **Móvil**: `flutter_local_notifications.zonedSchedule()`

### Dependencias

```yaml
dependencies:
  flutter_local_notifications: ^17.2.3  # Para móviles
  timezone: ^0.9.2                      # Para zonas horarias
  # dart:js (incluido en Flutter)       # Para web
```

## Pruebas

### Prueba Básica

1. **Configurar recordatorio para 1 minuto en el futuro**
2. **Esperar y verificar que aparece la notificación**
3. **Hacer clic en la notificación para verificar interacción**

### Prueba de Permisos

1. **Denegar permisos inicialmente**
2. **Intentar configurar recordatorio**
3. **Verificar que solicita permisos**
4. **Conceder permisos y probar de nuevo**

### Prueba de Plataforma

1. **Probar en navegador web (Chrome/Firefox)**
2. **Probar en dispositivo Android**
3. **Probar en dispositivo iOS**
4. **Verificar comportamiento específico de cada plataforma**

## Futuras Mejoras

### Posibles Extensiones

1. **Notificaciones Push**: Integrar Firebase Cloud Messaging
2. **Recordatorios Recurrentes**: Diario, semanal, mensual
3. **Sonidos Personalizados**: Diferentes tonos por tipo de evento
4. **Notificaciones Silenciosas**: Solo vibración o badge
5. **Integración con Calendario**: Sincronizar con Google Calendar

### Consideraciones Técnicas

- **Service Workers**: Para notificaciones web en background
- **Background Tasks**: Para tareas programadas en móviles
- **Push Notifications**: Para notificaciones remotas
- **Local Storage**: Para persistir recordatorios programados

## Conclusión

La implementación actual proporciona una base sólida y funcional para recordatorios en todas las plataformas. Aunque tiene limitaciones en web (solo funciona con pestaña abierta), es una solución práctica que cumple con los requisitos básicos y es fácil de extender en el futuro.

Para casos de uso más avanzados, se recomienda implementar notificaciones push con un servidor backend.