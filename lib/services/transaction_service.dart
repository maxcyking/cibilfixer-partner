import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart' as tx;
import '../models/wallet_model.dart';
import '../models/customer_model.dart';
import '../models/user_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _transactionsCollection => _firestore.collection('transactions');
  CollectionReference get _walletsCollection => _firestore.collection('wallets');
  CollectionReference get _customersCollection => _firestore.collection('customers');
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Main method to mark payment as done and handle all related operations
  Future<Map<String, dynamic>> markPaymentDone({
    required String customerId,
    required String adminId,
    required String adminName,
    String? packageId,
    double? packageAmount,
  }) async {
    try {
      print('Starting payment processing for customer: $customerId');
      
      // Step 1: Get customer data (outside transaction)
      final customerQuery = await _customersCollection
          .where('customerId', isEqualTo: customerId)
          .limit(1)
          .get();
      
      if (customerQuery.docs.isEmpty) {
        throw Exception('Customer not found');
      }
      
      final customerDoc = customerQuery.docs.first;
      final customer = Customer.fromFirestore(customerDoc);
      
      // Step 2: Check if payment is already done
      if (customer.paymentStatus.toLowerCase() == 'full payment done' && customer.amountDue <= 0) {
        throw Exception('Payment already marked as done for this customer');
      }
      
      // Step 3: Determine payment amount
      double paymentAmount = 0.0;
      
      // First check if there's an amount due
      if (customer.amountDue > 0) {
        paymentAmount = customer.amountDue;
      } 
      // If no amount due, check if customer has a package assigned
      else if (customer.hasPackage && customer.packagePrice != null && customer.packagePrice! > 0) {
        paymentAmount = customer.packagePrice!;
      }
      // Fallback: If no package price, determine from issue
      else if (customer.issue.isNotEmpty) {
        final packageType = tx.Transaction.getPackageFromIssue(customer.issue);
        paymentAmount = tx.Transaction.packagePrices[packageType] ?? 0.0;
      }
      
      if (paymentAmount <= 0) {
        throw Exception('Unable to determine payment amount. Please assign a package to this customer first.');
      }
      
      print('💰 Payment amount determined: ₹${paymentAmount.toStringAsFixed(0)}');
      print('📊 Customer amountDue: ₹${customer.amountDue.toStringAsFixed(0)}');
      print('📦 Customer packagePrice: ₹${(customer.packagePrice ?? 0.0).toStringAsFixed(0)}');
      
      // Step 4: Pre-fetch referrer data if referral code exists (outside transaction)
      UserModel? referrer;
      Wallet? referrerWallet;
      
      if (customer.referralCode.isNotEmpty) {
        final referrerQuery = await _usersCollection
            .where('referralCode', isEqualTo: customer.referralCode)
            .limit(1)
            .get();
        
        if (referrerQuery.docs.isNotEmpty) {
          referrer = UserModel.fromFirestore(referrerQuery.docs.first);
          
          // Get or create referrer's wallet
          final walletDoc = await _walletsCollection.doc(referrer.uid).get();
          if (walletDoc.exists) {
            referrerWallet = Wallet.fromFirestore(walletDoc);
          } else {
            referrerWallet = Wallet.createNew(
              userId: referrer.uid,
              userName: referrer.fullName,
            );
          }
        }
      }
      
      // Use Firestore transaction for atomicity
      return await _firestore.runTransaction<Map<String, dynamic>>((transaction) async {
        
        // Step 5: Determine package and commission
        tx.PackageType packageType;
        double amount = paymentAmount;
        
        if (customer.packageId != null && customer.packageId!.isNotEmpty) {
          // Use assigned package information
          packageType = tx.PackageType.premium; // For assigned packages
        } else {
          // Fall back to issue-based package determination
          packageType = tx.Transaction.getPackageFromIssue(customer.issue);
          amount = tx.Transaction.packagePrices[packageType]!;
        }
        
        final commissionAmount = amount * tx.Transaction.commissionRate;
        
        // Step 6: Create payment transaction
        final paymentTransactionRef = _transactionsCollection.doc();
        final paymentTransaction = tx.Transaction(
          id: paymentTransactionRef.id,
          customerId: customerId,
          customerName: customer.fullName,
          amount: amount,
          type: tx.TransactionType.payment,
          status: tx.TransactionStatus.completed,
          packageType: packageType,
          referrerId: customer.referralCode.isNotEmpty ? customer.referralCode : null,
          referrerName: referrer?.fullName,
          commissionAmount: customer.referralCode.isNotEmpty ? commissionAmount : null,
          description: customer.hasPackage 
              ? 'Payment for ${customer.packageDisplayName}'
              : 'Payment for ${packageType.name} package',
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
          metadata: {
            'processedBy': adminId,
            'processedByName': adminName,
            'packageId': customer.packageId,
            'packageName': customer.packageDisplayName,
            'amountDueBefore': customer.amountDue,
            'amountPaid': amount,
          },
        );
        
        // Step 7: Update customer payment status and amount due
        final newAmountDue = customer.amountDue - amount;
        final isPaymentComplete = newAmountDue <= 0;
        
        transaction.update(_customersCollection.doc(customer.id), {
          'paymentStatus': isPaymentComplete ? 'FULL PAYMENT DONE' : 'PARTIAL PAYMENT',
          'amountDue': newAmountDue > 0 ? newAmountDue : 0.0,
          'updatedAt': Timestamp.now(),
        });
        
        // Step 8: Save payment transaction
        transaction.set(paymentTransactionRef, paymentTransaction.toFirestore());
        
        // Step 9: Handle referral commission if exists
        String? referrerName;
        if (referrer != null && referrerWallet != null) {
          // Update referrer's wallet
          final updatedWallet = referrerWallet.copyWith(
            balance: referrerWallet.balance + commissionAmount,
            totalEarned: referrerWallet.totalEarned + commissionAmount,
            referralCount: referrerWallet.referralCount + 1,
            updatedAt: DateTime.now(),
          );
          
          // Save updated wallet
          transaction.set(_walletsCollection.doc(referrer.uid), updatedWallet.toFirestore());
          
          // Create commission transaction
          final commissionTransactionRef = _transactionsCollection.doc();
          final commissionTransaction = tx.Transaction(
            id: commissionTransactionRef.id,
            customerId: customerId,
            customerName: customer.fullName,
            amount: commissionAmount,
            type: tx.TransactionType.commission,
            status: tx.TransactionStatus.completed,
            packageType: packageType,
            referrerId: referrer.uid,
            referrerName: referrer.fullName,
            commissionAmount: commissionAmount,
            description: 'Referral commission for ${customer.fullName}',
            createdAt: DateTime.now(),
            completedAt: DateTime.now(),
            metadata: {
              'originalAmount': amount,
              'commissionRate': tx.Transaction.commissionRate,
              'processedBy': adminId,
              'processedByName': adminName,
              'paymentTransactionId': paymentTransactionRef.id,
            },
          );
          
          transaction.set(commissionTransactionRef, commissionTransaction.toFirestore());
          referrerName = referrer.fullName;
          
          print('Commission processed: $commissionAmount for ${referrer.fullName}');
        }
        
        print('Payment processed successfully for customer: $customerId');
        
        return {
          'success': true,
          'message': isPaymentComplete 
              ? 'Payment completed successfully'
              : 'Partial payment processed successfully',
          'transactionId': paymentTransactionRef.id,
          'amount': amount,
          'amountDueBefore': customer.amountDue,
          'amountDueAfter': newAmountDue > 0 ? newAmountDue : 0.0,
          'isPaymentComplete': isPaymentComplete,
          'packageType': packageType.name,
          'packageId': customer.packageId,
          'packageName': customer.packageDisplayName,
          'commissionPaid': customer.referralCode.isNotEmpty ? commissionAmount : 0.0,
          'referrerName': referrerName,
        };
        
      });
      
    } catch (e) {
      print('Error in markPaymentDone: $e');
      return {
        'success': false,
        'message': 'Failed to process payment: ${e.toString()}',
      };
    }
  }

  /// Get all transactions with pagination
  Future<List<tx.Transaction>> getTransactions({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    tx.TransactionType? type,
    tx.TransactionStatus? status,
  }) async {
    try {
      Query query = _transactionsCollection.orderBy('createdAt', descending: true);
      
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      query = query.limit(limit);
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) => tx.Transaction.fromFirestore(doc)).toList();
      
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  /// Get transactions for a specific customer
  Future<List<tx.Transaction>> getCustomerTransactions(String customerId) async {
    try {
      final querySnapshot = await _transactionsCollection
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) => tx.Transaction.fromFirestore(doc)).toList();
      
    } catch (e) {
      print('Error fetching customer transactions: $e');
      return [];
    }
  }

  /// Get wallet for a user
  Future<Wallet?> getUserWallet(String userId) async {
    try {
      final walletDoc = await _walletsCollection.doc(userId).get();
      
      if (walletDoc.exists) {
        return Wallet.fromFirestore(walletDoc);
      }
      
      return null;
      
    } catch (e) {
      print('Error fetching wallet: $e');
      return null;
    }
  }

  /// Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStats() async {
    try {
      final allTransactions = await _transactionsCollection.get();
      
      double totalRevenue = 0.0;
      double totalCommissions = 0.0;
      int totalTransactions = 0;
      int completedPayments = 0;
      
      for (var doc in allTransactions.docs) {
        final transaction = tx.Transaction.fromFirestore(doc);
        
        if (transaction.status == tx.TransactionStatus.completed) {
          if (transaction.type == tx.TransactionType.payment) {
            totalRevenue += transaction.amount;
            completedPayments++;
          } else if (transaction.type == tx.TransactionType.commission) {
            totalCommissions += transaction.amount;
          }
          totalTransactions++;
        }
      }
      
      return {
        'totalRevenue': totalRevenue,
        'totalCommissions': totalCommissions,
        'totalTransactions': totalTransactions,
        'completedPayments': completedPayments,
        'netRevenue': totalRevenue - totalCommissions,
      };
      
    } catch (e) {
      print('Error fetching transaction stats: $e');
      return {
        'totalRevenue': 0.0,
        'totalCommissions': 0.0,
        'totalTransactions': 0,
        'completedPayments': 0,
        'netRevenue': 0.0,
      };
    }
  }

  /// Check if customer payment can be processed
  Future<bool> canProcessPayment(String customerId) async {
    try {
      final customerDoc = await _customersCollection.doc(customerId).get();
      
      if (!customerDoc.exists) {
        return false;
      }
      
      final customer = Customer.fromFirestore(customerDoc);
      
      // Check if payment is already done
      return customer.paymentStatus.toLowerCase() != 'full payment done';
      
    } catch (e) {
      print('Error checking payment status: $e');
      return false;
    }
  }

  // Enhanced payment processing with payment details
  Future<Map<String, dynamic>> markPaymentDoneWithDetails({
    required String customerId,
    required String adminId,
    required String adminName,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
  }) async {
    try {
      print('🔄 Starting enhanced payment processing for customer: $customerId');
      print('💰 Payment amount: ₹${amount.toStringAsFixed(0)}');
      print('📅 Payment date: ${paymentDate.toIso8601String()}');
      print('💳 Payment method: $paymentMethod');
      
      // Step 1: Get customer data (outside transaction)
      final customerQuery = await _customersCollection
          .where('customerId', isEqualTo: customerId)
          .limit(1)
          .get();
      
      if (customerQuery.docs.isEmpty) {
        throw Exception('Customer not found');
      }
      
      final customerDoc = customerQuery.docs.first;
      final customer = Customer.fromFirestore(customerDoc);
      
      // Step 2: Validate payment amount
      if (amount <= 0) {
        throw Exception('Payment amount must be greater than 0');
      }
      
      if (amount > customer.amountDue) {
        throw Exception('Payment amount cannot exceed amount due (₹${customer.amountDue.toStringAsFixed(0)})');
      }
      
      // Step 3: Check if payment is already fully done
      if (customer.paymentStatus.toLowerCase() == 'full payment done' && customer.amountDue <= 0) {
        throw Exception('Payment already marked as done for this customer');
      }
      
      print('✅ Payment validation passed');
      print('📊 Customer current amountDue: ₹${customer.amountDue.toStringAsFixed(0)}');
      print('💵 Payment amount being processed: ₹${amount.toStringAsFixed(0)}');
      
      // Step 4: Pre-fetch referrer data if referral code exists (outside transaction)
      UserModel? referrer;
      if (customer.referralCode.isNotEmpty) {
        final referrerSnapshot = await _usersCollection
            .where('myReferralCode', isEqualTo: customer.referralCode)
            .limit(1)
            .get();
        
        if (referrerSnapshot.docs.isNotEmpty) {
          referrer = UserModel.fromFirestore(referrerSnapshot.docs.first);
          print('👤 Referrer found: ${referrer.fullName}');
        }
      }
      
      // Step 5: Process transaction
      return await _firestore.runTransaction<Map<String, dynamic>>((transaction) async {
        
        // Step 6: Determine package and commission
        tx.PackageType packageType;
        
        if (customer.packageId != null && customer.packageId!.isNotEmpty) {
          // Use assigned package information
          packageType = tx.PackageType.premium; // For assigned packages
        } else {
          // Fall back to issue-based package determination
          packageType = tx.Transaction.getPackageFromIssue(customer.issue);
        }
        
        final commissionAmount = amount * tx.Transaction.commissionRate;
        
        // Step 7: Create payment transaction
        final paymentTransactionRef = _transactionsCollection.doc();
        final paymentTransaction = tx.Transaction(
          id: paymentTransactionRef.id,
          customerId: customerId,
          customerName: customer.fullName,
          amount: amount,
          type: tx.TransactionType.payment,
          status: tx.TransactionStatus.completed,
          packageType: packageType,
          referrerId: customer.referralCode.isNotEmpty ? customer.referralCode : null,
          referrerName: referrer?.fullName,
          commissionAmount: customer.referralCode.isNotEmpty ? commissionAmount : null,
          description: 'Payment of ₹${amount.toStringAsFixed(0)} via $paymentMethod for ${customer.packageDisplayName}',
          createdAt: paymentDate, // Use provided payment date
          completedAt: paymentDate, // Use provided payment date
          metadata: {
            'processedBy': adminId,
            'processedByName': adminName,
            'paymentMethod': paymentMethod,
            'packageId': customer.packageId,
            'packageName': customer.packageDisplayName,
            'amountDueBefore': customer.amountDue,
            'amountPaid': amount,
            'isPartialPayment': amount < customer.amountDue,
          },
        );
        
        transaction.set(paymentTransactionRef, paymentTransaction.toFirestore());
        print('💳 Payment transaction created: ${paymentTransaction.id}');
        
        // Step 8: Calculate new amount due and payment status
        final newAmountDue = customer.amountDue - amount;
        final isFullPayment = newAmountDue <= 0;
        
        String newPaymentStatus;
        if (isFullPayment) {
          newPaymentStatus = 'FULL PAYMENT DONE';
        } else if (amount < customer.amountDue) {
          newPaymentStatus = 'PARTIAL PAYMENT';
        } else {
          newPaymentStatus = customer.paymentStatus; // Keep existing status
        }
        
        // Step 9: Update customer document
        final customerUpdateData = {
          'paymentStatus': newPaymentStatus,
          'amountDue': newAmountDue > 0 ? newAmountDue : 0.0,
          'lastPaymentDate': paymentDate.toIso8601String(),
          'lastPaymentMethod': paymentMethod,
          'lastPaymentAmount': amount,
          'updatedAt': DateTime.now().toIso8601String(),
        };
        
        // If full payment, also update general status
        if (isFullPayment) {
          customerUpdateData['status'] = 'PAYMENT COMPLETED';
        }
        
        transaction.update(customerDoc.reference, customerUpdateData);
        print('👤 Customer updated: paymentStatus = $newPaymentStatus, amountDue = ₹${newAmountDue.toStringAsFixed(0)}');
        
        // Step 10: Create commission transaction if referrer exists
        if (customer.referralCode.isNotEmpty && referrer != null) {
          final commissionTransactionRef = _transactionsCollection.doc();
          final commissionTransaction = tx.Transaction(
            id: commissionTransactionRef.id,
            customerId: customerId,
            customerName: customer.fullName,
            amount: commissionAmount,
            type: tx.TransactionType.commission,
            status: tx.TransactionStatus.completed,
            packageType: packageType,
            referrerId: customer.referralCode,
            referrerName: referrer.fullName,
            description: 'Commission for ${customer.fullName} payment (${(tx.Transaction.commissionRate * 100).toStringAsFixed(1)}%)',
            createdAt: paymentDate, // Use provided payment date
            completedAt: paymentDate, // Use provided payment date
            metadata: {
              'relatedPaymentTransaction': paymentTransaction.id,
              'paymentMethod': paymentMethod,
              'processedBy': adminId,
              'processedByName': adminName,
            },
          );
          
          transaction.set(commissionTransactionRef, commissionTransaction.toFirestore());
          print('💰 Commission transaction created: ${commissionTransaction.id}');
          
          // Update referrer's earnings
          final referrerDoc = _usersCollection.doc(referrer.uid);
          transaction.update(referrerDoc, {
            'earnings': FieldValue.increment(commissionAmount.toInt()),
          });
          print('📈 Referrer earnings updated: +₹${commissionAmount.toStringAsFixed(0)}');
        }
        
        final totalProcessingTime = DateTime.now().millisecondsSinceEpoch;
        print('✅ Enhanced payment processing completed successfully');
        print('⏱️ Total processing time: ${totalProcessingTime}ms');
        
        return {
          'success': true,
          'message': isFullPayment ? 'Full payment processed successfully' : 'Partial payment processed successfully',
          'paymentAmount': amount,
          'newAmountDue': newAmountDue,
          'isPartialPayment': !isFullPayment,
          'paymentMethod': paymentMethod,
          'paymentDate': paymentDate.toIso8601String(),
          'transactionId': paymentTransaction.id,
          'referrerName': referrer?.fullName,
          'commissionAmount': customer.referralCode.isNotEmpty ? commissionAmount : null,
        };
      });
      
    } catch (e) {
      print('❌ Error in enhanced payment processing: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
} 