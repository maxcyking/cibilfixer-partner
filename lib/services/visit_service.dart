import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/visit_model.dart';

class VisitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'visits';

  // Add a new visit
  Future<bool> addVisit(Visit visit) async {
    try {
      await _firestore.collection(_collection).add(visit.toMap());
      print('Visit added successfully');
      return true;
    } catch (e) {
      print('Error adding visit: $e');
      return false;
    }
  }

  // Get all visits for a specific user
  Future<List<Visit>> getUserVisits(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('dateOfVisit', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Visit.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching user visits: $e');
      return [];
    }
  }

  // Get all visits (for admin)
  Future<List<Visit>> getAllVisits() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('dateOfVisit', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Visit.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching all visits: $e');
      return [];
    }
  }

  // Update a visit
  Future<bool> updateVisit(String visitId, Visit updatedVisit) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(visitId)
          .update(updatedVisit.toMap());
      print('Visit updated successfully');
      return true;
    } catch (e) {
      print('Error updating visit: $e');
      return false;
    }
  }

  // Delete a visit
  Future<bool> deleteVisit(String visitId) async {
    try {
      await _firestore.collection(_collection).doc(visitId).delete();
      print('Visit deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting visit: $e');
      return false;
    }
  }

  // Get visits by date range
  Future<List<Visit>> getVisitsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('dateOfVisit', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('dateOfVisit', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('dateOfVisit', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Visit.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching visits by date range: $e');
      return [];
    }
  }

  // Get visits stream for real-time updates
  Stream<List<Visit>> getUserVisitsStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('dateOfVisit', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Visit.fromFirestore(doc))
            .toList());
  }

  // Search visits by name or firm
  Future<List<Visit>> searchVisits(String userId, String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final visits = querySnapshot.docs
          .map((doc) => Visit.fromFirestore(doc))
          .toList();

      // Filter results based on search query
      return visits.where((visit) {
        final searchQuery = query.toLowerCase();
        return visit.name.toLowerCase().contains(searchQuery) ||
               visit.firmCompanyName.toLowerCase().contains(searchQuery) ||
               visit.village.toLowerCase().contains(searchQuery) ||
               visit.tehsilCity.toLowerCase().contains(searchQuery) ||
               visit.district.toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      print('Error searching visits: $e');
      return [];
    }
  }

  // Get visit statistics
  Future<Map<String, int>> getVisitStats(String userId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      
      final allVisits = await getUserVisits(userId);
      
      final thisMonthVisits = allVisits.where((visit) =>
          visit.dateOfVisit.isAfter(startOfMonth) ||
          visit.dateOfVisit.isAtSameMomentAs(startOfMonth)).length;
      
      final thisWeekVisits = allVisits.where((visit) =>
          visit.dateOfVisit.isAfter(startOfWeek) ||
          visit.dateOfVisit.isAtSameMomentAs(startOfWeek)).length;
      
      final todayVisits = allVisits.where((visit) =>
          visit.dateOfVisit.day == now.day &&
          visit.dateOfVisit.month == now.month &&
          visit.dateOfVisit.year == now.year).length;

      return {
        'total': allVisits.length,
        'thisMonth': thisMonthVisits,
        'thisWeek': thisWeekVisits,
        'today': todayVisits,
      };
    } catch (e) {
      print('Error getting visit stats: $e');
      return {
        'total': 0,
        'thisMonth': 0,
        'thisWeek': 0,
        'today': 0,
      };
    }
  }
} 