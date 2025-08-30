# Calendario Familiar

Una aplicación móvil completa para organizar eventos familiares compartidos con sincronización en tiempo real, notificaciones push y soporte para eventos recurrentes.

## 🚀 Características

- **Calendario mixto**: Eventos y turnos familiares
- **Sincronización en tiempo real**: Compartido entre miembros de la familia
- **Múltiples vistas**: Mensual, semanal y agenda
- **Eventos completos**: Título, descripción, fecha/hora, color, categoría, ubicación
- **Recurrencia**: Eventos diarios, semanales y mensuales
- **Notificaciones**: Locales y push para recordatorios
- **Autenticación**: Google Sign-In
- **Modo offline**: Funciona sin conexión con sincronización automática
- **Zona horaria**: Configurada para Europe/Madrid por defecto
- **Modo oscuro**: Soporte completo para tema claro/oscuro

## 📱 Capturas de pantalla

*[Aquí irían las capturas de pantalla de la aplicación]*

## 🛠️ Stack Técnico

- **Frontend**: Flutter 3.9+
- **Estado**: Riverpod
- **Navegación**: Go Router
- **Backend**: Firebase
  - Authentication (Google Sign-In)
  - Firestore (Base de datos)
  - Cloud Messaging (Notificaciones push)
  - Cloud Functions (Lógica del servidor)
- **Notificaciones**: Flutter Local Notifications
- **Modelos**: Freezed + JSON Serializable
- **Calendario**: Table Calendar

## 📋 Prerrequisitos

- Flutter SDK 3.9.0 o superior
- Dart SDK 3.9.0 o superior
- Android Studio / VS Code
- Xcode (para desarrollo iOS)
- Node.js 18+ (para funciones de Firebase)
- Cuenta de Google (para Firebase)

## 🔧 Instalación

### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd calendario_familiar
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar Firebase

#### 3.1 Crear proyecto Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto
3. Habilita los siguientes servicios:
   - Authentication (Google Sign-In)
   - Firestore Database
   - Cloud Messaging
   - Cloud Functions

#### 3.2 Configurar FlutterFire

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Iniciar sesión en Firebase
firebase login

# Configurar el proyecto
flutterfire configure
```

Durante la configuración:
- Selecciona tu proyecto Firebase
- Agrega apps para Android e iOS
- Para Android: usa el package name `com.example.calendariofamiliar`
- Para iOS: usa el Bundle ID `com.example.calendarioFamiliar`

#### 3.3 Configurar Android

1. Descarga el archivo `google-services.json` desde Firebase Console
2. Colócalo en `android/app/`
3. Obtén las huellas SHA-1 y SHA-256:
   ```bash
   cd android
   ./gradlew signingReport
   ```
4. Agrega las huellas en Firebase Console > Project Settings > Android app

#### 3.4 Configurar iOS

1. Descarga el archivo `GoogleService-Info.plist` desde Firebase Console
2. Colócalo en `ios/Runner/`
3. En Xcode:
   - Abre `ios/Runner.xcworkspace`
   - Selecciona el target "Runner"
   - Ve a "Signing & Capabilities"
   - Agrega "Push Notifications"
   - Agrega "Background Modes" y marca "Remote notifications"

### 4. Configurar reglas de Firestore

En Firebase Console > Firestore Database > Rules, reemplaza las reglas con:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() { return request.auth != null; }
    function isMember(calendarId) {
      return signedIn() &&
        get(/databases/$(database)/documents/calendars/$(calendarId)).data.members.hasAny([request.auth.uid]);
    }

    match /users/{uid} {
      allow read, write: if signedIn() && request.auth.uid == uid;
    }

    match /calendars/{calendarId} {
      allow read, write: if isMember(calendarId);

      match /events/{eventId} {
        allow read: if isMember(calendarId);
        allow create: if isMember(calendarId) && request.resource.data.ownerId == request.auth.uid;
        allow update, delete: if isMember(calendarId) &&
          (resource.data.ownerId == request.auth.uid || request.auth.uid in resource.data.participants);
      }
    }
  }
}
```

### 5. Generar código

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 6. Desplegar funciones de Firebase

```bash
cd functions
npm install
firebase deploy --only functions
```

## 🚀 Ejecutar la aplicación

### Desarrollo

```bash
flutter run
```

### Build para producción

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## 📁 Estructura del proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── routing/
│   └── app_router.dart       # Configuración de navegación
├── theme/
│   └── app_theme.dart        # Temas de la aplicación
├── core/
│   ├── models/               # Modelos de datos
│   ├── utils/                # Utilidades y extensiones
│   ├── services/             # Servicios (notificaciones, tiempo)
│   └── firebase/             # Configuración de Firebase
└── features/
    ├── auth/                 # Autenticación
    │   ├── data/
    │   ├── logic/
    │   └── presentation/
    └── calendar/             # Funcionalidad del calendario
        ├── data/
        ├── logic/
        └── presentation/
```

## 🔐 Configuración de seguridad

### Variables de entorno

Crea un archivo `.env` en la raíz del proyecto:

```env
FIREBASE_PROJECT_ID=tu-proyecto-id
FIREBASE_API_KEY=tu-api-key
```

### Configuración de Android

En `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        applicationId "com.example.calendariofamiliar"
        minSdkVersion 21
        targetSdkVersion 33
    }
}
```

### Configuración de iOS

En `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

## 🧪 Testing

### Tests unitarios

```bash
flutter test
```

### Tests de integración

```bash
flutter test integration_test/
```

## 📦 Despliegue

### Android

1. Generar keystore:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Configurar `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to-keystore>
```

3. Build APK:
```bash
flutter build apk --release
```

### iOS

1. En Xcode, configurar certificados y provisioning profiles
2. Build:
```bash
flutter build ios --release
```

## 🐛 Solución de problemas

### Error de compilación

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Error de Firebase

1. Verificar que `google-services.json` esté en `android/app/`
2. Verificar que `GoogleService-Info.plist` esté en `ios/Runner/`
3. Ejecutar `flutterfire configure` nuevamente

### Error de notificaciones

1. Verificar permisos en Android/iOS
2. Verificar configuración de FCM
3. Verificar que las funciones estén desplegadas

### Error de índices Firestore

Si ves errores sobre índices faltantes:
1. Ve a Firebase Console > Firestore > Indexes
2. Crea el índice compuesto: `calendarId ASC, startAt ASC`

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 📞 Soporte

Si tienes problemas o preguntas:

1. Revisa la [documentación de Flutter](https://docs.flutter.dev/)
2. Revisa la [documentación de Firebase](https://firebase.google.com/docs)
3. Abre un issue en este repositorio

## 🗺️ Roadmap

- [ ] Widget de inicio (Android)
- [ ] Live Activity (iOS)
- [ ] Exportar/Importar ICS
- [ ] Sincronización con Google Calendar
- [ ] Múltiples calendarios
- [ ] Estadísticas de eventos
- [ ] Búsqueda avanzada
- [ ] Temas personalizables

---

Desarrollado con ❤️ usando Flutter y Firebase
