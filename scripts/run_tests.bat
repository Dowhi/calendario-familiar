@echo off
echo ========================================
echo   Calendario Familiar - Test Runner
echo ========================================
echo.

REM Verificar que Flutter está instalado
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter no está instalado o no está en el PATH
    pause
    exit /b 1
)

REM Verificar que estamos en el directorio correcto
if not exist "pubspec.yaml" (
    echo ❌ No se encontró pubspec.yaml. Asegúrate de estar en el directorio del proyecto
    pause
    exit /b 1
)

REM Obtener dependencias
echo 📦 Obteniendo dependencias...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Error obteniendo dependencias
    pause
    exit /b 1
)

REM Verificar argumentos
if "%1"=="" (
    goto :run_all_tests
)

if "%1"=="unit" goto :run_unit_tests
if "%1"=="widget" goto :run_widget_tests
if "%1"=="integration" goto :run_integration_tests
if "%1"=="e2e" goto :run_e2e_tests
if "%1"=="coverage" goto :run_coverage_tests
if "%1"=="clean" goto :clean_tests
if "%1"=="help" goto :show_help

echo ❌ Argumento no reconocido: %1
goto :show_help

:run_all_tests
echo 🚀 Ejecutando todas las pruebas...
echo.
echo 📋 Ejecutando pruebas unitarias...
flutter test test/unit/
if %errorlevel% neq 0 (
    echo ❌ Pruebas unitarias fallaron
    pause
    exit /b 1
)

echo.
echo 🎨 Ejecutando pruebas de widget...
flutter test test/widget/
if %errorlevel% neq 0 (
    echo ❌ Pruebas de widget fallaron
    pause
    exit /b 1
)

echo.
echo 🔗 Ejecutando pruebas de integración...
flutter test integration_test/
if %errorlevel% neq 0 (
    echo ❌ Pruebas de integración fallaron
    pause
    exit /b 1
)

echo.
echo ✅ Todas las pruebas completadas exitosamente!
goto :end

:run_unit_tests
echo 📋 Ejecutando pruebas unitarias...
flutter test test/unit/
goto :end

:run_widget_tests
echo 🎨 Ejecutando pruebas de widget...
flutter test test/widget/
goto :end

:run_integration_tests
echo 🔗 Ejecutando pruebas de integración...
flutter test integration_test/
goto :end

:run_e2e_tests
echo 🌐 Ejecutando pruebas end-to-end...
flutter test test/e2e/
goto :end

:run_coverage_tests
echo 📈 Ejecutando pruebas con cobertura...
flutter test --coverage
if %errorlevel% neq 0 (
    echo ❌ Error ejecutando pruebas con cobertura
    pause
    exit /b 1
)

echo.
echo 📊 Generando reporte de cobertura...
genhtml coverage/lcov.info -o coverage/html
if %errorlevel% neq 0 (
    echo ❌ Error generando reporte de cobertura
    pause
    exit /b 1
)

echo ✅ Reporte de cobertura generado en coverage/html/index.html
goto :end

:clean_tests
echo 🧹 Limpiando archivos de prueba...
if exist "test_reports" rmdir /s /q "test_reports"
if exist "coverage" rmdir /s /q "coverage"
if exist ".dart_tool" rmdir /s /q ".dart_tool"
echo ✅ Limpieza completada
goto :end

:show_help
echo Uso: run_tests.bat [comando]
echo.
echo Comandos disponibles:
echo   (sin argumentos) - Ejecutar todas las pruebas
echo   unit            - Solo pruebas unitarias
echo   widget          - Solo pruebas de widget
echo   integration     - Solo pruebas de integración
echo   e2e             - Solo pruebas end-to-end
echo   coverage        - Pruebas con cobertura de código
echo   clean           - Limpiar archivos de prueba
echo   help            - Mostrar esta ayuda
echo.
echo Ejemplos:
echo   run_tests.bat
echo   run_tests.bat unit
echo   run_tests.bat coverage
echo   run_tests.bat clean
goto :end

:end
echo.
echo ========================================
echo   Pruebas completadas
echo ========================================
pause

