# 🔔 Instrucciones para Agregar Sonido de Alarma

## Para que las alarmas tengan sonido personalizado:

### 1. Descargar un archivo de sonido
- Ve a uno de estos sitios:
  - https://freesound.org/ (gratis)
  - https://mixkit.co/free-sound-effects/ (gratis)
  - https://www.zapsplat.com/ (gratis)

### 2. Buscar un sonido de alarma
- Busca términos como: "alarm", "bell", "notification", "ringtone"
- Descarga el archivo en formato MP3

### 3. Colocar el archivo
- Renombra el archivo a: `alarm_sound.mp3`
- Colócalo en: `android/app/src/main/res/raw/alarm_sound.mp3`

### 4. Activar el sonido en el código
- Ve a `lib/features/calendar/presentation/widgets/alarm_dialog.dart`
- Busca la línea: `// sound: const RawResourceAndroidNotificationSound('alarm_sound'),`
- Quita los `//` para activar el sonido

- Ve a `lib/main.dart`
- Busca la línea: `// sound: const RawResourceAndroidNotificationSound('alarm_sound'),`
- Quita los `//` para activar el sonido

### 5. Recompilar la app
```bash
flutter clean
flutter pub get
flutter run
```

## Notas importantes:
- El archivo debe ser MP3
- No debe exceder 1MB
- El nombre debe ser exactamente: `alarm_sound.mp3`
- La ubicación debe ser exactamente: `android/app/src/main/res/raw/`

## Actualmente:
- Las alarmas usan el sonido del sistema por defecto
- Funcionan cuando la app está cerrada
- Tienen vibración y luces LED





