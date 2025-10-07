# ⚡ Guía Rápida: Probar Notificaciones en 5 Minutos

## 🎯 Pasos Inmediatos

### 1️⃣ Instalar dependencias
```bash
flutter pub get
```

### 2️⃣ Probar en tu dispositivo Android
```bash
# Conecta tu teléfono Android por USB con depuración activada
flutter run -d android
```

**Prueba inmediata:**
1. Abre la app
2. Inicia sesión o regístrate
3. Ve al calendario
4. Toca cualquier día
5. Crea un evento
6. En el diálogo, configura "Recordatorio 1" para dentro de **2 minutos**
7. Guarda el evento
8. **Cierra completamente la app** (swipe en aplicaciones recientes)
9. Espera 2 minutos
10. ✅ **¡Deberías recibir la notificación!**

---

## 🧪 Probar Notificación Inmediata

Para verificar que todo funciona SIN esperar:

1. Abre el calendario
2. Toca cualquier día
3. Presiona el icono de alarma/notificación
4. En el diálogo, presiona el botón del **icono de probeta** (🔬) en la esquina superior derecha
5. ✅ **Deberías ver una notificación de prueba inmediatamente**

---

## 📱 Comandos por Plataforma

### **Android**
```bash
# Verificar dispositivos conectados
flutter devices

# Compilar y ejecutar
flutter run -d android

# Ver logs en tiempo real
flutter logs
```

### **iOS** (requiere Mac y Xcode)
```bash
# Verificar dispositivos conectados
flutter devices

# Compilar y ejecutar (USAR DISPOSITIVO REAL, NO SIMULADOR)
flutter run -d ios

# Ver logs
flutter logs
```

### **Windows**
```bash
# Compilar y ejecutar
flutter run -d windows
```

### **Web**
```bash
# Ejecutar en Chrome
flutter run -d chrome
```

---

## 🚨 Problemas Comunes

### "No recibo notificaciones en Android"

**Solución 1: Verificar permisos**
- Ve a Configuración > Apps > Calendario Familiar
- Activa "Notificaciones"
- Activa "Alarmas y recordatorios" (Android 12+)

**Solución 2: Desactivar optimización de batería**
- Configuración > Batería > Optimización de batería
- Busca "Calendario Familiar"
- Selecciona "No optimizar"

**Solución 3: Fabricantes específicos (Xiaomi, Huawei, etc.)**
- Ve a Configuración > Aplicaciones > Permisos
- Busca "Inicio automático" o "Autostart"
- Actívalo para "Calendario Familiar"

### "No recibo notificaciones en iOS"

**Solución:**
- ⚠️ **DEBES usar un iPhone/iPad REAL**
- El simulador de iOS NO soporta notificaciones programadas
- Verifica permisos: Configuración > Notificaciones > Calendario Familiar

### "La app no compila"

```bash
# Limpiar y reconstruir
flutter clean
flutter pub get
flutter run
```

---

## ✅ Verificación Rápida

Para asegurarte de que todo está configurado:

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Verificar que no hay errores
flutter analyze

# 3. Ver dispositivos disponibles
flutter devices

# 4. Ejecutar en tu dispositivo
flutter run
```

---

## 🎯 Resultado Esperado

Al completar estos pasos, deberías poder:

✅ Crear eventos en el calendario
✅ Configurar alarmas para los eventos
✅ Recibir notificaciones incluso con la app cerrada
✅ Ver el título del evento en la notificación
✅ Configurar múltiples recordatorios por evento

---

## 📖 Documentación Completa

Para instrucciones detalladas, consulta: **`GUIA_NOTIFICACIONES_MULTIPLATAFORMA.md`**

---

## 🎉 ¡Ya Está Todo Listo!

Tu proyecto ya tiene las notificaciones completamente configuradas. Solo necesitas:
1. Ejecutar `flutter pub get`
2. Compilar para tu plataforma
3. ¡Probar!

**No necesitas crear nada nuevo.** Todo el código ya está implementado y funcionando.

