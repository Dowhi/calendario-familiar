import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

/// Script de migración simplificado para la nueva estructura optimizada
/// 
/// Este script:
/// 1. Verifica la conectividad con Firebase
/// 2. Muestra estadísticas de las colecciones actuales
/// 3. Proporciona opciones de migración

class SimpleFirebaseMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<void> runMigration() async {
    print('🚀 Script de Migración Simplificado');
    print('📅 Fecha: ${DateTime.now()}');
    print('=' * 50);
    
    try {
      // Verificar conectividad
      await _checkConnectivity();
      
      // Mostrar estadísticas actuales
      await _showCurrentStatistics();
      
      // Mostrar opciones
      await _showOptions();
      
    } catch (e) {
      print('❌ Error durante la migración: $e');
    }
  }
  
  /// Verifica la conectividad con Firebase
  Future<void> _checkConnectivity() async {
    print('🔍 Verificando conectividad con Firebase...');
    
    try {
      // Verificar autenticación
      final user = _auth.currentUser;
      if (user != null) {
        print('✅ Usuario autenticado: ${user.email}');
      } else {
        print('⚠️ No hay usuario autenticado');
      }
      
      // Verificar Firestore
      final testDoc = await _firestore.collection('test').doc('connection').get();
      print('✅ Firestore conectado correctamente');
      
    } catch (e) {
      print('❌ Error de conectividad: $e');
      throw Exception('No se puede conectar a Firebase');
    }
  }
  
  /// Muestra estadísticas de las colecciones actuales
  Future<void> _showCurrentStatistics() async {
    print('\n📊 Estadísticas Actuales de la Base de Datos');
    print('=' * 50);
    
    try {
      // Contar eventos (legacy)
      final eventsSnapshot = await _firestore.collection('events').get();
      print('📝 Eventos (legacy): ${eventsSnapshot.docs.length}');
      
      // Contar notas
      final notesSnapshot = await _firestore.collection('notes').get();
      print('📝 Notas: ${notesSnapshot.docs.length}');
      
      // Contar turnos
      final shiftsSnapshot = await _firestore.collection('shifts').get();
      print('🔄 Turnos: ${shiftsSnapshot.docs.length}');
      
      // Contar categorías
      final categoriesSnapshot = await _firestore.collection('dayCategories').get();
      print('🏷️ Categorías: ${categoriesSnapshot.docs.length}');
      
      // Contar plantillas
      final templatesSnapshot = await _firestore.collection('shift_templates').get();
      print('📋 Plantillas: ${templatesSnapshot.docs.length}');
      
      // Contar familias
      final familiesSnapshot = await _firestore.collection('families').get();
      print('👨‍👩‍👧‍👦 Familias: ${familiesSnapshot.docs.length}');
      
      // Contar usuarios
      final usersSnapshot = await _firestore.collection('users').get();
      print('👤 Usuarios: ${usersSnapshot.docs.length}');
      
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
    }
  }
  
  /// Muestra opciones de migración
  Future<void> _showOptions() async {
    print('\n🛠️ Opciones de Migración');
    print('=' * 50);
    print('1. Solo verificar conectividad y estadísticas');
    print('2. Migrar datos a la nueva estructura');
    print('3. Limpiar colecciones duplicadas (PELIGROSO)');
    print('4. Salir');
    
    print('\n¿Qué opción deseas? (1-4):');
    final input = stdin.readLineSync()?.trim();
    
    switch (input) {
      case '1':
        print('✅ Verificación completada');
        break;
      case '2':
        await _migrateData();
        break;
      case '3':
        await _cleanupCollections();
        break;
      case '4':
        print('👋 ¡Hasta luego!');
        break;
      default:
        print('❌ Opción no válida');
    }
  }
  
  /// Migra datos a la nueva estructura
  Future<void> _migrateData() async {
    print('\n🔄 Iniciando migración de datos...');
    print('⚠️ Esta operación puede tomar varios minutos');
    
    try {
      // Migrar notas
      await _migrateNotes();
      
      // Migrar turnos
      await _migrateShifts();
      
      // Migrar categorías
      await _migrateCategories();
      
      print('✅ Migración completada exitosamente');
      
    } catch (e) {
      print('❌ Error durante la migración: $e');
    }
  }
  
  /// Migra notas a la nueva estructura
  Future<void> _migrateNotes() async {
    print('📝 Migrando notas...');
    
    try {
      final notesSnapshot = await _firestore.collection('notes').get();
      int migrated = 0;
      
      for (final doc in notesSnapshot.docs) {
        final data = doc.data();
        
        // Crear nuevo documento en 'events'
        final eventData = {
          'id': doc.id,
          'familyId': data['familyId'] ?? 'demo_family',
          'ownerId': data['ownerId'] ?? data['userId'],
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'eventType': 'note',
          'date': data['date'] ?? '',
          'startTime': null,
          'endTime': null,
          'colorHex': data['color'] ?? '#3B82F6',
          'category': data['category'] ?? '',
          'isAllDay': true,
          'recurrence': null,
          'participants': [],
          'location': null,
          'notifyMinutesBefore': 30,
          'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': data['updatedAt'] ?? FieldValue.serverTimestamp(),
          'deletedAt': null,
        };
        
        await _firestore.collection('events').doc(doc.id).set(eventData);
        migrated++;
        
        if (migrated % 10 == 0) {
          print('   ✅ $migrated notas migradas...');
        }
      }
      
      print('✅ Total de notas migradas: $migrated');
      
    } catch (e) {
      print('❌ Error migrando notas: $e');
    }
  }
  
  /// Migra turnos a la nueva estructura
  Future<void> _migrateShifts() async {
    print('🔄 Migrando turnos...');
    
    try {
      final shiftsSnapshot = await _firestore.collection('shifts').get();
      int migrated = 0;
      
      for (final doc in shiftsSnapshot.docs) {
        final data = doc.data();
        
        // Crear nuevo documento en 'events'
        final eventData = {
          'id': doc.id,
          'familyId': data['familyId'] ?? 'demo_family',
          'ownerId': data['ownerId'] ?? data['userId'],
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'eventType': 'shift',
          'date': data['date'] ?? '',
          'startTime': null,
          'endTime': null,
          'colorHex': data['color'] ?? '#FF6B6B',
          'category': data['category'] ?? '',
          'isAllDay': true,
          'recurrence': null,
          'participants': [],
          'location': null,
          'notifyMinutesBefore': 30,
          'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': data['updatedAt'] ?? FieldValue.serverTimestamp(),
          'deletedAt': null,
        };
        
        await _firestore.collection('events').doc(doc.id).set(eventData);
        migrated++;
        
        if (migrated % 10 == 0) {
          print('   ✅ $migrated turnos migrados...');
        }
      }
      
      print('✅ Total de turnos migrados: $migrated');
      
    } catch (e) {
      print('❌ Error migrando turnos: $e');
    }
  }
  
  /// Migra categorías a la nueva estructura
  Future<void> _migrateCategories() async {
    print('🏷️ Migrando categorías...');
    
    try {
      final categoriesSnapshot = await _firestore.collection('dayCategories').get();
      int migrated = 0;
      
      for (final doc in categoriesSnapshot.docs) {
        final data = doc.data();
        
        // Crear estructura normalizada
        final normalizedData = {
          'familyId': data['familyId'] ?? 'demo_family',
          'date': doc.id, // El ID del documento es la fecha
          'categories': {
            'category1': data['category1'] ?? '',
            'category2': data['category2'] ?? '',
            'category3': data['category3'] ?? '',
          },
          'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': data['updatedAt'] ?? FieldValue.serverTimestamp(),
        };
        
        // Migrar a nueva colección 'day_categories'
        await _firestore.collection('day_categories').doc(doc.id).set(normalizedData);
        migrated++;
        
        if (migrated % 10 == 0) {
          print('   ✅ $migrated categorías migradas...');
        }
      }
      
      print('✅ Total de categorías migradas: $migrated');
      
    } catch (e) {
      print('❌ Error migrando categorías: $e');
    }
  }
  
  /// Limpia colecciones duplicadas
  Future<void> _cleanupCollections() async {
    print('\n🗑️ LIMPIEZA DE COLECCIONES DUPLICADAS');
    print('⚠️ ADVERTENCIA: Esta operación es irreversible');
    print('⚠️ Se eliminarán las colecciones: notes, shifts, dayCategories');
    print('¿Estás seguro de que quieres continuar? (y/N)');
    
    final input = stdin.readLineSync()?.toLowerCase();
    if (input != 'y' && input != 'yes') {
      print('❌ Operación cancelada');
      return;
    }
    
    try {
      // Eliminar colección 'notes'
      await _deleteCollection('notes');
      print('✅ Colección "notes" eliminada');
      
      // Eliminar colección 'shifts'
      await _deleteCollection('shifts');
      print('✅ Colección "shifts" eliminada');
      
      // Eliminar colección 'dayCategories' (legacy)
      await _deleteCollection('dayCategories');
      print('✅ Colección "dayCategories" eliminada');
      
      print('🎉 Limpieza completada exitosamente');
      
    } catch (e) {
      print('❌ Error durante la limpieza: $e');
    }
  }
  
  /// Elimina una colección completa
  Future<void> _deleteCollection(String collectionName) async {
    final snapshot = await _firestore.collection(collectionName).get();
    final batch = _firestore.batch();
    
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}

/// Función principal
void main() async {
  print('🚀 Script de Migración Simplificado');
  print('Este script te ayudará a migrar tu base de datos');
  print('');
  
  final migration = SimpleFirebaseMigration();
  await migration.runMigration();
  
  print('\n✅ Proceso completado');
}



