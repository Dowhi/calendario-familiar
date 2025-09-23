import 'dart:io';

/// Script para compilar la versión mínima de la app para test en iPhone
/// Ejecutar con: dart run scripts/build_minimal.dart

void main() async {
  print('📱 Compilando versión mínima para test en iPhone...\n');
  
  // Verificar que Flutter está instalado
  await _checkFlutterInstallation();
  
  // Limpiar build anterior
  await _cleanBuild();
  
  // Copiar archivos mínimos
  await _copyMinimalFiles();
  
  // Compilar versión mínima
  await _buildMinimal();
  
  // Copiar a docs para GitHub Pages
  await _copyToDocs();
  
  print('\n✅ Versión mínima compilada y lista para probar en iPhone.');
  print('\n📋 Próximos pasos:');
  print('1. Hacer commit y push de los cambios');
  print('2. Esperar despliegue en GitHub Pages');
  print('3. Probar en iPhone: https://dowhi.github.io/calendario-familiar/');
  print('4. Si funciona, agregar funcionalidades una por una');
}

Future<void> _checkFlutterInstallation() async {
  print('🔍 Verificando Flutter...');
  
  try {
    final result = await Process.run('flutter', ['--version']);
    if (result.exitCode == 0) {
      print('✅ Flutter está instalado');
    } else {
      throw Exception('Flutter no está disponible');
    }
  } catch (e) {
    print('❌ Error: Flutter no está instalado');
    exit(1);
  }
}

Future<void> _cleanBuild() async {
  print('\n🧹 Limpiando build anterior...');
  
  try {
    await Process.run('flutter', ['clean']);
    print('✅ Build limpiado');
  } catch (e) {
    print('⚠️ Error limpiando build: $e');
  }
}

Future<void> _copyMinimalFiles() async {
  print('\n📁 Copiando archivos mínimos...');
  
  try {
    // Copiar pubspec_minimal.yaml a pubspec.yaml
    final pubspecMinimal = File('pubspec_minimal.yaml');
    final pubspec = File('pubspec.yaml');
    
    if (await pubspecMinimal.exists()) {
      await pubspecMinimal.copy('pubspec.yaml');
      print('✅ pubspec.yaml actualizado con dependencias mínimas');
    }
    
    // Copiar index_minimal.html a web/index.html
    final indexMinimal = File('web/index_minimal.html');
    final index = File('web/index.html');
    
    if (await indexMinimal.exists()) {
      await indexMinimal.copy('web/index.html');
      print('✅ web/index.html actualizado con versión mínima');
    }
    
    // Copiar main_minimal.dart a main.dart
    final mainMinimal = File('lib/main_minimal.dart');
    final main = File('lib/main.dart');
    
    if (await mainMinimal.exists()) {
      await mainMinimal.copy('lib/main.dart');
      print('✅ lib/main.dart actualizado con versión mínima');
    }
    
  } catch (e) {
    print('❌ Error copiando archivos: $e');
    exit(1);
  }
}

Future<void> _buildMinimal() async {
  print('\n🔨 Compilando versión mínima...');
  
  try {
    // Instalar dependencias mínimas
    await Process.run('flutter', ['pub', 'get']);
    print('✅ Dependencias instaladas');
    
    // Compilar para web
    final result = await Process.run('flutter', [
      'build', 
      'web', 
      '--release', 
      '--base-href=/calendario-familiar/',
      '--web-renderer=html'
    ]);
    
    if (result.exitCode == 0) {
      print('✅ Versión mínima compilada exitosamente');
    } else {
      print('❌ Error compilando: ${result.stderr}');
      exit(1);
    }
  } catch (e) {
    print('❌ Error en build: $e');
    exit(1);
  }
}

Future<void> _copyToDocs() async {
  print('\n📂 Copiando a carpeta docs...');
  
  try {
    if (Platform.isWindows) {
      await Process.run('powershell', [
        '-NoProfile', 
        '-ExecutionPolicy', 
        'Bypass', 
        '-Command', 
        'if(!(Test-Path docs)){New-Item -ItemType Directory -Path docs | Out-Null}; robocopy build/web docs /MIR | Out-Null; Write-Output "Copy complete"'
      ]);
    } else {
      await Process.run('cp', ['-r', 'build/web/*', 'docs/']);
    }
    
    print('✅ Archivos copiados a docs/');
  } catch (e) {
    print('❌ Error copiando a docs: $e');
    exit(1);
  }
}
