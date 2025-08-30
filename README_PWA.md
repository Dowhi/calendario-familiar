# 📱 Calendario Familiar - PWA

## 🚀 Despliegue Rápido

Tu **Calendario Familiar** ya está configurado como una **Progressive Web App (PWA)** completa. Aquí tienes las opciones para desplegarlo:

### 🌐 Opción 1: GitHub Pages (Recomendado)

1. **Sube tu código a GitHub** (si no lo has hecho ya)
2. **Habilita GitHub Pages**:
   - Ve a tu repositorio → Settings → Pages
   - Source: "Deploy from a branch"
   - Branch: `gh-pages` (se creará automáticamente)
   - Folder: `/ (root)`
   - Save

3. **El workflow automático se encargará del resto**:
   - Cada vez que hagas push a `main`
   - Se construirá automáticamente la PWA
   - Se desplegará en GitHub Pages

### 🔧 Opción 2: Despliegue Manual

Si prefieres desplegar manualmente:

```bash
# 1. Construir la PWA
flutter build web --release --pwa-strategy offline-first

# 2. Los archivos estarán en build/web/
# 3. Sube el contenido de build/web/ a tu servidor
```

### 🧪 Probar Localmente

```bash
# Construir
flutter build web --release --pwa-strategy offline-first

# Servir localmente
cd build/web
python -m http.server 8000

# Abrir en navegador
http://localhost:8000
```

## ✨ Características de la PWA

### ✅ Funcionalidades Implementadas:
- **📱 Instalable**: Los usuarios pueden agregar la app al escritorio
- **🔌 Offline**: Funciona sin conexión a internet
- **📐 Responsive**: Se adapta a diferentes tamaños de pantalla
- **⚡ Fast**: Carga rápida con cache inteligente
- **🎯 Engaging**: Experiencia similar a app nativa

### 🎨 Diseño:
- **Tema**: Azul (#2196F3) con fondo blanco
- **Iconos**: 192px y 512px (estándar y maskable)
- **Idioma**: Español
- **Categorías**: Productividad y Familia

## 🔍 Verificar que Funciona

### Chrome DevTools:
1. Abre DevTools (F12)
2. Ve a "Application" → "Manifest"
3. Verifica que aparezca "Calendario Familiar"
4. Ve a "Service Workers" → debe estar activo
5. Ve a "Cache Storage" → debe tener contenido

### Lighthouse:
1. DevTools → Lighthouse
2. Ejecuta auditoría PWA
3. Deberías obtener **90+ puntos**

## 📱 Instalar en Dispositivos

### Android:
- Abre Chrome
- Ve a tu PWA
- Toca el menú (⋮) → "Instalar app"
- O aparecerá un banner automático

### iOS:
- Abre Safari
- Ve a tu PWA
- Toca el botón compartir (□↑)
- "Agregar a pantalla de inicio"

### Desktop:
- Chrome mostrará un banner de instalación
- O ve a menú → "Instalar Calendario Familiar"

## 🐛 Solución de Problemas

### PWA no se instala:
- ✅ Verifica que estés en HTTPS (requerido)
- ✅ Asegúrate de que el manifest.json esté en la raíz
- ✅ Comprueba que los iconos existan

### No funciona offline:
- ✅ Verifica que el service worker esté activo
- ✅ Revisa la consola para errores
- ✅ Asegúrate de que las rutas sean correctas

### Iconos no aparecen:
- ✅ Verifica que los archivos existan en `/icons/`
- ✅ Comprueba las rutas en manifest.json
- ✅ Asegúrate de que los tamaños sean correctos

## 🌟 URLs de Ejemplo

Una vez desplegado, tu PWA estará disponible en:
- **GitHub Pages**: `https://tuusuario.github.io/turepositorio`
- **Netlify**: `https://tuapp.netlify.app`
- **Vercel**: `https://tuapp.vercel.app`

## 📞 Soporte

Si tienes problemas:
1. Revisa la consola del navegador
2. Verifica los logs del service worker
3. Comprueba que todos los archivos estén en su lugar
4. Asegúrate de estar en HTTPS

---

¡Tu **Calendario Familiar** ahora es una PWA completa y lista para usar! 🎉

**Características principales:**
- 📅 Gestión de eventos familiares
- 🔄 Sincronización en tiempo real
- 📱 Instalable como app nativa
- 🔌 Funciona offline
- 🌐 Accesible desde cualquier dispositivo

---
**Última actualización**: 30 de agosto de 2025 - PWA configurada y lista para despliegue
