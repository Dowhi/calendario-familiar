# 🔐 Reglas de Firestore para Calendario Familiar

## Configurar permisos en Firebase Console

1. **Ve a tu consola de Firebase**: https://console.firebase.google.com/project/apptaxi-f2190
2. **En el menú lateral, ve a "Firestore Database"**
3. **Haz clic en la pestaña "Reglas"**
4. **Reemplaza las reglas existentes con estas:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir lectura y escritura para la familia
    match /events/{document} {
      allow read, write: if true; // Temporalmente permitir todo para pruebas
    }
    match /dayCategories/{document} {
      allow read, write: if true; // Temporalmente permitir todo para pruebas
    }
  }
}
```

5. **Haz clic en "Publicar"**

## Explicación de las reglas:

- **`allow read, write: if true`** - Permite lectura y escritura sin restricciones
- Esto es temporal para que puedas probar la sincronización
- Más adelante podemos hacer las reglas más seguras

## Verificar que Firestore esté habilitado:

1. En Firestore Database, asegúrate de que veas "Base de datos creada"
2. Si no está creada, haz clic en "Crear base de datos"
3. Selecciona "Comenzar en modo de prueba"
4. Elige la ubicación más cercana (ej: `us-central1`)

## Próximo paso:

Una vez que tengas la API Key real y las reglas configuradas, podremos probar la sincronización en tiempo real.







