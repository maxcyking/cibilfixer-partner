import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction_model.dart' as transaction_model;
import '../models/user_model.dart';

class PayoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _transactionsCollection => _firestore.collection('transactions');

  Future<Map<String, dynamic>> processPayout({
    required String userId,
    required String userName,
    required String userEmail,
    required double amount,
    required DateTime payoutDateTime,
    required bool isFullPayout,
  }) async {
    try {
      print('🔄 Starting payout processing for user: $userId');
      print('💰 Payout amount: ₹${amount.toStringAsFixed(0)}');
      print('📅 Payout date: ${payoutDateTime.toIso8601String()}');
      print('🔄 Full payout: $isFullPayout');
      
      // Step 1: Get user data (outside transaction)
      final userDoc = await _usersCollection.doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      
      final user = UserModel.fromFirestore(userDoc);
      
      // Step 2: Validate payout amount
      if (amount <= 0) {
        throw Exception('Payout amount must be greater than 0');
      }
      
      if (amount > user.earnings) {
        throw Exception('Payout amount cannot exceed wallet balance (₹${user.earnings.toStringAsFixed(0)})');
      }
      
      // Step 3: Check if user has sufficient balance
      if (user.earnings <= 0) {
        throw Exception('User has no earnings to payout');
      }
      
      print('✅ Payout validation passed');
      print('📊 User current earnings: ₹${user.earnings.toStringAsFixed(0)}');
      print('💵 Payout amount: ₹${amount.toStringAsFixed(0)}');
      
      // Step 4: Process payout transaction
      return await _firestore.runTransaction<Map<String, dynamic>>((transaction) async {
        
        // Step 5: Create payout transaction
        final payoutTransactionRef = _transactionsCollection.doc();
        final payoutTransaction = transaction_model.Transaction(
          id: payoutTransactionRef.id,
          customerId: userId, // Using userId as customerId for payout
          customerName: userName,
          amount: amount,
          type: transaction_model.TransactionType.payout,
          status: transaction_model.TransactionStatus.completed,
          packageType: transaction_model.PackageType.basic, // Default package type for payouts
          referrerId: null,
          referrerName: null,
          commissionAmount: null,
          description: isFullPayout 
              ? 'Full payout of ₹${amount.toStringAsFixed(0)} to $userName'
              : 'Partial payout of ₹${amount.toStringAsFixed(0)} to $userName',
          createdAt: payoutDateTime,
          completedAt: payoutDateTime,
          metadata: {
            'userId': userId,
            'userEmail': userEmail,
            'payoutType': isFullPayout ? 'full' : 'partial',
            'walletBalanceBefore': user.earnings,
            'payoutMethod': 'admin_initiated',
            'processedAt': DateTime.now().toIso8601String(),
          },
        );
        
        transaction.set(payoutTransactionRef, payoutTransaction.toFirestore());
        print('💳 Payout transaction created: ${payoutTransaction.id}');
        
        // Step 6: Calculate new wallet balance
        final newEarnings = user.earnings - amount.toInt();
        
        // Step 7: Update user earnings
        transaction.update(userDoc.reference, {
          'earnings': newEarnings,
          'lastPayoutDate': payoutDateTime.toIso8601String(),
          'lastPayoutAmount': amount,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        
        print('👤 User earnings updated: ₹${user.earnings.toStringAsFixed(0)} → ₹${newEarnings.toStringAsFixed(0)}');
        
        final totalProcessingTime = DateTime.now().millisecondsSinceEpoch;
        print('✅ Payout processing completed successfully');
        print('⏱️ Total processing time: ${totalProcessingTime}ms');
        
        return {
          'success': true,
          'message': 'Payout processed successfully',
          'payoutAmount': amount,
          'newWalletBalance': newEarnings,
          'isFullPayout': isFullPayout,
          'payoutDateTime': payoutDateTime.toIso8601String(),
          'transactionId': payoutTransaction.id,
          'userId': userId,
          'userName': userName,
        };
      });
      
    } catch (e) {
      print('❌ Error in payout processing: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Get users with earnings (for selection)
  Future<List<UserModel>> getUsersWithEarnings() async {
    try {
      print('🔄 Fetching users with earnings...');
      
      final snapshot = await _usersCollection
          .where('earnings', isGreaterThan: 0)
          .get();
      
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
      
      print('✅ Found ${users.length} users with earnings');
      return users;
    } catch (e) {
      print('❌ Error fetching users with earnings: $e');
      return [];
    }
  }

  // Get payout history for a user
  Future<List<transaction_model.Transaction>> getUserPayoutHistory(String userId) async {
    try {
      print('🔄 Fetching payout history for user: $userId');
      
      final snapshot = await _transactionsCollection
          .where('customerId', isEqualTo: userId)
          .where('type', isEqualTo: transaction_model.TransactionType.payout.name)
          .orderBy('createdAt', descending: true)
          .get();
      
      final payouts = snapshot.docs
          .map((doc) => transaction_model.Transaction.fromFirestore(doc))
          .toList();
      
      print('✅ Found ${payouts.length} payouts for user');
      return payouts;
    } catch (e) {
      print('❌ Error fetching payout history: $e');
      return [];
    }
  }

  // Get all payouts (for admin view)
  Future<List<transaction_model.Transaction>> getAllPayouts() async {
    try {
      print('🔄 Fetching all payouts...');
      
      final snapshot = await _transactionsCollection
          .where('type', isEqualTo: transaction_model.TransactionType.payout.name)
          .orderBy('createdAt', descending: true)
          .limit(100) // Limit to last 100 payouts
          .get();
      
      final payouts = snapshot.docs
          .map((doc) => transaction_model.Transaction.fromFirestore(doc))
          .toList();
      
      print('✅ Found ${payouts.length} total payouts');
      return payouts;
    } catch (e) {
      print('❌ Error fetching all payouts: $e');
      return [];
    }
  }

  // Calculate total payouts for a date range
  Future<Map<String, dynamic>> getPayoutStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      print('🔄 Calculating payout statistics...');
      
      Query query = _transactionsCollection
          .where('type', isEqualTo: transaction_model.TransactionType.payout.name);
      
      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      final snapshot = await query.get();
      
      double totalAmount = 0.0;
      int totalPayouts = snapshot.docs.length;
      Set<String> uniqueUsers = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalAmount += (data['amount'] ?? 0.0).toDouble();
        uniqueUsers.add(data['customerId'] ?? '');
      }
      
      print('✅ Payout statistics calculated successfully');
      
      return {
        'totalAmount': totalAmount,
        'totalPayouts': totalPayouts,
        'uniqueUsers': uniqueUsers.length,
        'averageAmount': totalPayouts > 0 ? totalAmount / totalPayouts : 0.0,
      };
    } catch (e) {
      print('❌ Error calculating payout statistics: $e');
      return {
        'totalAmount': 0.0,
        'totalPayouts': 0,
        'uniqueUsers': 0,
        'averageAmount': 0.0,
      };
    }
  }
} 