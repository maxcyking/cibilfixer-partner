import 'package:cloud_firestore/cloud_firestore.dart';

class SystemSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get commission settings from the database
  Future<Map<String, dynamic>> getCommissionSettings() async {
    try {
      print('🔍 Fetching commission settings from database...');
      
      final doc = await _firestore
          .collection('system_settings')
          .doc('global_settings')
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final commissionSettings = data['commissionSettings'] as Map<String, dynamic>? ?? {};
        
        print('✅ Commission settings loaded successfully');
        return {
          'directReferrerRate': commissionSettings['directReferrerRate'] ?? 0.1,
          'partnerReferrerRate': commissionSettings['partnerReferrerRate'] ?? 0.1,
          'maxCommissionRate': commissionSettings['maxCommissionRate'] ?? 0.2,
          'enableTwoLevelCommission': commissionSettings['enableTwoLevelCommission'] ?? true,
          'enableCommissionCap': commissionSettings['enableCommissionCap'] ?? false,
          'dailyCommissionCap': commissionSettings['dailyCommissionCap'],
          'monthlyCommissionCap': commissionSettings['monthlyCommissionCap'],
        };
      }
      
      // Return default values if document doesn't exist
      print('⚠️ Commission settings document not found, using defaults');
      return {
        'directReferrerRate': 0.1, // 10%
        'partnerReferrerRate': 0.1, // 10%
        'maxCommissionRate': 0.2, // 20%
        'enableTwoLevelCommission': true,
        'enableCommissionCap': false,
        'dailyCommissionCap': null,
        'monthlyCommissionCap': null,
      };
    } catch (e) {
      print('❌ Error fetching commission settings: $e');
      // Return default values on error
      return {
        'directReferrerRate': 0.1,
        'partnerReferrerRate': 0.1,
        'maxCommissionRate': 0.2,
        'enableTwoLevelCommission': true,
        'enableCommissionCap': false,
        'dailyCommissionCap': null,
        'monthlyCommissionCap': null,
      };
    }
  }

  /// Get general settings from the database
  Future<Map<String, dynamic>> getGeneralSettings() async {
    try {
      print('🔍 Fetching general settings from database...');
      
      final doc = await _firestore
          .collection('system_settings')
          .doc('global_settings')
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final generalSettings = data['generalSettings'] as Map<String, dynamic>? ?? {};
        
        print('✅ General settings loaded successfully');
        return {
          'companyName': generalSettings['companyName'] ?? 'Company Name',
          'companyEmail': generalSettings['companyEmail'] ?? 'info@company.com',
          'companyAddress': generalSettings['companyAddress'] ?? 'India',
          'supportEmail': generalSettings['supportEmail'] ?? 'support@company.com',
          'supportPhone': generalSettings['supportPhone'] ?? '+91 9876543210',
        };
      }
      
      print('⚠️ General settings document not found, using defaults');
      return {
        'companyName': 'Future Capital',
        'companyEmail': 'info@futurecapital.com',
        'companyAddress': 'India',
        'supportEmail': 'support@futurecapital.com',
        'supportPhone': '+91 9876543210',
      };
    } catch (e) {
      print('❌ Error fetching general settings: $e');
      return {
        'companyName': 'Future Capital',
        'companyEmail': 'info@futurecapital.com',
        'companyAddress': 'India',
        'supportEmail': 'support@futurecapital.com',
        'supportPhone': '+91 9876543210',
      };
    }
  }

  /// Get all system settings at once
  Future<Map<String, dynamic>> getAllSettings() async {
    try {
      final results = await Future.wait([
        getCommissionSettings(),
        getGeneralSettings(),
      ]);
      
      return {
        'commission': results[0],
        'general': results[1],
      };
    } catch (e) {
      print('❌ Error fetching all settings: $e');
      return {
        'commission': await getCommissionSettings(),
        'general': await getGeneralSettings(),
      };
    }
  }

  /// Stream commission settings for real-time updates
  Stream<Map<String, dynamic>> getCommissionSettingsStream() {
    return _firestore
        .collection('system_settings')
        .doc('global_settings')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final commissionSettings = data['commissionSettings'] as Map<String, dynamic>? ?? {};
        
        return {
          'directReferrerRate': commissionSettings['directReferrerRate'] ?? 0.1,
          'partnerReferrerRate': commissionSettings['partnerReferrerRate'] ?? 0.1,
          'maxCommissionRate': commissionSettings['maxCommissionRate'] ?? 0.2,
          'enableTwoLevelCommission': commissionSettings['enableTwoLevelCommission'] ?? true,
          'enableCommissionCap': commissionSettings['enableCommissionCap'] ?? false,
          'dailyCommissionCap': commissionSettings['dailyCommissionCap'],
          'monthlyCommissionCap': commissionSettings['monthlyCommissionCap'],
        };
      }
      
      return {
        'directReferrerRate': 0.1,
        'partnerReferrerRate': 0.1,
        'maxCommissionRate': 0.2,
        'enableTwoLevelCommission': true,
        'enableCommissionCap': false,
        'dailyCommissionCap': null,
        'monthlyCommissionCap': null,
      };
    });
  }
} 