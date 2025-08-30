import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:calendario_familiar/core/models/family_calendar.dart';
import 'package:calendario_familiar/core/models/app_user.dart';

class CalendarRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  
  Stream<FamilyCalendar?> getCalendarStream(String calendarId) {
    return _firestore
        .collection('calendars')
        .doc(calendarId)
        .snapshots()
        .map((doc) => doc.exists ? FamilyCalendar.fromJson(doc.data()!) : null);
  }
  
  Future<FamilyCalendar?> getCalendar(String calendarId) async {
    try {
      final doc = await _firestore.collection('calendars').doc(calendarId).get();
      if (doc.exists) {
        return FamilyCalendar.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error obteniendo calendario: $e');
      return null;
    }
  }
  
  Future<FamilyCalendar> createCalendar(String name, String ownerId) async {
    try {
      final calendarId = _uuid.v4();
      final now = DateTime.now();
      
      final calendar = FamilyCalendar(
        id: calendarId,
        name: name,
        members: [ownerId],
        createdAt: now,
        updatedAt: now,
      );
      
      await _firestore.collection('calendars').doc(calendarId).set(calendar.toJson());
      return calendar;
    } catch (e) {
      print('Error creando calendario: $e');
      rethrow;
    }
  }
  
  Future<void> updateCalendar(FamilyCalendar calendar) async {
    try {
      final updatedCalendar = calendar.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('calendars')
          .doc(calendar.id)
          .update(updatedCalendar.toJson());
    } catch (e) {
      print('Error actualizando calendario: $e');
      rethrow;
    }
  }
  
  Future<void> addMember(String calendarId, String memberId) async {
    try {
      await _firestore.collection('calendars').doc(calendarId).update({
        'members': FieldValue.arrayUnion([memberId]),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      print('Error añadiendo miembro: $e');
      rethrow;
    }
  }
  
  Future<void> removeMember(String calendarId, String memberId) async {
    try {
      await _firestore.collection('calendars').doc(calendarId).update({
        'members': FieldValue.arrayRemove([memberId]),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      print('Error removiendo miembro: $e');
      rethrow;
    }
  }
  
  Future<AppUser?> findUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return AppUser.fromJson(query.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error buscando usuario por email: $e');
      return null;
    }
  }
  
  Future<List<AppUser>> getCalendarMembers(String calendarId) async {
    try {
      final calendar = await getCalendar(calendarId);
      if (calendar == null) return [];
      
      final members = <AppUser>[];
      for (final memberId in calendar.members) {
        final userDoc = await _firestore.collection('users').doc(memberId).get();
        if (userDoc.exists) {
          members.add(AppUser.fromJson(userDoc.data()!));
        }
      }
      
      return members;
    } catch (e) {
      print('Error obteniendo miembros del calendario: $e');
      return [];
    }
  }
}




