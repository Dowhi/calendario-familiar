import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:calendario_familiar/core/utils/date_time_ext.dart';

void main() {
  group('DateTimeExtension', () {
    test('startOfDay should return start of day', () {
      final date = DateTime(2024, 1, 15, 14, 30, 45);
      final startOfDay = date.startOfDay;
      
      expect(startOfDay.year, 2024);
      expect(startOfDay.month, 1);
      expect(startOfDay.day, 15);
      expect(startOfDay.hour, 0);
      expect(startOfDay.minute, 0);
      expect(startOfDay.second, 0);
    });

    test('endOfDay should return end of day', () {
      final date = DateTime(2024, 1, 15, 14, 30, 45);
      final endOfDay = date.endOfDay;
      
      expect(endOfDay.year, 2024);
      expect(endOfDay.month, 1);
      expect(endOfDay.day, 15);
      expect(endOfDay.hour, 23);
      expect(endOfDay.minute, 59);
      expect(endOfDay.second, 59);
    });

    test('isToday should return true for today', () {
      final today = DateTime.now();
      expect(today.isToday, true);
    });

    test('isToday should return false for other days', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(yesterday.isToday, false);
    });

    test('formattedDate should format correctly', () {
      final date = DateTime(2024, 1, 15);
      expect(date.formattedDate, '15/01/2024');
    });

    test('formattedTime should format correctly', () {
      final time = DateTime(2024, 1, 15, 14, 30);
      expect(time.formattedTime, '14:30');
    });

    test('addDays should add correct number of days', () {
      final date = DateTime(2024, 1, 15);
      final newDate = date.addDays(5);
      expect(newDate.day, 20);
    });

    test('addWeeks should add correct number of weeks', () {
      final date = DateTime(2024, 1, 15);
      final newDate = date.addWeeks(2);
      expect(newDate.day, 29);
    });

    test('addMonths should add correct number of months', () {
      final date = DateTime(2024, 1, 15);
      final newDate = date.addMonths(3);
      expect(newDate.month, 4);
      expect(newDate.day, 15);
    });
  });

  group('DateTimeRangeExtension', () {
    test('containsDate should return true for date in range', () {
      final range = DateTimeRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );
      final date = DateTime(2024, 1, 15);
      
      expect(range.containsDate(date), true);
    });

    test('containsDate should return false for date outside range', () {
      final range = DateTimeRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );
      final date = DateTime(2024, 2, 15);
      
      expect(range.containsDate(date), false);
    });

    test('daysInRange should return correct number of days', () {
      final range = DateTimeRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 3),
      );
      final days = range.daysInRange;
      
      expect(days.length, 3);
      expect(days[0].day, 1);
      expect(days[1].day, 2);
      expect(days[2].day, 3);
    });
  });
}

