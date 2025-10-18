import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final eventTextSizeProvider = StateNotifierProvider<EventTextSizeNotifier, double>((ref) => EventTextSizeNotifier());

class EventTextSizeNotifier extends StateNotifier<double> {
  EventTextSizeNotifier() : super(11.0) {
    _loadTextSize();
  }

  static const String _textSizeKey = 'event_text_size';

  Future<void> _loadTextSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final textSize = prefs.getDouble(_textSizeKey) ?? 11.0;
      state = textSize;
    } catch (e) {
      print('Error loading event text size: $e');
      state = 11.0; // Default size
    }
  }

  Future<void> setTextSize(double size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_textSizeKey, size);
      state = size;
    } catch (e) {
      print('Error saving event text size: $e');
    }
  }

  double get textSize => state;
}

