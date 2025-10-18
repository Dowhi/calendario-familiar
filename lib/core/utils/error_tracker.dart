/// Utilidad para rastrear errores y mapear líneas de código
class ErrorTracker {
  static final Map<String, String> _codeMap = {};
  static final List<String> _errorLog = [];

  /// Registrar una función o sección de código
  static void registerCode(String id, String description) {
    _codeMap[id] = description;
    print('📍 CÓDIGO REGISTRADO: $id - $description');
  }

  /// Ejecutar código con tracking de errores
  static T trackExecution<T>(String id, String description, T Function() code) {
    registerCode(id, description);
    
    try {
      print('🔄 EJECUTANDO: $id - $description');
      final result = code();
      print('✅ COMPLETADO: $id - $description');
      return result;
    } catch (e, stack) {
      final errorMsg = '❌ ERROR EN: $id - $description\nError: $e\nStack: $stack';
      _errorLog.add(errorMsg);
      print(errorMsg);
      rethrow;
    }
  }

  /// Ejecutar código asíncrono con tracking de errores
  static Future<T> trackAsyncExecution<T>(String id, String description, Future<T> Function() code) async {
    registerCode(id, description);
    
    try {
      print('🔄 EJECUTANDO ASYNC: $id - $description');
      final result = await code();
      print('✅ COMPLETADO ASYNC: $id - $description');
      return result;
    } catch (e, stack) {
      final errorMsg = '❌ ERROR ASYNC EN: $id - $description\nError: $e\nStack: $stack';
      _errorLog.add(errorMsg);
      print(errorMsg);
      rethrow;
    }
  }

  /// Obtener el log de errores
  static List<String> getErrorLog() => List.from(_errorLog);

  /// Limpiar el log de errores
  static void clearErrorLog() {
    _errorLog.clear();
  }

  /// Obtener el mapa de código registrado
  static Map<String, String> getCodeMap() => Map.from(_codeMap);

  /// Imprimir resumen de errores
  static void printErrorSummary() {
    print('\n📊 RESUMEN DE ERRORES:');
    print('Total de errores: ${_errorLog.length}');
    for (int i = 0; i < _errorLog.length; i++) {
      print('${i + 1}. ${_errorLog[i]}');
    }
  }
}
