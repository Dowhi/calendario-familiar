# 🔐 Configuración de Google Sign-In para Firebase

## 🚨 **Problema Actual:**
Google Sign-In no funciona porque el dominio `localhost:8080` no está autorizado en Firebase Console.

## ✅ **Solución: Configurar Dominios Autorizados**

### **Paso 1: Ir a Firebase Console**
1. Abre [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto: **apptaxi-f2190**
3. Ve a **Authentication** → **Sign-in method**

### **Paso 2: Configurar Google Sign-In**
1. Haz clic en **Google** en la lista de proveedores
2. Asegúrate de que esté **Habilitado**
3. Haz clic en **Editar** (ícono de lápiz)

### **Paso 3: Agregar Dominios Autorizados**
En la sección **Dominios autorizados**, agrega:
```
localhost:8080
127.0.0.1:8080
localhost
127.0.0.1
```

### **Paso 4: Guardar Cambios**
1. Haz clic en **Guardar**
2. Espera unos minutos para que los cambios se propaguen

## 🔧 **Verificación en Código**

### **Archivo: `web/index.html`**
```javascript
// Configuración actualizada
if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
  try {
    // Solo conectar Firestore y Storage a emuladores
    connectFirestoreEmulator(db, 'localhost', 8080);
    connectStorageEmulator(storage, 'localhost', 9199);
    console.log('🌐 Conectado a emuladores de Firestore y Storage');
    
    // NO conectar Auth a emulador para permitir Google Sign-In real
    console.log('🔐 Auth usando Firebase real para Google Sign-In');
  } catch (error) {
    console.log('⚠️ Error conectando a emuladores:', error);
  }
}
```

## 🎯 **Resultado Esperado:**
- ✅ Google Sign-In funcionará en `localhost:8080`
- ✅ Los datos se guardarán en Firebase real
- ✅ La autenticación será persistente
- ✅ Los emuladores solo se usarán para desarrollo local

## 🚀 **Después de la Configuración:**
1. Recarga la página en `localhost:8080`
2. Haz clic en "Continuar con Google"
3. Debería abrirse la ventana de Google Sign-In
4. Selecciona tu cuenta de Google
5. ¡Listo! Deberías ir al calendario

## 🔍 **Si Aún No Funciona:**
1. Verifica que hayas guardado los cambios en Firebase Console
2. Espera 5-10 minutos para propagación
3. Limpia caché del navegador
4. Verifica la consola del navegador para errores
