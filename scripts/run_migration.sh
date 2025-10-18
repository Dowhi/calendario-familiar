#!/bin/bash

echo "========================================"
echo "    MIGRACION DE FIREBASE FIRESTORE"
echo "========================================"
echo

echo "[1/4] Verificando dependencias..."
flutter pub get

echo
echo "[2/4] Ejecutando script de migracion..."
dart scripts/migrate_firebase.dart

echo
echo "[3/4] Actualizando indices de Firestore..."
echo "Por favor, ve a Firebase Console y actualiza los indices manualmente"
echo "o ejecuta: firebase deploy --only firestore:indexes"

echo
echo "[4/4] Actualizando reglas de seguridad..."
echo "Por favor, ve a Firebase Console y actualiza las reglas manualmente"
echo "o ejecuta: firebase deploy --only firestore:rules"

echo
echo "========================================"
echo "    MIGRACION COMPLETADA"
echo "========================================"
echo
echo "Proximos pasos:"
echo "1. Revisar el archivo migration_report.txt"
echo "2. Verificar que la aplicacion funciona correctamente"
echo "3. Actualizar el codigo para usar la nueva estructura"
echo "4. Eliminar colecciones duplicadas si todo esta bien"
echo



