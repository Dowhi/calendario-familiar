import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class TimeService {
  static const String _defaultTimeZone = 'Europe/Madrid';
  
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_defaultTimeZone));
  }
  
  static tz.Location get currentLocation => tz.local;
  
  static DateTime now() => tz.TZDateTime.now(currentLocation);
  
  static DateTime fromLocal(DateTime local) {
    return tz.TZDateTime.from(local, currentLocation);
  }
  
  static DateTime toLocal(DateTime utc) {
    return tz.TZDateTime.from(utc, currentLocation);
  }
  
  static String getTimeZoneName() {
    return currentLocation.name;
  }
  
  static bool isDaylightSavingTime() {
    return false; // Simplificado para evitar errores de timezone
  }
}

