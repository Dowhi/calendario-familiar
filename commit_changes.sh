#!/bin/bash

# Actualizar la versión de Flutter en GitHub Actions
echo "Actualizando versión de Flutter en GitHub Actions..."

# Hacer commit de los cambios
git add .github/workflows/deploy.yml
git commit -m "fix: actualizar Flutter a 3.19.0 para compatibilidad con firebase_auth

- Actualiza Flutter de 3.13.0 a 3.19.0 en GitHub Actions
- Resuelve conflicto de versiones con firebase_auth ^5.7.0
- firebase_auth requiere Dart SDK >=3.2.0 <4.0.0
- Flutter 3.19.0 incluye Dart SDK 3.2.0+
- Fixes: Error de resolución de dependencias en CI/CD"

echo "✅ Cambios aplicados y commit creado"
echo "🚀 El próximo push activará el workflow con la versión correcta de Flutter"
