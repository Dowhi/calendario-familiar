#!/bin/bash

echo "========================================"
echo "Construyendo PWA del Calendario Familiar"
echo "========================================"

echo ""
echo "1. Limpiando build anterior..."
flutter clean

echo ""
echo "2. Obteniendo dependencias..."
flutter pub get

echo ""
echo "3. Construyendo para web..."
flutter build web --release --pwa-strategy offline-first

echo ""
echo "4. Verificando archivos generados..."
if [ -d "build/web" ]; then
    echo "✓ Build completado exitosamente"
    echo ""
    echo "Archivos generados en: build/web/"
    echo ""
    echo "Para probar localmente:"
    echo "cd build/web"
    echo "python3 -m http.server 8000"
    echo ""
    echo "Luego abre: http://localhost:8000"
    echo ""
    echo "Para desplegar en GitHub Pages:"
    echo "1. Copia el contenido de build/web/ a tu repositorio"
    echo "2. Configura GitHub Pages en tu repositorio"
    echo "3. Selecciona la carpeta raíz como fuente"
else
    echo "✗ Error: No se generó el build"
fi

echo ""
echo "========================================"
