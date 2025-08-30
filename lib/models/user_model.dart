import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String mobile;
  final String role;
  final String status;
  final String kycStatus;
  final String? myReferralCode;
  final String? referredBy;
  final String? dateOfBirth;
  final String? lastPayoutDate;
  final double? lastPayoutAmount;
  final bool isActive;
  final int earnings;
  final double walletAmount;
  final int referrals;
  final int kycProgress;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.mobile,
    required this.role,
    required this.status,
    required this.kycStatus,
    this.myReferralCode,
    this.referredBy,
    this.dateOfBirth,
    this.lastPayoutDate,
    this.lastPayoutAmount,
    required this.isActive,
    required this.earnings,
    required this.walletAmount,
    required this.referrals,
    required this.kycProgress,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      mobile: data['mobile'] ?? '',
      role: data['role'] ?? 'user',
      status: data['status'] ?? 'pending',
      kycStatus: data['kycStatus'] ?? 'pending',
      myReferralCode: data['myReferralCode'],
      referredBy: data['referredBy'],
      dateOfBirth: data['dateOfBirth'],
      lastPayoutDate: data['lastPayoutDate'],
      lastPayoutAmount: data['lastPayoutAmount']?.toDouble(),
      isActive: data['isActive'] ?? false,
      earnings: data['earnings'] ?? 0,
      walletAmount: data['walletAmount']?.toDouble() ?? 0.0,
      referrals: data['referrals'] ?? 0,
      kycProgress: data['kycProgress'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] is Timestamp 
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt']))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'mobile': mobile,
      'role': role,
      'status': status,
      'kycStatus': kycStatus,
      'myReferralCode': myReferralCode,
      'referredBy': referredBy,
      'dateOfBirth': dateOfBirth,
      'lastPayoutDate': lastPayoutDate,
      'lastPayoutAmount': lastPayoutAmount,
      'isActive': isActive,
      'earnings': earnings,
      'walletAmount': walletAmount,
      'referrals': referrals,
      'kycProgress': kycProgress,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? mobile,
    String? role,
    String? status,
    String? kycStatus,
    String? myReferralCode,
    String? referredBy,
    String? dateOfBirth,
    String? lastPayoutDate,
    double? lastPayoutAmount,
    bool? isActive,
    int? earnings,
    double? walletAmount,
    int? referrals,
    int? kycProgress,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      mobile: mobile ?? this.mobile,
      role: role ?? this.role,
      status: status ?? this.status,
      kycStatus: kycStatus ?? this.kycStatus,
      myReferralCode: myReferralCode ?? this.myReferralCode,
      referredBy: referredBy ?? this.referredBy,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      lastPayoutDate: lastPayoutDate ?? this.lastPayoutDate,
      lastPayoutAmount: lastPayoutAmount ?? this.lastPayoutAmount,
      isActive: isActive ?? this.isActive,
      earnings: earnings ?? this.earnings,
      walletAmount: walletAmount ?? this.walletAmount,
      referrals: referrals ?? this.referrals,
      kycProgress: kycProgress ?? this.kycProgress,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper method to format date of birth
  String get formattedDateOfBirth {
    if (dateOfBirth == null || dateOfBirth!.isEmpty) {
      return 'Not provided';
    }
    try {
      final date = DateTime.parse(dateOfBirth!);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateOfBirth!;
    }
  }

  // Helper method to calculate age
  int? get age {
    if (dateOfBirth == null || dateOfBirth!.isEmpty) {
      return null;
    }
    try {
      final date = DateTime.parse(dateOfBirth!);
      final now = DateTime.now();
      int age = now.year - date.year;
      if (now.month < date.month || (now.month == date.month && now.day < date.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }
} 