import 'package:cloud_firestore/cloud_firestore.dart';

class CommissionTransaction {
  final String id;
  final double amount;
  final double? commissionAmount;
  final DateTime? completedAt;
  final DateTime createdAt;
  final String customerId;
  final String customerName;
  final String description;
  final CommissionMetadata metadata;
  final String packageType;
  final String referrerId;
  final String referrerName;
  final String status;
  final String type;

  CommissionTransaction({
    required this.id,
    required this.amount,
    this.commissionAmount,
    this.completedAt,
    required this.createdAt,
    required this.customerId,
    required this.customerName,
    required this.description,
    required this.metadata,
    required this.packageType,
    required this.referrerId,
    required this.referrerName,
    required this.status,
    required this.type,
  });

  factory CommissionTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CommissionTransaction(
      id: doc.id,
      amount: (data['amount'] ?? 0).toDouble(),
      commissionAmount: data['commissionAmount']?.toDouble(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      description: data['description'] ?? '',
      metadata: CommissionMetadata.fromMap(data['metadata'] ?? {}),
      packageType: data['packageType'] ?? '',
      referrerId: data['referrerId'] ?? '',
      referrerName: data['referrerName'] ?? '',
      status: data['status'] ?? '',
      type: data['type'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'commissionAmount': commissionAmount,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'customerId': customerId,
      'customerName': customerName,
      'description': description,
      'metadata': metadata.toMap(),
      'packageType': packageType,
      'referrerId': referrerId,
      'referrerName': referrerName,
      'status': status,
      'type': type,
    };
  }

  String get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return '#10B981'; // Green
      case 'pending':
        return '#F59E0B'; // Orange
      case 'failed':
        return '#EF4444'; // Red
      default:
        return '#6B7280'; // Gray
    }
  }

  String get formattedAmount {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String get formattedCommissionAmount {
    if (commissionAmount == null) return 'N/A';
    return '₹${commissionAmount!.toStringAsFixed(2)}';
  }
}

class CommissionMetadata {
  final String commissionLevel;
  final double commissionRate;
  final String paymentMethod;
  final String processedBy;
  final String processedByName;
  final String relatedPaymentTransaction;

  CommissionMetadata({
    required this.commissionLevel,
    required this.commissionRate,
    required this.paymentMethod,
    required this.processedBy,
    required this.processedByName,
    required this.relatedPaymentTransaction,
  });

  factory CommissionMetadata.fromMap(Map<String, dynamic> map) {
    return CommissionMetadata(
      commissionLevel: map['commissionLevel'] ?? '',
      commissionRate: (map['commissionRate'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      processedBy: map['processedBy'] ?? '',
      processedByName: map['processedByName'] ?? '',
      relatedPaymentTransaction: map['relatedPaymentTransaction'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commissionLevel': commissionLevel,
      'commissionRate': commissionRate,
      'paymentMethod': paymentMethod,
      'processedBy': processedBy,
      'processedByName': processedByName,
      'relatedPaymentTransaction': relatedPaymentTransaction,
    };
  }

  String get formattedCommissionRate {
    return '${(commissionRate * 100).toStringAsFixed(1)}%';
  }
} 