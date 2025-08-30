import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'dart:math';

class UsersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

  // Get all users stream
  Stream<List<UserModel>> getUsersStream() {
    return _usersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  // Get single user
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Update user
  Future<bool> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await _usersCollection.doc(uid).update(updates);
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Toggle user active status
  Future<bool> toggleUserStatus(String uid, bool isActive) async {
    try {
      await _usersCollection.doc(uid).update({'isActive': isActive});
      return true;
    } catch (e) {
      print('Error toggling user status: $e');
      return false;
    }
  }

  // Update user role
  Future<bool> updateUserRole(String uid, String role) async {
    try {
      await _usersCollection.doc(uid).update({'role': role});
      return true;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }

  // Get user roles list
  List<String> getUserRoles() {
    return [
      'user',
      'admin',
      'Sales Representative',
      'Manager',
      'Partner',
    ];
  }

  // Get status options
  List<String> getStatusOptions() {
    return [
      'pending',
      'active',
      'suspended',
      'blocked',
    ];
  }

  // Get KYC status options
  List<String> getKycStatusOptions() {
    return [
      'pending',
      'in-progress',
      'approved',
      'rejected',
    ];
  }

  // ==================== REFERRAL SYSTEM METHODS ====================
  
  // Generate a unique referral code for a user
  Future<String?> generateReferralCode(String uid, String userName) async {
    try {
      // Create a unique referral code based on user name and random string
      final String baseCode = userName.replaceAll(' ', '').toUpperCase();
      String randomSuffix = _generateRandomString(4);
      String referralCode = '$baseCode$randomSuffix';
      
      // Ensure uniqueness by checking existing codes
      int attempt = 0;
      while (await _isReferralCodeExists(referralCode) && attempt < 10) {
        randomSuffix = _generateRandomString(4);
        referralCode = '$baseCode$randomSuffix';
        attempt++;
      }
      
      // Update user with the new referral code
      await _usersCollection.doc(uid).update({'myReferralCode': referralCode});
      return referralCode;
    } catch (e) {
      print('Error generating referral code: $e');
      return null;
    }
  }
  
  // Update user's referrer (who referred this user)
  Future<bool> updateReferrer(String uid, String referrerCode) async {
    try {
      // First, validate that the referrer code exists
      final referrer = await _getUserByReferralCode(referrerCode);
      if (referrer == null) {
        print('Invalid referral code: $referrerCode');
        return false;
      }
      
      // Check if user already has a referrer
      final user = await getUser(uid);
      if (user?.referredBy != null && user!.referredBy!.isNotEmpty) {
        print('User already has a referrer');
        return false;
      }
      
      // Update user's referredBy field
      await _usersCollection.doc(uid).update({
        'referredBy': referrerCode,
      });
      
      // Increment referrer's referral count
      await _incrementReferralCount(referrer.uid);
      
      return true;
    } catch (e) {
      print('Error updating referrer: $e');
      return false;
    }
  }
  
  // Get user by referral code
  Future<UserModel?> _getUserByReferralCode(String referralCode) async {
    try {
      final querySnapshot = await _usersCollection
          .where('myReferralCode', isEqualTo: referralCode)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting user by referral code: $e');
      return null;
    }
  }
  
  // Check if referral code already exists
  Future<bool> _isReferralCodeExists(String referralCode) async {
    try {
      final querySnapshot = await _usersCollection
          .where('myReferralCode', isEqualTo: referralCode)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking referral code existence: $e');
      return false;
    }
  }
  
  // Increment referral count for a user
  Future<void> _incrementReferralCount(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'referrals': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing referral count: $e');
    }
  }
  
  // Generate random string for referral code
  String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
  
  // Generate referral link
  String generateReferralLink(String referralCode, {String? baseUrl}) {
    final domain = baseUrl ?? 'https://yourdomain.com'; // Replace with your actual domain
    return '$domain/download?ref=$referralCode';
  }
  
  // Validate referral code format
  bool isValidReferralCodeFormat(String code) {
    // Check if code is 6-12 characters, alphanumeric
    final regex = RegExp(r'^[A-Z0-9]{6,12}$');
    return regex.hasMatch(code.toUpperCase());
  }
  
  // Get all users referred by a specific referral code
  Future<List<UserModel>> getReferredUsers(String referralCode) async {
    try {
      final querySnapshot = await _usersCollection
          .where('referredBy', isEqualTo: referralCode)
          .get();
      
      return querySnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting referred users: $e');
      return [];
    }
  }
} 