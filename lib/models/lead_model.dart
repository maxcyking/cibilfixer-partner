import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_helpers.dart';

class Lead {
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
  final String tehsilCity;
  final String transactionId;
  final String updatedAt;
  final String village;
  final bool isSeen;
  final String? seenAt;

  Lead({
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
    required this.tehsilCity,
    required this.transactionId,
    required this.updatedAt,
    required this.village,
    this.isSeen = false,
    this.seenAt,
  });

  factory Lead.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Lead(
      id: doc.id,
      aadhar: data['aadhar'] as String? ?? '',
      address: data['address'] as String? ?? '',
      createdAt: FirestoreHelpers.convertToString(data['createdAt']),
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
      tehsilCity: data['tehsilCity'] as String? ?? '',
      transactionId: data['transactionId'] as String? ?? '',
      updatedAt: FirestoreHelpers.convertToString(data['updatedAt']),
      village: data['village'] as String? ?? '',
      isSeen: data['isSeen'] as bool? ?? false,
      seenAt: FirestoreHelpers.convertToStringNullable(data['seenAt']),
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
      'tehsilCity': tehsilCity,
      'transactionId': transactionId,
      'updatedAt': updatedAt,
      'village': village,
      'isSeen': isSeen,
      'seenAt': seenAt,
    };
  }

  Lead copyWith({
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
    String? tehsilCity,
    String? transactionId,
    String? updatedAt,
    String? village,
    bool? isSeen,
    String? seenAt,
  }) {
    return Lead(
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
      tehsilCity: tehsilCity ?? this.tehsilCity,
      transactionId: transactionId ?? this.transactionId,
      updatedAt: updatedAt ?? this.updatedAt,
      village: village ?? this.village,
      isSeen: isSeen ?? this.isSeen,
      seenAt: seenAt ?? this.seenAt,
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

  DateTime? get seenAtDate {
    try {
      return seenAt != null ? DateTime.parse(seenAt!) : null;
    } catch (e) {
      return null;
    }
  }
}

// Lead status enum
enum LeadStatus {
  newLead('NEW'),
  contacted('CONTACTED'),
  interested('INTERESTED'),
  notInterested('NOT INTERESTED'),
  noResponse('NO RESPONSE'),
  convertedToCustomer('CONVERTED TO CUSTOMER');

  const LeadStatus(this.value);
  final String value;

  static LeadStatus fromString(String status) {
    return LeadStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => LeadStatus.newLead,
    );
  }
} 