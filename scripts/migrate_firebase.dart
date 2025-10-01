import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

/// Script de migración para consolidar colecciones duplicadas en Firebase
/// 
/// Este script:
/// 1. Migra datos de 'notes' y 'shifts' a 'events'
/// 2. Normaliza 'dayCategories'
/// 3. Elimina colecciones duplicadas
/// 4. Verifica integridad de datos

class FirebaseMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Contadores para el reporte
  int _migratedNotes = 0;
  int _migratedShifts = 0;
  int _migratedCategories = 0;
  int _errors = 0;
  
  Future<void> runMigration() async {
    print('🚀 Iniciando migración de Firebase...');
    print('📅 Fecha: ${DateTime.now()}');
    print('=' * 50);
    
    try {
      // Fase 1: Migrar notas a eventos
      await _migrateNotesToEvents();
      
      // Fase 2: Migrar turnos a eventos
      await _migrateShiftsToEvents();
      
      // Fase 3: Normalizar categorías
      await _normalizeCategories();
      
      // Fase 4: Verificar integridad
      await _verifyDataIntegrity();
      
      // Fase 5: Generar reporte
      _generateReport();
      
    } catch (e) {
      print('❌ Error durante la migración: $e');
      _errors++;
    }
  }
  
  /// Migra datos de la colección 'notes' a 'events'
  Future<void> _migrateNotesToEvents() async {
    print('📝 Migrando notas a eventos...');
    
    try {
      final notesSnapshot = await _firestore.collection('notes').get();
      
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
        _migratedNotes++;
        
        print('✅ Nota migrada: ${data['title']}');
      }
      
      print('📊 Total de notas migradas: $_migratedNotes');
      
    } catch (e) {
      print('❌ Error migrando notas: $e');
      _errors++;
    }
  }
  
  /// Migra datos de la colección 'shifts' a 'events'
  Future<void> _migrateShiftsToEvents() async {
    print('🔄 Migrando turnos a eventos...');
    
    try {
      final shiftsSnapshot = await _firestore.collection('shifts').get();
      
      for (final doc in shiftsSnapshot.docs) {
        final data = doc.data();
        
        // Obtener plantilla de turno para información adicional
        String startTime = '';
        String endTime = '';
        
        if (data['title'] != null) {
          final templateSnapshot = await _firestore
              .collection('shift_templates')
              .where('name', isEqualTo: data['title'])
              .where('familyId', isEqualTo: data['familyId'])
              .limit(1)
              .get();
          
          if (templateSnapshot.docs.isNotEmpty) {
            final template = templateSnapshot.docs.first.data();
            startTime = template['startTime'] ?? '';
            endTime = template['endTime'] ?? '';
          }
        }
        
        // Crear nuevo documento en 'events'
        final eventData = {
          'id': doc.id,
          'familyId': data['familyId'] ?? 'demo_family',
          'ownerId': data['ownerId'] ?? data['userId'],
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'eventType': 'shift',
          'date': data['date'] ?? '',
          'startTime': startTime,
          'endTime': endTime,
          'colorHex': data['color'] ?? '#FF6B6B',
          'category': data['category'] ?? '',
          'isAllDay': startTime.isEmpty && endTime.isEmpty,
          'recurrence': null,
          'participants': [],
          'location': null,
          'notifyMinutesBefore': 30,
          'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': data['updatedAt'] ?? FieldValue.serverTimestamp(),
          'deletedAt': null,
        };
        
        await _firestore.collection('events').doc(doc.id).set(eventData);
        _migratedShifts++;
        
        print('✅ Turno migrado: ${data['title']}');
      }
      
      print('📊 Total de turnos migrados: $_migratedShifts');
      
    } catch (e) {
      print('❌ Error migrando turnos: $e');
      _errors++;
    }
  }
  
  /// Normaliza la colección 'dayCategories'
  Future<void> _normalizeCategories() async {
    print('🏷️ Normalizando categorías...');
    
    try {
      final categoriesSnapshot = await _firestore.collection('dayCategories').get();
      
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
        _migratedCategories++;
        
        print('✅ Categorías migradas para fecha: ${doc.id}');
      }
      
      print('📊 Total de categorías migradas: $_migratedCategories');
      
    } catch (e) {
      print('❌ Error normalizando categorías: $e');
      _errors++;
    }
  }
  
  /// Verifica la integridad de los datos migrados
  Future<void> _verifyDataIntegrity() async {
    print('🔍 Verificando integridad de datos...');
    
    try {
      // Verificar que todos los eventos tienen los campos requeridos
      final eventsSnapshot = await _firestore.collection('events').get();
      int validEvents = 0;
      int invalidEvents = 0;
      
      for (final doc in eventsSnapshot.docs) {
        final data = doc.data();
        
        // Verificar campos requeridos
        if (data['familyId'] != null && 
            data['title'] != null && 
            data['eventType'] != null &&
            data['date'] != null) {
          validEvents++;
        } else {
          invalidEvents++;
          print('⚠️ Evento inválido encontrado: ${doc.id}');
        }
      }
      
      print('📊 Eventos válidos: $validEvents');
      print('⚠️ Eventos inválidos: $invalidEvents');
      
      // Verificar que las categorías están normalizadas
      final categoriesSnapshot = await _firestore.collection('day_categories').get();
      int validCategories = 0;
      
      for (final doc in categoriesSnapshot.docs) {
        final data = doc.data();
        if (data['familyId'] != null && data['categories'] != null) {
          validCategories++;
        }
      }
      
      print('📊 Categorías válidas: $validCategories');
      
    } catch (e) {
      print('❌ Error verificando integridad: $e');
      _errors++;
    }
  }
  
  /// Genera un reporte de la migración
  void _generateReport() {
    print('\n${'=' * 50}');
    print('📋 REPORTE DE MIGRACIÓN');
    print('=' * 50);
    print('📅 Fecha: ${DateTime.now()}');
    print('📝 Notas migradas: $_migratedNotes');
    print('🔄 Turnos migrados: $_migratedShifts');
    print('🏷️ Categorías migradas: $_migratedCategories');
    print('❌ Errores: $_errors');
    print('✅ Estado: ${_errors == 0 ? 'EXITOSO' : 'CON ERRORES'}');
    print('=' * 50);
    
    // Guardar reporte en archivo
    final report = '''
REPORTE DE MIGRACIÓN FIREBASE
Fecha: ${DateTime.now()}

RESUMEN:
- Notas migradas: $_migratedNotes
- Turnos migrados: $_migratedShifts
- Categorías migradas: $_migratedCategories
- Errores: $_errors
- Estado: ${_errors == 0 ? 'EXITOSO' : 'CON ERRORES'}

PRÓXIMOS PASOS:
1. Verificar que la aplicación funciona correctamente
2. Eliminar colecciones duplicadas (notes, shifts, dayCategories)
3. Actualizar el código para usar la nueva estructura
4. Actualizar índices y reglas de seguridad
''';
    
    File('migration_report.txt').writeAsStringSync(report);
    print('📄 Reporte guardado en: migration_report.txt');
  }
  
  /// Limpia las colecciones duplicadas (SOLO EJECUTAR DESPUÉS DE VERIFICAR)
  Future<void> cleanupDuplicateCollections() async {
    print('🗑️ LIMPIEZA DE COLECCIONES DUPLICADAS');
    print('⚠️ ADVERTENCIA: Esta operación es irreversible');
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

/// Función principal para ejecutar la migración
void main() async {
  print('🚀 Script de Migración Firebase');
  print('Este script consolidará las colecciones duplicadas');
  print('');
  
  final migration = FirebaseMigration();
  
  // Ejecutar migración
  await migration.runMigration();
  
  // Preguntar si quiere limpiar colecciones duplicadas
  print('\n¿Quieres eliminar las colecciones duplicadas? (y/N)');
  final input = stdin.readLineSync()?.toLowerCase();
  
  if (input == 'y' || input == 'yes') {
    await migration.cleanupDuplicateCollections();
  }
  
  print('\n✅ Migración completada');
}



