import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/package_model.dart';

class PackagesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _packagesCollection => _firestore.collection('packages');

  /// Get all packages
  Future<List<Package>> getPackages({
    PackageStatus? statusFilter,
    String? categoryFilter,
  }) async {
    try {
      Query query = _packagesCollection.orderBy('createdAt', descending: true);
      
      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.name);
      }
      
      if (categoryFilter != null) {
        query = query.where('category', isEqualTo: categoryFilter);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) => Package.fromFirestore(doc)).toList();
      
    } catch (e) {
      print('Error fetching packages: $e');
      return [];
    }
  }

  /// Get active packages only
  Future<List<Package>> getActivePackages() async {
    try {
      final querySnapshot = await _packagesCollection
          .where('status', isEqualTo: PackageStatus.active.name)
          .orderBy('price')
          .get();
      
      return querySnapshot.docs.map((doc) => Package.fromFirestore(doc)).toList();
      
    } catch (e) {
      print('Error fetching active packages: $e');
      return [];
    }
  }

  /// Get package by ID
  Future<Package?> getPackageById(String packageId) async {
    try {
      final doc = await _packagesCollection.doc(packageId).get();
      
      if (doc.exists) {
        return Package.fromFirestore(doc);
      }
      
      return null;
      
    } catch (e) {
      print('Error fetching package: $e');
      return null;
    }
  }

  /// Create a new package
  Future<String?> createPackage(Package package) async {
    try {
      final docRef = await _packagesCollection.add(package.toFirestore());
      
      print('Package created successfully with ID: ${docRef.id}');
      return docRef.id;
      
    } catch (e) {
      print('Error creating package: $e');
      return null;
    }
  }

  /// Update an existing package
  Future<bool> updatePackage(String packageId, Package package) async {
    try {
      final updatedPackage = package.copyWith(
        id: packageId,
        updatedAt: DateTime.now(),
      );
      
      await _packagesCollection.doc(packageId).update(updatedPackage.toFirestore());
      
      print('Package updated successfully: $packageId');
      return true;
      
    } catch (e) {
      print('Error updating package: $e');
      return false;
    }
  }

  /// Delete a package
  Future<bool> deletePackage(String packageId) async {
    try {
      await _packagesCollection.doc(packageId).delete();
      
      print('Package deleted successfully: $packageId');
      return true;
      
    } catch (e) {
      print('Error deleting package: $e');
      return false;
    }
  }

  /// Update package status
  Future<bool> updatePackageStatus(String packageId, PackageStatus newStatus) async {
    try {
      await _packagesCollection.doc(packageId).update({
        'status': newStatus.name,
        'updatedAt': Timestamp.now(),
      });
      
      print('Package status updated successfully: $packageId');
      return true;
      
    } catch (e) {
      print('Error updating package status: $e');
      return false;
    }
  }

  /// Get packages by category
  Future<List<Package>> getPackagesByCategory(String category) async {
    try {
      final querySnapshot = await _packagesCollection
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: PackageStatus.active.name)
          .orderBy('price')
          .get();
      
      return querySnapshot.docs.map((doc) => Package.fromFirestore(doc)).toList();
      
    } catch (e) {
      print('Error fetching packages by category: $e');
      return [];
    }
  }

  /// Search packages
  Future<List<Package>> searchPackages(String searchQuery) async {
    try {
      final querySnapshot = await _packagesCollection.get();
      
      final allPackages = querySnapshot.docs.map((doc) => Package.fromFirestore(doc)).toList();
      
      final filteredPackages = allPackages.where((package) {
        final query = searchQuery.toLowerCase();
        return package.name.toLowerCase().contains(query) ||
               package.description.toLowerCase().contains(query) ||
               package.category.toLowerCase().contains(query) ||
               package.features.any((feature) => feature.toLowerCase().contains(query));
      }).toList();
      
      return filteredPackages;
      
    } catch (e) {
      print('Error searching packages: $e');
      return [];
    }
  }

  /// Get package statistics
  Future<Map<String, dynamic>> getPackageStats() async {
    try {
      final querySnapshot = await _packagesCollection.get();
      final packages = querySnapshot.docs.map((doc) => Package.fromFirestore(doc)).toList();
      
      int activeCount = 0;
      int inactiveCount = 0;
      int draftCount = 0;
      double totalRevenue = 0.0;
      double avgPrice = 0.0;
      
      for (var package in packages) {
        switch (package.status) {
          case PackageStatus.active:
            activeCount++;
            totalRevenue += package.price;
            break;
          case PackageStatus.inactive:
            inactiveCount++;
            break;
          case PackageStatus.draft:
            draftCount++;
            break;
        }
      }
      
      if (packages.isNotEmpty) {
        avgPrice = packages.map((p) => p.price).reduce((a, b) => a + b) / packages.length;
      }
      
      return {
        'totalPackages': packages.length,
        'activePackages': activeCount,
        'inactivePackages': inactiveCount,
        'draftPackages': draftCount,
        'totalPotentialRevenue': totalRevenue,
        'averagePrice': avgPrice,
      };
      
    } catch (e) {
      print('Error fetching package stats: $e');
      return {
        'totalPackages': 0,
        'activePackages': 0,
        'inactivePackages': 0,
        'draftPackages': 0,
        'totalPotentialRevenue': 0.0,
        'averagePrice': 0.0,
      };
    }
  }

  /// Check if package is in use (has customers assigned)
  Future<bool> isPackageInUse(String packageId) async {
    try {
      final customersSnapshot = await _firestore.collection('customers')
          .where('packageId', isEqualTo: packageId)
          .limit(1)
          .get();
      
      return customersSnapshot.docs.isNotEmpty;
      
    } catch (e) {
      print('Error checking package usage: $e');
      return false;
    }
  }

  /// Assign package to customer
  Future<bool> assignPackageToCustomer(String customerId, String packageId) async {
    try {
      await _firestore.collection('customers').doc(customerId).update({
        'packageId': packageId,
        'updatedAt': Timestamp.now(),
      });
      
      print('Package assigned to customer successfully');
      return true;
      
    } catch (e) {
      print('Error assigning package to customer: $e');
      return false;
    }
  }

  /// Remove package assignment from customer
  Future<bool> removePackageFromCustomer(String customerId) async {
    try {
      await _firestore.collection('customers').doc(customerId).update({
        'packageId': FieldValue.delete(),
        'updatedAt': Timestamp.now(),
      });
      
      print('Package removed from customer successfully');
      return true;
      
    } catch (e) {
      print('Error removing package from customer: $e');
      return false;
    }
  }
} 