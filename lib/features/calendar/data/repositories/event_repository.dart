import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:calendario_familiar/core/models/app_event.dart';
import 'package:calendario_familiar/core/utils/recurrence_utils.dart';
import 'package:calendario_familiar/core/services/notification_service.dart';
import 'package:calendario_familiar/core/utils/date_time_ext.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  
  Stream<List<AppEvent>> getEventsStream(String calendarId, DateTimeRange range) {
    return _firestore
        .collection('calendars')
        .doc(calendarId)
        .collection('events')
        .where('deletedAt', isNull: true)
        .where('startAt', isGreaterThanOrEqualTo: range.start)
        .where('startAt', isLessThanOrEqualTo: range.end)
        .orderBy('startAt')
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => AppEvent.fromJson(doc.data()))
              .toList();
          
          // Expandir eventos recurrentes
          final expandedEvents = <AppEvent>[];
          for (final event in events) {
            if (event.recurrence != null && event.recurrence!.rule != 'none') {
              final occurrences = RecurrenceUtils.expandRecurrence(event, range);
              expandedEvents.addAll(occurrences);
            } else {
              expandedEvents.add(event);
            }
          }
          
          return expandedEvents;
        });
  }
  
  Future<List<AppEvent>> getEvents(String calendarId, DateTimeRange range) async {
    try {
      final query = await _firestore
          .collection('calendars')
          .doc(calendarId)
          .collection('events')
          .where('deletedAt', isNull: true)
          .where('startAt', isGreaterThanOrEqualTo: range.start)
          .where('startAt', isLessThanOrEqualTo: range.end)
          .orderBy('startAt')
          .get();
      
      final events = query.docs
          .map((doc) => AppEvent.fromJson(doc.data()))
          .toList();
      
      // Expandir eventos recurrentes
      final expandedEvents = <AppEvent>[];
      for (final event in events) {
        if (event.recurrence != null && event.recurrence!.rule != 'none') {
          final occurrences = RecurrenceUtils.expandRecurrence(event, range);
          expandedEvents.addAll(occurrences);
        } else {
          expandedEvents.add(event);
        }
      }
      
      return expandedEvents;
    } catch (e) {
      print('Error obteniendo eventos: $e');
      return [];
    }
  }
  
  Future<AppEvent?> getEvent(String calendarId, String eventId) async {
    try {
      final doc = await _firestore
          .collection('calendars')
          .doc(calendarId)
          .collection('events')
          .doc(eventId)
          .get();
      
      if (doc.exists) {
        return AppEvent.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error obteniendo evento: $e');
      return null;
    }
  }
  
  Future<AppEvent> createEvent(AppEvent event) async {
    try {
      final eventId = _uuid.v4();
      final now = DateTime.now();
      
      final newEvent = event.copyWith(
        id: eventId,
        createdAt: now,
        updatedAt: now,
      );
      
      await _firestore
          .collection('calendars')
          .doc(newEvent.familyId) // Cambiado de event.calendarId a newEvent.familyId
          .collection('events')
          .doc(eventId)
          .set(newEvent.toJson());
      
      // Programar notificación
      await NotificationService.scheduleEventNotification(newEvent);
      
      return newEvent;
    } catch (e) {
      print('Error creando evento: $e');
      rethrow;
    }
  }
  
  Future<AppEvent> updateEvent(AppEvent event) async {
    try {
      final updatedEvent = event.copyWith(updatedAt: DateTime.now());
      
      await _firestore
          .collection('calendars')
          .doc(updatedEvent.familyId) // Cambiado de event.calendarId a updatedEvent.familyId
          .collection('events')
          .doc(event.id)
          .update(updatedEvent.toJson());
      
      // Cancelar notificación anterior y programar nueva
      await NotificationService.cancelEventNotification(event);
      await NotificationService.scheduleEventNotification(updatedEvent);
      
      return updatedEvent;
    } catch (e) {
      print('Error actualizando evento: $e');
      rethrow;
    }
  }
  
  Future<void> deleteEvent(String calendarId, String eventId) async {
    try {
      // Soft delete
      await _firestore
          .collection('calendars')
          .doc(calendarId)
          .collection('events')
          .doc(eventId)
          .update({
        'deletedAt': DateTime.now(),
      });
      
      // Cancelar notificación
      final event = await getEvent(calendarId, eventId);
      if (event != null) {
        await NotificationService.cancelEventNotification(event);
      }
    } catch (e) {
      print('Error eliminando evento: $e');
      rethrow;
    }
  }
  
  Future<void> hardDeleteEvent(String calendarId, String eventId) async {
    try {
      await _firestore
          .collection('calendars')
          .doc(calendarId)
          .collection('events')
          .doc(eventId)
          .delete();
      
      // Cancelar notificación
      final event = await getEvent(calendarId, eventId);
      if (event != null) {
        await NotificationService.cancelEventNotification(event);
      }
    } catch (e) {
      print('Error eliminando evento permanentemente: $e');
      rethrow;
    }
  }
  
  Future<List<AppEvent>> getEventsByDate(String calendarId, DateTime date) async {
    final startOfDay = date.startOfDay;
    final endOfDay = date.endOfDay;
    final range = DateTimeRange(start: startOfDay, end: endOfDay);
    
    return await getEvents(calendarId, range);
  }
  
  Future<List<AppEvent>> getEventsByWeek(String calendarId, DateTime weekStart) async {
    final endOfWeek = weekStart.endOfWeek;
    final range = DateTimeRange(start: weekStart, end: endOfWeek);
    
    return await getEvents(calendarId, range);
  }
  
  Future<List<AppEvent>> getEventsByMonth(String calendarId, DateTime monthStart) async {
    final endOfMonth = monthStart.endOfMonth;
    final range = DateTimeRange(start: monthStart, end: endOfMonth);
    
    return await getEvents(calendarId, range);
  }
}

