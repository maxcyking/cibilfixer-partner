import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum PackageStatus {
  active,
  inactive,
  draft,
}

class Package {
  final String id;
  final String name;
  final double price;
  final String description;
  final List<String> features;
  final PackageStatus status;
  final String category;
  final int durationDays;
  final double commissionRate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final Map<String, dynamic> metadata;

  Package({
    required this.id,
    required this.name,
    required this.price,
    this.description = '',
    this.features = const [],
    this.status = PackageStatus.active,
    this.category = 'General',
    this.durationDays = 30,
    this.commissionRate = 0.1,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.createdBy = '',
    this.metadata = const {},
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Package.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Package(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      features: List<String>.from(data['features'] ?? []),
      status: PackageStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PackageStatus.active,
      ),
      category: data['category'] ?? 'General',
      durationDays: data['durationDays'] ?? 30,
      commissionRate: (data['commissionRate'] ?? 0.1).toDouble(),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'features': features,
      'status': status.name,
      'category': category,
      'durationDays': durationDays,
      'commissionRate': commissionRate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'metadata': metadata,
    };
  }

  Package copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    List<String>? features,
    PackageStatus? status,
    String? category,
    int? durationDays,
    double? commissionRate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? metadata,
  }) {
    return Package(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      features: features ?? this.features,
      status: status ?? this.status,
      category: category ?? this.category,
      durationDays: durationDays ?? this.durationDays,
      commissionRate: commissionRate ?? this.commissionRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      metadata: metadata ?? this.metadata,
    );
  }

  // Factory method to create a simple package with just name and price
  factory Package.createSimple({
    required String name,
    required double price,
    String? createdBy,
  }) {
    final now = DateTime.now();
    return Package(
      id: '',
      name: name,
      price: price,
      createdAt: now,
      updatedAt: now,
      createdBy: createdBy ?? '',
    );
  }

  // Factory method to create a full package (for backward compatibility)
  factory Package.createFull({
    required String name,
    required double price,
    String description = '',
    List<String> features = const [],
    String category = 'General',
    String createdBy = '',
    int durationDays = 30,
    double commissionRate = 0.1,
    PackageStatus status = PackageStatus.active,
  }) {
    final now = DateTime.now();
    return Package(
      id: '',
      name: name,
      price: price,
      description: description,
      features: features,
      status: status,
      category: category,
      durationDays: durationDays,
      commissionRate: commissionRate,
      createdAt: now,
      updatedAt: now,
      createdBy: createdBy,
    );
  }

  // Helper methods
  bool get isActive => status == PackageStatus.active;
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';
  String get formattedCommission => '${(commissionRate * 100).toStringAsFixed(1)}%';
  
  // Package hierarchy and upgrade logic
  bool isUpgradeFrom(Package? otherPackage) {
    if (otherPackage == null) return true;
    return price > otherPackage.price;
  }
  
  bool isDowngradeFrom(Package? otherPackage) {
    if (otherPackage == null) return false;
    return price < otherPackage.price;
  }
  
  bool isSameTierAs(Package? otherPackage) {
    if (otherPackage == null) return false;
    return price == otherPackage.price;
  }
  
  String getChangeTypeFrom(Package? otherPackage) {
    if (otherPackage == null) return 'new';
    if (isUpgradeFrom(otherPackage)) return 'upgrade';
    if (isDowngradeFrom(otherPackage)) return 'downgrade';
    return 'same';
  }
  
  // Get package tier based on price ranges
  String get tier {
    if (price >= 1500) return 'Enterprise';
    if (price >= 1000) return 'Premium';
    if (price >= 500) return 'Standard';
    return 'Basic';
  }
  
  // Get tier color
  Color get tierColor {
    switch (tier) {
      case 'Enterprise':
        return const Color(0xFF7C3AED); // Purple
      case 'Premium':
        return const Color(0xFFEF4444); // Red
      case 'Standard':
        return const Color(0xFFF59E0B); // Orange
      default:
        return const Color(0xFF10B981); // Green
    }
  }

  // Common package categories
  static const List<String> categories = [
    'General',
    'Credit Report',
    'Loan Services',
    'Financial Advisory',
    'Credit Repair',
    'Investment Planning',
    'Insurance Services',
  ];

  // Validation - only name and price are required
  bool get isValid {
    return name.isNotEmpty && price > 0;
  }
} 