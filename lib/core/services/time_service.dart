import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class TimeService {
  static const String _defaultTimeZone = 'Europe/Madrid';
  
  static Future<void> initialize() async {
    if (kIsWeb) {
      print('🌐 Ejecutándose en web - timezone no disponible');
      return;
    }
    
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_defaultTimeZone));
  }
  
  static tz.Location get currentLocation {
    if (kIsWeb) {
      return tz.getLocation('UTC'); // Fallback para web
    }
    return tz.local;
  }
  
  static DateTime now() {
    if (kIsWeb) {
      return DateTime.now();
    }
    return tz.TZDateTime.now(currentLocation);
  }
  
  static DateTime fromLocal(DateTime local) {
    if (kIsWeb) {
      return local;
    }
    return tz.TZDateTime.from(local, currentLocation);
  }
  
  static DateTime toLocal(DateTime utc) {
    if (kIsWeb) {
      return utc;
    }
    return tz.TZDateTime.from(utc, currentLocation);
  }
  
  static String getTimeZoneName() {
    if (kIsWeb) {
      return 'UTC';
    }
    return currentLocation.name;
  }
  
  static bool isDaylightSavingTime() {
    return false; // Simplificado para evitar errores de timezone
  }
}

