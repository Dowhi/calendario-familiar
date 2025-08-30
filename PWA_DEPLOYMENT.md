# 🚀 Despliegue PWA - Calendario Familiar

## ¿Qué es una PWA?

Una **Progressive Web App (PWA)** es una aplicación web que se comporta como una aplicación nativa, permitiendo:
- ✅ Instalación en el dispositivo
- ✅ Funcionamiento offline
- ✅ Notificaciones push
- ✅ Acceso rápido desde el escritorio

## 📋 Configuración Actual

Tu proyecto ya está configurado como PWA con:
- ✅ `manifest.json` - Configuración de la app
- ✅ `sw.js` - Service Worker para funcionalidad offline
- ✅ Iconos en múltiples tamaños
- ✅ Metadatos optimizados

## 🛠️ Pasos para Construir y Desplegar

### Opción 1: Usando los Scripts Automáticos

**Windows:**
```bash
build_pwa.bat
```

**Linux/Mac:**
```bash
chmod +x build_pwa.sh
./build_pwa.sh
```

### Opción 2: Comandos Manuales

```bash
# 1. Limpiar build anterior
flutter clean

# 2. Obtener dependencias
flutter pub get

# 3. Construir para web
flutter build web --release --web-renderer canvaskit
```

## 🌐 Despliegue en GitHub Pages

### Paso 1: Preparar el Repositorio
1. Crea una nueva rama llamada `gh-pages` (opcional)
2. Copia todo el contenido de `build/web/` a la raíz de tu repositorio

### Paso 2: Configurar GitHub Pages
1. Ve a tu repositorio en GitHub
2. Settings → Pages
3. Source: Deploy from a branch
4. Branch: `main` (o `gh-pages` si la creaste)
5. Folder: `/ (root)`
6. Save

### Paso 3: Verificar
- Tu PWA estará disponible en: `https://tuusuario.github.io/turepositorio`
- Los usuarios podrán instalarla desde el navegador

## 🔧 Despliegue en Otros Servicios

### Netlify
1. Conecta tu repositorio de GitHub
2. Build command: `flutter build web --release`
3. Publish directory: `build/web`

### Vercel
1. Conecta tu repositorio de GitHub
2. Framework preset: Other
3. Build command: `flutter build web --release`
4. Output directory: `build/web`

### Firebase Hosting
```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Inicializar Firebase
firebase init hosting

# Desplegar
firebase deploy
```

## 🧪 Probar Localmente

```bash
# Navegar al directorio build
cd build/web

# Servir archivos (Python 3)
python -m http.server 8000

# O con Python 2
python -m SimpleHTTPServer 8000

# Abrir en navegador
http://localhost:8000
```

## 📱 Características de la PWA

### Funcionalidades Implementadas:
- ✅ **Instalable**: Los usuarios pueden agregar la app al escritorio
- ✅ **Offline**: Funciona sin conexión a internet
- ✅ **Responsive**: Se adapta a diferentes tamaños de pantalla
- ✅ **Fast**: Carga rápida con cache inteligente
- ✅ **Engaging**: Experiencia similar a app nativa

### Iconos Disponibles:
- 192x192 px (estándar)
- 512x512 px (alta resolución)
- Versiones maskable para Android

## 🔍 Verificar PWA

### Chrome DevTools:
1. Abre DevTools (F12)
2. Ve a la pestaña "Application"
3. Verifica:
   - Manifest
   - Service Workers
   - Cache Storage

### Lighthouse:
1. Abre DevTools
2. Ve a la pestaña "Lighthouse"
3. Ejecuta auditoría PWA
4. Deberías obtener 90+ puntos

## 🐛 Solución de Problemas

### PWA no se instala:
- Verifica que el manifest.json esté en la raíz
- Asegúrate de que los iconos existan
- Comprueba que el service worker esté registrado

### No funciona offline:
- Verifica que el service worker esté activo
- Revisa la consola para errores
- Asegúrate de que las rutas en sw.js sean correctas

### Iconos no aparecen:
- Verifica que los archivos de iconos existan
- Comprueba las rutas en manifest.json
- Asegúrate de que los tamaños sean correctos

## 📞 Soporte

Si tienes problemas con el despliegue:
1. Revisa la consola del navegador
2. Verifica los logs del service worker
3. Comprueba que todos los archivos estén en su lugar

¡Tu Calendario Familiar ahora es una PWA completa! 🎉
