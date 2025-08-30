import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload KYC document to Firebase Storage
  Future<String> uploadKycDocument({
    required String userId,
    required String stepId,
    required String documentType,
    required File file,
    Function(double)? onProgress,
  }) async {
    try {
      print('📤 Starting upload for user: $userId, step: $stepId, document: $documentType');
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(file.path);
      final fileName = '${documentType}_$timestamp$fileExtension';
      
      // Create storage reference
      final storageRef = _storage.ref().child('kyc_documents/$userId/$stepId/$fileName');
      
      // Check if file exists locally
      if (!await file.exists()) {
        throw Exception('Selected file no longer exists');
      }
      
      // Upload file with progress tracking
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          customMetadata: {
            'userId': userId,
            'stepId': stepId,
            'documentType': documentType,
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalName': path.basename(file.path),
          },
          contentType: _getContentType(fileExtension),
        ),
      );
      
      // Listen to upload progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen(
          (TaskSnapshot snapshot) {
            if (snapshot.totalBytes > 0) {
              final progress = snapshot.bytesTransferred / snapshot.totalBytes;
              onProgress(progress);
            }
          },
          onError: (error) {
            print('❌ Upload progress error: $error');
          },
        );
      }
      
      // Wait for upload completion
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Upload completed successfully');
      print('📁 Download URL: $downloadUrl');
      
      return downloadUrl;
      
    } on FirebaseException catch (e) {
      print('❌ Firebase error uploading document: ${e.code} - ${e.message}');
      
      // Handle specific Firebase Storage errors
      switch (e.code) {
        case 'storage/object-not-found':
          throw Exception('Storage bucket not found. Please contact support.');
        case 'storage/unauthorized':
          throw Exception('Upload permission denied. Please check your account.');
        case 'storage/canceled':
          throw Exception('Upload was canceled.');
        case 'storage/unknown':
          throw Exception('An unknown error occurred. Please try again.');
        case 'storage/invalid-format':
          throw Exception('Invalid file format. Please use PDF, JPG, or PNG.');
        case 'storage/invalid-argument':
          throw Exception('Invalid upload parameters. Please try again.');
        default:
          throw Exception('Upload failed: ${e.message ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ Error uploading document: $e');
      throw Exception('Failed to upload document: ${e.toString()}');
    }
  }

  /// Upload KYC document bytes to Firebase Storage (for web)
  Future<String> uploadKycDocumentBytes({
    required String userId,
    required String stepId,
    required String documentType,
    required Uint8List fileBytes,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      print('📤 Starting bytes upload for user: $userId, step: $stepId, document: $documentType');
      print('📁 File name: $fileName');
      print('📊 File size: ${fileBytes.length} bytes');
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(fileName);
      final uniqueFileName = '${documentType}_$timestamp$fileExtension';
      
      // Create storage reference
      final storageRef = _storage.ref().child('kyc_documents/$userId/$stepId/$uniqueFileName');
      
      // Upload bytes with progress tracking
      final uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(
          customMetadata: {
            'userId': userId,
            'stepId': stepId,
            'documentType': documentType,
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalName': fileName,
          },
          contentType: _getContentType(fileExtension),
        ),
      );
      
      // Listen to upload progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }
      
      // Wait for completion
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Bytes upload completed successfully');
      print('📁 Download URL: $downloadUrl');
      
      return downloadUrl;
      
    } on FirebaseException catch (e) {
      print('❌ Firebase error uploading document bytes: ${e.code} - ${e.message}');
      
      // Handle specific Firebase Storage errors
      switch (e.code) {
        case 'storage/object-not-found':
          throw Exception('Storage bucket not found. Please contact support.');
        case 'storage/unauthorized':
          throw Exception('Upload permission denied. Please check your account.');
        case 'storage/canceled':
          throw Exception('Upload was canceled.');
        case 'storage/unknown':
          throw Exception('An unknown error occurred. Please try again.');
        case 'storage/invalid-format':
          throw Exception('Invalid file format. Please use PDF, JPG, or PNG.');
        case 'storage/invalid-argument':
          throw Exception('Invalid upload parameters. Please try again.');
        default:
          throw Exception('Upload failed: ${e.message ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ Error uploading document bytes: $e');
      throw Exception('Failed to upload document: ${e.toString()}');
    }
  }

  /// Get content type for file extension
  String _getContentType(String fileExtension) {
    switch (fileExtension.toLowerCase()) {
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// Upload multiple documents
  Future<Map<String, String>> uploadMultipleKycDocuments({
    required String userId,
    required String stepId,
    required Map<String, File> documents,
    Function(String documentType, double progress)? onProgress,
  }) async {
    final uploadResults = <String, String>{};
    
    for (final entry in documents.entries) {
      try {
        final downloadUrl = await uploadKycDocument(
          userId: userId,
          stepId: stepId,
          documentType: entry.key,
          file: entry.value,
          onProgress: onProgress != null 
              ? (progress) => onProgress(entry.key, progress)
              : null,
        );
        
        uploadResults[entry.key] = downloadUrl;
      } catch (e) {
        print('Failed to upload ${entry.key}: $e');
        // Continue with other uploads even if one fails
      }
    }
    
    return uploadResults;
  }

  /// Delete KYC document from Firebase Storage
  Future<void> deleteKycDocument(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      print('🗑️ Document deleted successfully');
    } catch (e) {
      print('❌ Error deleting document: $e');
      throw Exception('Failed to delete document: $e');
    }
  }

  /// Get metadata for uploaded document
  Future<FullMetadata?> getDocumentMetadata(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      return await ref.getMetadata();
    } catch (e) {
      print('❌ Error getting document metadata: $e');
      return null;
    }
  }

  /// List all documents for a user's KYC step
  Future<List<Reference>> listKycDocuments(String userId, String stepId) async {
    try {
      final ref = _storage.ref().child('kyc_documents/$userId/$stepId');
      final result = await ref.listAll();
      return result.items;
    } catch (e) {
      print('❌ Error listing documents: $e');
      return [];
    }
  }

  /// Upload profile picture
  Future<String> uploadProfilePicture({
    required String userId,
    required File file,
    Function(double)? onProgress,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(file.path);
      final fileName = 'profile_$timestamp$fileExtension';
      
      final storageRef = _storage.ref().child('profile_pictures/$userId/$fileName');
      
      final uploadTask = storageRef.putFile(file);
      
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
      
    } catch (e) {
      print('❌ Error uploading profile picture: $e');
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  /// Upload general document (for other purposes)
  Future<String> uploadDocument({
    required String userId,
    required String category,
    required File file,
    Map<String, String>? metadata,
    Function(double)? onProgress,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(file.path);
      final fileName = '${category}_$timestamp$fileExtension';
      
      final storageRef = _storage.ref().child('documents/$userId/$category/$fileName');
      
      final uploadMetadata = SettableMetadata(
        customMetadata: {
          'userId': userId,
          'category': category,
          'uploadedAt': DateTime.now().toIso8601String(),
          ...?metadata,
        },
      );
      
      final uploadTask = storageRef.putFile(file, uploadMetadata);
      
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
      
    } catch (e) {
      print('❌ Error uploading document: $e');
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Get file size in a human readable format
  String getFileSizeString(int bytes) {
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    if (bytes == 0) return '0 B';
    
    int i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Check if file type is allowed for KYC documents
  bool isAllowedFileType(String filePath) {
    final allowedExtensions = ['.pdf', '.jpg', '.jpeg', '.png'];
    
    if (filePath.isEmpty) {
      return false;
    }
    
    final fileExtension = path.extension(filePath).toLowerCase();
    return allowedExtensions.contains(fileExtension);
  }

  /// Check if file type is allowed based on filename (for web)
  bool isAllowedFileTypeByName(String fileName) {
    final allowedExtensions = ['.pdf', '.jpg', '.jpeg', '.png'];
    
    if (fileName.isEmpty) {
      return false;
    }
    
    final fileExtension = path.extension(fileName).toLowerCase();
    return allowedExtensions.contains(fileExtension);
  }

  /// Check if file size is within limits (5MB for images, 10MB for PDFs)
  bool isFileSizeValid(File file) {
    const maxImageSize = 5 * 1024 * 1024; // 5MB
    const maxPdfSize = 10 * 1024 * 1024; // 10MB
    
    final fileSize = file.lengthSync();
    final extension = path.extension(file.path).toLowerCase();
    
    if (['.jpg', '.jpeg', '.png'].contains(extension)) {
      return fileSize <= maxImageSize;
    } else if (extension == '.pdf') {
      return fileSize <= maxPdfSize;
    }
    
    return false;
  }

  /// Check if Firebase Storage is properly initialized
  Future<bool> isStorageAvailable() async {
    try {
      // Try to get the storage bucket reference
      final ref = _storage.ref();
      await ref.child('test').getMetadata().catchError((error) {
        // Expected error for non-existent file, but confirms storage is accessible
        return null;
      });
      return true;
    } catch (e) {
      print('❌ Firebase Storage not available: $e');
      return false;
    }
  }
} 