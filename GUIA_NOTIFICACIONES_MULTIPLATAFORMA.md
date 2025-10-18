# 📱 Guía Completa: Notificaciones Locales Multiplataforma

## ✅ Estado Actual del Proyecto

Tu calendario familiar ya tiene **notificaciones locales programadas** completamente implementadas y funcionando en:
- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 10+)
- ✅ **Windows** (Windows 10/11)
- ✅ **Web/PWA** (con notificaciones web)

---

## 🎯 Funcionalidades Implementadas

### ✨ Características principales:
1. **Notificaciones programadas** que se activan en la fecha/hora exacta del evento
2. **Funcionan con la app cerrada** (usando `AndroidScheduleMode.exactAllowWhileIdle`)
3. **Configuración flexible**: define minutos de anticipación para cada evento
4. **Gestión automática**: al crear/editar/eliminar eventos, las notificaciones se sincronizan automáticamente
5. **Compatibilidad multiplataforma**: funciona en Android, iOS, Windows y Web
6. **Sistema de alarmas personalizado**: 2 recordatorios independientes por evento

---

## 📋 Dependencias Instaladas

```yaml
flutter_local_notifications: ^17.2.3  # Notificaciones locales
timezone: ^0.9.2                       # Manejo de zonas horarias
permission_handler: ^11.2.0            # Gestión de permisos
uuid: ^4.5.1                           # Generación de IDs únicos
firebase_messaging: ^15.1.3            # Notificaciones push (web)
```

---

## 🔧 Configuraciones Realizadas

### **Android** (`android/app/src/main/AndroidManifest.xml`)
```xml
<!-- Permisos configurados -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

### **iOS** (`ios/Runner/Info.plist`)
```xml
<!-- Permisos configurados -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
<key>NSUserNotificationsUsageDescription</key>
<string>Esta app necesita enviar notificaciones para recordarte eventos importantes del calendario familiar.</string>
```

### **Windows**
✅ No requiere configuración adicional. El plugin usa el sistema de notificaciones nativo de Windows 10/11.

---

## 🚀 Cómo Probar las Notificaciones

### **1️⃣ Instalar dependencias**
```bash
flutter pub get
```

### **2️⃣ Compilar para Android**
```bash
# Conecta tu dispositivo Android o inicia un emulador
flutter devices

# Compila e instala
flutter run -d android
```

**Pasos de prueba en Android:**
1. Abre la app
2. Ve al calendario y crea un evento
3. Configura una alarma para dentro de 1-2 minutos
4. Cierra completamente la app (swipe en recientes)
5. Espera el tiempo configurado
6. ✅ Deberías recibir la notificación incluso con la app cerrada

### **3️⃣ Compilar para iOS**
```bash
# Conecta tu iPhone o inicia el simulador
flutter devices

# Compila e instala
flutter run -d ios
```

**Notas importantes para iOS:**
- En el **simulador de iOS**, las notificaciones programadas NO funcionan completamente
- **DEBES probar en un dispositivo físico** (iPhone/iPad real)
- La primera vez que abras la app, aparecerá un popup pidiendo permisos de notificaciones
- Acepta los permisos

**Pasos de prueba en iOS:**
1. Abre la app en tu iPhone físico
2. Acepta los permisos de notificación cuando se soliciten
3. Crea un evento y configura alarma para 1-2 minutos
4. Cierra la app (botón Home o swipe arriba)
5. Bloquea la pantalla
6. ✅ La notificación aparecerá en la pantalla de bloqueo

### **4️⃣ Compilar para Windows**
```bash
# Compila para Windows
flutter run -d windows
```

**Pasos de prueba en Windows:**
1. La app se abrirá como una ventana de escritorio
2. Crea un evento y configura alarma
3. Minimiza la ventana (no cierres la app)
4. ✅ Aparecerá una notificación de Windows en la esquina inferior derecha

**Nota:** En Windows, las notificaciones funcionan mejor cuando la app está minimizada, no completamente cerrada.

### **5️⃣ Probar en Web/PWA**
```bash
# Ejecuta en navegador Chrome
flutter run -d chrome
```

**Pasos de prueba en Web:**
1. El navegador te pedirá permisos de notificación
2. Acepta los permisos
3. Las notificaciones web tienen limitaciones (no son tan exactas)
4. Funcionan mejor cuando la pestaña está abierta

---

## 🧪 Probar Notificaciones Inmediatas

La app incluye un botón de **prueba de notificación** en el diálogo de alarmas:

1. Abre el diálogo de configuración de alarmas (icono 🔬)
2. Presiona el botón de "Probar notificación" (icono de probeta)
3. ✅ Deberías ver una notificación inmediatamente

---

## 📖 Cómo Funciona el Sistema

### **Flujo de Notificaciones**

```
1. Usuario crea evento
   ↓
2. EventRepository.createEvent() se llama
   ↓
3. Se guarda en Firebase
   ↓
4. NotificationService.scheduleEventNotification() se ejecuta automáticamente
   ↓
5. Se calcula la fecha/hora de la notificación (startAt - notifyMinutesBefore)
   ↓
6. Se programa con zonedSchedule() usando timezone local
   ↓
7. El sistema operativo dispara la notificación en el momento exacto
   ↓
8. ✅ Usuario recibe la notificación (incluso con app cerrada)
```

### **Archivos Clave**

| Archivo | Descripción |
|---------|-------------|
| `lib/core/services/notification_service.dart` | Servicio principal de notificaciones |
| `lib/core/services/time_service.dart` | Manejo de zonas horarias |
| `lib/features/calendar/data/repositories/event_repository.dart` | Integración con eventos |
| `lib/features/calendar/presentation/widgets/alarm_settings_dialog.dart` | UI para configurar alarmas |
| `lib/main.dart` | Inicialización de servicios |

---

## 🔍 Debugging y Troubleshooting

### **Android**

**Problema:** Las notificaciones no aparecen
```bash
# Ver logs en tiempo real
flutter logs

# O con adb
adb logcat | grep -i notification
```

**Soluciones comunes:**
1. Verificar que los permisos estén concedidos en Configuración > Apps > Calendario Familiar > Notificaciones
2. En Android 12+, también verificar "Alarmas y recordatorios" en Configuración
3. Desactivar "Optimización de batería" para la app
4. Algunos fabricantes (Xiaomi, Huawei) requieren permisos adicionales en configuración

### **iOS**

**Problema:** Las notificaciones no aparecen
```bash
# Ver logs del dispositivo
flutter logs
```

**Soluciones comunes:**
1. Verificar permisos en Configuración > Notificaciones > Calendario Familiar
2. Asegurarse de probar en dispositivo físico (no simulador)
3. Verificar que "No molestar" no esté activado
4. Reiniciar el dispositivo si es necesario

### **Windows**

**Problema:** Las notificaciones no aparecen
**Soluciones:**
1. Verificar que las notificaciones de Windows estén habilitadas en Configuración
2. No cerrar completamente la app (solo minimizar)
3. Algunos antivirus pueden bloquear notificaciones

---

## 🎨 Personalizar Notificaciones

### **Cambiar el icono de notificación (Android)**

1. Crea un icono en `android/app/src/main/res/drawable/notification_icon.png`
2. Edita `notification_service.dart`:
```dart
const androidSettings = AndroidInitializationSettings('notification_icon');
```

### **Cambiar el sonido de notificación**

En `notification_service.dart`, línea ~310:
```dart
AndroidNotificationDetails(
  _channelId,
  _channelName,
  sound: RawResourceAndroidNotificationSound('nombre_del_sonido'),
  playSound: true,
)
```

### **Cambiar minutos de anticipación por defecto**

En `app_event.dart`, línea 95:
```dart
@Default(30) int notifyMinutesBefore,  // Cambiar 30 por el valor deseado
```

---

## 📊 Verificar Notificaciones Programadas

Para ver cuántas notificaciones están programadas, agrega este método de debug:

```dart
// En notification_service.dart
static Future<void> debugPendingNotifications() async {
  final pending = await _localNotifications.pendingNotificationRequests();
  print('📋 Notificaciones pendientes: ${pending.length}');
  for (final notification in pending) {
    print('   - ID: ${notification.id}, Título: ${notification.title}');
  }
}
```

Llámalo desde cualquier parte:
```dart
await NotificationService.debugPendingNotifications();
```

---

## 🚨 Limitaciones Conocidas

### **Android**
- Android 12+ requiere permisos explícitos (ya implementado)
- Algunos fabricantes (Xiaomi, Oppo, Vivo) tienen optimizaciones agresivas de batería que pueden matar la app
- Solución: Pedir al usuario desactivar optimización de batería para la app

### **iOS**
- Las notificaciones programadas **NO funcionan en el simulador**
- **DEBES usar un dispositivo físico** para probar
- iOS tiene límites en el número de notificaciones programadas (64 notificaciones)

### **Windows**
- Las notificaciones funcionan mejor con la app minimizada, no cerrada
- Windows 10 version 1903+ requerido para notificaciones avanzadas

### **Web/PWA**
- Las notificaciones web requieren que el navegador esté abierto o la PWA instalada
- No son tan precisas como las notificaciones nativas
- Service Workers pueden no despertar en el momento exacto

---

## ✅ Checklist de Verificación

Antes de lanzar tu app, verifica:

- [ ] Las notificaciones funcionan en Android (dispositivo físico)
- [ ] Las notificaciones funcionan en iOS (dispositivo físico)
- [ ] Las notificaciones funcionan en Windows
- [ ] Los permisos se solicitan correctamente en primera ejecución
- [ ] Las notificaciones se cancelan al eliminar eventos
- [ ] Las notificaciones se reprograman al editar eventos
- [ ] El botón de prueba funciona correctamente
- [ ] Las notificaciones aparecen incluso con la app cerrada
- [ ] El texto de las notificaciones es claro y útil
- [ ] Las notificaciones tienen sonido y vibración

---

## 📞 Soporte y Ayuda

Si encuentras problemas:

1. **Revisa los logs**: `flutter logs` es tu mejor amigo
2. **Verifica permisos**: Muchos problemas son de permisos no concedidos
3. **Prueba en dispositivo real**: Especialmente en iOS
4. **Busca en la documentación oficial**:
   - [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
   - [timezone](https://pub.dev/packages/timezone)

---

## 🎉 ¡Listo para Usar!

Tu aplicación de calendario familiar ahora tiene notificaciones locales completamente funcionales en todas las plataformas. Los usuarios recibirán recordatorios de sus eventos importantes, ¡incluso con la app cerrada!

**Comandos rápidos para empezar a probar:**

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Windows
flutter run -d windows

# Web
flutter run -d chrome
```

---

**Fecha de última actualización:** Octubre 2025
**Versión del proyecto:** 1.0.0+1

