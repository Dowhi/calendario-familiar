# 🔧 Configuración de Google Sign-In en Firebase

## Paso 1: Configurar Firebase Console

### 1.1 Ir a Firebase Console
- Ve a: https://console.firebase.google.com/
- Selecciona tu proyecto: `apptaxi-f2190`

### 1.2 Habilitar Google Sign-In
- Ve a **Authentication** en el menú lateral
- Haz clic en **Sign-in method**
- Busca **Google** en la lista de proveedores
- Haz clic en **Google** para habilitarlo

### 1.3 Configurar Google Sign-In
- **Habilita** Google como proveedor de autenticación
- **Nombre del proyecto público**: `Calendario Familiar`
- **Correo de soporte**: Tu correo personal
- **Dominios autorizados**: Deja vacío por ahora

### 1.4 Agregar SHA-1 de tu aplicación
- En la misma página de Google Sign-In
- Busca la sección **SHA certificate fingerprints**
- Haz clic en **Agregar huella**
- Agrega este SHA-1: `9E:E8:32:BE:61:A1:B6:26:AD:F0:95:42:B8:F2:F2:5B:07:C2:2C:D5`
- Haz clic en **Guardar**

## Paso 2: Descargar google-services.json actualizado

### 2.1 Descargar el archivo
- Ve a **Configuración del proyecto** (ícono de engranaje)
- Selecciona **Configuración del proyecto**
- En la pestaña **General**, busca **Tus apps**
- Selecciona tu app Android: `com.juancarlos.calendariofamiliar`
- Haz clic en **Descargar google-services.json**

### 2.2 Reemplazar el archivo
- Reemplaza el archivo actual en: `android/app/google-services.json`
- El nuevo archivo debería tener una sección `oauth_client` con datos

## Paso 3: Verificar configuración

### 3.1 Verificar google-services.json
El archivo debería tener una estructura como esta:
```json
{
  "project_info": {
    "project_number": "804273724178",
    "project_id": "apptaxi-f2190",
    "storage_bucket": "apptaxi-f2190.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:804273724178:android:7e8c68a174ca93bce7f1cb",
        "android_client_info": {
          "package_name": "com.juancarlos.calendariofamiliar"
        }
      },
      "oauth_client": [
        {
          "client_id": "804273724178-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com",
          "client_type": 1,
          "android_info": {
            "package_name": "com.juancarlos.calendariofamiliar",
            "certificate_hash": "9E:E8:32:BE:61:A1:B6:26:AD:F0:95:42:B8:F2:F2:5B:07:C2:2C:D5"
          }
        }
      ],
      "api_key": [
        {
          "current_key": "AIzaSyD_dHKJyrAOPt3xpBsCU7W_lj8G9qKKAwE"
        }
      ]
    }
  ]
}
```

## Paso 4: Probar la aplicación

### 4.1 Ejecutar la aplicación
```bash
flutter run
```

### 4.2 Probar Google Sign-In
- Ve a la pantalla de login
- Haz clic en "Continuar con Google"
- Debería abrirse el selector de cuentas de Google
- Selecciona tu cuenta
- Deberías ver un mensaje de éxito

### 4.3 Probar crear familia
- Después de iniciar sesión, ve a "Gestión Familiar"
- Haz clic en "Crear Nueva Familia"
- Ingresa un nombre para la familia
- Haz clic en "Crear Nueva Familia"
- Debería funcionar correctamente

## Solución de problemas

### Error: "No se pudo obtener usuario de Firebase"
- Verifica que el SHA-1 esté correctamente configurado en Firebase Console
- Asegúrate de que el google-services.json esté actualizado

### Error: "Google Sign-In no está configurado"
- Verifica que Google Sign-In esté habilitado en Firebase Console
- Asegúrate de que el google-services.json tenga la sección `oauth_client`

### Error: "No se pudo crear la familia"
- Verifica que el usuario esté autenticado correctamente
- Revisa los logs de la aplicación para más detalles

## Notas importantes

- El SHA-1 que proporcionamos es para desarrollo (debug)
- Para producción, necesitarás el SHA-1 de tu keystore de release
- Google Sign-In requiere conexión a internet
- La primera vez que uses Google Sign-In, se creará automáticamente un usuario en Firestore





