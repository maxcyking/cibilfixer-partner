import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/commission_transaction_model.dart';

class CommissionTransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'commissions_transaction';

  // Get commission transactions for a specific user (referrerId)
  Future<List<CommissionTransaction>> getUserCommissionTransactions(String userId) async {
    try {
      print('Fetching commission transactions for user: $userId');
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('referrerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${querySnapshot.docs.length} commission transactions');
      
      return querySnapshot.docs
          .map((doc) => CommissionTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching commission transactions: $e');
      return [];
    }
  }

  // Get commission transactions stream for real-time updates
  Stream<List<CommissionTransaction>> getUserCommissionTransactionsStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('referrerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommissionTransaction.fromFirestore(doc))
            .toList());
  }

  // Get commission transactions by status
  Future<List<CommissionTransaction>> getUserCommissionTransactionsByStatus(
    String userId, 
    String status
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('referrerId', isEqualTo: userId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CommissionTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching commission transactions by status: $e');
      return [];
    }
  }

  // Get commission transactions by date range
  Future<List<CommissionTransaction>> getUserCommissionTransactionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('referrerId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CommissionTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching commission transactions by date range: $e');
      return [];
    }
  }

  // Get commission transaction statistics
  Future<Map<String, dynamic>> getCommissionStats(String userId) async {
    try {
      final transactions = await getUserCommissionTransactions(userId);
      
      final totalAmount = transactions.fold<double>(
        0.0, 
        (sum, transaction) => sum + transaction.amount
      );
      
      final totalCommission = transactions.fold<double>(
        0.0, 
        (sum, transaction) => sum + (transaction.commissionAmount ?? 0.0)
      );
      
      final completedTransactions = transactions
          .where((t) => t.status.toLowerCase() == 'completed')
          .length;
      
      final pendingTransactions = transactions
          .where((t) => t.status.toLowerCase() == 'pending')
          .length;
      
      // This month's stats
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final thisMonthTransactions = transactions.where((t) =>
          t.createdAt.isAfter(startOfMonth) ||
          t.createdAt.isAtSameMomentAs(startOfMonth)).toList();
      
      final thisMonthAmount = thisMonthTransactions.fold<double>(
        0.0, 
        (sum, transaction) => sum + transaction.amount
      );
      
      final thisMonthCommission = thisMonthTransactions.fold<double>(
        0.0, 
        (sum, transaction) => sum + (transaction.commissionAmount ?? 0.0)
      );

      return {
        'totalTransactions': transactions.length,
        'totalAmount': totalAmount,
        'totalCommission': totalCommission,
        'completedTransactions': completedTransactions,
        'pendingTransactions': pendingTransactions,
        'thisMonthTransactions': thisMonthTransactions.length,
        'thisMonthAmount': thisMonthAmount,
        'thisMonthCommission': thisMonthCommission,
      };
    } catch (e) {
      print('Error calculating commission stats: $e');
      return {
        'totalTransactions': 0,
        'totalAmount': 0.0,
        'totalCommission': 0.0,
        'completedTransactions': 0,
        'pendingTransactions': 0,
        'thisMonthTransactions': 0,
        'thisMonthAmount': 0.0,
        'thisMonthCommission': 0.0,
      };
    }
  }

  // Search commission transactions
  Future<List<CommissionTransaction>> searchCommissionTransactions(
    String userId, 
    String query
  ) async {
    try {
      final transactions = await getUserCommissionTransactions(userId);
      
      final searchQuery = query.toLowerCase();
      return transactions.where((transaction) {
        return transaction.customerName.toLowerCase().contains(searchQuery) ||
               transaction.customerId.toLowerCase().contains(searchQuery) ||
               transaction.description.toLowerCase().contains(searchQuery) ||
               transaction.status.toLowerCase().contains(searchQuery) ||
               transaction.packageType.toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      print('Error searching commission transactions: $e');
      return [];
    }
  }
} 