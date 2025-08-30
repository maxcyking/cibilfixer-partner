import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String aadhar;
  final String address;
  final String createdAt;
  final String customerId;
  final String district;
  final String dob;
  final Map<String, dynamic> documents;
  final String fatherName;
  final String fullName;
  final String gender;
  final String issue;
  final String mobile;
  final String pan;
  final String pin;
  final String referralCode;
  final String referralCode1; // Second level referral code (referrer of referrer)
  final String remark;
  final String state;
  final String status;
  final String paymentStatus;
  final String tehsilCity;
  final String transactionId;
  final String updatedAt;
  final String village;
  final String? email; // Added for Firebase Auth user
  final String? userId; // Firebase Auth UID
  final String? packageId; // Assigned package ID
  final String? packageName; // Assigned package name
  final double? packagePrice; // Assigned package price
  final double amountDue; // Amount due for payment
  final String? lastPaymentDate;
  final String? lastPaymentMethod;
  final double? lastPaymentAmount;

  Customer({
    required this.id,
    required this.aadhar,
    required this.address,
    required this.createdAt,
    required this.customerId,
    required this.district,
    required this.dob,
    required this.documents,
    required this.fatherName,
    required this.fullName,
    required this.gender,
    required this.issue,
    required this.mobile,
    required this.pan,
    required this.pin,
    required this.referralCode,
    required this.referralCode1,
    required this.remark,
    required this.state,
    required this.status,
    required this.paymentStatus,
    required this.tehsilCity,
    required this.transactionId,
    required this.updatedAt,
    required this.village,
    this.email,
    this.userId,
    this.packageId,
    this.packageName,
    this.packagePrice,
    this.amountDue = 0.0,
    this.lastPaymentDate,
    this.lastPaymentMethod,
    this.lastPaymentAmount,
  });

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Helper function to convert Timestamp to String
    String convertToString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Timestamp) return value.toDate().toIso8601String();
      return value.toString();
    }
    
    return Customer(
      id: doc.id,
      aadhar: data['aadhar'] as String? ?? '',
      address: data['address'] as String? ?? '',
      createdAt: convertToString(data['createdAt']),
      customerId: data['customerId'] as String? ?? '',
      district: data['district'] as String? ?? '',
      dob: data['dob'] as String? ?? '',
      documents: data['documents'] as Map<String, dynamic>? ?? {},
      fatherName: data['fatherName'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      issue: data['issue'] as String? ?? '',
      mobile: data['mobile'] as String? ?? '',
      pan: data['pan'] as String? ?? '',
      pin: data['pin'] as String? ?? '',
      referralCode: data['referralCode'] as String? ?? '',
      referralCode1: data['referralCode1'] as String? ?? '',
      remark: data['remark'] as String? ?? '',
      state: data['state'] as String? ?? '',
      status: data['status'] as String? ?? '',
      paymentStatus: data['paymentStatus'] as String? ?? '',
      tehsilCity: data['tehsilCity'] as String? ?? '',
      transactionId: data['transactionId'] as String? ?? '',
      updatedAt: convertToString(data['updatedAt']),
      village: data['village'] as String? ?? '',
      email: data['email'] as String?,
      userId: data['userId'] as String?,
      packageId: data['packageId'] as String?,
      packageName: data['packageName'] as String?,
      packagePrice: data['packagePrice'] != null ? (data['packagePrice'] as num).toDouble() : null,
      amountDue: data['amountDue'] != null ? (data['amountDue'] as num).toDouble() : 0.0,
      lastPaymentDate: data['lastPaymentDate'] as String?,
      lastPaymentMethod: data['lastPaymentMethod'] as String?,
      lastPaymentAmount: data['lastPaymentAmount'] != null ? (data['lastPaymentAmount'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'aadhar': aadhar,
      'address': address,
      'createdAt': createdAt,
      'customerId': customerId,
      'district': district,
      'dob': dob,
      'documents': documents,
      'fatherName': fatherName,
      'fullName': fullName,
      'gender': gender,
      'issue': issue,
      'mobile': mobile,
      'pan': pan,
      'pin': pin,
      'referralCode': referralCode,
      'referralCode1': referralCode1,
      'remark': remark,
      'state': state,
      'status': status,
      'paymentStatus': paymentStatus,
      'tehsilCity': tehsilCity,
      'transactionId': transactionId,
      'updatedAt': updatedAt,
      'village': village,
      'email': email,
      'userId': userId,
      'packageId': packageId,
      'packageName': packageName,
      'packagePrice': packagePrice,
      'amountDue': amountDue,
      'lastPaymentDate': lastPaymentDate,
      'lastPaymentMethod': lastPaymentMethod,
      'lastPaymentAmount': lastPaymentAmount,
    };
  }

  Customer copyWith({
    String? aadhar,
    String? address,
    String? createdAt,
    String? customerId,
    String? district,
    String? dob,
    Map<String, dynamic>? documents,
    String? fatherName,
    String? fullName,
    String? gender,
    String? issue,
    String? mobile,
    String? pan,
    String? pin,
    String? referralCode,
    String? referralCode1,
    String? remark,
    String? state,
    String? status,
    String? paymentStatus,
    String? tehsilCity,
    String? transactionId,
    String? updatedAt,
    String? village,
    String? email,
    String? userId,
    String? packageId,
    String? packageName,
    double? packagePrice,
    double? amountDue,
    String? lastPaymentDate,
    String? lastPaymentMethod,
    double? lastPaymentAmount,
  }) {
    return Customer(
      id: id,
      aadhar: aadhar ?? this.aadhar,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      customerId: customerId ?? this.customerId,
      district: district ?? this.district,
      dob: dob ?? this.dob,
      documents: documents ?? this.documents,
      fatherName: fatherName ?? this.fatherName,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      issue: issue ?? this.issue,
      mobile: mobile ?? this.mobile,
      pan: pan ?? this.pan,
      pin: pin ?? this.pin,
      referralCode: referralCode ?? this.referralCode,
      referralCode1: referralCode1 ?? this.referralCode1,
      remark: remark ?? this.remark,
      state: state ?? this.state,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      tehsilCity: tehsilCity ?? this.tehsilCity,
      transactionId: transactionId ?? this.transactionId,
      updatedAt: updatedAt ?? this.updatedAt,
      village: village ?? this.village,
      email: email ?? this.email,
      userId: userId ?? this.userId,
      packageId: packageId ?? this.packageId,
      packageName: packageName ?? this.packageName,
      packagePrice: packagePrice ?? this.packagePrice,
      amountDue: amountDue ?? this.amountDue,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      lastPaymentMethod: lastPaymentMethod ?? this.lastPaymentMethod,
      lastPaymentAmount: lastPaymentAmount ?? this.lastPaymentAmount,
    );
  }

  DateTime? get createdAtDate {
    try {
      return DateTime.parse(createdAt);
    } catch (e) {
      return null;
    }
  }

  DateTime? get updatedAtDate {
    try {
      return DateTime.parse(updatedAt);
    } catch (e) {
      return null;
    }
  }

  DateTime? get dobDate {
    try {
      return DateTime.parse(dob);
    } catch (e) {
      return null;
    }
  }

  String get name => fullName;

  // Helper methods for package assignment
  bool get hasPackage => packageId != null && packageId!.isNotEmpty;
  
  String get packageDisplayName => packageName ?? 'No Package';
  
  String get packagePriceDisplay => packagePrice != null ? '₹${packagePrice!.toStringAsFixed(0)}' : 'Free';
  
  // Helper methods for amount due
  bool get hasAmountDue => amountDue > 0;
  
  String get amountDueDisplay => '₹${amountDue.toStringAsFixed(0)}';
  
  bool get isPaymentPending => hasAmountDue && paymentStatus.toLowerCase() != 'full payment done';
}

// Customer status enum
enum CustomerStatus {
  pendingPaymentConfirmation('PENDING FOR PAYMENT CONFIRMATION'),
  inProcessingWithBank('IN PROCESSING WITH BANK/CIC'),
  pendingWithBankForPayment('PENDING WITH BANK FOR PAYMENT'),
  pendingWithCic('PENDING WITH CIC'),
  pendingWithCustomerForFullPayment('PENDING WITH CUSTOMER FOR FULL PAYMENT'),
  fullPaymentDone('FULL PAYMENT DONE'),
  inProcessingWithBankStep2('IN PROCESSING WITH BANK/CIC 2 STEP'),
  completed('COMPLETED'),
  lost('LOST');

  const CustomerStatus(this.value);
  final String value;

  static CustomerStatus fromString(String status) {
    // Normalize the input status (handle underscores, case, etc.)
    final normalizedInput = status.toUpperCase()
        .replaceAll('_', ' ')
        .replaceAll('CONFERMATION', 'CONFIRMATION')
        .trim();
    
    return CustomerStatus.values.firstWhere(
      (e) => e.value.toUpperCase() == normalizedInput,
      orElse: () => CustomerStatus.pendingPaymentConfirmation,
    );
  }
}

// Payment status enum
enum PaymentStatus {
  pending('PENDING'),
  partialPayment('PARTIAL PAYMENT'),
  fullPaymentDone('FULL PAYMENT DONE'),
  overdue('OVERDUE'),
  refunded('REFUNDED');

  const PaymentStatus(this.value);
  final String value;

  static PaymentStatus fromString(String status) {
    final normalizedInput = status.toUpperCase().trim();
    
    return PaymentStatus.values.firstWhere(
      (e) => e.value.toUpperCase() == normalizedInput,
      orElse: () => PaymentStatus.pending,
    );
  }
} 