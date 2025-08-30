import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class KycApplication {
  final String userId;
  final String fullName;
  final String email;
  final String mobile;
  final Map<String, dynamic> personalInfo;
  final Map<String, dynamic> contactInfo;
  final Map<String, dynamic> addressInfo;
  final Map<String, dynamic> documentInfo;
  final Map<String, dynamic> experienceInfo;
  final Map<String, dynamic> bankInfo;
  final String overallStatus;
  final int progress;
  final DateTime submittedAt;
  final DateTime? lastUpdated;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final Map<String, String> stepStatuses;
  final Map<String, String> rejectionReasons;

  KycApplication({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.personalInfo,
    required this.contactInfo,
    required this.addressInfo,
    required this.documentInfo,
    required this.experienceInfo,
    required this.bankInfo,
    required this.overallStatus,
    required this.progress,
    required this.submittedAt,
    this.lastUpdated,
    this.reviewedAt,
    this.reviewedBy,
    required this.stepStatuses,
    required this.rejectionReasons,
  });

  factory KycApplication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return KycApplication(
      userId: doc.id,
      fullName: _extractFieldValue(data, 'personal_info', 'fullName') ?? 
                _extractFieldValue(data, 'contact_info', 'fullName') ?? 
                _extractUserName(data) ?? 'Unknown User',
      email: _extractFieldValue(data, 'contact_info', 'emailAddress') ?? 
             _extractFieldValue(data, 'personal_info', 'email') ?? 'No email',
      mobile: _extractFieldValue(data, 'contact_info', 'mobileNumber') ?? 
              _extractFieldValue(data, 'personal_info', 'mobile') ?? 'No mobile',
      personalInfo: _extractStepData(data, 'personal_info'),
      contactInfo: _extractStepData(data, 'contact_info'),
      addressInfo: _extractStepData(data, 'address_info'),
      documentInfo: _extractStepData(data, 'document_info'),
      experienceInfo: _extractStepData(data, 'experience_info'),
      bankInfo: _extractStepData(data, 'bank_info'),
      overallStatus: data['overallStatus'] ?? 'pending',
      progress: (data['progress'] as num?)?.toInt() ?? 0,
      submittedAt: _parseTimestamp(data['submittedAt']) ?? DateTime.now(),
      lastUpdated: _parseTimestamp(data['lastUpdated']),
      reviewedAt: _parseTimestamp(data['reviewedAt']),
      reviewedBy: data['reviewedBy'],
      stepStatuses: _extractStepStatuses(data),
      rejectionReasons: _extractRejectionReasons(data),
    );
  }

  static String? _extractUserName(Map<String, dynamic> data) {
    // Try to get user name from various possible locations
    return data['userName'] ?? data['fullName'] ?? data['name'];
  }

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static String? _extractFieldValue(Map<String, dynamic> data, String stepId, String fieldKey) {
    final step = data[stepId] as Map<String, dynamic>?;
    if (step == null) return null;
    
    final fields = step['fields'] as Map<String, dynamic>?;
    if (fields == null) return null;
    
    return fields[fieldKey]?.toString();
  }

  static Map<String, dynamic> _extractStepData(Map<String, dynamic> data, String stepId) {
    return (data[stepId] as Map<String, dynamic>?) ?? {};
  }

  static Map<String, String> _extractStepStatuses(Map<String, dynamic> data) {
    final stepStatuses = <String, String>{};
    final stepIds = ['personal_info', 'contact_info', 'address_info', 'document_info', 'experience_info', 'bank_info'];
    
    for (final stepId in stepIds) {
      final step = data[stepId] as Map<String, dynamic>?;
      stepStatuses[stepId] = step?['status']?.toString() ?? 'pending';
    }
    
    return stepStatuses;
  }

  static Map<String, String> _extractRejectionReasons(Map<String, dynamic> data) {
    final rejectionReasons = <String, String>{};
    final stepIds = ['personal_info', 'contact_info', 'address_info', 'document_info', 'experience_info', 'bank_info'];
    
    for (final stepId in stepIds) {
      final step = data[stepId] as Map<String, dynamic>?;
      rejectionReasons[stepId] = step?['rejectionReason']?.toString() ?? '';
    }
    
    return rejectionReasons;
  }

  Color get statusColor {
    switch (overallStatus) {
      case 'completed':
        return Colors.green;
      case 'under_review':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String get statusText {
    switch (overallStatus) {
      case 'completed':
        return 'Completed';
      case 'under_review':
        return 'Under Review';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  // Get all uploaded documents from all steps
  Map<String, String> get allDocuments {
    final documents = <String, String>{};
    
    final steps = [personalInfo, contactInfo, addressInfo, documentInfo, experienceInfo, bankInfo];
    
    for (final step in steps) {
      final stepDocuments = step['documents'] as Map<String, dynamic>?;
      if (stepDocuments != null) {
        for (final entry in stepDocuments.entries) {
          if (entry.value != null && entry.value.toString().isNotEmpty) {
            documents[entry.key] = entry.value.toString();
          }
        }
      }
    }
    
    return documents;
  }

  // Get field value with fallback
  String getFieldValue(String stepId, String fieldKey, [String fallback = 'Not provided']) {
    final stepData = getStepData(stepId);
    final fields = stepData['fields'] as Map<String, dynamic>?;
    return fields?[fieldKey]?.toString() ?? fallback;
  }

  Map<String, dynamic> getStepData(String stepId) {
    switch (stepId) {
      case 'personal_info':
        return personalInfo;
      case 'contact_info':
        return contactInfo;
      case 'address_info':
        return addressInfo;
      case 'document_info':
        return documentInfo;
      case 'experience_info':
        return experienceInfo;
      case 'bank_info':
        return bankInfo;
      default:
        return {};
    }
  }
}

class KycManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'kyc_applications';

  /// Get all KYC applications with real-time updates
  Stream<List<KycApplication>> getKycApplicationsStream({
    String? statusFilter,
    int limit = 50,
  }) {
    Query query = _firestore.collection(_collection);

    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('overallStatus', isEqualTo: statusFilter);
    }

    return query
        .orderBy('lastUpdated', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => KycApplication.fromFirestore(doc))
            .toList());
  }

  /// Get KYC applications with search and filter
  Future<List<KycApplication>> getKycApplications({
    String? statusFilter,
    String? searchQuery,
    String sortBy = 'latest',
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      // Apply status filter
      if (statusFilter != null && statusFilter != 'all') {
        query = query.where('overallStatus', isEqualTo: statusFilter);
      }

      // Apply sorting
      switch (sortBy) {
        case 'latest':
          query = query.orderBy('lastUpdated', descending: true);
          break;
        case 'oldest':
          query = query.orderBy('lastUpdated', descending: false);
          break;
        case 'progress_high':
          query = query.orderBy('progress', descending: true);
          break;
        case 'progress_low':
          query = query.orderBy('progress', descending: false);
          break;
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      
      // Fetch KYC applications with user details
      List<KycApplication> applications = [];
      
      for (final doc in querySnapshot.docs) {
        final kycApp = await _createKycApplicationWithUserDetails(doc);
        applications.add(kycApp);
      }

      // Apply search filter locally (Firestore doesn't support complex text search)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        applications = applications.where((app) =>
            app.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            app.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
            app.mobile.contains(searchQuery)).toList();
      }

      // Apply name sorting if needed (after Firestore query)
      if (sortBy == 'name') {
        applications.sort((a, b) => a.fullName.compareTo(b.fullName));
      }

      return applications;
    } catch (e) {
      print('❌ Error getting KYC applications: $e');
      throw Exception('Failed to get KYC applications: $e');
    }
  }

  /// Create KYC application with user details from users collection
  Future<KycApplication> _createKycApplicationWithUserDetails(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final userId = doc.id;
    
    // Fetch user details from users collection
    String fullName = 'Unknown User';
    String email = 'No email';
    String mobile = 'No mobile';
    
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        fullName = userData['fullName'] ?? userData['name'] ?? 'Unknown User';
        email = userData['email'] ?? email;
        mobile = userData['mobile'] ?? mobile;
      }
    } catch (e) {
      print('⚠️ Could not fetch user details for $userId: $e');
    }
    
    // If still unknown, try to extract from KYC data as fallback
    if (fullName == 'Unknown User') {
      fullName = KycApplication._extractFieldValue(data, 'personal_info', 'fullName') ?? 
                KycApplication._extractFieldValue(data, 'contact_info', 'fullName') ?? 
                KycApplication._extractUserName(data) ?? 'Unknown User';
    }
    
    if (email == 'No email') {
      email = KycApplication._extractFieldValue(data, 'contact_info', 'emailAddress') ?? 
             KycApplication._extractFieldValue(data, 'personal_info', 'email') ?? 'No email';
    }
    
    if (mobile == 'No mobile') {
      mobile = KycApplication._extractFieldValue(data, 'contact_info', 'mobileNumber') ?? 
               KycApplication._extractFieldValue(data, 'personal_info', 'mobile') ?? 'No mobile';
    }
    
    return KycApplication(
      userId: userId,
      fullName: fullName,
      email: email,
      mobile: mobile,
      personalInfo: KycApplication._extractStepData(data, 'personal_info'),
      contactInfo: KycApplication._extractStepData(data, 'contact_info'),
      addressInfo: KycApplication._extractStepData(data, 'address_info'),
      documentInfo: KycApplication._extractStepData(data, 'document_info'),
      experienceInfo: KycApplication._extractStepData(data, 'experience_info'),
      bankInfo: KycApplication._extractStepData(data, 'bank_info'),
      overallStatus: data['overallStatus'] ?? 'pending',
      progress: (data['progress'] as num?)?.toInt() ?? 0,
      submittedAt: KycApplication._parseTimestamp(data['submittedAt']) ?? DateTime.now(),
      lastUpdated: KycApplication._parseTimestamp(data['lastUpdated']),
      reviewedAt: KycApplication._parseTimestamp(data['reviewedAt']),
      reviewedBy: data['reviewedBy'],
      stepStatuses: KycApplication._extractStepStatuses(data),
      rejectionReasons: KycApplication._extractRejectionReasons(data),
    );
  }

  /// Get single KYC application by user ID
  Future<KycApplication?> getKycApplication(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      
      if (doc.exists) {
        return await _createKycApplicationWithUserDetails(doc);
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting KYC application: $e');
      throw Exception('Failed to get KYC application: $e');
    }
  }

  /// Update step status and rejection reason
  Future<void> updateStepStatus({
    required String userId,
    required String stepId,
    required String status, // 'approved', 'rejected', 'pending'
    String? rejectionReason,
    String? reviewedBy,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc(userId);
      
      final updateData = <String, dynamic>{
        '$stepId.status': status,
        '$stepId.reviewedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      if (reviewedBy != null) {
        updateData['$stepId.reviewedBy'] = reviewedBy;
        updateData['reviewedBy'] = reviewedBy;
      }
      
      if (status == 'rejected' && rejectionReason != null) {
        updateData['$stepId.rejectionReason'] = rejectionReason;
      } else {
        updateData['$stepId.rejectionReason'] = FieldValue.delete();
      }
      
      await docRef.update(updateData);
      
      // Recalculate overall progress and status
      await _recalculateKycStatus(userId);
      
      print('✅ Updated step $stepId status to $status for user $userId');
    } catch (e) {
      print('❌ Error updating step status: $e');
      throw Exception('Failed to update step status: $e');
    }
  }

  /// Update overall KYC status
  Future<void> updateOverallStatus({
    required String userId,
    required String status,
    String? rejectionReason,
    String? reviewedBy,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'overallStatus': status,
        'lastUpdated': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.serverTimestamp(),
      };
      
      if (reviewedBy != null) {
        updateData['reviewedBy'] = reviewedBy;
      }
      
      if (status == 'rejected' && rejectionReason != null) {
        updateData['overallRejectionReason'] = rejectionReason;
      }
      
      await _firestore.collection(_collection).doc(userId).update(updateData);
      
      // Also update user's KYC status in users collection
      await _updateUserKycStatus(userId, status);
      
      print('✅ Updated overall KYC status to $status for user $userId');
    } catch (e) {
      print('❌ Error updating overall status: $e');
      throw Exception('Failed to update overall status: $e');
    }
  }

  /// Recalculate overall KYC status based on step statuses
  Future<void> _recalculateKycStatus(String userId) async {
    try {
      final kycApp = await getKycApplication(userId);
      if (kycApp == null) return;
      
      final stepIds = ['personal_info', 'contact_info', 'address_info', 'document_info', 'experience_info', 'bank_info'];
      int approvedSteps = 0;
      int totalSteps = stepIds.length;
      bool hasRejected = false;
      
      for (final stepId in stepIds) {
        final status = kycApp.stepStatuses[stepId] ?? 'pending';
        
        if (status == 'approved') {
          approvedSteps++;
        } else if (status == 'rejected') {
          hasRejected = true;
        }
      }
      
      // Calculate progress percentage
      final progress = ((approvedSteps / totalSteps) * 100).round();
      
      // Determine overall status
      String overallStatus;
      if (hasRejected) {
        overallStatus = 'rejected';
      } else if (approvedSteps == totalSteps) {
        overallStatus = 'completed';
      } else if (approvedSteps > 0) {
        overallStatus = 'under_review';
      } else {
        overallStatus = 'pending';
      }
      
      // Update document
      await _firestore.collection(_collection).doc(userId).update({
        'progress': progress,
        'overallStatus': overallStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Update user document
      await _updateUserKycStatus(userId, overallStatus, progress);
      
      print('✅ Recalculated KYC status: $progress% ($overallStatus) for user $userId');
    } catch (e) {
      print('❌ Error recalculating KYC status: $e');
    }
  }

  /// Update user's KYC status in users collection
  Future<void> _updateUserKycStatus(String userId, String kycStatus, [int? progress]) async {
    try {
      final updateData = <String, dynamic>{
        'kycStatus': kycStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      if (progress != null) {
        updateData['kycProgress'] = progress;
      }
      
      await _firestore.collection('users').doc(userId).update(updateData);
    } catch (e) {
      print('❌ Error updating user KYC status: $e');
    }
  }

  /// Get KYC statistics
  Future<Map<String, int>> getKycStatistics() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      
      int total = querySnapshot.docs.length;
      int pending = 0;
      int underReview = 0;
      int completed = 0;
      int rejected = 0;
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['overallStatus'] ?? 'pending';
        
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'under_review':
            underReview++;
            break;
          case 'completed':
            completed++;
            break;
          case 'rejected':
            rejected++;
            break;
        }
      }
      
      return {
        'total': total,
        'pending': pending,
        'under_review': underReview,
        'completed': completed,
        'rejected': rejected,
      };
    } catch (e) {
      print('❌ Error getting KYC statistics: $e');
      return {
        'total': 0,
        'pending': 0,
        'under_review': 0,
        'completed': 0,
        'rejected': 0,
      };
    }
  }

  /// Delete KYC application
  Future<void> deleteKycApplication(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).delete();
      
      // Reset user's KYC status
      await _updateUserKycStatus(userId, 'pending', 0);
      
      print('🗑️ Deleted KYC application for user $userId');
    } catch (e) {
      print('❌ Error deleting KYC application: $e');
      throw Exception('Failed to delete KYC application: $e');
    }
  }
} 