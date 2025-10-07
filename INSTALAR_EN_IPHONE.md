# 📱 Cómo Instalar la App en tu iPhone X

## ✅ REQUISITOS

- Mac con macOS Catalina o superior
- Xcode instalado (descarga gratis desde Mac App Store)
- iPhone X conectado al Mac con cable Lightning
- Apple ID (el mismo que usas en tu iPhone)

---

## 📋 PASOS DETALLADOS

### 1️⃣ Instalar Xcode (si no lo tienes)

1. Abre **Mac App Store** en tu Mac
2. Busca **"Xcode"**
3. Haz clic en **"Obtener"** y luego **"Instalar"**
4. Espera (la descarga es grande, ~10-15 GB)
5. Una vez instalado, abre Xcode
6. Acepta los términos y condiciones
7. Espera a que instale componentes adicionales

---

### 2️⃣ Configurar el Proyecto para iOS

1. **En tu Mac**, abre Terminal y ve a la carpeta del proyecto:
   ```bash
   cd "ruta/a/calendario_familiar 01_09_25"
   ```

2. **Abre el proyecto iOS en Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```
   ⚠️ Asegúrate de abrir el archivo `.xcworkspace`, NO el `.xcodeproj`

3. **En Xcode**, en el panel izquierdo, haz clic en **"Runner"** (el proyecto principal)

4. En la pestaña **"Signing & Capabilities"**:
   - Marca ✅ **"Automatically manage signing"**
   - En **"Team"**, selecciona tu Apple ID (o haz clic en "Add Account" si no aparece)
   - El **Bundle Identifier** debería ser algo como: `com.calendariofamiliar.app`
   - Si da error de "Bundle Identifier not available", cámbialo a algo único como:
     `com.tunombre.calendariofamiliar`

5. **Conecta tu iPhone X al Mac** con el cable Lightning

6. **Desbloquea tu iPhone** y, si aparece un mensaje "¿Confiar en este ordenador?", toca **"Confiar"**

7. En Xcode, en la parte superior, verás un menú desplegable de dispositivos
   - Haz clic en él y selecciona tu **"iPhone X"** (aparecerá con tu nombre)

8. Presiona el botón **▶️ (Play)** en la esquina superior izquierda de Xcode

9. Espera a que compile (puede tardar 2-5 minutos la primera vez)

---

### 3️⃣ Confiar en el Certificado de Desarrollador (Primera Vez)

Cuando la app intente abrirse en tu iPhone, verás un error de seguridad.

**En tu iPhone X:**

1. Ve a **Configuración** → **General** → **VPN y gestión de dispositivos**
2. Verás tu Apple ID bajo "App de desarrollador"
3. Toca en tu Apple ID
4. Toca **"Confiar en [tu Apple ID]"**
5. Confirma tocando **"Confiar"**

**Vuelve a la app** en tu iPhone y ahora se abrirá correctamente.

---

### 4️⃣ Probar las Notificaciones

1. La primera vez que abras la app, iOS te pedirá permisos de notificación
2. Toca **"Permitir"**
3. Crea un evento en el calendario
4. Configura una alarma para dentro de 2 minutos
5. **Cierra la app** (desliza hacia arriba desde la parte inferior)
6. **Bloquea la pantalla** de tu iPhone
7. Espera 2 minutos
8. ✅ **¡La notificación aparecerá en la pantalla de bloqueo!**

---

## 🔧 SOLUCIÓN DE PROBLEMAS

### "No se puede verificar la app"
- Sigue los pasos del apartado 3️⃣ para confiar en el certificado

### "Signing for Runner requires a development team"
- Necesitas añadir tu Apple ID en Xcode
- Ve a Xcode → Preferences → Accounts → Add Account (+)
- Inicia sesión con tu Apple ID

### "El dispositivo no se detecta"
- Asegúrate de que el cable funciona (prueba conectándolo y desconectándolo)
- En el iPhone, revoca la confianza y vuelve a confiar: Configuración → General → Transferir o Restablecer iPhone → Restablecer → Restablecer configuración de ubicación y privacidad
- Reinicia Xcode

### "Error de compilación"
- En Terminal, ejecuta:
  ```bash
  cd ios
  pod install
  cd ..
  ```
- Luego vuelve a intentar compilar en Xcode

---

## ⚠️ LIMITACIONES DE LA CUENTA GRATUITA

Con una **cuenta gratuita de Apple Developer**:
- ✅ Puedes instalar la app en tu iPhone
- ✅ Las notificaciones funcionan perfectamente
- ⚠️ La app **caduca en 7 días** (tendrás que reinstalarla)
- ⚠️ Solo puedes tener **hasta 3 apps instaladas** a la vez
- ⚠️ Solo en **tus propios dispositivos**

Si quieres distribución permanente:
- Necesitas una **cuenta de Apple Developer** ($99/año)
- O usa **TestFlight** para distribución beta

---

## 🚀 ALTERNATIVA: TestFlight (Sin Mac pero con ayuda)

Si tienes un amigo o familiar con Mac, pueden:

1. Compilar la app siguiendo estos pasos
2. Subirla a TestFlight
3. Invitarte como beta tester
4. Tú la instalas desde TestFlight en tu iPhone

---

## 📞 AYUDA

Si tienes problemas:
1. Revisa que Xcode esté actualizado
2. Revisa que iOS en tu iPhone X esté actualizado (iOS 13+)
3. Asegúrate de usar el cable original de Apple
4. Reinicia tanto el Mac como el iPhone

---

**¡Suerte con la instalación!** 🎉

