# 🚀 Configuración de Firebase para Calendario Familiar

## Paso 1: Crear proyecto Firebase

1. **Ve a la consola de Firebase**: https://console.firebase.google.com/
2. **Crea un nuevo proyecto**:
   - Nombre: `calendario-familiar`
   - Habilita Google Analytics (opcional)
   - Haz clic en "Crear proyecto"

## Paso 2: Habilitar Firestore Database

1. En el menú lateral, ve a **"Firestore Database"**
2. Haz clic en **"Crear base de datos"**
3. Selecciona **"Comenzar en modo de prueba"** (para desarrollo)
4. Selecciona la ubicación más cercana (ej: `us-central1`)
5. Haz clic en **"Listo"**

## Paso 3: Configurar reglas de Firestore

1. En Firestore Database, ve a la pestaña **"Reglas"**
2. Reemplaza las reglas con:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir lectura y escritura para la familia
    match /events/{document} {
      allow read, write: if resource.data.familyId == 'familia_principal';
    }
    match /dayCategories/{document} {
      allow read, write: if resource.data.familyId == 'familia_principal';
    }
  }
}
```

3. Haz clic en **"Publicar"**

## Paso 4: Agregar aplicación Android

1. En la página principal del proyecto, haz clic en el ícono de **Android**
2. **Package name**: `com.juancarlos.calendariofamiliar`
3. **Nickname**: `Calendario Familiar Android`
4. Haz clic en **"Registrar app"**
5. **Descarga el archivo `google-services.json`**
6. **Colócalo en la carpeta `android/app/`** de tu proyecto Flutter

## Paso 5: Obtener las claves de configuración

1. Ve a **Configuración del proyecto** (ícono de engranaje)
2. En la pestaña **"General"**, busca la sección **"Tus apps"**
3. Haz clic en tu app Android
4. Copia las siguientes claves:

### Claves necesarias:
- **API Key**: `AIzaSy...` (empieza con AIzaSy)
- **App ID**: `1:123456789012:android:abcdef1234567890`
- **Project ID**: `calendario-familiar`
- **Storage Bucket**: `calendario-familiar.appspot.com`

## Paso 6: Actualizar firebase_options.dart

1. Abre el archivo `lib/core/firebase/firebase_options.dart`
2. Reemplaza todas las claves `TU_API_KEY_AQUI` con las reales:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyTU_API_KEY_REAL_AQUI',
  appId: '1:123456789012:android:abcdef1234567890',
  messagingSenderId: '123456789012',
  projectId: 'calendario-familiar',
  storageBucket: 'calendario-familiar.appspot.com',
);
```

## Paso 7: Probar la sincronización

1. Ejecuta la app: `flutter run`
2. Agrega algunos eventos en el calendario
3. Ve a la consola de Firebase > Firestore Database
4. Deberías ver los eventos en la colección `events`

## 🔄 Sincronización en tiempo real

Una vez configurado, la app funcionará como Shifter Calendar:

- ✅ **Sincronización instantánea** entre tu dispositivo y el de tu mujer
- ✅ **Datos en tiempo real** - cualquier cambio se refleja inmediatamente
- ✅ **Modo offline** - funciona sin internet y sincroniza cuando vuelve la conexión
- ✅ **Datos seguros** - solo tu familia puede acceder a los datos

## 🛠️ Solución de problemas

### Error: "Firebase not configured"
- Verifica que `google-services.json` esté en `android/app/`
- Asegúrate de que las claves en `firebase_options.dart` sean correctas

### Error: "Permission denied"
- Verifica las reglas de Firestore
- Asegúrate de que el `familyId` sea `'familia_principal'`

### No se ven los datos
- Verifica la consola de Firebase > Firestore Database
- Usa el botón de "Verificar Firebase" en la pantalla de estadísticas

## 📱 Para tu mujer

1. Comparte el APK de la app
2. Asegúrate de que use la misma configuración de Firebase
3. Los datos se sincronizarán automáticamente

¡Listo! Ahora tienes tu propio Shifter Calendar personalizado para ti y tu mujer. 🎉







