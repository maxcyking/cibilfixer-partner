import 'package:flutter/material.dart';

enum KycStepStatus {
  pending,
  approved,
  rejected,
}

class KycStepModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final KycStepStatus status;
  final Map<String, dynamic> fields;
  final Map<String, dynamic>? documents;
  final bool isRequired;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  KycStepModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.status,
    required this.fields,
    this.documents,
    required this.isRequired,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
  });

  KycStepModel copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    KycStepStatus? status,
    Map<String, dynamic>? fields,
    Map<String, dynamic>? documents,
    bool? isRequired,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? reviewedAt,
  }) {
    return KycStepModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      fields: fields ?? Map<String, dynamic>.from(this.fields),
      documents: documents ?? (this.documents != null 
          ? Map<String, dynamic>.from(this.documents!) 
          : null),
      isRequired: isRequired ?? this.isRequired,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': _statusToString(status),
      'fields': fields,
      'documents': documents,
      'isRequired': isRequired,
      'rejectionReason': rejectionReason,
      'submittedAt': submittedAt?.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
    };
  }

  factory KycStepModel.fromMap(Map<String, dynamic> map) {
    return KycStepModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: Icons.help_outline, // Default icon, should be set by caller
      status: _stringToStatus(map['status']),
      fields: Map<String, dynamic>.from(map['fields'] ?? {}),
      documents: map['documents'] != null 
          ? Map<String, dynamic>.from(map['documents']) 
          : null,
      isRequired: map['isRequired'] ?? true,
      rejectionReason: map['rejectionReason'],
      submittedAt: map['submittedAt'] != null 
          ? DateTime.parse(map['submittedAt']) 
          : null,
      reviewedAt: map['reviewedAt'] != null 
          ? DateTime.parse(map['reviewedAt']) 
          : null,
    );
  }

  static String _statusToString(KycStepStatus status) {
    switch (status) {
      case KycStepStatus.pending:
        return 'pending';
      case KycStepStatus.approved:
        return 'approved';
      case KycStepStatus.rejected:
        return 'rejected';
    }
  }

  static KycStepStatus _stringToStatus(String? status) {
    switch (status) {
      case 'approved':
        return KycStepStatus.approved;
      case 'rejected':
        return KycStepStatus.rejected;
      case 'pending':
      default:
        return KycStepStatus.pending;
    }
  }

  bool get isCompleted => status == KycStepStatus.approved;
  bool get isPending => status == KycStepStatus.pending;
  bool get isRejected => status == KycStepStatus.rejected;

  // Check if step is filled (has required data)
  bool get isFilled {
    // Check if required fields are filled
    for (final entry in fields.entries) {
      if (isRequired && entry.value != null && entry.value.toString().isNotEmpty) {
        return true; // At least one field is filled
      }
    }
    
    // Check if required documents are uploaded
    if (documents != null) {
      for (final doc in documents!.values) {
        if (doc != null) {
          return true; // At least one document is uploaded
        }
      }
    }
    
    return false;
  }

  double get completionPercentage {
    final totalFields = fields.length + (documents?.length ?? 0);
    if (totalFields == 0) return 0.0;

    int completedFields = 0;
    
    // Count filled fields
    for (final value in fields.values) {
      if (value != null && value.toString().trim().isNotEmpty) {
        completedFields++;
      }
    }
    
    // Count uploaded documents
    if (documents != null) {
      for (final doc in documents!.values) {
        if (doc != null) {
          completedFields++;
        }
      }
    }
    
    return completedFields / totalFields;
  }
} 