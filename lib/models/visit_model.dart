import 'package:cloud_firestore/cloud_firestore.dart';

class Visit {
  final String id;
  final String userId;
  final String userName;
  final DateTime dateOfVisit;
  final String name;
  final String firmCompanyName;
  final String village;
  final String tehsilCity;
  final String district;
  final String state;
  final String pin;
  final String remark;
  final DateTime createdAt;
  final DateTime updatedAt;

  Visit({
    required this.id,
    required this.userId,
    required this.userName,
    required this.dateOfVisit,
    required this.name,
    required this.firmCompanyName,
    required this.village,
    required this.tehsilCity,
    required this.district,
    required this.state,
    required this.pin,
    required this.remark,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Visit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Visit(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      dateOfVisit: (data['dateOfVisit'] as Timestamp?)?.toDate() ?? DateTime.now(),
      name: data['name'] ?? '',
      firmCompanyName: data['firmCompanyName'] ?? '',
      village: data['village'] ?? '',
      tehsilCity: data['tehsilCity'] ?? '',
      district: data['district'] ?? '',
      state: data['state'] ?? '',
      pin: data['pin'] ?? '',
      remark: data['remark'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'dateOfVisit': Timestamp.fromDate(dateOfVisit),
      'name': name,
      'firmCompanyName': firmCompanyName,
      'village': village,
      'tehsilCity': tehsilCity,
      'district': district,
      'state': state,
      'pin': pin,
      'remark': remark,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Visit copyWith({
    String? id,
    String? userId,
    String? userName,
    DateTime? dateOfVisit,
    String? name,
    String? firmCompanyName,
    String? village,
    String? tehsilCity,
    String? district,
    String? state,
    String? pin,
    String? remark,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Visit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      dateOfVisit: dateOfVisit ?? this.dateOfVisit,
      name: name ?? this.name,
      firmCompanyName: firmCompanyName ?? this.firmCompanyName,
      village: village ?? this.village,
      tehsilCity: tehsilCity ?? this.tehsilCity,
      district: district ?? this.district,
      state: state ?? this.state,
      pin: pin ?? this.pin,
      remark: remark ?? this.remark,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fullAddress {
    final parts = [village, tehsilCity, district, state, pin]
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
} 