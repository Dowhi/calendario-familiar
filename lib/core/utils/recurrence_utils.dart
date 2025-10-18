import 'package:calendario_familiar/core/models/app_event.dart';
import 'package:calendario_familiar/core/models/recurrence.dart';
import 'package:flutter/material.dart';

class RecurrenceUtils {
  static List<AppEvent> expandRecurrence(AppEvent event, DateTimeRange range) {
    if (event.recurrence == null || event.recurrence!.rule == 'none') {
      return [event];
    }

    // Verificar que startAt y endAt no sean null
    if (event.startAt == null || event.endAt == null) {
      return [event];
    }

    final occurrences = <AppEvent>[];
    final startDate = event.startAt!;
    final endDate = event.endAt!;
    final duration = endDate.difference(startDate);

    DateTime currentDate = startDate;
    final until = event.recurrence!.until ?? range.end;

    while (currentDate.isBefore(until)) {
      if (currentDate.isAfter(range.start.subtract(const Duration(days: 1)))) {
        final occurrenceStart = currentDate;
        final occurrenceEnd = currentDate.add(duration);
        
        final occurrence = event.copyWith(
          id: '${event.id}_${currentDate.millisecondsSinceEpoch}',
          startAt: occurrenceStart,
          endAt: occurrenceEnd,
        );
        
        occurrences.add(occurrence);
      }

      currentDate = _getNextOccurrence(currentDate, event.recurrence!);
    }

    return occurrences;
  }

  static DateTime _getNextOccurrence(DateTime current, Recurrence recurrence) {
    switch (recurrence.rule) {
      case 'daily':
        return _getNextDaily(current, recurrence.interval ?? 1);
      case 'weekly':
        return _getNextWeekly(current, recurrence);
      case 'monthly':
        return _getNextMonthly(current, recurrence);
      default:
        return current.add(const Duration(days: 1));
    }
  }

  static DateTime _getNextDaily(DateTime current, int interval) => current.add(Duration(days: interval));

  static DateTime _getNextWeekly(DateTime current, Recurrence recurrence) {
    final interval = recurrence.interval ?? 1;
    final byWeekdays = recurrence.byWeekdays;
    
    if (byWeekdays != null && byWeekdays.isNotEmpty) {
      // Find next occurrence based on specific weekdays
      DateTime next = current.add(const Duration(days: 1));
      while (!byWeekdays.contains(next.weekday)) {
        next = next.add(const Duration(days: 1));
      }
      return next;
    } else {
      // Same weekday, next week
      return current.add(Duration(days: 7 * interval));
    }
  }

  static DateTime _getNextMonthly(DateTime current, Recurrence recurrence) {
    final interval = recurrence.interval ?? 1;
    final byMonthDay = recurrence.byMonthDay;
    
    if (byMonthDay != null) {
      // Same day of month, next month
      int year = current.year;
      int month = current.month + interval;
      
      while (month > 12) {
        year++;
        month -= 12;
      }
      
      // Handle invalid dates (e.g., Feb 30)
      int day = byMonthDay;
      while (day > 28) {
        try {
          DateTime(year, month, day);
          break;
        } catch (e) {
          day--;
        }
      }
      
      return DateTime(year, month, day);
    } else {
      // Same date, next month
      int year = current.year;
      int month = current.month + interval;
      
      while (month > 12) {
        year++;
        month -= 12;
      }
      
      // Handle invalid dates
      int day = current.day;
      while (day > 28) {
        try {
          DateTime(year, month, day);
          break;
        } catch (e) {
          day--;
        }
      }
      
      return DateTime(year, month, day);
    }
  }

  static String getRecurrenceDescription(Recurrence? recurrence) {
    if (recurrence == null || recurrence.rule == 'none') {
      return 'Sin repetición';
    }

    switch (recurrence.rule) {
      case 'daily':
        final interval = recurrence.interval ?? 1;
        return interval == 1 ? 'Diario' : 'Cada $interval días';
      case 'weekly':
        final interval = recurrence.interval ?? 1;
        if (recurrence.byWeekdays != null && recurrence.byWeekdays!.isNotEmpty) {
          final weekdays = recurrence.byWeekdays!.map((day) => _getWeekdayName(day)).join(', ');
          return interval == 1 ? 'Semanal ($weekdays)' : 'Cada $interval semanas ($weekdays)';
        }
        return interval == 1 ? 'Semanal' : 'Cada $interval semanas';
      case 'monthly':
        final interval = recurrence.interval ?? 1;
        return interval == 1 ? 'Mensual' : 'Cada $interval meses';
      default:
        return 'Sin repetición';
    }
  }

  static String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return 'Lun';
      case 2: return 'Mar';
      case 3: return 'Mié';
      case 4: return 'Jue';
      case 5: return 'Vie';
      case 6: return 'Sáb';
      case 7: return 'Dom';
      default: return '';
    }
  }

  static List<String> getRecurrenceOptions() => [
      'Sin repetición',
      'Diario',
      'Semanal',
      'Mensual',
    ];

  static Recurrence? getRecurrenceRule(String option) {
    switch (option) {
      case 'Sin repetición':
        return null;
      case 'Diario':
        return const Recurrence(rule: 'daily', interval: 1);
      case 'Semanal':
        return const Recurrence(rule: 'weekly', interval: 1);
      case 'Mensual':
        return const Recurrence(rule: 'monthly', interval: 1);
      default:
        return null;
    }
  }
}
