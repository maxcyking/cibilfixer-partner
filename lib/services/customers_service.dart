import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import '../models/package_model.dart';

class CustomersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get customers filtered by referral code and package information
  Future<List<Customer>> getCustomers({
    String? statusFilter,
    String? searchQuery,
    String? referralCode, // Add referral code filter
  }) async {
    try {
      print('🔍 Fetching customers for referral code: $referralCode');
      
      // If no referral code provided, return empty list
      if (referralCode == null || referralCode.isEmpty) {
        print('⚠️ No referral code provided, returning empty list');
        return [];
      }
      
      // Create two separate queries to handle two-level referral system
      // Query 1: Direct referrals (referralCode field)
      Query query1 = _firestore.collection('customers')
          .where('referralCode', isEqualTo: referralCode);
      
      // Query 2: Indirect referrals (referralCode1 field)
      Query query2 = _firestore.collection('customers')
          .where('referralCode1', isEqualTo: referralCode);
      
      // Apply status filter if provided
      if (statusFilter != null && statusFilter.isNotEmpty) {
        query1 = query1.where('status', isEqualTo: statusFilter);
        query2 = query2.where('status', isEqualTo: statusFilter);
      }
      
      // Execute both queries in parallel
      final results = await Future.wait([
        query1.get(),
        query2.get(),
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
      
      final customers = <Customer>[];
      
      // Fetch package data for each customer
      for (final doc in allCustomerDocs.values) {
        final customer = Customer.fromFirestore(doc);
        
        // If customer has a package assigned, fetch package details
        if (customer.packageId != null && customer.packageId!.isNotEmpty) {
          final packageDoc = await _firestore.collection('packages').doc(customer.packageId!).get();
          if (packageDoc.exists) {
            final package = Package.fromFirestore(packageDoc);
            final updatedCustomer = customer.copyWith(
              packageName: package.name,
              packagePrice: package.price,
            );
            customers.add(updatedCustomer);
          } else {
            customers.add(customer);
          }
        } else {
          customers.add(customer);
        }
      }
      
      // Apply search filter locally
      List<Customer> filteredCustomers = customers;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        filteredCustomers = customers.where((customer) {
          final searchLower = searchQuery.toLowerCase();
          return customer.fullName.toLowerCase().contains(searchLower) ||
                 customer.customerId.toLowerCase().contains(searchLower) ||
                 customer.mobile.contains(searchQuery) ||
                 customer.aadhar.contains(searchQuery) ||
                 customer.district.toLowerCase().contains(searchLower) ||
                 customer.state.toLowerCase().contains(searchLower) ||
                 (customer.email?.toLowerCase().contains(searchLower) ?? false);
        }).toList();
      }
      
      // Sort by creation date (newest first)
      filteredCustomers.sort((a, b) {
        final dateA = a.createdAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      
      print('👥 Fetched ${filteredCustomers.length} customers with two-level referral filtering');
      return filteredCustomers;
    } catch (e) {
      print('❌ Error fetching customers: $e');
      return [];
    }
  }

  // Update customer status - DISABLED for read-only access
  Future<bool> updateCustomerStatus(String customerId, String newStatus, {String? remark}) async {
    print('🚫 Customer status updates are disabled for this user role');
    return false;
    
    /* DISABLED FOR READ-ONLY ACCESS
    try {
      print('🔄 Updating customer $customerId status to $newStatus');
      
      final updateData = {
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (remark != null && remark.isNotEmpty) {
        updateData['remark'] = remark;
      }
      
      await _firestore.collection('customers').doc(customerId).update(updateData);
      
      print('✅ Customer status updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating customer status: $e');
      return false;
    }
    */
  }

  // Update customer payment status - DISABLED for read-only access
  Future<bool> updateCustomerPaymentStatus(String customerId, String newPaymentStatus, {String? remark}) async {
    print('🚫 Customer payment status updates are disabled for this user role');
    return false;
    
    /* DISABLED FOR READ-ONLY ACCESS
    try {
      print('🔄 Updating customer $customerId payment status to $newPaymentStatus');
      
      final updateData = {
        'paymentStatus': newPaymentStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (remark != null && remark.isNotEmpty) {
        updateData['remark'] = remark;
      }
      
      await _firestore.collection('customers').doc(customerId).update(updateData);
      
      print('✅ Customer payment status updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating customer payment status: $e');
      return false;
    }
    */
  }

  // Update customer package - DISABLED for read-only access
  Future<bool> updateCustomerPackage({
    required String customerId,
    required String packageId,
    required String packageName,
    required double packagePrice,
    double? currentPackagePrice,
  }) async {
    print('🚫 Customer package updates are disabled for this user role');
    return false;
    
    /* DISABLED FOR READ-ONLY ACCESS
    try {
      print('🔄 Updating customer package...');
      print('📦 Customer ID: $customerId');
      print('📦 New Package: $packageName (₹${packagePrice.toStringAsFixed(0)})');
      print('📦 Current Package Price: ₹${(currentPackagePrice ?? 0.0).toStringAsFixed(0)}');
      
      // Validate that this is not a downgrade
      if (currentPackagePrice != null && packagePrice < currentPackagePrice) {
        print('❌ Package downgrade attempted - not allowed');
        throw Exception('Package downgrades are not allowed. You can only upgrade to higher-tier packages.');
      }
      
      // Calculate amount due adjustment
      final currentAmount = currentPackagePrice ?? 0.0;
      final priceDifference = packagePrice - currentAmount;
      
      print('💰 Price difference: ₹${priceDifference.toStringAsFixed(0)}');
      
      // Get current customer data
      final customerQuery = await _firestore
          .collection('customers')
          .where('customerId', isEqualTo: customerId)
          .limit(1)
          .get();
      
      if (customerQuery.docs.isEmpty) {
        print('❌ Customer not found');
        return false;
      }
      
      final customerDoc = customerQuery.docs.first;
      final customerData = customerDoc.data();
      final currentAmountDue = (customerData['amountDue'] as num?)?.toDouble() ?? 0.0;
      
      // Calculate new amount due
      final newAmountDue = currentAmountDue + priceDifference;
      
      print('📊 Current amount due: ₹${currentAmountDue.toStringAsFixed(0)}');
      print('📊 New amount due: ₹${newAmountDue.toStringAsFixed(0)}');
      
      // Update customer package and amount due
      await customerDoc.reference.update({
        'packageId': packageId,
        'packageName': packageName,
        'packagePrice': packagePrice,
        'amountDue': newAmountDue > 0 ? newAmountDue : 0.0,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      print('✅ Customer package updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating customer package: $e');
      return false;
    }
    */
  }

  // Get customer statistics
  Future<Map<String, int>> getCustomerStats() async {
    try {
      final snapshot = await _firestore.collection('customers').get();
      final customers = snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList();
      
      final stats = <String, int>{};
      
      for (final status in CustomerStatus.values) {
        stats[status.value] = customers.where((customer) => customer.status == status.value).length;
      }
      
      stats['total'] = customers.length;
      
      return stats;
    } catch (e) {
      print('❌ Error fetching customer stats: $e');
      return {};
    }
  }

  // Add remark to customer
  Future<bool> addRemarkToCustomer(String customerId, String remark) async {
    try {
      await _firestore.collection('customers').doc(customerId).update({
        'remark': remark,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('❌ Error adding remark: $e');
      return false;
    }
  }

  // Get customer by ID
  Future<Customer?> getCustomerById(String customerId) async {
    try {
      final doc = await _firestore.collection('customers').doc(customerId).get();
      if (doc.exists) {
        return Customer.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching customer: $e');
      return null;
    }
  }

  // Update customer details
  Future<bool> updateCustomerDetails(String customerId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection('customers').doc(customerId).update(updates);
      return true;
    } catch (e) {
      print('❌ Error updating customer details: $e');
      return false;
    }
  }

  // Get customers by status for pipeline view
  Future<Map<String, List<Customer>>> getCustomersPipeline() async {
    try {
      final customers = await getCustomers();
      final pipeline = <String, List<Customer>>{};
      
      for (final status in CustomerStatus.values) {
        pipeline[status.value] = customers.where((c) => c.status == status.value).toList();
      }
      
      return pipeline;
    } catch (e) {
      print('❌ Error fetching customers pipeline: $e');
      return {};
    }
  }
} 