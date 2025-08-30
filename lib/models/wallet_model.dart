import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String id;
  final String userId;
  final String userName;
  final double balance;
  final double totalEarned;
  final int referralCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  Wallet({
    required this.id,
    required this.userId,
    required this.userName,
    this.balance = 0.0,
    this.totalEarned = 0.0,
    this.referralCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.metadata = const {},
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Wallet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Wallet(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      balance: (data['balance'] ?? 0.0).toDouble(),
      totalEarned: (data['totalEarned'] ?? 0.0).toDouble(),
      referralCount: data['referralCount'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'balance': balance,
      'totalEarned': totalEarned,
      'referralCount': referralCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  Wallet copyWith({
    String? id,
    String? userId,
    String? userName,
    double? balance,
    double? totalEarned,
    int? referralCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      referralCount: referralCount ?? this.referralCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  factory Wallet.createNew({
    required String userId,
    required String userName,
  }) {
    final now = DateTime.now();
    return Wallet(
      id: '',
      userId: userId,
      userName: userName,
      balance: 0.0,
      totalEarned: 0.0,
      referralCount: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Helper methods
  String get formattedBalance => '₹${balance.toStringAsFixed(2)}';
  String get formattedTotalEarned => '₹${totalEarned.toStringAsFixed(2)}';
  bool get hasBalance => balance > 0;
} 