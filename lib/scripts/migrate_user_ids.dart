import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// 🔧 Script para migrar eventos existentes y agregar campo userId
/// 
/// Este script:
/// 1. Obtiene todos los eventos de Firebase que no tienen userId
/// 2. Les asigna userId = 1 (Juan) como default
/// 3. Los actualiza en Firebase
/// 
/// Ejecutar con: dart lib/scripts/migrate_user_ids.dart

void main() async {
  print('🚀 Iniciando migración de userIds...');
  
  try {
    // Inicializar Firebase
    await Firebase.initializeApp();
    print('✅ Firebase inicializado');
    
    final firestore = FirebaseFirestore.instance;
    
    // Obtener todos los eventos
    final eventsSnapshot = await firestore
        .collection('calendar_events')
        .get();
    
    print('📊 Total de eventos encontrados: ${eventsSnapshot.docs.length}');
    
    int updatedCount = 0;
    int skippedCount = 0;
    
    for (final doc in eventsSnapshot.docs) {
      final data = doc.data();
      
      // Verificar si ya tiene userId
      if (data.containsKey('userId')) {
        print('⏭️ Evento "${data['title']}" ya tiene userId: ${data['userId']}');
        skippedCount++;
        continue;
      }
      
      // Agregar userId = 1 (Juan) como default
      await doc.reference.update({
        'userId': 1,
        'migratedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Evento "${data['title']}" actualizado con userId: 1');
      updatedCount++;
    }
    
    print('\n🎉 Migración completada:');
    print('   ✅ Eventos actualizados: $updatedCount');
    print('   ⏭️ Eventos omitidos: $skippedCount');
    print('   📊 Total procesados: ${eventsSnapshot.docs.length}');
    
  } catch (e) {
    print('❌ Error durante la migración: $e');
  }
  
  print('\n💡 Próximos pasos:');
  print('   1. Ejecutar: flutter run');
  print('   2. Crear nuevos eventos para probar colores');
  print('   3. Los eventos existentes ahora tendrán color de Juan (azul)');
}
