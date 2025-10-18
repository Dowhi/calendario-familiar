import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
// import 'dart:html' as html; // Comentado para compatibilidad con WebAssembly
import 'package:calendario_familiar/core/models/shift_template.dart';
import 'package:collection/collection.dart';
// Eliminado: import auth_controller (ya no se utiliza)
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Eliminado: import family, app_user (ya no se utiliza)
import 'package:calendario_familiar/core/models/app_event.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:calendario_familiar/core/utils/error_tracker.dart';
import 'package:flutter/material.dart'; // Para WidgetsBinding
import 'package:calendario_familiar/core/providers/current_user_provider.dart';
import 'package:calendario_familiar/core/services/user_sync_service.dart';

final calendarDataServiceProvider = ChangeNotifierProvider((ref) => CalendarDataService(ref));

class CalendarDataService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref _ref;

  // Datos locales como caché
  final Map<String, List<String>> _events = {}; // Legacy - mantener para compatibilidad
  final Map<String, List<String>> _notes = {}; // Nueva caché para notas
  final Map<String, List<String>> _shifts = {}; // Nueva caché para turnos
  final Map<String, Map<String, String?>> _dayCategories = {};
  final List<ShiftTemplate> _shiftTemplates = [];
  // 🔹 Caché para mapear eventos a sus userIds: dateKey -> {eventTitle: userId}
  final Map<String, Map<String, int>> _eventUserIds = {};
  
  // Streams para sincronización en tiempo real
  StreamSubscription<QuerySnapshot>? _eventsSubscription; // Legacy
  StreamSubscription<QuerySnapshot>? _notesSubscription; // Nueva suscripción para notas
  StreamSubscription<QuerySnapshot>? _shiftsSubscription; // Nueva suscripción para turnos
  StreamSubscription<QuerySnapshot>? _categoriesSubscription;
  StreamSubscription<QuerySnapshot>? _shiftTemplatesSubscription;
  
  // ID de la familia (dinámico)
  String? _userFamilyId; 
  String? get userFamilyId => _userFamilyId;

  // Control de conectividad y reconexión
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  Timer? _reconnectionTimer;
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 5;
  static const Duration _reconnectionDelay = Duration(seconds: 5);
  
  // Modo polling para iOS
  bool _isPollingMode = false;
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(minutes: 5); // Reducido de 30 segundos a 5 minutos
  
  // Control de caché para evitar recargas innecesarias
  DateTime? _lastDataUpdate;
  static const Duration _cacheValidityDuration = Duration(minutes: 10); // Los datos son válidos por 10 minutos

  CalendarDataService(this._ref) {
    print('🔧 CalendarDataService constructor iniciado');
    _setupConnectivityListener();
    
    // Eliminado: listener de authController - ya no se utiliza
    // Sin autenticación, usamos null para cargar todos los datos
    _userFamilyId = 'default_family'; // FamilyId fijo para almacenar datos
    print('🔧 DIAGNÓSTICO: FamilyId fijo: $_userFamilyId - cargando todos los datos (sin autenticación)');
    
    _reinitializeSubscriptions();
    _migrateExistingEvents(); // 🔹 Migrar eventos existentes automáticamente
    _testFirebaseConnection(); // 🔹 Probar conexión con Firebase
    _initializeUsers(); // 🔹 Inicializar usuarios en Firebase
  }

  // Configurar listener de conectividad
  void _setupConnectivityListener() {
    if (kIsWeb) {
      // En web, usar eventos del navegador
      _setupWebConnectivityListener();
    } else {
      // En móvil, usar eventos del sistema
      _setupMobileConnectivityListener();
    }
  }

  void _setupWebConnectivityListener() {
    // Listener para cambios de conectividad en web
    if (kIsWeb) {
      // Usar eventos del navegador para detectar cambios de conectividad
      _checkWebConnectivity();
      
      // Verificar conectividad cada 30 segundos
      Timer.periodic(const Duration(seconds: 30), (_) {
        _checkWebConnectivity();
      });
    }
  }

  void _setupMobileConnectivityListener() {
    // En móvil, usar eventos del sistema (implementar si es necesario)
    print('📱 Configurando listener de conectividad móvil');
  }

  void _checkWebConnectivity() {
    if (kIsWeb) {
      final wasOnline = _isOnline;
      // _isOnline = html.window.navigator.onLine ?? true; // Comentado para compatibilidad
      _isOnline = true; // Asumir online por defecto
      
      if (wasOnline != _isOnline) {
        print('🌐 Estado de conectividad cambió: ${_isOnline ? "ONLINE" : "OFFLINE"}');
        
        if (_isOnline) {
          _onConnectionRestored();
        } else {
          _onConnectionLost();
        }
        
        notifyListeners();
      }
    }
  }

  void _onConnectionLost() {
    print('❌ Conexión perdida, pausando sincronización...');
    _cancelSubscriptions();
    _startReconnectionTimer();
  }

  void _onConnectionRestored() {
    print('✅ Conexión restaurada, reiniciando sincronización...');
    _reconnectionAttempts = 0;
    _reconnectionTimer?.cancel();
    _reinitializeSubscriptions();
  }

  void _startReconnectionTimer() {
    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer.periodic(_reconnectionDelay, (_) {
      if (_reconnectionAttempts < _maxReconnectionAttempts) {
        _reconnectionAttempts++;
        print('🔄 Intento de reconexión $_reconnectionAttempts/$_maxReconnectionAttempts');
        _attemptReconnection();
      } else {
        print('❌ Máximo de intentos de reconexión alcanzado');
        _reconnectionTimer?.cancel();
      }
    });
  }

  void _attemptReconnection() {
    if (_isOnline && _userFamilyId != null) {
      print('🔄 Intentando reconexión...');
      _reinitializeSubscriptions();
    }
  }

  void _reinitializeSubscriptions() {
    print('🔧 _reinitializeSubscriptions iniciado');
    print('🔧 FamilyId actual: $_userFamilyId');
    print('🔧 Estado de conectividad: ${_isOnline ? "ONLINE" : "OFFLINE"}');
    
    _cancelSubscriptions();
    
    if (_isOnline) {
      print('🔧 Online, inicializando sincronización universal...');
      
      // Usar sincronización en tiempo real para todos los dispositivos
      print('🌐 Inicializando sincronización en tiempo real universal');
      initialize();
    } else {
      print('🔧 Sin conexión, limpiando datos locales...');
      _events.clear();
      _dayCategories.clear();
      _shiftTemplates.clear();
      notifyListeners();
    }
  }

  void _cancelSubscriptions() {
    _eventsSubscription?.cancel();
    _notesSubscription?.cancel();
    _shiftsSubscription?.cancel();
    _categoriesSubscription?.cancel();
    _shiftTemplatesSubscription?.cancel();
  }

  Future<void> initialize() async {
    if (!_isOnline) {
      print('⚠️ Sin conexión, saltando inicialización de sincronización.');
      return;
    }

    print('🚀 Inicializando sincronización universal (sin familyId específico)');
    
    try {
      // Para iOS, usar modo polling en lugar de streams
      if (kIsWeb && _isLikelyIOS()) {
        print('📱 iOS detectado, usando modo polling en lugar de streams');
        await _initializeWithPolling();
        return;
      }
      
      // Configurar timeout para las suscripciones (reducido para evitar bloqueos)
      final timeout = const Duration(seconds: 10);
      
      // Suscripciones SIN familyId - cargar todos los datos
      _eventsSubscription = _firestore
          .collection('events')
          .snapshots()
          .listen(
            _onEventsChanged,
            onError: (error) {
              print('❌ Error en suscripción de eventos: $error');
              _handleSubscriptionError('events', error);
            },
          );
      
      _notesSubscription = _firestore
          .collection('notes')
          .snapshots()
          .listen(
            _onNotesChanged,
            onError: (error) {
              print('❌ Error en suscripción de notas: $error');
              _handleSubscriptionError('notes', error);
            },
          );
      
      _shiftsSubscription = _firestore
          .collection('shifts')
          .snapshots()
          .listen(
            _onShiftsChanged,
            onError: (error) {
              print('❌ Error en suscripción de turnos: $error');
              _handleSubscriptionError('shifts', error);
            },
          );
      
      _categoriesSubscription = _firestore
          .collection('dayCategories')
          .snapshots()
          .listen(
            _onCategoriesChanged,
            onError: (error) {
              print('❌ Error en suscripción de categorías: $error');
              _handleSubscriptionError('categories', error);
            },
          );

      print('🔧 Configurando suscripción a shift_templates sin filtro familyId');
      _shiftTemplatesSubscription = _firestore
          .collection('shift_templates')
          .snapshots()
          .listen(
            _onShiftTemplatesChanged,
            onError: (error) {
              print('❌ Error en suscripción de plantillas: $error');
              _handleSubscriptionError('shift_templates', error);
            },
          );
      
      print('✅ Sincronización en tiempo real activada (sin familyId específico)');
      
      // Cargar datos iniciales inmediatamente
      print('🔍 Cargando datos iniciales...');
      await _loadInitialData();
      
    } catch (e) {
      print('❌ Error inicializando sincronización: $e');
      _handleInitializationError(e);
    }
  }

  // Manejar errores de suscripción
  void _handleSubscriptionError(String subscriptionType, dynamic error) {
    print('❌ Error en suscripción $subscriptionType: $error');
    
    // Si es un error de timeout o conexión, intentar reconectar
    if (error.toString().contains('timeout') || 
        error.toString().contains('connection') ||
        error.toString().contains('network')) {
      print('🔄 Error de conexión detectado, programando reconexión...');
      _scheduleReconnection();
      
      // Para iOS, cargar datos de muestra si Firebase falla
      if (kIsWeb && _isLikelyIOS()) {
        print('📱 iOS detectado, cargando datos de muestra como fallback...');
        _loadFallbackDataForIOS();
      }
    }
  }
  
  // Detectar si es probable que sea iOS
  bool _isLikelyIOS() {
    if (!kIsWeb) return false;
    
    // Intentar detectar iOS usando JavaScript interop
    try {
      // Solo usar polling si realmente hay problemas de conectividad
      // No asumir iOS por defecto
      return false; // Deshabilitado temporalmente para evitar polling innecesario
    } catch (e) {
      print('⚠️ Error detectando iOS: $e');
      return false;
    }
  }

  // Inicializar con modo polling para iOS
  Future<void> _initializeWithPolling() async {
    print('📱 Iniciando modo polling para iOS...');
    
    try {
      // Activar modo polling
      _isPollingMode = true;
      
      // Cargar datos inmediatamente
      await _pollData();
      
      // Programar polling periódico solo si es necesario
      _pollingTimer = Timer.periodic(_pollingInterval, (_) {
        // Solo hacer polling si no hay datos, si hay errores de conectividad, o si los datos están obsoletos
        if (_shouldRefreshData()) {
          print('📱 Polling periódico: datos obsoletos o faltantes, actualizando...');
          _pollData();
        } else {
          print('📱 Polling periódico: datos actualizados, saltando...');
        }
      });
      
      print('✅ Modo polling iniciado para iOS');
      
    } catch (e) {
      print('❌ Error iniciando modo polling: $e');
      // Fallback a datos de muestra
      _loadFallbackDataForIOS();
    }
  }
  
          // Cargar datos de muestra para iOS
          void _loadFallbackDataForIOS() {
            print('📱 Cargando datos de muestra para iOS...');
            
            // Cargar datos de muestra más robustos
            _events.clear();
            _dayCategories.clear();
            _notes.clear();
            _shifts.clear();
            _shiftTemplates.clear();
            
            // Agregar datos de ejemplo más realistas para iOS
            final today = DateTime.now();
            final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
            
            // Datos para hoy
            _events[todayKey] = ['Reunión familiar', 'Cumpleaños de María'];
            _shifts[todayKey] = ['D1', 'N1'];
            _notes[todayKey] = ['Recordar comprar regalo', 'Llamar al médico'];
            
            // Datos para mañana
            final tomorrow = today.add(const Duration(days: 1));
            final tomorrowKey = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
            _events[tomorrowKey] = ['Cita médica', 'Entrenamiento'];
            _shifts[tomorrowKey] = ['D2'];
            _notes[tomorrowKey] = ['Preparar documentos'];
            
            // Datos para pasado mañana
            final dayAfter = today.add(const Duration(days: 2));
            final dayAfterKey = '${dayAfter.year}-${dayAfter.month.toString().padLeft(2, '0')}-${dayAfter.day.toString().padLeft(2, '0')}';
            _events[dayAfterKey] = ['Viaje de trabajo'];
            _shifts[dayAfterKey] = ['D1', 'D2'];
            _notes[dayAfterKey] = ['Hacer maleta'];
            
            // Agregar plantillas de turnos de ejemplo
            final template1 = ShiftTemplate(
              id: 'ios-fallback-template-1',
              name: 'D1',
              description: 'Turno de día 1',
              startTime: '08:00',
              endTime: '16:00',
              colorHex: '#2196F3',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            final template2 = ShiftTemplate(
              id: 'ios-fallback-template-2',
              name: 'D2',
              description: 'Turno de día 2',
              startTime: '16:00',
              endTime: '00:00',
              colorHex: '#FF9800',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            final template3 = ShiftTemplate(
              id: 'ios-fallback-template-3',
              name: 'N1',
              description: 'Turno de noche 1',
              startTime: '00:00',
              endTime: '08:00',
              colorHex: '#9C27B0',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            _shiftTemplates[0] = template1;
            _shiftTemplates[1] = template2;
            _shiftTemplates[2] = template3;
            
            print('✅ Datos de fallback para iOS cargados correctamente');
            
            // Forzar actualización de UI en iOS
            if (kIsWeb) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                notifyListeners();
              });
            } else {
              notifyListeners();
            }
          }
  
          // Iniciar modo polling para iOS
          void _startPollingMode() {
            print('📱 Iniciando modo polling para iOS...');
            _isPollingMode = true;
            _pollingTimer?.cancel();
            
            // Cargar datos inmediatamente
            _pollData();
            
            // Programar polling periódico solo si no hay datos
            _pollingTimer = Timer.periodic(_pollingInterval, (_) {
              // Solo hacer polling si no hay datos o si hay errores
              if (_events.isEmpty && _shifts.isEmpty && _notes.isEmpty) {
                print('📱 Polling periódico: sin datos, intentando cargar...');
                _pollData();
              } else {
                print('📱 Polling periódico: datos disponibles, saltando...');
              }
            });
          }
  
          // Detener modo polling
          void _stopPollingMode() {
            print('📱 Deteniendo modo polling...');
            _isPollingMode = false;
            _pollingTimer?.cancel();
          }
          
          // Iniciar sincronización limitada para iOS
          void _startLimitedSyncForIOS() {
            print('📱 Iniciando sincronización limitada para iOS...');
            print('📱 FamilyId para sincronización: $_userFamilyId');
            
            // Sincronizar datos una sola vez después de 3 segundos
            Timer(const Duration(seconds: 3), () async {
              try {
                print('📱 Sincronizando datos de Firebase para iOS...');
                print('📱 FamilyId actual: $_userFamilyId');
                
                // Obtener eventos
                print('📱 Consultando eventos para familyId: $_userFamilyId');
                final eventsQuery = await _firestore
                    .collection('events')
                    // Sin filtro familyId
                    .limit(50) // Limitar a 50 eventos
                    .get();
                print('📱 Eventos encontrados: ${eventsQuery.docs.length}');
                
                // Obtener turnos
                print('📱 Consultando turnos para familyId: $_userFamilyId');
                final shiftsQuery = await _firestore
                    .collection('shifts')
                    // Sin filtro familyId
                    .limit(50) // Limitar a 50 turnos
                    .get();
                print('📱 Turnos encontrados: ${shiftsQuery.docs.length}');
                
                // Obtener notas
                print('📱 Consultando notas para familyId: $_userFamilyId');
                final notesQuery = await _firestore
                    .collection('notes')
                    // Sin filtro familyId
                    .limit(50) // Limitar a 50 notas
                    .get();
                print('📱 Notas encontradas: ${notesQuery.docs.length}');
                
                // Obtener plantillas
                print('📱 Consultando plantillas para familyId: $_userFamilyId');
                final templatesQuery = await _firestore
                    .collection('shift_templates')
                    // Sin filtro familyId
                    .limit(20) // Limitar a 20 plantillas
                    .get();
                print('📱 Plantillas encontradas: ${templatesQuery.docs.length}');
                
                // Procesar datos obtenidos
                print('📱 Procesando eventos...');
                _processPolledEvents(eventsQuery.docs);
                print('📱 Procesando turnos...');
                _processPolledShifts(shiftsQuery.docs);
                print('📱 Procesando notas...');
                _processPolledNotes(notesQuery.docs);
                print('📱 Procesando plantillas...');
                _processPolledTemplates(templatesQuery.docs);
                
                print('✅ Sincronización limitada completada para iOS');
                print('📱 Datos finales - Eventos: ${_events.length}, Turnos: ${_shifts.length}, Notas: ${_notes.length}, Plantillas: ${_shiftTemplates.length}');
                
                // Forzar actualización de UI
                if (kIsWeb) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    notifyListeners();
                  });
                } else {
                  notifyListeners();
                }
                
              } catch (e) {
                print('❌ Error en sincronización limitada para iOS: $e');
                // Mantener datos de fallback si falla la sincronización
              }
            });
          }
  
  // Verificar si los datos necesitan ser actualizados
  bool _shouldRefreshData() {
    // Si no hay datos, necesitamos cargarlos
    if (_events.isEmpty && _shifts.isEmpty && _notes.isEmpty) {
      return true;
    }
    
    // Si no tenemos timestamp de última actualización, necesitamos cargar
    if (_lastDataUpdate == null) {
      return true;
    }
    
    // Si los datos son más antiguos que la duración de validez del caché, actualizar
    final now = DateTime.now();
    final timeSinceLastUpdate = now.difference(_lastDataUpdate!);
    
    return timeSinceLastUpdate > _cacheValidityDuration;
  }

  // Obtener datos mediante polling (get() en lugar de streams)
  Future<void> _pollData() async {
    try {
      print('📱 Polling datos para iOS...');
      
      // Obtener eventos
      final eventsQuery = await _firestore
          .collection('events')
          // Sin filtro familyId
          .get();
      
      // Obtener turnos
      final shiftsQuery = await _firestore
          .collection('shifts')
          // Sin filtro familyId
          .get();
      
      // Obtener notas
      final notesQuery = await _firestore
          .collection('notes')
          // Sin filtro familyId
          .get();
      
      // Obtener plantillas
      final templatesQuery = await _firestore
          .collection('shift_templates')
          // Sin filtro familyId
          .get();
      
      // Procesar datos obtenidos
      _processPolledEvents(eventsQuery.docs);
      _processPolledShifts(shiftsQuery.docs);
      _processPolledNotes(notesQuery.docs);
      _processPolledTemplates(templatesQuery.docs);
      
      // Marcar que los datos han sido actualizados
      _lastDataUpdate = DateTime.now();
      
      print('✅ Polling completado para iOS');
      
      // Forzar actualización de UI en iOS
      if (kIsWeb) {
        // Usar addPostFrameCallback para evitar bloqueos de UI
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      } else {
        notifyListeners();
      }
      
    } catch (e) {
      print('❌ Error en polling para iOS: $e');
      // En caso de error, cargar datos de fallback
      _loadFallbackDataForIOS();
    }
  }
  
  // Procesar eventos obtenidos por polling
  void _processPolledEvents(List<QueryDocumentSnapshot> docs) {
    _events.clear();
    final Map<String, Set<String>> tempEvents = {};
    
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateKey = (data['date'] != null) ? data['date'].toString() : '';
      final title = (data['title'] != null) ? data['title'].toString() : '';
      if (dateKey.isNotEmpty && title.isNotEmpty) {
        tempEvents.putIfAbsent(dateKey, () => {});
        tempEvents[dateKey]!.add(title);
      }
    }
    
    for (final entry in tempEvents.entries) {
      _events[entry.key] = entry.value.map((e) => e.toString()).toList();
    }
  }
  
          // Procesar turnos obtenidos por polling
          void _processPolledShifts(List<QueryDocumentSnapshot> docs) {
            print('📱 Procesando ${docs.length} turnos...');
            _shifts.clear();
            final Map<String, Set<String>> tempShifts = {};
            
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              print('📱 Turno raw data: $data');
              
              // Intentar diferentes campos para el nombre del turno
              String shiftName = '';
              if (data['title'] != null) {
                shiftName = data['title'].toString();
              } else if (data['shiftName'] != null) {
                shiftName = data['shiftName'].toString();
              } else if (data['name'] != null) {
                shiftName = data['name'].toString();
              }
              
              final dateKey = (data['date'] != null) ? data['date'].toString() : '';
              print('📱 Turno procesado - Fecha: $dateKey, Nombre: $shiftName');
              
              if (dateKey.isNotEmpty && shiftName.isNotEmpty) {
                tempShifts.putIfAbsent(dateKey, () => {});
                tempShifts[dateKey]!.add(shiftName);
              }
            }
            
            for (final entry in tempShifts.entries) {
              _shifts[entry.key] = entry.value.map((e) => e.toString()).toList();
            }
            
            print('📱 Turnos procesados: ${_shifts.length} fechas con turnos');
          }
  
  // Procesar notas obtenidas por polling
  void _processPolledNotes(List<QueryDocumentSnapshot> docs) {
    print('📱 Procesando ${docs.length} notas...');
    _notes.clear();
    final Map<String, Set<String>> tempNotes = {};
    
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      print('📱 Nota raw data: $data');
      
      final dateKey = (data['date'] != null) ? data['date'].toString() : '';
      
      // Intentar diferentes campos para el texto de la nota
      String noteText = '';
      if (data['title'] != null) {
        noteText = data['title'].toString();
      } else if (data['text'] != null) {
        noteText = data['text'].toString();
      } else if (data['noteText'] != null) {
        noteText = data['noteText'].toString();
      }
      
      print('📱 Nota procesada - Fecha: $dateKey, Texto: $noteText');
      
      if (dateKey.isNotEmpty && noteText.isNotEmpty) {
        tempNotes.putIfAbsent(dateKey, () => {});
        tempNotes[dateKey]!.add(noteText);
      }
    }
    
    for (final entry in tempNotes.entries) {
      _notes[entry.key] = entry.value.map((e) => e.toString()).toList();
    }
    
    print('📱 Notas procesadas: ${_notes.length} fechas con notas');
  }
  
  // Procesar plantillas obtenidas por polling
  void _processPolledTemplates(List<QueryDocumentSnapshot> docs) {
    _shiftTemplates.clear();
    
    for (int i = 0; i < docs.length; i++) {
      final doc = docs[i];
      try {
        final template = ShiftTemplate.fromJson(doc.data() as Map<String, dynamic>);
        _shiftTemplates[i] = template;
        print('📱 Plantilla cargada por polling: ${template.name} (ID: ${template.id})');
      } catch (e) {
        print('❌ Error procesando plantilla por polling: $e');
      }
    }
  }

  // Manejar errores de inicialización
  void _handleInitializationError(dynamic error) {
    print('❌ Error de inicialización: $error');
    
    // Cargar datos de ejemplo como fallback
    loadSampleData();
    
    // Programar reintento de inicialización
    _scheduleReconnection();
  }

  // Programar reconexión
  void _scheduleReconnection() {
    if (_reconnectionAttempts < _maxReconnectionAttempts) {
      _reconnectionAttempts++;
      print('🔄 Programando reconexión en ${_reconnectionDelay.inSeconds} segundos...');
      
      Timer(_reconnectionDelay, () {
        if (_isOnline && _userFamilyId != null) {
          print('🔄 Ejecutando reconexión programada...');
          _reinitializeSubscriptions();
        }
      });
    } else {
      print('❌ Máximo de intentos de reconexión alcanzado');
    }
  }

  // Cargar datos iniciales inmediatamente
  Future<void> _loadInitialData() async {
    print('🔍 CARGANDO DATOS INICIALES: sin familyId específico');
    
    try {
      // Consultar plantillas sin filtro de familyId
      final templatesQuery = await _firestore
          .collection('shift_templates')
          .get();
      
      print('🔍 CARGANDO DATOS: Encontradas ${templatesQuery.docs.length} plantillas');
      
      // Procesar plantillas iniciales
      _shiftTemplates.clear();
      for (final doc in templatesQuery.docs) {
        try {
          final data = doc.data();
          final template = ShiftTemplate.fromJson(data);
          _shiftTemplates.add(template);
          print('✅ Plantilla cargada: ${template.name}');
        } catch (e) {
          print('❌ Error procesando plantilla ${doc.id}: $e');
        }
      }
      
      _shiftTemplates.sort((a, b) => a.name.compareTo(b.name));
      _notifyChangesOptimized();
      
      print('✅ DATOS INICIALES CARGADOS: ${_shiftTemplates.length} plantillas');
      
      // También cargar eventos, turnos y notas
      await _loadInitialEvents();
      await _loadInitialShifts();
      await _loadInitialNotes();
      
    } catch (e) {
      print('❌ Error cargando datos iniciales: $e');
    }
  }

  Future<void> _loadInitialEvents() async {
    try {
      final eventsQuery = await _firestore
          .collection('events')
          // Sin filtro familyId
          .get();
      
      _events.clear();
      for (final doc in eventsQuery.docs) {
        final data = doc.data();
        final dateKey = data['date']?.toString() ?? '';
        final title = data['title']?.toString() ?? '';
        
        if (dateKey.isNotEmpty && title.isNotEmpty) {
          if (!_events.containsKey(dateKey)) {
            _events[dateKey] = <String>[];
          }
          _events[dateKey]!.add(title);
        }
      }
      print('✅ Eventos iniciales cargados: ${_events.length} fechas');
    } catch (e) {
      print('❌ Error cargando eventos iniciales: $e');
    }
  }

  Future<void> _loadInitialShifts() async {
    try {
      final shiftsQuery = await _firestore
          .collection('shifts')
          // Sin filtro familyId
          .get();
      
      _shifts.clear();
      for (final doc in shiftsQuery.docs) {
        final data = doc.data();
        final dateKey = data['date']?.toString() ?? '';
        final title = data['title']?.toString() ?? '';
        
        if (dateKey.isNotEmpty && title.isNotEmpty) {
          if (!_shifts.containsKey(dateKey)) {
            _shifts[dateKey] = <String>[];
          }
          _shifts[dateKey]!.add(title);
        }
      }
      print('✅ Turnos iniciales cargados: ${_shifts.length} fechas');
    } catch (e) {
      print('❌ Error cargando turnos iniciales: $e');
    }
  }

  Future<void> _loadInitialNotes() async {
    try {
      final notesQuery = await _firestore
          .collection('notes')
          // Sin filtro familyId
          .get();
      
      _notes.clear();
      for (final doc in notesQuery.docs) {
        final data = doc.data();
        final dateKey = data['date']?.toString() ?? '';
        final title = data['title']?.toString() ?? '';
        
        if (dateKey.isNotEmpty && title.isNotEmpty) {
          if (!_notes.containsKey(dateKey)) {
            _notes[dateKey] = <String>[];
          }
          _notes[dateKey]!.add(title);
        }
      }
      print('✅ Notas iniciales cargadas: ${_notes.length} fechas');
    } catch (e) {
      print('❌ Error cargando notas iniciales: $e');
    }
  }

  // Método de diagnóstico temporal
  Future<void> diagnosticInfo() async {
    print('🔍 === DIAGNÓSTICO COMPLETO ===');
    print('🔍 _userFamilyId: $_userFamilyId');
    print('🔍 _isOnline: $_isOnline');
    print('🔍 _shiftTemplates.length: ${_shiftTemplates.length}');
    print('🔍 _events.length: ${_events.length}');
    
    // Eliminado: verificación de usuario (ya no se utiliza)
    print('🔍 FamilyId fijo: $_userFamilyId (sin autenticación)');
    
    // Verificar conexión a Firebase
    try {
      final testQuery = await _firestore.collection('shift_templates').limit(1).get();
      print('🔍 Conexión Firebase OK: ${testQuery.docs.length} documentos de prueba');
    } catch (e) {
      print('🔍 Error conexión Firebase: $e');
    }
    
    // Consultar todos los documentos
    try {
      final allDocs = await _firestore.collection('shift_templates').get();
      print('🔍 Total documentos en shift_templates: ${allDocs.docs.length}');
      for (final doc in allDocs.docs) {
        final data = doc.data();
        print('🔍 Doc ${doc.id}: name=${data['name']}, familyId=${data['familyId']}');
      }
    } catch (e) {
      print('🔍 Error consultando todos los documentos: $e');
    }
    
    print('🔍 === FIN DIAGNÓSTICO ===');
  }

  // Método público para forzar actualización manual
  Future<void> forceRefresh() async {
    print('🔄 Forzando actualización manual de datos...');
    
    // Usar familyId fijo

    try {
      // Reinicializar suscripciones
      dispose();
      await initialize();
      
      print('✅ Actualización manual completada');
    } catch (e) {
      print('❌ Error en actualización manual: $e');
      // Intentar cargar datos estáticos como fallback
      if (kIsWeb && _isLikelyIOS()) {
        _loadFallbackDataForIOS();
      }
    }
  }

  // Método helper para notificar cambios de manera optimizada
  void _notifyChangesOptimized() {
    if (kIsWeb) {
      // En web, usar addPostFrameCallback para evitar bloqueos
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      // En móvil, notificar directamente
      notifyListeners();
    }
  }

  void _onEventsChanged(QuerySnapshot snapshot) {
    ErrorTracker.trackExecution(
      'on_events_changed',
      'Procesando cambios en eventos de Firebase',
      () {
        print('🔄 Eventos actualizados desde Firebase: ${snapshot.docs.length} documentos');
    
    _events.clear();
    
    final Map<String, Set<String>> tempEvents = {};
    
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateKey = data['date']?.toString() ?? '';
      final title = data['title']?.toString() ?? '';
      final eventType = data['eventType']?.toString() ?? '';
      final userId = (data['userId'] is int) ? data['userId'] as int : 1; // Default a userId 1
      
      if (dateKey.isNotEmpty && title.isNotEmpty) {
        if (!tempEvents.containsKey(dateKey)) {
          tempEvents[dateKey] = <String>{};
        }
        tempEvents[dateKey]!.add(title);
        
        // 🔹 Almacenar el userId del evento
        if (!_eventUserIds.containsKey(dateKey)) {
          _eventUserIds[dateKey] = {};
        }
        _eventUserIds[dateKey]![title] = userId;
        
        if (eventType.isNotEmpty) {
          print('📝 Evento cargado: $title ($eventType) en $dateKey (userId: $userId)');
        }
      }
    }
    
    for (final entry in tempEvents.entries) {
      _events[entry.key] = entry.value.map((e) => e.toString()).toList();
    }
    
        _notifyChangesOptimized();
        print('📊 Datos locales actualizados: $_events');
      },
    );
  }

  void _onNotesChanged(QuerySnapshot snapshot) {
    print('🔄 Notas actualizadas desde Firebase: ${snapshot.docs.length} documentos');
    
    if (snapshot.docs.isEmpty) {
      print('⚠️ No hay documentos en la colección de notas');
    }
    
    _notes.clear();
    
    final Map<String, Set<String>> tempNotes = {};
    
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateKey = data['date']?.toString() ?? '';
      final title = data['title']?.toString() ?? '';
      final userId = (data['userId'] is int) ? data['userId'] as int : 1; // Default a userId 1
      
      print('📄 Documento procesado: ID=${doc.id}, date=$dateKey, title=$title, userId=$userId');
      
      if (dateKey.isNotEmpty && title.isNotEmpty) {
        if (!tempNotes.containsKey(dateKey)) {
          tempNotes[dateKey] = <String>{};
        }
        tempNotes[dateKey]!.add(title);
        
        // 🔹 Almacenar el userId del evento
        if (!_eventUserIds.containsKey(dateKey)) {
          _eventUserIds[dateKey] = {};
        }
        _eventUserIds[dateKey]![title] = userId;
        
        print('📝 Nota cargada: $title en $dateKey (userId: $userId)');
      } else {
        print('⚠️ Documento con datos incompletos: date=$dateKey, title=$title');
      }
    }
    
    for (final entry in tempNotes.entries) {
      _notes[entry.key] = entry.value.map((e) => e.toString()).toList();
    }
    
    _notifyChangesOptimized();
    print('📊 Notas locales actualizadas: $_notes');
    print('📊 Total de fechas con notas: ${_notes.length}');
  }

  void _onShiftsChanged(QuerySnapshot snapshot) {
    print('🔄 Turnos actualizados desde Firebase: ${snapshot.docs.length} documentos');
    
    if (snapshot.docs.isEmpty) {
      print('⚠️ No hay documentos en la colección de turnos');
    }
    
    _shifts.clear();
    
    final Map<String, Set<String>> tempShifts = {};
    
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateKey = data['date']?.toString() ?? '';
      final title = data['title']?.toString() ?? '';
      final userId = (data['userId'] is int) ? data['userId'] as int : 1; // Default a userId 1
      
      print('📄 Documento de turno procesado: ID=${doc.id}, date=$dateKey, title=$title, userId=$userId');
      
      if (dateKey.isNotEmpty && title.isNotEmpty) {
        if (!tempShifts.containsKey(dateKey)) {
          tempShifts[dateKey] = <String>{};
        }
        tempShifts[dateKey]!.add(title);
        
        // 🔹 Almacenar el userId del evento
        if (!_eventUserIds.containsKey(dateKey)) {
          _eventUserIds[dateKey] = {};
        }
        _eventUserIds[dateKey]![title] = userId;
        
        print('🔄 Turno cargado: $title en $dateKey (userId: $userId)');
      } else {
        print('⚠️ Documento de turno con datos incompletos: date=$dateKey, title=$title');
      }
    }
    
    for (final entry in tempShifts.entries) {
      _shifts[entry.key] = entry.value.map((e) => e.toString()).toList();
    }
    
    _notifyChangesOptimized();
    print('📊 Turnos locales actualizados: $_shifts');
    print('📊 Total de fechas con turnos: ${_shifts.length}');
  }

  void _onCategoriesChanged(QuerySnapshot snapshot) {
    print('🔄 Categorías actualizadas desde Firebase: ${snapshot.docs.length} documentos');
    
    _dayCategories.clear();
    
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateKey = data['date']?.toString() ?? '';
      final categories = data['categories'] as Map<String, dynamic>? ?? {};
      
      if (dateKey.isNotEmpty) {
        _dayCategories[dateKey] = Map<String, String?>.from(categories);
      }
    }
    
    _notifyChangesOptimized();
    print('📊 Categorías locales actualizadas: $_dayCategories');
  }

  void _onShiftTemplatesChanged(QuerySnapshot snapshot) {
    print('🔄 Plantillas de turnos actualizadas desde Firebase: ${snapshot.docs.length} documentos');
    print('🔧 IDs de documentos recibidos: ${snapshot.docs.map((doc) => doc.id).toList()}');
    
    // Limpiar lista actual
    _shiftTemplates.clear();
    print('🔧 Lista local limpiada, agregando ${snapshot.docs.length} plantillas...');
    
    // Procesar cada documento
    for (final doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        print('🔧 Procesando documento ${doc.id}: ${data['name']}');
        
        // Cargar todas las plantillas independientemente del familyId (sin autenticación)
        final docFamilyId = data['familyId']?.toString();
        print('🔧 Procesando documento ${doc.id}: familyId = $docFamilyId (cargando todas las plantillas)');
        
        final template = ShiftTemplate.fromJson(data);
        _shiftTemplates.add(template);
        
        print('✅ Plantilla cargada: ${template.name} (ID: ${template.id})');
      } catch (e) {
        print('❌ Error cargando plantilla: $e');
        print('🔧 Documento problemático: ${doc.data()}');
      }
    }
    
    // Ordenar plantillas por nombre para consistencia
    _shiftTemplates.sort((a, b) => a.name.compareTo(b.name));
    
    // Notificar cambios inmediatamente
    _notifyChangesOptimized();
    print('📊 Plantillas de turnos locales actualizadas: ${_shiftTemplates.length} plantillas');
    print('🔧 IDs finales en lista local: ${_shiftTemplates.map((t) => '${t.name}(${t.id})').toList()}');
  }
   
  // ===== EVENTOS =====

  bool isPredefinedShift(String eventTitle) {
    return _shiftTemplates.any((template) => template.name == eventTitle);
  }
   
  Map<String, List<String>> getShifts() {
    // Usar la nueva caché de turnos
    return Map.from(_shifts);
  }
   
  Map<String, List<String>> getNotes() {
    // Usar la nueva caché de notas
    return Map.from(_notes);
  }

  // Método para añadir NOTAS (colección separada)
  Future<void> addNote({
    required DateTime date,
    required String title,
    String? noteId,
    String? description,
    String? category,
  }) async {
    print('🔧 addNote iniciado');
    print('🔧 date: $date');
    print('🔧 title: $title');
    print('🔧 noteId: $noteId');
    
    final dateKey = _formatDate(date);
    // Obtener el userId del usuario actual
    final currentUserId = _ref.read(currentUserIdProvider);
    print('🔧 Usuario actual: $currentUserId');
    
    try {
      final docRef = noteId != null ? _firestore.collection('notes').doc(noteId) : _firestore.collection('notes').doc();
      final finalNoteId = noteId ?? docRef.id;
      
      final noteData = {
        'id': finalNoteId,
        'title': title,
        'date': dateKey,
        'description': description ?? '',
        'category': category ?? '',
        'eventType': 'nota',
        'familyId': 'default_family',
        'userId': currentUserId, // 🔹 Guardar el ID del usuario creador
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      print('🔧 Guardando nota en Firestore con ID: $finalNoteId y userId: $currentUserId');
      await docRef.set(noteData, SetOptions(merge: true));
      
      // Actualizar caché local de notas
      if (!_notes.containsKey(dateKey)) {
        _notes[dateKey] = <String>[];
      }
      if (!_notes[dateKey]!.contains(title)) {
        _notes[dateKey]!.add(title);
        notifyListeners();
      }
      
      // 🔹 Actualizar caché de userIds
      if (!_eventUserIds.containsKey(dateKey)) {
        _eventUserIds[dateKey] = {};
      }
      _eventUserIds[dateKey]![title] = currentUserId;
      
      print('✅ Nota agregada exitosamente: $title en $dateKey con ID $finalNoteId');
    } catch (e) {
      print('❌ Error agregando nota: $e');
      // Fallback local
      if (!_notes.containsKey(dateKey)) {
        _notes[dateKey] = <String>[];
      }
      if (!_notes[dateKey]!.contains(title)) {
        _notes[dateKey]!.add(title);
        notifyListeners();
      }
      print('✅ Nota guardada localmente como fallback: $title en $dateKey');
    }
  }

  // Método para añadir TURNOS (colección separada)
  Future<void> addShift({
    required DateTime date,
    required String title,
    String? shiftId,
    String? description,
    String? category,
    String? color,
  }) async {
    print('🔧 addShift iniciado');
    print('🔧 date: $date');
    print('🔧 title: $title');
    print('🔧 shiftId: $shiftId');
    
    final dateKey = _formatDate(date);
    // Obtener el userId del usuario actual
    final currentUserId = _ref.read(currentUserIdProvider);
    print('🔧 Usuario actual: $currentUserId');

    String eventColor = color ?? '';
    final template = getShiftTemplateByName(title);
    if (template != null) {
      eventColor = template.colorHex;
      print('🔧 Color de plantilla encontrado: $eventColor');
    }
    
    try {
      final docRef = shiftId != null ? _firestore.collection('shifts').doc(shiftId) : _firestore.collection('shifts').doc();
      final finalShiftId = shiftId ?? docRef.id;
      
      final shiftData = {
        'id': finalShiftId,
        'title': title,
        'date': dateKey,
        'description': description ?? '',
        'category': category ?? '',
        'color': eventColor,
        'eventType': 'turno',
        'familyId': 'default_family',
        'userId': currentUserId, // 🔹 Guardar el ID del usuario creador
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      print('🔧 Guardando turno en Firestore con ID: $finalShiftId y userId: $currentUserId');
      await docRef.set(shiftData, SetOptions(merge: true));
      
      // Actualizar caché local de turnos
      if (!_shifts.containsKey(dateKey)) {
        _shifts[dateKey] = <String>[];
      }
      if (!_shifts[dateKey]!.contains(title)) {
        _shifts[dateKey]!.add(title);
        notifyListeners();
      }
      
      // 🔹 Actualizar caché de userIds
      if (!_eventUserIds.containsKey(dateKey)) {
        _eventUserIds[dateKey] = {};
      }
      _eventUserIds[dateKey]![title] = currentUserId;
      
      print('✅ Turno agregado exitosamente: $title en $dateKey con ID $finalShiftId');
    } catch (e) {
      print('❌ Error agregando turno: $e');
      // Fallback local
      if (!_shifts.containsKey(dateKey)) {
        _shifts[dateKey] = <String>[];
      }
      if (!_shifts[dateKey]!.contains(title)) {
        _shifts[dateKey]!.add(title);
        notifyListeners();
      }
      print('✅ Turno guardado localmente como fallback: $title en $dateKey');
    }
  }

  // Método para obtener el ID de una nota existente
  Future<String?> getExistingNoteId(DateTime date) async {
    try {
      final dateKey = _formatDate(date);
      final snapshot = await _firestore
          .collection('notes')
          .where('date', isEqualTo: dateKey)
          // Sin filtro familyId
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo ID de nota existente: $e');
      return null;
    }
  }

  // Método para actualizar una nota existente
  Future<void> updateNote({
    required String noteId,
    required DateTime date,
    required String title,
    String? description,
    String? category,
  }) async {
    print('🔧 updateNote iniciado para ID: $noteId');
    
    final dateKey = _formatDate(date);
    // Eliminado: obtención de ownerId desde authController (ya no se utiliza)
    final currentOwnerId = 'default_user'; // Usuario fijo sin autenticación
    
    try {
      await _firestore.collection('notes').doc(noteId).update({
        'title': title,
        'date': dateKey,
        'description': description ?? '',
        'category': category ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Actualizar caché local
      if (!_notes.containsKey(dateKey)) {
        _notes[dateKey] = <String>[];
      }
      // Reemplazar la nota existente
      _notes[dateKey]!.clear();
      _notes[dateKey]!.add(title);
      notifyListeners();
      
      print('✅ Nota actualizada exitosamente: $title en $dateKey');
    } catch (e) {
      print('❌ Error actualizando nota: $e');
      // Fallback local
      if (!_notes.containsKey(dateKey)) {
        _notes[dateKey] = <String>[];
      }
      _notes[dateKey]!.clear();
      _notes[dateKey]!.add(title);
      notifyListeners();
      print('✅ Nota actualizada localmente como fallback: $title en $dateKey');
    }
  }

  // Método para eliminar una nota
  Future<void> deleteNote({
    required String noteId,
    required DateTime date,
  }) async {
    print('🔧 deleteNote iniciado para ID: $noteId');
    
    final dateKey = _formatDate(date);
    // Eliminado: obtención de ownerId desde authController (ya no se utiliza)
    final currentOwnerId = 'default_user'; // Usuario fijo sin autenticación
    
    try {
      await _firestore.collection('notes').doc(noteId).delete();
      
      // Actualizar caché local
      if (_notes.containsKey(dateKey)) {
        _notes[dateKey]!.clear();
        notifyListeners();
      }
      
      print('✅ Nota eliminada exitosamente: $noteId en $dateKey');
    } catch (e) {
      print('❌ Error eliminando nota: $e');
      // Fallback local
      if (_notes.containsKey(dateKey)) {
        _notes[dateKey]!.clear();
        notifyListeners();
      }
      print('✅ Nota eliminada localmente como fallback: $noteId en $dateKey');
    }
  }

  // Método legacy para compatibilidad (mantiene la colección 'events')
  Future<void> addEvent({
    required DateTime date,
    required String title,
    String? eventId,
    String? description,
    String? category,
    String? color,
  }) async {
    // Redirigir a los métodos específicos
    final isShift = isPredefinedShift(title);
    if (isShift) {
      await addShift(
        date: date,
        title: title,
        shiftId: eventId,
        description: description,
        category: category,
        color: color,
      );
    } else {
      await addNote(
        date: date,
        title: title,
        noteId: eventId,
        description: description,
        category: category,
      );
    }
  }

  Future<void> updateEvent({
    required String eventId,
    required DateTime date,
    required String title,
    String? description,
    String? category,
    String? color,
  }) async {
    print('🔧 updateEvent iniciado para ID: $eventId');
    print('🔧 date: $date, title: $title');
    // Usar familyId fijo
    final dateKey = _formatDate(date);
    // Eliminado: obtención de ownerId desde authController (ya no se utiliza)
    final currentOwnerId = 'default_user'; // Usuario fijo sin autenticación
    
    final isShift = isPredefinedShift(title);
    String eventColor = color ?? '';

    if (isShift) {
      final template = getShiftTemplateByName(title);
      if (template != null) {
        eventColor = template.colorHex;
      }
    }

    try {
      final currentDoc = await _firestore.collection('events').doc(eventId).get();
      final oldTitle = (currentDoc.data()?['title'] ?? '') as String;

      await _firestore.collection('events').doc(eventId).update({
        'title': title,
        'date': dateKey,
        'description': description ?? '',
        'category': category ?? '',
        'color': eventColor,
        'ownerId': currentOwnerId, // Asegurarse de que ownerId esté actualizado
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Actualizar la caché local después de la actualización de Firebase
      if (_events.containsKey(dateKey)) {
        _events[dateKey]!.removeWhere((element) => element == oldTitle);
        if (!_events[dateKey]!.contains(title)) {
          _events[dateKey]!.add(title);
        }
        notifyListeners();
      }

      print('✅ Evento actualizado y sincronizado: $title en $dateKey con ID $eventId');
    } catch (e) {
      print('❌ Error actualizando evento: $e');
    }
  }

  Future<void> deleteEvent(String eventId, DateTime date) async {
    // Usar familyId fijo
    try {
      await _firestore.collection('events').doc(eventId).delete();
      print('✅ Evento eliminado y sincronizado: $eventId');
    } catch (e) {
      print('❌ Error eliminando evento: $e');
    }
  }

  Future<void> deleteAllEventsForDay(DateTime date) async {
    // Usar familyId fijo
    final dateKey = _formatDate(date);
    
    try {
      final batch = _firestore.batch();
      
      // Eliminar de la colección 'events' (legacy)
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('date', isEqualTo: dateKey)
          // Sin filtro familyId
          .get();
      
      for (final doc in eventsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Eliminar de la colección 'notes'
      final notesSnapshot = await _firestore
          .collection('notes')
          .where('date', isEqualTo: dateKey)
          // Sin filtro familyId
          .get();
      
      for (final doc in notesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Eliminar de la colección 'shifts'
      final shiftsSnapshot = await _firestore
          .collection('shifts')
          .where('date', isEqualTo: dateKey)
          // Sin filtro familyId
          .get();
      
      for (final doc in shiftsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Eliminar categorías del día
      await _firestore
          .collection('dayCategories')
          .doc(dateKey)
          .delete();
      
      print('✅ Todos los eventos, notas y turnos eliminados para $dateKey de familyId: $_userFamilyId');
    } catch (e) {
      print('❌ Error eliminando eventos: $e');
    }
  }
     
  List<String> getEventsForDay(DateTime date) {
    final dateKey = _formatDate(date);
    final notes = _notes[dateKey] ?? [];
    final shifts = _shifts[dateKey] ?? [];
    final legacyEvents = _events[dateKey] ?? []; // Para compatibilidad
    
    // Debug logging
    if (kIsWeb) {
      print('🔍 getEventsForDay($dateKey):');
      print('   - Notas: $notes');
      print('   - Turnos: $shifts');
      print('   - Eventos legacy: $legacyEvents');
      print('   - Total _notes: ${_notes.length} fechas');
      print('   - Total _shifts: ${_shifts.length} fechas');
      print('   - Total _events: ${_events.length} fechas');
    }
    
    // Combinar todos los eventos (notas + turnos + legacy)
    final allEvents = <String>{};
    allEvents.addAll(notes);
    allEvents.addAll(shifts);
    allEvents.addAll(legacyEvents);
    
    final result = allEvents.toList();
    if (kIsWeb) {
      print('   - Resultado final: $result');
    }
    
    return result;
  }

  // ===== PLANTILLAS DE TURNOS =====

  Future<void> addShiftTemplate(ShiftTemplate template) async {
    print('🔧 addShiftTemplate iniciado');
    print('🔧 template: ${template.name}');
    print('🔧 _userFamilyId: $_userFamilyId');
    
    try {
      final docRef = _firestore.collection('shift_templates').doc();
      final newTemplate = template.copyWith(
        id: docRef.id, 
        createdAt: DateTime.now(), 
        updatedAt: DateTime.now()
      );
      
      final templateData = {
        ...newTemplate.toJson(),
        'familyId': 'default_family',
      };
      
      print('🔧 Guardando plantilla en Firestore: ${newTemplate.name}');
      await docRef.set(templateData);
      
      print('✅ Plantilla de turno agregada exitosamente: ${newTemplate.name}');
      print('🔧 La suscripción en tiempo real actualizará la lista automáticamente');
    } catch (e) {
      print('❌ Error agregando plantilla de turno: $e');
      final localTemplate = template.copyWith(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _shiftTemplates.add(localTemplate);
      notifyListeners();
      print('✅ Plantilla guardada localmente como fallback: ${localTemplate.name}');
    }
  }

  Future<void> updateShiftTemplate(ShiftTemplate template) async {
    // Usar familyId fijo
    try {
      await _firestore.collection('shift_templates').doc(template.id).update({
        ...template.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Plantilla de turno actualizada: ${template.name}');
    } catch (e) {
      print('❌ Error actualizando plantilla de turno: $e');
    }
  }

  Future<void> deleteShiftTemplate(String templateId) async {
    // Usar familyId fijo
    try {
      print('🗑️ Iniciando eliminación de plantilla: $templateId');
      
      // Obtener el nombre de la plantilla antes de eliminarla
      final template = getShiftTemplateById(templateId);
      final templateName = template?.name;
      
      print('📝 Nombre de plantilla a eliminar: $templateName');
      
      // Eliminar la plantilla de Firestore
      await _firestore.collection('shift_templates').doc(templateId).delete();
      print('✅ Plantilla de turno eliminada de Firestore: $templateId');
      
      // Actualizar caché local - remover la plantilla
      _shiftTemplates.removeWhere((template) => template.id == templateId);
      notifyListeners();
      print('✅ Plantilla removida del caché local');
      
      // Si tenemos el nombre de la plantilla, limpiar turnos huérfanos AUTOMÁTICAMENTE
      if (templateName != null) {
        print('🧹 Iniciando limpieza automática de turnos huérfanos para: $templateName');
        await _cleanupOrphanedShifts(templateName);
      } else {
        print('⚠️ No se pudo obtener el nombre de la plantilla para limpieza');
      }
    } catch (e) {
      print('❌ Error eliminando plantilla de turno: $e');
    }
  }

  // Limpiar turnos huérfanos cuando se elimina una plantilla
  Future<void> _cleanupOrphanedShifts(String templateName) async {
    try {
      print('🧹 Limpiando turnos huérfanos para: $templateName');
      print('👥 FamilyId actual: $_userFamilyId');
      
      // Buscar todos los turnos de esta plantilla en Firestore
      final shiftsSnapshot = await _firestore
          .collection('shifts')
          // Sin filtro familyId
          .where('title', isEqualTo: templateName)
          .get();
      
      print('🔍 Consulta realizada. Documentos encontrados: ${shiftsSnapshot.docs.length}');
      
      if (shiftsSnapshot.docs.isNotEmpty) {
        print('🗑️ Encontrados ${shiftsSnapshot.docs.length} turnos huérfanos para eliminar');
        
        // Mostrar detalles de los turnos que se van a eliminar
        for (final doc in shiftsSnapshot.docs) {
          print('   - Eliminando turno: ${doc.id} (${doc.data()['title']})');
        }
        
        // Eliminar en lotes
        final batch = _firestore.batch();
        for (final doc in shiftsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print('✅ Turnos eliminados de Firestore exitosamente');
        
        // Limpiar caché local
        final keysToUpdate = <String>[];
        for (final entry in _shifts.entries) {
          if (entry.value.contains(templateName)) {
            print('   - Limpiando fecha local: ${entry.key}');
            entry.value.remove(templateName);
            keysToUpdate.add(entry.key);
          }
        }
        
        // Notificar cambios
        if (keysToUpdate.isNotEmpty) {
          notifyListeners();
          print('✅ Caché local limpiado para ${keysToUpdate.length} fechas');
          print('📱 UI actualizada - notificando listeners');
        }
        
        print('✅ Limpieza automática de turnos huérfanos completada');
      } else {
        print('ℹ️ No se encontraron turnos huérfanos para limpiar');
      }
    } catch (e) {
      print('❌ Error limpiando turnos huérfanos: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  ShiftTemplate? getShiftTemplateById(String id) {
    return _shiftTemplates.firstWhereOrNull((template) => template.id == id);
  }

  ShiftTemplate? getShiftTemplateByName(String name) {
    return _shiftTemplates.firstWhereOrNull((template) => template.name == name);
  }
   
  // ===== CATEGORÍAS POR DÍA =====

  Future<void> setDayCategory(DateTime date, String categoryKey, String? category) async {
    // Usar familyId fijo
    final dateKey = _formatDate(date);
    
    try {
      await _firestore.collection('dayCategories').doc(dateKey).set({
        'date': dateKey,
        'familyId': _userFamilyId,
        'categories': {
          categoryKey: category,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ Categoría sincronizada: $categoryKey = $category para $dateKey en familyId: $_userFamilyId');
    } catch (e) {
      print('❌ Error guardando categoría: $e');
      if (!_dayCategories.containsKey(dateKey)) {
        _dayCategories[dateKey] = <String, String?>{};
      }
      _dayCategories[dateKey]![categoryKey] = category;
      notifyListeners();
    }
  }

  Map<String, String?> getDayCategories(DateTime date) {
    final dateKey = _formatDate(date);
    return _dayCategories[dateKey] ?? {};
  }

  // Método para obtener categorías por día específico (mantiene compatibilidad)
  Map<String, String?> getDayCategoriesForDate(DateTime date) {
    final dateKey = _formatDate(date);
    return _dayCategories[dateKey] ?? {
      'category1': null,
      'category2': null,
      'category3': null,
    };
  }

  // ===== ESTADÍSTICAS =====

  Future<Map<String, dynamic>> getMonthStatistics(DateTime month) async {
    // Usar familyId fijo
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    
    final stats = <String, int>{};
    int totalEvents = 0;
    int daysWithEvents = 0;
    final daysWithEventsSet = <int>{};
    
    for (final entry in _events.entries) {
      final dateKey = entry.key;
      final eventsList = entry.value;
      
      try {
        final parts = dateKey.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          final eventDate = DateTime(year, month, day);
          
          if (eventDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) && 
              eventDate.isBefore(endOfMonth.add(const Duration(days: 1)))) {
            
            daysWithEventsSet.add(day);
            
            for (final event in eventsList) {
              totalEvents++;
              stats[event] = (stats[event] ?? 0) + 1;
            }
          }
        }
      } catch (e) {
        // Ignorar fechas mal formateadas
      }
    }
    
    daysWithEvents = daysWithEventsSet.length;
    
    return {
      'totalEvents': totalEvents,
      'categories': stats,
      'daysWithEvents': daysWithEvents,
    };
  }

  // ===== UTILIDADES =====

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void loadSampleData() {
    _events.clear();
    _dayCategories.clear();
    _shiftTemplates.clear();

    // Usar familyId fijo

    _events['2025-10-12'] = <String>['D1'];
    _events['2025-10-15'] = <String>['D2', 'T'];
    _events['2025-10-18'] = <String>['Libre'];
    _events['2025-10-20'] = <String>['Mañana'];
    _events['2025-10-25'] = <String>['Noche'];
    _events['2025-10-28'] = <String>['D1', 'Tarde'];
    
    _dayCategories['2025-10-12'] = {
      'category1': 'Cambio de turno',
      'category2': 'Ingreso',
    };
    _dayCategories['2025-10-15'] = {
      'category1': 'Importante',
    };
    
    if (_shiftTemplates.isEmpty) {
      _shiftTemplates.addAll([
        ShiftTemplate(id: '1', name: 'D1', colorHex: '#FF0000', startTime: '08:00', endTime: '16:00'),
        ShiftTemplate(id: '2', name: 'D2', colorHex: '#00FF00', startTime: '08:00', endTime: '16:00'),
        ShiftTemplate(id: '3', name: 'Libre', colorHex: '#0000FF', startTime: '00:00', endTime: '00:00'),
        ShiftTemplate(id: '4', name: 'Tarde', colorHex: '#FFFF00', startTime: '16:00', endTime: '00:00'),
        ShiftTemplate(id: '5', name: 'Mañana', colorHex: '#FF00FF', startTime: '08:00', endTime: '16:00'),
        ShiftTemplate(id: '6', name: 'Noche', colorHex: '#00FFFF', startTime: '00:00', endTime: '08:00'),
      ]);
    }
    
    notifyListeners();
    print('📝 Datos de ejemplo cargados para familyId: $_userFamilyId');
  }

  void clearDayEvents(DateTime date) {
    final dateKey = _formatDate(date);
    _events.remove(dateKey);
    _notes.remove(dateKey);
    _shifts.remove(dateKey);
    _dayCategories.remove(dateKey);
    _eventUserIds.remove(dateKey); // 🔹 Limpiar también userIds
    notifyListeners();
    print('🗑️ Eventos, notas y turnos limpiados localmente para: $dateKey');
  }

  /// 🔹 Obtener el userId del creador de un evento específico
  int getUserIdForEvent(DateTime date, String eventTitle) {
    final dateKey = _formatDate(date);
    final cachedUserId = _eventUserIds[dateKey]?[eventTitle];
    
    if (cachedUserId != null) {
      return cachedUserId; // Usar el userId guardado
    }
    
    // 🔹 Si no hay userId guardado, asignar automáticamente basado en el título
    // Esto es para eventos creados antes de nuestros cambios
    int assignedUserId = _assignUserIdToLegacyEvent(eventTitle);
    
    // Guardar en caché para futuras consultas
    if (!_eventUserIds.containsKey(dateKey)) {
      _eventUserIds[dateKey] = {};
    }
    _eventUserIds[dateKey]![eventTitle] = assignedUserId;
    
    print('⚠️ Evento "$eventTitle" sin userId guardado, asignado automáticamente: $assignedUserId');
    return assignedUserId;
  }
  
  /// 🔹 Asignar userId a eventos legacy basado en patrones del título
  int _assignUserIdToLegacyEvent(String eventTitle) {
    final title = eventTitle.toLowerCase();
    
    // 🔹 Caso especial: "Pedro Juan" - asignar a Pedro (primera palabra)
    if (title == 'pedro juan') {
      return 3; // Pedro
    }
    
    // Patrones para asignar usuarios específicos
    if (title.contains('pedro') || title.contains('prueba')) {
      return 3; // Pedro
    }
    if (title.contains('maría') || title.contains('maria')) {
      return 2; // María
    }
    if (title.contains('juan')) {
      return 1; // Juan
    }
    if (title.contains('lucía') || title.contains('lucia')) {
      return 4; // Lucía
    }
    if (title.contains('ana')) {
      return 5; // Ana
    }
    
    // Si no hay patrón, usar el usuario actual
    return _ref.read(currentUserIdProvider);
  }

  Future<void> checkFirebaseStatus() async {
    // Usar familyId fijo
    try {
      print('🔍 Verificando estado de sincronización...');
      print('🔧 Configuración:');
      print('   - Proyecto: ${_firestore.app.name}');
      print('   - Familia ID: $_userFamilyId');
      
      final snapshot = await _firestore
          .collection('events')
          // Sin filtro familyId
          .limit(5)
          .get();
      
      print('📊 Eventos sincronizados: ${snapshot.docs.length}');
      print('📱 Eventos locales: ${_events.length}');
      print('📊 Plantillas de turno locales: ${_shiftTemplates.length}');
      
      if (snapshot.docs.isNotEmpty) {
        print('📄 Últimos eventos:');
        for (int i = 0; i < snapshot.docs.length; i++) {
          final doc = snapshot.docs[i];
          final data = doc.data();
          print('   ${i + 1}. ${data['date']}: ${data['title']}');
        }
      }
    } catch (e) {
      print('❌ Error verificando estado: $e');
    }
  }

  Future<void> syncWithFirebase() async {
    // Usar familyId fijo
    try {
      print('🔄 Sincronizando datos locales...');
      
      for (final entry in _events.entries) {
        final dateKey = entry.key;
        final eventsList = entry.value;
        
        for (final event in eventsList) {
          final docId = '${dateKey}_${event.replaceAll(' ', '_')}';
          await _firestore.collection('events').doc(docId).set({
            'title': event,
            'date': dateKey,
            'familyId': _userFamilyId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      print('✅ Sincronización completada');
    } catch (e) {
      print('❌ Error en sincronización: $e');
    }
  }

  // Método auxiliar para la caché local
  bool _isEditingEventInCache(String dateKey, String eventId, String newTitle) {
    // Implementar lógica para verificar si el título ha cambiado para un ID de evento dado
    // Esto es un placeholder; la lógica real debería ser más robusta si los eventos pueden tener ID y títulos cambiantes
    return true;
  }

  String? _getOldEventTitleFromCache(String dateKey, String eventId) {
    // Placeholder; la lógica real buscaría el título antiguo por eventId en la caché
    // Por ahora, solo devolveremos el primer evento si existe
    if (_events.containsKey(dateKey) && _events[dateKey]!.isNotEmpty) {
      return _events[dateKey]!.first;
    }
    return null;
  }

  Future<AppEvent?> getAppEventByTitleAndDate(String title, DateTime date) async {
    final dateKey = _formatDate(date);
    print('🔍 Buscando evento en Firestore por título: $title y fecha: $dateKey');
    
    try {
      final snapshot = await _firestore.collection('events')
        .where('title', isEqualTo: title)
        .where('date', isEqualTo: dateKey)
        .where('familyId', isEqualTo: _userFamilyId)
        .get();
      
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        print('🔍 Datos del documento antes de fromJson: $data'); // DEBUG: Imprimir datos
        
        // Asegurar que el campo 'id' esté presente
        if (!data.containsKey('id')) {
          data['id'] = doc.id; // Usar el ID del documento como fallback
          print('🔧 Añadido ID del documento como fallback: ${doc.id}');
        }
        
        return AppEvent.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener AppEvent por título y fecha: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _reconnectionTimer?.cancel();
    _stopPollingMode();
    super.dispose();
  }

  // Getters para compatibilidad
  Map<String, List<String>> get events => _events; // Legacy
  Map<String, List<String>> get notes {
    if (kIsWeb) {
      print('🔍 getNotes() llamado - Total notas: ${_notes.length} fechas');
      print('🔍 Contenido de _notes: $_notes');
    }
    return _notes; // Nueva caché de notas
  }
  Map<String, List<String>> get shifts => _shifts; // Nueva caché de turnos
  Map<String, Map<String, String?>> get dayCategories => _dayCategories;
  List<ShiftTemplate> get shiftTemplates => _shiftTemplates;
  bool get hasData => _events.isNotEmpty || _notes.isNotEmpty || _shifts.isNotEmpty || _dayCategories.isNotEmpty || _shiftTemplates.isNotEmpty;

  // Obtener todos los eventos para exportación
  Future<Map<String, dynamic>> getAllEvents() async {
    // Usar familyId fijo

    final exportEvents = <String, dynamic>{};
    final querySnapshot = await _firestore.collection('events')
        .where('familyId', isEqualTo: _userFamilyId)
        .orderBy('date')
        .get();

    for (final doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateKey = data['date'] as String;
      final title = data['title'] as String;
      
      if (!exportEvents.containsKey(dateKey)) {
        exportEvents[dateKey] = {
          'events': [],
          'categories': _dayCategories[dateKey] ?? {},
        };
      }
      (exportEvents[dateKey]['events'] as List).add(title);
    }
    return exportEvents;
  }

  // Obtener plantillas de turnos para exportación
  List<Map<String, dynamic>> getShiftTemplatesForExport() {
    return _shiftTemplates.map((template) => template.toJson()).toList();
  }

  /// 🔹 Migrar eventos existentes que no tienen userId
  Future<void> _migrateExistingEvents() async {
    try {
      print('🔄 Iniciando migración de eventos existentes...');
      
      // Migrar notas
      await _migrateCollection('notes');
      
      // Migrar turnos
      await _migrateCollection('shifts');
      
      // Migrar eventos del calendario (si existen)
      await _migrateCollection('calendar_events');
      
      print('✅ Migración de eventos completada');
    } catch (e) {
      print('❌ Error durante la migración: $e');
    }
  }

  /// 🔹 Migrar una colección específica
  Future<void> _migrateCollection(String collectionName) async {
    try {
      print('📝 Migrando colección: $collectionName');
      
      final snapshot = await _firestore.collection(collectionName).get();
      print('📊 Encontrados ${snapshot.docs.length} documentos en $collectionName');
      
      int migratedCount = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Si ya tiene userId, saltarlo
        if (data.containsKey('userId') && data['userId'] != null) {
          continue;
        }
        
        // Obtener el título para determinar el userId
        final title = data['title']?.toString() ?? '';
        final userId = _assignUserIdFromTitle(title);
        
        // Actualizar el documento con el userId
        await doc.reference.update({
          'userId': userId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        print('✅ Documento ${doc.id} actualizado con userId: $userId (título: "$title")');
        migratedCount++;
      }
      
      if (migratedCount > 0) {
        print('📈 Migrados $migratedCount documentos en $collectionName');
      }
    } catch (e) {
      print('❌ Error migrando colección $collectionName: $e');
    }
  }

  /// 🔹 Asignar userId basado en el contenido del título
  int _assignUserIdFromTitle(String title) {
    final lowerTitle = title.toLowerCase().trim();
    
    // Patrones para asignar usuarios específicos
    if (lowerTitle.contains('pedro') || lowerTitle.contains('prueba')) {
      return 3; // Pedro
    }
    if (lowerTitle.contains('maría') || lowerTitle.contains('maria')) {
      return 2; // María
    }
    if (lowerTitle.contains('juan')) {
      return 1; // Juan
    }
    if (lowerTitle.contains('lucía') || lowerTitle.contains('lucia')) {
      return 4; // Lucía
    }
    if (lowerTitle.contains('ana')) {
      return 5; // Ana
    }
    
    // Si no hay patrón, usar usuario 1 por defecto
    return 1;
  }

  /// 🔹 Probar conexión con Firebase
  Future<void> _testFirebaseConnection() async {
    try {
      print('🔍 Probando conexión con Firebase...');
      
      // Probar lectura de notas
      final notesSnapshot = await _firestore.collection('notes').limit(1).get();
      print('✅ Conexión a notas exitosa: ${notesSnapshot.docs.length} documentos');
      
      // Probar lectura de turnos
      final shiftsSnapshot = await _firestore.collection('shifts').limit(1).get();
      print('✅ Conexión a turnos exitosa: ${shiftsSnapshot.docs.length} documentos');
      
      // Probar lectura de eventos del calendario
      final eventsSnapshot = await _firestore.collection('calendar_events').limit(1).get();
      print('✅ Conexión a eventos exitosa: ${eventsSnapshot.docs.length} documentos');
      
      // Probar escritura (crear un documento de prueba)
      final testDoc = _firestore.collection('test').doc('connection_test');
      await testDoc.set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': true,
      });
      print('✅ Escritura de prueba exitosa');
      
      // Limpiar documento de prueba
      await testDoc.delete();
      print('✅ Limpieza de prueba exitosa');
      
      print('🎉 Firebase está funcionando correctamente');
    } catch (e) {
      print('❌ Error de conexión con Firebase: $e');
      print('🔧 Verifica las reglas de Firestore y la configuración de Firebase');
    }
  }

  /// 🔹 Inicializar usuarios en Firebase
  Future<void> _initializeUsers() async {
    try {
      print('👥 Inicializando usuarios en Firebase...');
      
      // Inicializar usuarios en Firebase
      await UserSyncService.initializeUsersInFirebase();
      
      // Cargar usuarios desde Firebase (por si hay cambios)
      await UserSyncService.loadUsersFromFirebase();
      
      print('✅ Usuarios inicializados correctamente');
    } catch (e) {
      print('❌ Error inicializando usuarios: $e');
    }
  }
}
