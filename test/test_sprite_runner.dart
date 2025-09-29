import 'dart:io';
import 'package:patrol/patrol.dart';

/// Ejecutor principal de pruebas para Calendario Familiar
class CalendarioFamiliarTestRunner {
  late PatrolTester _patrol;
  
  CalendarioFamiliarTestRunner() {
    _patrol = PatrolTester();
  }
  
  /// Ejecuta todas las pruebas
  Future<void> runAllTests() async {
    print('🚀 Iniciando pruebas de Calendario Familiar...');
    
    try {
      // Ejecutar pruebas unitarias
      await runUnitTests();
      
      // Ejecutar pruebas de widget
      await runWidgetTests();
      
      // Ejecutar pruebas de integración
      await runIntegrationTests();
      
      // Ejecutar pruebas end-to-end
      await runE2ETests();
      
      print('✅ Todas las pruebas completadas exitosamente');
    } catch (e) {
      print('❌ Error ejecutando pruebas: $e');
      exit(1);
    }
  }
  
  /// Ejecuta solo las pruebas unitarias
  Future<void> runUnitTests() async {
    print('📋 Ejecutando pruebas unitarias...');
    
    try {
      final result = await Process.run('flutter', ['test', 'test/unit/']);
      if (result.exitCode == 0) {
        print('  ✅ Pruebas unitarias completadas exitosamente');
        print(result.stdout);
      } else {
        print('  ❌ Pruebas unitarias fallaron');
        print(result.stderr);
      }
    } catch (e) {
      print('  ❌ Error ejecutando pruebas unitarias: $e');
    }
  }
  
  /// Ejecuta solo las pruebas de widget
  Future<void> runWidgetTests() async {
    print('🎨 Ejecutando pruebas de widget...');
    
    try {
      final result = await Process.run('flutter', ['test', 'test/widget/']);
      if (result.exitCode == 0) {
        print('  ✅ Pruebas de widget completadas exitosamente');
        print(result.stdout);
      } else {
        print('  ❌ Pruebas de widget fallaron');
        print(result.stderr);
      }
    } catch (e) {
      print('  ❌ Error ejecutando pruebas de widget: $e');
    }
  }
  
  /// Ejecuta solo las pruebas de integración
  Future<void> runIntegrationTests() async {
    print('🔗 Ejecutando pruebas de integración...');
    
    try {
      final result = await Process.run('flutter', ['test', 'integration_test/']);
      if (result.exitCode == 0) {
        print('  ✅ Pruebas de integración completadas exitosamente');
        print(result.stdout);
      } else {
        print('  ❌ Pruebas de integración fallaron');
        print(result.stderr);
      }
    } catch (e) {
      print('  ❌ Error ejecutando pruebas de integración: $e');
    }
  }
  
  /// Ejecuta solo las pruebas end-to-end
  Future<void> runE2ETests() async {
    print('🌐 Ejecutando pruebas end-to-end...');
    
    try {
      final result = await Process.run('flutter', ['test', 'test/e2e/']);
      if (result.exitCode == 0) {
        print('  ✅ Pruebas end-to-end completadas exitosamente');
        print(result.stdout);
      } else {
        print('  ❌ Pruebas end-to-end fallaron');
        print(result.stderr);
      }
    } catch (e) {
      print('  ❌ Error ejecutando pruebas end-to-end: $e');
    }
  }
  
  /// Ejecuta pruebas específicas por nombre
  Future<void> runSpecificTests(List<String> testNames) async {
    print('🎯 Ejecutando pruebas específicas: ${testNames.join(', ')}');
    
    for (final testName in testNames) {
      try {
        await _testSprite.runSpecificTest(
          testName,
          onTestStart: (name) {
            print('  🔍 Ejecutando: $name');
          },
          onTestComplete: (name, result) {
            if (result.success) {
              print('  ✅ $name - PASÓ');
            } else {
              print('  ❌ $name - FALLÓ: ${result.error}');
            }
          },
        );
      } catch (e) {
        print('  ❌ Error ejecutando $testName: $e');
      }
    }
  }
  
  /// Ejecuta pruebas en modo CI/CD
  Future<void> runCITests() async {
    print('🤖 Ejecutando pruebas en modo CI/CD...');
    
    // Configurar para CI
    _testSprite.configureForCI();
    
    // Ejecutar todas las pruebas
    await runAllTests();
    
    // Generar reportes
    await _testSprite.generateReports();
    
    print('📊 Reportes generados en test_reports/');
  }
  
  /// Ejecuta pruebas con cobertura de código
  Future<void> runTestsWithCoverage() async {
    print('📈 Ejecutando pruebas con cobertura de código...');
    
    await _testSprite.runWithCoverage(
      outputDir: 'coverage',
      format: ['html', 'lcov'],
      onCoverageGenerated: (coverage) {
        print('📊 Cobertura generada: ${coverage.percentage}%');
        print('📁 Reporte HTML disponible en coverage/html/index.html');
      },
    );
  }
  
  /// Limpia archivos temporales de pruebas
  Future<void> cleanup() async {
    print('🧹 Limpiando archivos temporales...');
    
    await _testSprite.cleanup();
    
    print('✅ Limpieza completada');
  }
}

/// Función principal para ejecutar desde línea de comandos
void main(List<String> args) async {
  final runner = CalendarioFamiliarTestRunner();
  
  if (args.isEmpty) {
    // Sin argumentos, ejecutar todas las pruebas
    await runner.runAllTests();
  } else {
    switch (args[0]) {
      case 'unit':
        await runner.runUnitTests();
        break;
      case 'widget':
        await runner.runWidgetTests();
        break;
      case 'integration':
        await runner.runIntegrationTests();
        break;
      case 'e2e':
        await runner.runE2ETests();
        break;
      case 'ci':
        await runner.runCITests();
        break;
      case 'coverage':
        await runner.runTestsWithCoverage();
        break;
      case 'specific':
        if (args.length > 1) {
          await runner.runSpecificTests(args.sublist(1));
        } else {
          print('❌ Debe especificar nombres de pruebas');
        }
        break;
      case 'cleanup':
        await runner.cleanup();
        break;
      default:
        print('❌ Comando no reconocido: ${args[0]}');
        print('Comandos disponibles: unit, widget, integration, e2e, ci, coverage, specific, cleanup');
        exit(1);
    }
  }
  
  await runner.cleanup();
}
