import 'dart:io';
import 'dart:convert';

void main() async {
  print('🎨 Generando icono para Calendario Familiar...');
  
  // Crear el directorio si no existe
  final iconDir = Directory('assets/icon');
  if (!iconDir.existsSync()) {
    iconDir.createSync(recursive: true);
  }
  
  // Leer el archivo SVG
  final svgFile = File('assets/icon/app_icon.svg');
  if (!svgFile.existsSync()) {
    print('❌ Error: No se encontró el archivo SVG');
    return;
  }
  
  final svgContent = svgFile.readAsStringSync();
  
  // Crear un archivo HTML temporal para convertir SVG a PNG
  final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <title>Icon Generator</title>
    <style>
        body { margin: 0; padding: 0; background: transparent; }
        svg { width: 1024px; height: 1024px; }
    </style>
</head>
<body>
    $svgContent
</body>
</html>
''';
  
  final htmlFile = File('temp_icon.html');
  htmlFile.writeAsStringSync(htmlContent);
  
  print('✅ Archivo HTML temporal creado');
  print('📝 Para generar el icono PNG:');
  print('1. Abre el archivo temp_icon.html en un navegador');
  print('2. Haz una captura de pantalla del SVG');
  print('3. Guarda la imagen como app_icon.png en assets/icon/');
  print('4. Ejecuta: flutter pub get');
  print('5. Ejecuta: flutter pub run flutter_launcher_icons:main');
  
  print('\n🎯 Alternativamente, puedes usar herramientas online:');
  print('- https://convertio.co/svg-png/');
  print('- https://cloudconvert.com/svg-to-png');
  print('- https://www.svgviewer.dev/');
  
  print('\n📋 Instrucciones para convertir SVG a PNG:');
  print('1. Copia el contenido del archivo assets/icon/app_icon.svg');
  print('2. Pégalo en una herramienta de conversión online');
  print('3. Configura el tamaño a 1024x1024 píxeles');
  print('4. Descarga el PNG y guárdalo como assets/icon/app_icon.png');
}



