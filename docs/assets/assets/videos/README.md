# 📹 Videos para Splash Screen

## 📋 Instrucciones para tu Video MP4

### 🎯 **PASOS PARA IMPLEMENTAR TU VIDEO:**

1. **Coloca tu video MP4** en esta carpeta con el nombre: `splash_video.mp4`

2. **Especificaciones recomendadas:**
   - **Formato:** MP4
   - **Duración:** 3-5 segundos (ideal)
   - **Resolución:** 1080x1920 (vertical) o 1920x1080 (horizontal)
   - **Tamaño:** Máximo 5MB para carga rápida
   - **FPS:** 30 fps

3. **Optimización del video:**
   - Usa un video corto y atractivo
   - Evita texto que requiera lectura
   - Usa colores que combinen con tu app
   - Considera un loop suave

### 🔄 **Alternativas si el video no funciona:**

Si tienes problemas con el video, puedes usar la versión alternativa con animaciones:

1. **Cambia en `app_router.dart`** la línea:
   ```dart
   builder: (context, state) => const SplashScreen(),
   ```
   
   Por:
   ```dart
   builder: (context, state) => const SplashScreenAlternative(),
   ```

### 📱 **Compatibilidad:**

- ✅ **Android:** Soporte completo
- ✅ **iOS:** Soporte completo  
- ✅ **Web:** Soporte completo
- ✅ **Windows:** Soporte completo

### 🎨 **Ejemplo de estructura:**

```
assets/videos/
├── splash_video.mp4    ← Tu video aquí
└── README.md          ← Este archivo
```

### ⚡ **Consejos de rendimiento:**

- **Comprime el video** antes de agregarlo
- **Usa formatos optimizados** (H.264)
- **Mantén el archivo pequeño** para carga rápida
- **Prueba en diferentes dispositivos**

¡Una vez que agregues tu video, la app mostrará automáticamente tu splash screen personalizado!
