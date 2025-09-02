import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = ChangeNotifierProvider((ref) => ConnectivityService());

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  
  bool _isFirebaseConnected = false;
  bool get isFirebaseConnected => _isFirebaseConnected;
  
  Timer? _connectivityCheckTimer;
  Timer? _firebaseHealthCheckTimer;
  
  // Callbacks para manejar cambios de estado
  final List<Function(bool)> _onlineStatusCallbacks = [];
  final List<Function(bool)> _firebaseStatusCallbacks = [];

  ConnectivityService() {
    _initializeConnectivityMonitoring();
  }

  void _initializeConnectivityMonitoring() {
    if (kIsWeb) {
      _setupWebConnectivityMonitoring();
    } else {
      _setupMobileConnectivityMonitoring();
    }
    
    // Verificar conectividad cada 30 segundos
    _connectivityCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnectivity();
    });
    
    // Verificar salud de Firebase cada 60 segundos
    _firebaseHealthCheckTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _checkFirebaseHealth();
    });
  }

  void _setupWebConnectivityMonitoring() {
    if (kIsWeb) {
      // Usar eventos del navegador
      _checkWebConnectivity();
      
      // Escuchar eventos de cambio de conectividad
      _setupWebEventListeners();
    }
  }

  void _setupWebEventListeners() {
    if (kIsWeb) {
      // Evento cuando la conexión se restaura
      if (window.navigator.onLine != null) {
        window.addEventListener('online', (_) {
          _onConnectionRestored();
        });
        
        // Evento cuando la conexión se pierde
        window.addEventListener('offline', (_) {
          _onConnectionLost();
        });
      }
    }
  }

  void _setupMobileConnectivityMonitoring() {
    // Implementar para móvil si es necesario
    print('📱 Configurando monitoreo de conectividad móvil');
  }

  void _checkWebConnectivity() {
    if (kIsWeb) {
      final wasOnline = _isOnline;
      _isOnline = window.navigator.onLine;
      
      if (wasOnline != _isOnline) {
        print('🌐 Estado de conectividad cambió: ${_isOnline ? "ONLINE" : "OFFLINE"}');
        _notifyOnlineStatusChange();
      }
    }
  }

  void _checkConnectivity() {
    if (kIsWeb) {
      _checkWebConnectivity();
    }
    // Implementar para móvil si es necesario
  }

  void _checkFirebaseHealth() {
    // Verificar si Firebase está respondiendo
    _performFirebaseHealthCheck();
  }

  Future<void> _performFirebaseHealthCheck() async {
    try {
      // Intentar una operación simple de Firebase
      // Por ejemplo, obtener un documento de configuración
      // Esto se puede implementar cuando se necesite
      _isFirebaseConnected = true;
      _notifyFirebaseStatusChange();
    } catch (e) {
      print('❌ Error en verificación de salud de Firebase: $e');
      _isFirebaseConnected = false;
      _notifyFirebaseStatusChange();
    }
  }

  void _onConnectionRestored() {
    print('✅ Conexión restaurada');
    _isOnline = true;
    _notifyOnlineStatusChange();
    
    // Verificar Firebase después de restaurar conexión
    Future.delayed(const Duration(seconds: 2), () {
      _checkFirebaseHealth();
    });
  }

  void _onConnectionLost() {
    print('❌ Conexión perdida');
    _isOnline = false;
    _isFirebaseConnected = false;
    _notifyOnlineStatusChange();
    _notifyFirebaseStatusChange();
  }

  void _notifyOnlineStatusChange() {
    notifyListeners();
    for (final callback in _onlineStatusCallbacks) {
      try {
        callback(_isOnline);
      } catch (e) {
        print('❌ Error en callback de estado online: $e');
      }
    }
  }

  void _notifyFirebaseStatusChange() {
    notifyListeners();
    for (final callback in _firebaseStatusCallbacks) {
      try {
        callback(_isFirebaseConnected);
      } catch (e) {
        print('❌ Error en callback de estado Firebase: $e');
      }
    }
  }

  // Métodos públicos para registrar callbacks
  void addOnlineStatusCallback(Function(bool) callback) {
    _onlineStatusCallbacks.add(callback);
  }

  void removeOnlineStatusCallback(Function(bool) callback) {
    _onlineStatusCallbacks.remove(callback);
  }

  void addFirebaseStatusCallback(Function(bool) callback) {
    _firebaseStatusCallbacks.add(callback);
  }

  void removeFirebaseStatusCallback(Function(bool) callback) {
    _firebaseStatusCallbacks.remove(callback);
  }

  // Forzar verificación de conectividad
  Future<void> forceConnectivityCheck() async {
    _checkConnectivity();
    await _checkFirebaseHealth();
  }

  // Obtener estado completo de conectividad
  Map<String, bool> getConnectivityStatus() {
    return {
      'isOnline': _isOnline,
      'isFirebaseConnected': _isFirebaseConnected,
      'isWeb': kIsWeb,
    };
  }

  @override
  void dispose() {
    _connectivityCheckTimer?.cancel();
    _firebaseHealthCheckTimer?.cancel();
    _onlineStatusCallbacks.clear();
    _firebaseStatusCallbacks.clear();
    super.dispose();
  }
}
