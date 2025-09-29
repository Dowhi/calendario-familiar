#!/bin/bash

echo "========================================"
echo "  Calendario Familiar - Test Runner"
echo "========================================"
echo

# Verificar que Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter no está instalado o no está en el PATH"
    exit 1
fi

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ No se encontró pubspec.yaml. Asegúrate de estar en el directorio del proyecto"
    exit 1
fi

# Obtener dependencias
echo "📦 Obteniendo dependencias..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ Error obteniendo dependencias"
    exit 1
fi

# Función para ejecutar todas las pruebas
run_all_tests() {
    echo "🚀 Ejecutando todas las pruebas..."
    echo
    
    echo "📋 Ejecutando pruebas unitarias..."
    flutter test test/unit/
    if [ $? -ne 0 ]; then
        echo "❌ Pruebas unitarias fallaron"
        exit 1
    fi
    
    echo
    echo "🎨 Ejecutando pruebas de widget..."
    flutter test test/widget/
    if [ $? -ne 0 ]; then
        echo "❌ Pruebas de widget fallaron"
        exit 1
    fi
    
    echo
    echo "🔗 Ejecutando pruebas de integración..."
    flutter test integration_test/
    if [ $? -ne 0 ]; then
        echo "❌ Pruebas de integración fallaron"
        exit 1
    fi
    
    echo
    echo "✅ Todas las pruebas completadas exitosamente!"
}

# Función para ejecutar pruebas con cobertura
run_coverage_tests() {
    echo "📈 Ejecutando pruebas con cobertura..."
    flutter test --coverage
    if [ $? -ne 0 ]; then
        echo "❌ Error ejecutando pruebas con cobertura"
        exit 1
    fi
    
    echo
    echo "📊 Generando reporte de cobertura..."
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html
        if [ $? -ne 0 ]; then
            echo "❌ Error generando reporte de cobertura"
            exit 1
        fi
        echo "✅ Reporte de cobertura generado en coverage/html/index.html"
    else
        echo "⚠️  genhtml no está disponible. Instala lcov para generar reportes HTML"
    fi
}

# Función para limpiar archivos de prueba
clean_tests() {
    echo "🧹 Limpiando archivos de prueba..."
    rm -rf test_reports coverage .dart_tool
    echo "✅ Limpieza completada"
}

# Función para mostrar ayuda
show_help() {
    echo "Uso: ./run_tests.sh [comando]"
    echo
    echo "Comandos disponibles:"
    echo "  (sin argumentos) - Ejecutar todas las pruebas"
    echo "  unit            - Solo pruebas unitarias"
    echo "  widget          - Solo pruebas de widget"
    echo "  integration     - Solo pruebas de integración"
    echo "  e2e             - Solo pruebas end-to-end"
    echo "  coverage        - Pruebas con cobertura de código"
    echo "  clean           - Limpiar archivos de prueba"
    echo "  help            - Mostrar esta ayuda"
    echo
    echo "Ejemplos:"
    echo "  ./run_tests.sh"
    echo "  ./run_tests.sh unit"
    echo "  ./run_tests.sh coverage"
    echo "  ./run_tests.sh clean"
}

# Procesar argumentos
case "${1:-}" in
    "")
        run_all_tests
        ;;
    "unit")
        echo "📋 Ejecutando pruebas unitarias..."
        flutter test test/unit/
        ;;
    "widget")
        echo "🎨 Ejecutando pruebas de widget..."
        flutter test test/widget/
        ;;
    "integration")
        echo "🔗 Ejecutando pruebas de integración..."
        flutter test integration_test/
        ;;
    "e2e")
        echo "🌐 Ejecutando pruebas end-to-end..."
        flutter test test/e2e/
        ;;
    "coverage")
        run_coverage_tests
        ;;
    "clean")
        clean_tests
        ;;
    "help")
        show_help
        ;;
    *)
        echo "❌ Argumento no reconocido: $1"
        show_help
        exit 1
        ;;
esac

echo
echo "========================================"
echo "  Pruebas completadas"
echo "========================================"
