# 🔧 Configuración de Google Sign-In en Firebase

## Paso 1: Obtener el Client ID de Google Cloud Console

### 1.1 Ir a Google Cloud Console
1. Ve a: https://console.cloud.google.com/
2. Selecciona tu proyecto: **apptaxi-f2190** (el mismo que usas en Firebase)

### 1.2 Habilitar Google+ API
1. En el menú lateral, ve a **APIs y servicios** → **Biblioteca**
2. Busca "Google+ API" o "Google Sign-In API"
3. Haz clic en **Habilitar**

### 1.3 Crear credenciales OAuth 2.0
1. Ve a **APIs y servicios** → **Credenciales**
2. Haz clic en **+ CREAR CREDENCIALES** → **ID de cliente OAuth 2.0**
3. Selecciona **Aplicación web**
4. Configura:
   - **Nombre**: `Calendario Familiar Web`
   - **Orígenes JavaScript autorizados**: 
     ```
     https://dowhi.github.io
     http://localhost
     http://localhost:8080
     http://127.0.0.1
     http://127.0.0.1:8080
     ```
   - **URI de redirección autorizados**:
     ```
     https://dowhi.github.io/calendario-familiar/
     http://localhost:8080
     ```

### 1.4 Copiar el Client ID
Después de crear, copia el **Client ID** que aparece (algo como: `804273724178-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com`)

## Paso 2: Configurar Firebase Console

### 2.1 Ir a Firebase Console
1. Ve a: https://console.firebase.google.com/
2. Selecciona tu proyecto: **apptaxi-f2190**

### 2.2 Configurar Google Sign-In
1. Ve a **Authentication** → **Sign-in method**
2. Haz clic en **Google** en la lista de proveedores
3. Haz clic en **Editar** (ícono de lápiz)
4. Asegúrate de que esté **Habilitado**
5. En **Dominios autorizados**, agrega:
   ```
   dowhi.github.io
   localhost
   127.0.0.1
   ```
6. Haz clic en **Guardar**

## Paso 3: Actualizar el código

### 3.1 Actualizar AuthRepository con el Client ID real:

```dart:lib/features/auth/data/repositories/auth_repository.dart
// ... existing code ...
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '804273724178-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com', // Reemplaza con tu Client ID real
  );
// ... existing code ...
```

### 3.2 Actualizar index.html con el Client ID:

```html:web/index.html
// ... existing code ...
    // Your web app's Firebase configuration
    const firebaseConfig = {
      apiKey: 'AIzaSyD_dHKJyrAOPt3xpBsCU7W_lj8G9qKKAwE',
      authDomain: 'apptaxi-f2190.firebaseapp.com',
      projectId: 'apptaxi-f2190',
      storageBucket: 'apptaxi-f2190.appspot.com',
      messagingSenderId: '804273724178',
      appId: '1:804273724178:web:1cb45dc889866ee2e7f1cb',
      databaseURL: 'https://apptaxi-f2190.firebaseio.com',
      measurementId: 'G-MEASUREMENT-ID',
      clientId: '804273724178-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com' // Agregar tu Client ID aquí
    };
// ... existing code ...
```

## Paso 4: Alternativa más simple (si no encuentras el Client ID)

Si no puedes encontrar el Client ID, puedes usar esta configuración más simple:

```dart:lib/features/auth/data/repositories/auth_repository.dart
// ... existing code ...
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
// ... existing code ...
```

## Paso 5: Probar la aplicación

1. **Haz commit y push de los cambios:**
   ```bash
   git add .
   git commit -m "fix: configure Google Sign-In with proper client ID"
   git push
   ```

2. **Espera a que se despliegue en GitHub Pages**

3. **Prueba Google Sign-In en:** `https://dowhi.github.io/calendario-familiar/`

## ¿Necesitas que te ayude con algún paso específico?

Si tienes problemas con alguno de estos pasos, dime exactamente en cuál te quedas y te ayudo más detalladamente. También puedo intentar hacer algunos de estos pasos por ti si me das acceso a la configuración.





