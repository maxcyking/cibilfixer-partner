import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  payment,
  commission,
  withdrawal,
  refund,
  payout,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

enum PackageType {
  basic,
  premium,
  enterprise,
}

class Transaction {
  final String id;
  final String customerId;
  final String customerName;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final PackageType packageType;
  final String? referrerId;
  final String? referrerName;
  final double? commissionAmount;
  final String description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic> metadata;

  Transaction({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.type,
    required this.status,
    required this.packageType,
    this.referrerId,
    this.referrerName,
    this.commissionAmount,
    required this.description,
    required this.createdAt,
    this.completedAt,
    this.metadata = const {},
  });

  // Package pricing configuration
  static const Map<PackageType, double> packagePrices = {
    PackageType.basic: 500.0,
    PackageType.premium: 1000.0,
    PackageType.enterprise: 1500.0,
  };

  // Commission rates (10% for referrers)
  static const double commissionRate = 0.10;

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.payment,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TransactionStatus.pending,
      ),
      packageType: PackageType.values.firstWhere(
        (e) => e.name == data['packageType'],
        orElse: () => PackageType.basic,
      ),
      referrerId: data['referrerId'],
      referrerName: data['referrerName'],
      commissionAmount: data['commissionAmount']?.toDouble(),
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'type': type.name,
      'status': status.name,
      'packageType': packageType.name,
      'referrerId': referrerId,
      'referrerName': referrerName,
      'commissionAmount': commissionAmount,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'metadata': metadata,
    };
  }

  Transaction copyWith({
    String? id,
    String? customerId,
    String? customerName,
    double? amount,
    TransactionType? type,
    TransactionStatus? status,
    PackageType? packageType,
    String? referrerId,
    String? referrerName,
    double? commissionAmount,
    String? description,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Transaction(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      packageType: packageType ?? this.packageType,
      referrerId: referrerId ?? this.referrerId,
      referrerName: referrerName ?? this.referrerName,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  static PackageType getPackageFromIssue(String issue) {
    final lowerIssue = issue.toLowerCase();
    if (lowerIssue.contains('premium') || lowerIssue.contains('gold')) {
      return PackageType.premium;
    } else if (lowerIssue.contains('enterprise') || lowerIssue.contains('platinum')) {
      return PackageType.enterprise;
    }
    return PackageType.basic;
  }
} 