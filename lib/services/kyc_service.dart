import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/kyc_step_model.dart';
import 'storage_service.dart';
import 'dart:io';
import 'dart:typed_data';

class KycService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  final String _collection = 'kyc_applications';

  /// Save individual KYC step to Firestore
  Future<void> saveKycStep({
    required String userId,
    required String stepId,
    required Map<String, dynamic> stepData,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc(userId);
      
      // Add timestamp
      stepData['submittedAt'] = FieldValue.serverTimestamp();
      stepData['status'] = 'pending';
      
      await docRef.set({
        stepId: stepData,
        'lastUpdated': FieldValue.serverTimestamp(),
        'userId': userId,
      }, SetOptions(merge: true));
      
      print('KYC step $stepId saved successfully for user $userId');
    } catch (e) {
      print('Error saving KYC step: $e');
      throw Exception('Failed to save KYC step: $e');
    }
  }

  /// Get existing KYC data for a user
  Future<Map<String, dynamic>?> getKycData(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        // Remove metadata fields
        data.remove('lastUpdated');
        data.remove('userId');
        data.remove('overallStatus');
        data.remove('progress');
        
        return data;
      }
      
      return null;
    } catch (e) {
      print('Error getting KYC data: $e');
      throw Exception('Failed to get KYC data: $e');
    }
  }

  /// Submit complete KYC application
  Future<void> submitCompleteKyc({
    required String userId,
    required List<KycStepModel> kycSteps,
    required int progress,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc(userId);
      
      // Prepare complete KYC data
      final kycData = <String, dynamic>{};
      
      for (final step in kycSteps) {
        kycData[step.id] = step.toMap();
      }
      
      // Add metadata
      kycData['userId'] = userId;
      kycData['progress'] = progress;
      kycData['overallStatus'] = 'under_review';
      kycData['submittedAt'] = FieldValue.serverTimestamp();
      kycData['lastUpdated'] = FieldValue.serverTimestamp();
      
      await docRef.set(kycData, SetOptions(merge: true));
      
      // Update user's KYC progress in users collection
      await _updateUserKycProgress(userId, progress, 'under_review');
      
      print('Complete KYC submitted successfully for user $userId');
    } catch (e) {
      print('Error submitting complete KYC: $e');
      throw Exception('Failed to submit KYC: $e');
    }
  }

  /// Update user's KYC progress in users collection
  Future<void> _updateUserKycProgress(
    String userId, 
    int progress, 
    String status,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'kycProgress': progress,
        'kycStatus': status,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user KYC progress: $e');
      // Don't throw here as the main KYC submission was successful
    }
  }

  /// Admin function to approve/reject KYC step
  Future<void> updateKycStepStatus({
    required String userId,
    required String stepId,
    required String status, // 'approved', 'rejected', 'pending'
    String? rejectionReason,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc(userId);
      
      final updateData = <String, dynamic>{
        '$stepId.status': status,
        '$stepId.reviewedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      if (status == 'rejected' && rejectionReason != null) {
        updateData['$stepId.rejectionReason'] = rejectionReason;
      }
      
      await docRef.update(updateData);
      
      // Recalculate overall progress
      await _recalculateKycProgress(userId);
      
      print('KYC step $stepId updated to $status for user $userId');
    } catch (e) {
      print('Error updating KYC step status: $e');
      throw Exception('Failed to update KYC step status: $e');
    }
  }

  /// Recalculate overall KYC progress after step status changes
  Future<void> _recalculateKycProgress(String userId) async {
    try {
      final kycData = await getKycData(userId);
      if (kycData == null) return;
      
      int totalSteps = 0;
      int approvedSteps = 0;
      bool hasRejected = false;
      
      // Count steps and their statuses
      for (final stepData in kycData.values) {
        if (stepData is Map<String, dynamic> && stepData.containsKey('status')) {
          totalSteps++;
          final status = stepData['status'];
          
          if (status == 'approved') {
            approvedSteps++;
          } else if (status == 'rejected') {
            hasRejected = true;
          }
        }
      }
      
      // Calculate progress percentage
      final progress = totalSteps > 0 ? ((approvedSteps / totalSteps) * 100).round() : 0;
      
      // Determine overall status
      String overallStatus;
      if (hasRejected) {
        overallStatus = 'rejected';
      } else if (approvedSteps == totalSteps && totalSteps > 0) {
        overallStatus = 'completed';
      } else if (approvedSteps > 0) {
        overallStatus = 'under_review';
      } else {
        overallStatus = 'pending';
      }
      
      // Update KYC document
      await _firestore.collection(_collection).doc(userId).update({
        'progress': progress,
        'overallStatus': overallStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Update user document
      await _updateUserKycProgress(userId, progress, overallStatus);
      
      print('KYC progress recalculated: $progress% ($overallStatus) for user $userId');
    } catch (e) {
      print('Error recalculating KYC progress: $e');
    }
  }

  /// Get all KYC applications for admin review
  Stream<QuerySnapshot> getKycApplicationsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('lastUpdated', descending: true)
        .snapshots();
  }

  /// Get KYC applications with specific status
  Future<List<Map<String, dynamic>>> getKycApplicationsByStatus(String status) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('overallStatus', isEqualTo: status)
          .orderBy('lastUpdated', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting KYC applications by status: $e');
      throw Exception('Failed to get KYC applications: $e');
    }
  }

  /// Delete KYC application (admin only)
  Future<void> deleteKycApplication(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).delete();
      
      // Reset user's KYC status
      await _updateUserKycProgress(userId, 0, 'pending');
      
      print('KYC application deleted for user $userId');
    } catch (e) {
      print('Error deleting KYC application: $e');
      throw Exception('Failed to delete KYC application: $e');
    }
  }

  /// Upload document to Firebase Storage
  Future<String?> uploadDocument({
    required String userId,
    required String stepId,
    required String documentType,
    required File file,
    Function(double)? onProgress,
  }) async {
    try {
      print('🔄 Uploading KYC document: $documentType for user: $userId');
      
      // Validate file type and size
      if (!_storageService.isAllowedFileType(file.path)) {
        throw Exception('File type not allowed. Please use PDF, JPG, or PNG files.');
      }
      
      if (!_storageService.isFileSizeValid(file)) {
        throw Exception('File size too large. Max 5MB for images, 10MB for PDFs.');
      }
      
      // Upload to Firebase Storage
      final downloadUrl = await _storageService.uploadKycDocument(
        userId: userId,
        stepId: stepId,
        documentType: documentType,
        file: file,
        onProgress: onProgress,
      );
      
      print('✅ Document uploaded successfully: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      print('❌ Error uploading document: $e');
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Upload document bytes (for web platform)
  Future<String?> uploadDocumentBytes({
    required String userId,
    required String stepId,
    required String documentType,
    required Uint8List fileBytes,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      print('🔄 Uploading KYC document (bytes): $documentType for user: $userId');
      print('📁 File name: $fileName');
      print('📏 File size: ${fileBytes.length} bytes');
      
      // Validate file type based on filename
      if (!_storageService.isAllowedFileTypeByName(fileName)) {
        throw Exception('File type not allowed. Please use PDF, JPG, or PNG files.');
      }
      
      // Validate file size (5MB for images, 10MB for PDFs)
      const maxImageSize = 5 * 1024 * 1024; // 5MB
      const maxPdfSize = 10 * 1024 * 1024; // 10MB
      
      final isImage = fileName.toLowerCase().endsWith('.jpg') || 
                     fileName.toLowerCase().endsWith('.jpeg') || 
                     fileName.toLowerCase().endsWith('.png');
      
      final maxSize = isImage ? maxImageSize : maxPdfSize;
      if (fileBytes.length > maxSize) {
        throw Exception('File size too large. Max 5MB for images, 10MB for PDFs.');
      }
      
      // Upload to Firebase Storage
      final downloadUrl = await _storageService.uploadKycDocumentBytes(
        userId: userId,
        stepId: stepId,
        documentType: documentType,
        fileBytes: fileBytes,
        fileName: fileName,
        onProgress: onProgress,
      );
      
      print('✅ Document uploaded successfully: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      print('❌ Error uploading document: $e');
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Upload multiple documents for a KYC step
  Future<Map<String, String>> uploadMultipleDocuments({
    required String userId,
    required String stepId,
    required Map<String, File> documents,
    Function(String documentType, double progress)? onProgress,
  }) async {
    try {
      return await _storageService.uploadMultipleKycDocuments(
        userId: userId,
        stepId: stepId,
        documents: documents,
        onProgress: onProgress,
      );
    } catch (e) {
      print('❌ Error uploading multiple documents: $e');
      throw Exception('Failed to upload documents: $e');
    }
  }

  /// Delete KYC document
  Future<void> deleteDocument(String downloadUrl) async {
    try {
      await _storageService.deleteKycDocument(downloadUrl);
    } catch (e) {
      print('❌ Error deleting document: $e');
      throw Exception('Failed to delete document: $e');
    }
  }

  /// Save KYC progress for resuming later
  Future<void> saveKycProgress({
    required String userId,
    required int currentStep,
    required List<KycStepModel> kycSteps,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc(userId);
      
      // Prepare progress data
      final progressData = <String, dynamic>{
        'currentStep': currentStep,
        'lastResumedAt': FieldValue.serverTimestamp(),
        'progressSavedAt': FieldValue.serverTimestamp(),
      };
      
      // Save each step's current state
      for (final step in kycSteps) {
        progressData[step.id] = step.toMap();
      }
      
      await docRef.set(progressData, SetOptions(merge: true));
      
      print('✅ KYC progress saved for user $userId at step $currentStep');
    } catch (e) {
      print('❌ Error saving KYC progress: $e');
      throw Exception('Failed to save KYC progress: $e');
    }
  }

  /// Get the step where user should resume KYC
  Future<int> getResumeStep(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        
        // Check if there's a saved currentStep
        if (data.containsKey('currentStep')) {
          final savedStep = data['currentStep'] as int;
          print('📍 User should resume at step: $savedStep');
          return savedStep;
        }
        
        // If no currentStep saved, find the first incomplete step
        int resumeStep = 0;
        final stepIds = ['personal_info', 'contact_info', 'address_info', 'document_info', 'experience_info', 'bank_info'];
        
        for (int i = 0; i < stepIds.length; i++) {
          final stepId = stepIds[i];
          if (data.containsKey(stepId)) {
            final stepData = data[stepId] as Map<String, dynamic>;
            final status = stepData['status'] as String?;
            
            // If step is not completed (not approved or pending), stop here
            if (status != 'approved' && status != 'pending') {
              resumeStep = i;
              break;
            }
            // If this is the last step and it's completed, resume at last step
            if (i == stepIds.length - 1 && (status == 'approved' || status == 'pending')) {
              resumeStep = i;
            } else if (status == 'approved' || status == 'pending') {
              resumeStep = i + 1; // Move to next step
            }
          } else {
            // Step doesn't exist, resume here
            resumeStep = i;
            break;
          }
        }
        
        print('📍 Calculated resume step: $resumeStep');
        return resumeStep;
      }
      
      // No existing data, start from beginning
      print('📍 No existing KYC data, starting from step 0');
      return 0;
    } catch (e) {
      print('❌ Error getting resume step: $e');
      return 0; // Default to first step on error
    }
  }

  /// Check if user has any KYC progress saved
  Future<bool> hasKycProgress(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      return doc.exists && doc.data()!.isNotEmpty;
    } catch (e) {
      print('❌ Error checking KYC progress: $e');
      return false;
    }
  }

  /// Get KYC completion percentage
  Future<int> getKycCompletionPercentage(String userId) async {
    try {
      final kycData = await getKycData(userId);
      if (kycData == null) return 0;
      
      final stepIds = ['personal_info', 'contact_info', 'address_info', 'document_info', 'experience_info', 'bank_info'];
      int completedSteps = 0;
      
      for (final stepId in stepIds) {
        if (kycData.containsKey(stepId)) {
          final stepData = kycData[stepId] as Map<String, dynamic>;
          final status = stepData['status'] as String?;
          
          if (status == 'approved' || status == 'pending') {
            completedSteps++;
          }
        }
      }
      
      return ((completedSteps / stepIds.length) * 100).round();
    } catch (e) {
      print('❌ Error getting KYC completion percentage: $e');
      return 0;
    }
  }

  /// Auto-save step data while user is filling the form
  Future<void> autoSaveStepData({
    required String userId,
    required String stepId,
    required Map<String, dynamic> stepData,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc(userId);
      
      // Add auto-save metadata
      stepData['autoSavedAt'] = FieldValue.serverTimestamp();
      stepData['status'] = stepData['status'] ?? 'draft'; // Mark as draft for auto-save
      
      await docRef.set({
        stepId: stepData,
        'lastAutoSave': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('💾 Auto-saved step $stepId for user $userId');
    } catch (e) {
      print('❌ Error auto-saving step data: $e');
      // Don't throw error for auto-save failures
    }
  }

  /// Clear corrupted KYC data for a user
  Future<void> clearKycData(String userId) async {
    try {
      final docRef = _firestore.collection(_collection).doc(userId);
      await docRef.delete();
      
      print('🧹 Cleared all KYC data for user $userId');
    } catch (e) {
      print('❌ Error clearing KYC data: $e');
      throw Exception('Failed to clear KYC data: $e');
    }
  }
} 