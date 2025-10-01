import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

extension DateTimeExtension on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);
  
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
  
  DateTime get startOfWeek {
    final daysFromMonday = weekday - 1;
    return subtract(Duration(days: daysFromMonday));
  }
  
  DateTime get endOfWeek => startOfWeek.add(const Duration(days: 6));
  
  DateTime get startOfMonth => DateTime(year, month, 1);
  
  DateTime get endOfMonth => DateTime(year, month + 1, 0);
  
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }
  
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
  
  String get formattedDate => DateFormat('dd/MM/yyyy').format(this);
  
  String get formattedTime => DateFormat('HH:mm').format(this);
  
  String get formattedDateTime => DateFormat('dd/MM/yyyy HH:mm').format(this);
  
  String get relativeDate {
    if (isToday) return 'Hoy';
    if (isTomorrow) return 'Mañana';
    if (isYesterday) return 'Ayer';
    return formattedDate;
  }
  
  DateTime addDays(int days) => add(Duration(days: days));
  
  DateTime addWeeks(int weeks) => add(Duration(days: weeks * 7));
  
  DateTime addMonths(int months) {
    final newMonth = month + months;
    final newYear = year + (newMonth - 1) ~/ 12;
    final adjustedMonth = ((newMonth - 1) % 12) + 1;
    return DateTime(newYear, adjustedMonth, day);
  }
  
  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;
  
  bool isBetween(DateTime start, DateTime end) => isAfter(start) && isBefore(end);
  
  bool isBetweenInclusive(DateTime start, DateTime end) => (isAfter(start) || isAtSameMomentAs(start)) && 
           (isBefore(end) || isAtSameMomentAs(end));
}

extension DateTimeRangeExtension on DateTimeRange {
  bool containsDate(DateTime date) => date.isBetweenInclusive(start, end);
  
  List<DateTime> get daysInRange {
    final days = <DateTime>[];
    var current = start.startOfDay;
    final endDate = end.startOfDay;
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      days.add(current);
      current = current.addDays(1);
    }
    
    return days;
  }
}

