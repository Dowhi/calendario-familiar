import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
// import 'dart:html' as html; // Comentado para compatibilidad con WebAssembly
import 'package:calendario_familiar/core/models/shift_template.dart';
import 'package:collection/collection.dart';
import 'package:calendario_familiar/features/auth/logic/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendario_familiar/core/models/family.dart';
import 'package:calendario_familiar/core/models/app_user.dart';
import 'package:calendario_familiar/core/models/app_event.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:calendario_familiar/core/utils/error_tracker.dart';
import 'package:flutter/material.dart'; // Para WidgetsBinding

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
  static const Duration _pollingInterval = Duration(seconds: 30);

  CalendarDataService(this._ref) {
    print('🔧 CalendarDataService constructor iniciado');
    _setupConnectivityListener();
    
    _ref.listen<AppUser?>(authControllerProvider, (previous, next) {
      print('🔧 AuthController cambió:');
      print('  - Previous familyId: ${previous?.familyId}');
      print('  - Next familyId: ${next?.familyId}');
      
      if (previous?.familyId != next?.familyId) {
        print('🔧 FamilyId cambió, reinicializando suscripciones...');
        _userFamilyId = next?.familyId;
        _reinitializeSubscriptions();
      } else {
        print('🔧 FamilyId no cambió, manteniendo suscripciones actuales');
      }
    });
    _userFamilyId = _ref.read(authControllerProvider)?.familyId;
    print('🔧 FamilyId inicial: $_userFamilyId');
    _reinitializeSubscriptions();
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
    
    if (_userFamilyId != null && _isOnline) {
      print('🔧 FamilyId válido y online, inicializando sincronización...');
      
              // Detectar iOS y usar modo híbrido
              if (kIsWeb && _isLikelyIOS()) {
                print('📱 iOS detectado, usando modo híbrido: fallback + sincronización limitada');
                _loadFallbackDataForIOS();
                _startLimitedSyncForIOS();
                return;
              }
      
      initialize();
    } else {
      print('🔧 No hay familyId o está offline, limpiando datos locales...');
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
    if (_userFamilyId == null) {
      print('⚠️ No hay familyId asignado, saltando inicialización de sincronización.');
      return;
    }

    if (!_isOnline) {
      print('⚠️ Sin conexión, saltando inicialización de sincronización.');
      return;
    }

    print('🚀 Inicializando sincronización en tiempo real para familyId: $_userFamilyId');
    
    try {
      // Configurar timeout para las suscripciones
      final timeout = const Duration(seconds: 10); // Reducir timeout para iOS
      
      // Suscripción legacy para compatibilidad
      _eventsSubscription = _firestore
          .collection('events')
          .where('familyId', isEqualTo: _userFamilyId)
          .snapshots()
          .timeout(timeout)
          .listen(
            _onEventsChanged,
            onError: (error) {
              print('❌ Error en suscripción de eventos: $error');
              _handleSubscriptionError('events', error);
            },
          );
      
      // Nueva suscripción para notas
      _notesSubscription = _firestore
          .collection('notes')
          .where('familyId', isEqualTo: _userFamilyId)
          .snapshots()
          .timeout(timeout)
          .listen(
            _onNotesChanged,
            onError: (error) {
              print('❌ Error en suscripción de notas: $error');
              _handleSubscriptionError('notes', error);
            },
          );
      
      // Nueva suscripción para turnos
      _shiftsSubscription = _firestore
          .collection('shifts')
          .where('familyId', isEqualTo: _userFamilyId)
          .snapshots()
          .timeout(timeout)
          .listen(
            _onShiftsChanged,
            onError: (error) {
              print('❌ Error en suscripción de turnos: $error');
              _handleSubscriptionError('shifts', error);
            },
          );
      
      _categoriesSubscription = _firestore
          .collection('dayCategories')
          .where('familyId', isEqualTo: _userFamilyId)
          .snapshots()
          .timeout(timeout)
          .listen(
            _onCategoriesChanged,
            onError: (error) {
              print('❌ Error en suscripción de categorías: $error');
              _handleSubscriptionError('categories', error);
            },
          );

      print('🔧 Configurando suscripción a shift_templates con familyId: $_userFamilyId');
      _shiftTemplatesSubscription = _firestore
          .collection('shift_templates')
          .where('familyId', isEqualTo: _userFamilyId)
          .snapshots()
          .timeout(timeout)
          .listen(
            _onShiftTemplatesChanged,
            onError: (error) {
              print('❌ Error en suscripción de plantillas: $error');
              _handleSubscriptionError('shift_templates', error);
            },
          );
      
      print('✅ Sincronización en tiempo real activada para familyId: $_userFamilyId');
      
      print('🔍 Verificando datos manualmente...');
      final manualQuery = await _firestore
          .collection('shift_templates')
          .where('familyId', isEqualTo: _userFamilyId)
          .get();
      print('🔍 Consulta manual: ${manualQuery.docs.length} documentos encontrados');
      for (final doc in manualQuery.docs) {
        print('🔍 Documento: ${doc.id} - ${doc.data()}');
      }
      
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
    // Esta función se ejecuta en el navegador, podemos usar JavaScript
    return true; // Asumir iOS si estamos en web y hay timeouts
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
            
            // Sincronizar datos una sola vez después de 3 segundos
            Timer(const Duration(seconds: 3), () async {
              try {
                print('📱 Sincronizando datos de Firebase para iOS...');
                
                // Obtener eventos
                final eventsQuery = await _firestore
                    .collection('events')
                    .where('familyId', isEqualTo: _userFamilyId)
                    .limit(50) // Limitar a 50 eventos
                    .get();
                
                // Obtener turnos
                final shiftsQuery = await _firestore
                    .collection('shifts')
                    .where('familyId', isEqualTo: _userFamilyId)
                    .limit(50) // Limitar a 50 turnos
                    .get();
                
                // Obtener notas
                final notesQuery = await _firestore
                    .collection('notes')
                    .where('familyId', isEqualTo: _userFamilyId)
                    .limit(50) // Limitar a 50 notas
                    .get();
                
                // Obtener plantillas
                final templatesQuery = await _firestore
                    .collection('shift_templates')
                    .where('familyId', isEqualTo: _userFamilyId)
                    .limit(20) // Limitar a 20 plantillas
                    .get();
                
                // Procesar datos obtenidos
                _processPolledEvents(eventsQuery.docs);
                _processPolledShifts(shiftsQuery.docs);
                _processPolledNotes(notesQuery.docs);
                _processPolledTemplates(templatesQuery.docs);
                
                print('✅ Sincronización limitada completada para iOS');
                
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
  
  // Obtener datos mediante polling (get() en lugar de streams)
  Future<void> _pollData() async {
    if (_userFamilyId == null) return;
    
    try {
      print('📱 Polling datos para iOS...');
      
      // Obtener eventos
      final eventsQuery = await _firestore
          .collection('events')
          .where('familyId', isEqualTo: _userFamilyId)
          .get();
      
      // Obtener turnos
      final shiftsQuery = await _firestore
          .collection('shifts')
          .where('familyId', isEqualTo: _userFamilyId)
          .get();
      
      // Obtener notas
      final notesQuery = await _firestore
          .collection('notes')
          .where('familyId', isEqualTo: _userFamilyId)
          .get();
      
      // Obtener plantillas
      final templatesQuery = await _firestore
          .collection('shift_templates')
          .where('familyId', isEqualTo: _userFamilyId)
          .get();
      
      // Procesar datos obtenidos
      _processPolledEvents(eventsQuery.docs);
      _processPolledShifts(shiftsQuery.docs);
      _processPolledNotes(notesQuery.docs);
      _processPolledTemplates(templatesQuery.docs);
      
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
    _shifts.clear();
    final Map<String, Set<String>> tempShifts = {};
    
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateKey = (data['date'] != null) ? data['date'].toString() : '';
      final shiftName = (data['shiftName'] != null) ? data['shiftName'].toString() : '';
      if (dateKey.isNotEmpty && shiftName.isNotEmpty) {
        tempShifts.putIfAbsent(dateKey, () => {});
        tempShifts[dateKey]!.add(shiftName);
      }
    }
    
    for (final entry in tempShifts.entries) {
      _shifts[entry.key] = entry.value.map((e) => e.toString()).toList();
    }
  }
  
  // Procesar notas obtenidas por polling
  void _processPolledNotes(List<QueryDocumentSnapshot> docs) {
    _notes.clear();
    final Map<String, Set<String>> tempNotes = {};
    
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateKey = (data['date'] != null) ? data['date'].toString() : '';
      final noteText = (data['text'] != null) ? data['text'].toString() : '';
      if (dateKey.isNotEmpty && noteText.isNotEmpty) {
        tempNotes.putIfAbsent(dateKey, () => {});
        tempNotes[dateKey]!.add(noteText);
      }
    }
    
    for (final entry in tempNotes.entries) {
      _notes[entry.key] = entry.value.map((e) => e.toString()).toList();
    }
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
      
      if (dateKey.isNotEmpty && title.isNotEmpty) {
        if (!tempEvents.containsKey(dateKey)) {
          tempEvents[dateKey] = <String>{};
        }
        tempEvents[dateKey]!.add(title);
        
        if (eventType.isNotEmpty) {
          print('📝 Evento cargado: $title ($eventType) en $dateKey');
        }
      }
    }
    
    for (final entry in tempEvents.entries) {
      _events[entry.key] = entry.value.map((e) => e.toString()).toList();
    }
    
        notifyListeners();
        print('📊 Datos locales actualizados: $_events');
      },
    );
  }

  void _onNotesChanged(QuerySnapshot snapshot) {
    print('🔄 Notas actualizadas desde Firebase: ${snapshot.docs.length} documentos');
    
    _notes.clear();
    
    final Map<String, Set<String>> tempNotes = {};
    
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateKey = data['date']?.toString() ?? '';
      final title = data['title']?.toString() ?? '';
      
      if (dateKey.isNotEmpty && title.isNotEmpty) {
        if (!tempNotes.containsKey(dateKey)) {
          tempNotes[dateKey] = <String>{};
        }
        tempNotes[dateKey]!.add(title);
        print('📝 Nota cargada: $title en $dateKey');
      }
    }
    
    for (final entry in tempNotes.entries) {
      _notes[entry.key] = entry.value.map((e) => e.toString()).toList();
    }
    
    notifyListeners();
    print('📊 Notas locales actualizadas: $_notes');
  }

  void _onShiftsChanged(QuerySnapshot snapshot) {
    print('🔄 Turnos actualizados desde Firebase: ${snapshot.docs.length} documentos');
    
    _shifts.clear();
    
    final Map<String, Set<String>> tempShifts = {};
    
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateKey = data['date']?.toString() ?? '';
      final title = data['title']?.toString() ?? '';
      
      if (dateKey.isNotEmpty && title.isNotEmpty) {
        if (!tempShifts.containsKey(dateKey)) {
          tempShifts[dateKey] = <String>{};
        }
        tempShifts[dateKey]!.add(title);
        print('🔄 Turno cargado: $title en $dateKey');
      }
    }
    
    for (final entry in tempShifts.entries) {
      _shifts[entry.key] = entry.value.map((e) => e.toString()).toList();
    }
    
    notifyListeners();
    print('📊 Turnos locales actualizados: $_shifts');
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
    
    notifyListeners();
    print('📊 Categorías locales actualizadas: $_dayCategories');
  }

  void _onShiftTemplatesChanged(QuerySnapshot snapshot) {
    print('🔄 Plantillas de turnos actualizadas desde Firebase: ${snapshot.docs.length} documentos');
    print('🔧 IDs de documentos recibidos: ${snapshot.docs.map((doc) => doc.id).toList()}');
    
    _shiftTemplates.clear();
    print('🔧 Lista local limpiada, agregando ${snapshot.docs.length} plantillas...');
    
    for (final doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        print('🔧 Procesando documento ${doc.id}: ${data['name']}');
        
        final template = ShiftTemplate.fromJson(data);
        _shiftTemplates.add(template);
        
        print('✅ Plantilla cargada: ${template.name} (ID: ${template.id})');
      } catch (e) {
        print('❌ Error cargando plantilla: $e');
        print('🔧 Documento problemático: ${doc.data()}');
      }
    }
    
    notifyListeners();
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
    final currentOwnerId = _ref.read(authControllerProvider)?.uid;
    
    if (currentOwnerId == null) {
      print('❌ No se puede añadir nota: No hay ownerId asignado.');
      return;
    }
    
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
        'familyId': _userFamilyId ?? 'demo_family',
        'ownerId': currentOwnerId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      print('🔧 Guardando nota en Firestore con ID: $finalNoteId');
      await docRef.set(noteData, SetOptions(merge: true));
      
      // Actualizar caché local de notas
      if (!_notes.containsKey(dateKey)) {
        _notes[dateKey] = <String>[];
      }
      if (!_notes[dateKey]!.contains(title)) {
        _notes[dateKey]!.add(title);
        notifyListeners();
      }
      
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
    final currentOwnerId = _ref.read(authControllerProvider)?.uid;
    
    if (currentOwnerId == null) {
      print('❌ No se puede añadir turno: No hay ownerId asignado.');
      return;
    }

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
        'familyId': _userFamilyId ?? 'demo_family',
        'ownerId': currentOwnerId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      print('🔧 Guardando turno en Firestore con ID: $finalShiftId');
      await docRef.set(shiftData, SetOptions(merge: true));
      
      // Actualizar caché local de turnos
      if (!_shifts.containsKey(dateKey)) {
        _shifts[dateKey] = <String>[];
      }
      if (!_shifts[dateKey]!.contains(title)) {
        _shifts[dateKey]!.add(title);
        notifyListeners();
      }
      
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
          .where('familyId', isEqualTo: _userFamilyId)
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
    final currentOwnerId = _ref.read(authControllerProvider)?.uid;
    
    if (currentOwnerId == null) {
      print('❌ No se puede actualizar nota: No hay ownerId asignado.');
      return;
    }
    
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
    final currentOwnerId = _ref.read(authControllerProvider)?.uid;
    
    if (currentOwnerId == null) {
      print('❌ No se puede eliminar nota: No hay ownerId asignado.');
      return;
    }
    
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
    if (_userFamilyId == null) {
      print('❌ No se puede actualizar evento: No hay familyId asignado.');
      return;
    }
    final dateKey = _formatDate(date);
    final currentOwnerId = _ref.read(authControllerProvider)?.uid; // Obtener ownerId actual

    if (currentOwnerId == null) {
      print('❌ No se puede actualizar evento: No hay ownerId asignado.');
      return;
    }
    
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
    if (_userFamilyId == null) {
      print('❌ No se puede eliminar evento: No hay familyId asignado.');
      return;
    }
    try {
      await _firestore.collection('events').doc(eventId).delete();
      print('✅ Evento eliminado y sincronizado: $eventId');
    } catch (e) {
      print('❌ Error eliminando evento: $e');
    }
  }

  Future<void> deleteAllEventsForDay(DateTime date) async {
    if (_userFamilyId == null) {
      print('❌ No se pueden eliminar eventos del día: No hay familyId asignado.');
      return;
    }
    final dateKey = _formatDate(date);
    
    try {
      final batch = _firestore.batch();
      
      // Eliminar de la colección 'events' (legacy)
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('date', isEqualTo: dateKey)
          .where('familyId', isEqualTo: _userFamilyId)
          .get();
      
      for (final doc in eventsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Eliminar de la colección 'notes'
      final notesSnapshot = await _firestore
          .collection('notes')
          .where('date', isEqualTo: dateKey)
          .where('familyId', isEqualTo: _userFamilyId)
          .get();
      
      for (final doc in notesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Eliminar de la colección 'shifts'
      final shiftsSnapshot = await _firestore
          .collection('shifts')
          .where('date', isEqualTo: dateKey)
          .where('familyId', isEqualTo: _userFamilyId)
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
    
    // Combinar todos los eventos (notas + turnos + legacy)
    final allEvents = <String>{};
    allEvents.addAll(notes);
    allEvents.addAll(shifts);
    allEvents.addAll(legacyEvents);
    
    return allEvents.toList();
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
        'familyId': _userFamilyId ?? 'demo_family',
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
    if (_userFamilyId == null) {
      print('❌ No se puede actualizar plantilla: No hay familyId asignado.');
      return;
    }
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
    if (_userFamilyId == null) {
      print('❌ No se puede eliminar plantilla: No hay familyId asignado.');
      return;
    }
    try {
      await _firestore.collection('shift_templates').doc(templateId).delete();
      print('✅ Plantilla de turno eliminada: $templateId');
    } catch (e) {
      print('❌ Error eliminando plantilla de turno: $e');
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
    if (_userFamilyId == null) {
      print('❌ No se puede establecer categoría: No hay familyId asignado.');
      return;
    }
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
    if (_userFamilyId == null) {
      print('❌ No se pueden obtener estadísticas: No hay familyId asignado.');
      return {
        'totalEvents': 0,
        'categories': {},
        'daysWithEvents': 0,
      };
    }
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

    if (_userFamilyId == null) {
      print('⚠️ No se cargan datos de ejemplo: No hay familyId asignado.');
      return;
    }

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
    notifyListeners();
    print('🗑️ Eventos, notas y turnos limpiados localmente para: $dateKey');
  }

  Future<void> checkFirebaseStatus() async {
    if (_userFamilyId == null) {
      print('⚠️ No se puede verificar estado de Firebase: No hay familyId asignado.');
      return;
    }
    try {
      print('🔍 Verificando estado de sincronización...');
      print('🔧 Configuración:');
      print('   - Proyecto: ${_firestore.app.name}');
      print('   - Familia ID: $_userFamilyId');
      
      final snapshot = await _firestore
          .collection('events')
          .where('familyId', isEqualTo: _userFamilyId)
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
    if (_userFamilyId == null) {
      print('❌ No se puede sincronizar con Firebase: No hay familyId asignado.');
      return;
    }
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
  Map<String, List<String>> get notes => _notes; // Nueva caché de notas
  Map<String, List<String>> get shifts => _shifts; // Nueva caché de turnos
  Map<String, Map<String, String?>> get dayCategories => _dayCategories;
  List<ShiftTemplate> get shiftTemplates => _shiftTemplates;
  bool get hasData => _events.isNotEmpty || _notes.isNotEmpty || _shifts.isNotEmpty || _dayCategories.isNotEmpty || _shiftTemplates.isNotEmpty;

  // Obtener todos los eventos para exportación
  Future<Map<String, dynamic>> getAllEvents() async {
    if (_userFamilyId == null) {
      print('❌ No se pueden obtener todos los eventos: No hay familyId asignado.');
      return {};
    }

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
}
