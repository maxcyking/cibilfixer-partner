import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/customer_model.dart';
import '../models/lead_model.dart';
import '../models/commission_transaction_model.dart';

class ReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get referred users by referral code
  Future<List<UserModel>> getReferredUsers(String referralCode) async {
    try {
      print('Fetching referred users for referral code: $referralCode');
      
      final querySnapshot = await _firestore
          .collection('users')
          .where('referredByCode', isEqualTo: referralCode)
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${querySnapshot.docs.length} referred users');
      
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching referred users: $e');
      return [];
    }
  }

  // Get customers referred by the user
  Future<List<Customer>> getReferredCustomers(String referralCode) async {
    try {
      print('Fetching referred customers for referral code: $referralCode');
      
      // Create two separate queries to handle two-level referral system
      // Query 1: Direct referrals (referralCode field)
      Query query1 = _firestore.collection('customers')
          .where('referralCode', isEqualTo: referralCode);
      
      // Query 2: Indirect referrals (referralCode1 field)
      Query query2 = _firestore.collection('customers')
          .where('referralCode1', isEqualTo: referralCode);
      
      // Execute both queries in parallel
      final results = await Future.wait([
        query1.orderBy('createdAt', descending: true).get(),
        query2.orderBy('createdAt', descending: true).get(),
      ]);
      
      final directReferralsSnapshot = results[0];
      final indirectReferralsSnapshot = results[1];
      
      print('📊 Direct referrals found: ${directReferralsSnapshot.docs.length}');
      print('📊 Indirect referrals found: ${indirectReferralsSnapshot.docs.length}');
      
      // Combine results and remove duplicates
      final allCustomerDocs = <String, QueryDocumentSnapshot>{};
      
      // Add direct referrals
      for (final doc in directReferralsSnapshot.docs) {
        allCustomerDocs[doc.id] = doc;
      }
      
      // Add indirect referrals (will overwrite if duplicate, but that's fine)
      for (final doc in indirectReferralsSnapshot.docs) {
        allCustomerDocs[doc.id] = doc;
      }
      
      print('📊 Total unique customers: ${allCustomerDocs.length}');
      
      // Convert to Customer objects and sort by creation date
      final customers = allCustomerDocs.values
          .map((doc) => Customer.fromFirestore(doc))
          .toList();
      
      // Sort by creation date (newest first)
      customers.sort((a, b) {
        final dateA = a.createdAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      
      print('👥 Found ${customers.length} referred customers (direct + indirect)');
      return customers;
    } catch (e) {
      print('Error fetching referred customers: $e');
      return [];
    }
  }

  // Get leads referred by the user
  Future<List<Lead>> getReferredLeads(String referralCode) async {
    try {
      print('Fetching referred leads for referral code: $referralCode');
      
      // Create two separate queries to handle two-level referral system
      // Query 1: Direct referrals (referralCode field)
      Query query1 = _firestore.collection('creditRequests')
          .where('referralCode', isEqualTo: referralCode);
      
      // Query 2: Indirect referrals (referralCode1 field)
      Query query2 = _firestore.collection('creditRequests')
          .where('referralCode1', isEqualTo: referralCode);
      
      // Execute both queries in parallel
      final results = await Future.wait([
        query1.orderBy('createdAt', descending: true).get(),
        query2.orderBy('createdAt', descending: true).get(),
      ]);
      
      final directReferralsSnapshot = results[0];
      final indirectReferralsSnapshot = results[1];
      
      print('📊 Direct referrals found: ${directReferralsSnapshot.docs.length}');
      print('📊 Indirect referrals found: ${indirectReferralsSnapshot.docs.length}');
      
      // Combine results and remove duplicates
      final allLeadDocs = <String, QueryDocumentSnapshot>{};
      
      // Add direct referrals
      for (final doc in directReferralsSnapshot.docs) {
        allLeadDocs[doc.id] = doc;
      }
      
      // Add indirect referrals (will overwrite if duplicate, but that's fine)
      for (final doc in indirectReferralsSnapshot.docs) {
        allLeadDocs[doc.id] = doc;
      }
      
      print('📊 Total unique leads: ${allLeadDocs.length}');
      
      // Convert to Lead objects and sort by creation date
      final leads = allLeadDocs.values
          .map((doc) => Lead.fromFirestore(doc))
          .toList();
      
      // Sort by creation date (newest first)
      leads.sort((a, b) {
        final dateA = a.createdAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      
      print('📋 Found ${leads.length} referred leads (direct + indirect)');
      return leads;
    } catch (e) {
      print('Error fetching referred leads: $e');
      return [];
    }
  }

  // Get commission transactions for the user
  Future<List<CommissionTransaction>> getCommissionTransactions(String userId) async {
    try {
      print('Fetching commission transactions for user: $userId');
      
      final querySnapshot = await _firestore
          .collection('commissions_transaction')
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

  // Get referral statistics
  Future<Map<String, dynamic>> getReferralStats(String referralCode, String userId) async {
    try {
      print('Calculating referral stats for: $referralCode');
      
      // Fetch all referral data in parallel
      final results = await Future.wait([
        getReferredUsers(referralCode),
        getReferredCustomers(referralCode),
        getReferredLeads(referralCode),
        getCommissionTransactions(userId),
      ]);

      final referredUsers = results[0] as List<UserModel>;
      final referredCustomers = results[1] as List<Customer>;
      final referredLeads = results[2] as List<Lead>;
      final commissionTransactions = results[3] as List<CommissionTransaction>;

      // Calculate stats
      final totalReferrals = referredUsers.length;
      final totalCustomers = referredCustomers.length;
      final totalLeads = referredLeads.length;
      
      // Calculate earnings
      double totalEarnings = 0.0;
      double pendingEarnings = 0.0;
      double completedEarnings = 0.0;
      
      for (var transaction in commissionTransactions) {
        if (transaction.status.toLowerCase() == 'completed') {
          completedEarnings += transaction.amount;
        } else if (transaction.status.toLowerCase() == 'pending') {
          pendingEarnings += transaction.amount;
        }
        totalEarnings += transaction.amount;
      }

      // Calculate customer conversions
      final convertedCustomers = referredCustomers
          .where((c) => c.paymentStatus.toLowerCase().contains('payment done'))
          .length;
      
      final conversionRate = totalLeads > 0 
          ? (convertedCustomers / totalLeads * 100) 
          : 0.0;

      // Calculate this month's stats
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month);
      
      final thisMonthCustomers = referredCustomers
          .where((c) => c.createdAtDate?.isAfter(thisMonth) ?? false)
          .length;
      
      final thisMonthEarnings = commissionTransactions
          .where((t) => t.createdAt.isAfter(thisMonth) && 
                       t.status.toLowerCase() == 'completed')
          .fold(0.0, (sum, t) => sum + t.amount);

      return {
        'totalReferrals': totalReferrals,
        'totalCustomers': totalCustomers,
        'totalLeads': totalLeads,
        'convertedCustomers': convertedCustomers,
        'conversionRate': conversionRate,
        'totalEarnings': totalEarnings,
        'completedEarnings': completedEarnings,
        'pendingEarnings': pendingEarnings,
        'thisMonthCustomers': thisMonthCustomers,
        'thisMonthEarnings': thisMonthEarnings,
        'totalCommissionTransactions': commissionTransactions.length,
      };
    } catch (e) {
      print('Error calculating referral stats: $e');
      return {
        'totalReferrals': 0,
        'totalCustomers': 0,
        'totalLeads': 0,
        'convertedCustomers': 0,
        'conversionRate': 0.0,
        'totalEarnings': 0.0,
        'completedEarnings': 0.0,
        'pendingEarnings': 0.0,
        'thisMonthCustomers': 0,
        'thisMonthEarnings': 0.0,
        'totalCommissionTransactions': 0,
      };
    }
  }

  // Get recent referral activities
  Future<List<Map<String, dynamic>>> getRecentActivities(String referralCode, String userId) async {
    try {
      print('Fetching recent referral activities');
      
      // Get recent activities from multiple sources
      final activities = <Map<String, dynamic>>[];
      
      // Recent customers
      final recentCustomers = await getReferredCustomers(referralCode);
      for (var customer in recentCustomers.take(5)) {
        activities.add({
          'type': 'customer',
          'title': 'New Customer Registered',
          'description': '${customer.fullName} joined as a customer',
          'date': customer.createdAtDate ?? DateTime.now(),
          'icon': 'person_add',
          'data': customer,
        });
      }
      
      // Recent commission transactions
      final recentCommissions = await getCommissionTransactions(userId);
      for (var transaction in recentCommissions.take(5)) {
        activities.add({
          'type': 'commission',
          'title': 'Commission Earned',
          'description': 'Earned ₹${transaction.amount.toStringAsFixed(2)} from ${transaction.customerName}',
          'date': transaction.createdAt,
          'icon': 'payments',
          'data': transaction,
        });
      }
      
      // Recent leads
      final recentLeads = await getReferredLeads(referralCode);
      for (var lead in recentLeads.take(3)) {
        activities.add({
          'type': 'lead',
          'title': 'New Lead Generated',
          'description': '${lead.fullName} submitted a credit request',
          'date': lead.createdAtDate ?? DateTime.now(),
          'icon': 'trending_up',
          'data': lead,
        });
      }
      
      // Sort by date (newest first)
      activities.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      
      return activities.take(10).toList();
    } catch (e) {
      print('Error fetching recent activities: $e');
      return [];
    }
  }

  // Stream for real-time referral stats
  Stream<Map<String, dynamic>> getReferralStatsStream(String referralCode, String userId) {
    return Stream.periodic(const Duration(minutes: 5))
        .asyncMap((_) => getReferralStats(referralCode, userId));
  }
} 