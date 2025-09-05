import 'dart:io';

void main() async {
  print('🎨 Verificando icono para Calendario Familiar...');
  
  // Verificar que existe el directorio de iconos
  final iconDir = Directory('assets/icon');
  if (!iconDir.existsSync()) {
    print('❌ Error: No se encontró el directorio assets/icon');
    return;
  }
  
  // Verificar que existe el archivo PNG
  final pngFile = File('assets/icon/app_icon.png');
  if (!pngFile.existsSync()) {
    print('❌ Error: No se encontró el archivo app_icon.png en assets/icon/');
    return;
  }
  
  print('✅ Archivo de icono encontrado');
  print('📝 Pasos para generar los iconos de la aplicación:');
  print('1. Ejecuta: flutter pub get');
  print('2. Ejecuta: flutter pub run flutter_launcher_icons:main');
  
  print('\n✨ El icono se aplicará en todas las plataformas configuradas.');
}



