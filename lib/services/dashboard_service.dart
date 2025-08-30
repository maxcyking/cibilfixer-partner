import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get dashboard statistics
  Future<DashboardStats> getDashboardStats() async {
    try {
      print('🔍 Fetching dashboard statistics...');
      
      // Get current date for monthly calculations
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0);
      
      // Fetch all users
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;
      
      // Process users and extract creation dates
      final users = <Map<String, dynamic>>[];
      int thisMonthUsers = 0;
      int lastMonthUsers = 0;
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        DateTime? createdAt;
        
        // Handle different createdAt field types
        final createdAtField = data['createdAt'];
        if (createdAtField is Timestamp) {
          createdAt = createdAtField.toDate();
        } else if (createdAtField is String) {
          try {
            createdAt = DateTime.parse(createdAtField);
          } catch (e) {
            print('Warning: Could not parse createdAt string: $createdAtField');
          }
        }
        
        // Count users by month
        if (createdAt != null) {
          if (createdAt.isAfter(startOfMonth)) {
            thisMonthUsers++;
          } else if (createdAt.isAfter(startOfLastMonth) && createdAt.isBefore(startOfMonth)) {
            lastMonthUsers++;
          }
        }
        
        users.add({...data, 'parsedCreatedAt': createdAt});
      }
      
      // Calculate user growth trend
      double userGrowthTrend = 0;
      if (lastMonthUsers > 0) {
        userGrowthTrend = ((thisMonthUsers - lastMonthUsers) / lastMonthUsers) * 100;
      } else if (thisMonthUsers > 0) {
        userGrowthTrend = 100; // 100% growth if no users last month but users this month
      }
      
      // Count active users (isActive = true)
      final activeUsers = users.where((data) {
        return data['isActive'] == true;
      }).length;
      
      // Count pending KYC users
      final pendingKycUsers = users.where((data) {
        return data['kycStatus'] == 'pending' || data['kycStatus'] == 'submitted';
      }).length;
      
      // Count completed KYC users
      final completedKycUsers = users.where((data) {
        return data['kycStatus'] == 'approved';
      }).length;
      
      // Calculate KYC completion rate
      double kycCompletionRate = 0;
      if (totalUsers > 0) {
        kycCompletionRate = (completedKycUsers / totalUsers) * 100;
      }
      
      // Calculate total earnings
      double totalEarnings = 0;
      double thisMonthEarnings = 0;
      double lastMonthEarnings = 0;
      
      for (var userData in users) {
        final userEarnings = (userData['earnings'] as num?)?.toDouble() ?? 0;
        totalEarnings += userEarnings;
        
        // For monthly earnings calculation, we'd need transaction history
        // For now, we'll estimate based on user creation date
        final createdAt = userData['parsedCreatedAt'] as DateTime?;
        if (createdAt != null) {
          if (createdAt.isAfter(startOfMonth)) {
            thisMonthEarnings += userEarnings * 0.3; // Estimate 30% of earnings this month
          } else if (createdAt.isAfter(startOfLastMonth) && createdAt.isBefore(startOfMonth)) {
            lastMonthEarnings += userEarnings * 0.3;
          }
        }
      }
      
      // Calculate earnings growth trend
      double earningsGrowthTrend = 0;
      if (lastMonthEarnings > 0) {
        earningsGrowthTrend = ((thisMonthEarnings - lastMonthEarnings) / lastMonthEarnings) * 100;
      } else if (thisMonthEarnings > 0) {
        earningsGrowthTrend = 100;
      }
      
      print('📊 Dashboard stats calculated:');
      print('   Total Users: $totalUsers');
      print('   Active Users: $activeUsers');
      print('   Pending KYC: $pendingKycUsers');
      print('   KYC Rate: ${kycCompletionRate.toStringAsFixed(1)}%');
      print('   Total Earnings: ₹${totalEarnings.toStringAsFixed(0)}');
      
      return DashboardStats(
        totalUsers: totalUsers,
        userGrowthTrend: userGrowthTrend,
        activeUsers: activeUsers,
        activeUsersGrowthTrend: userGrowthTrend * 0.8, // Estimate active user growth
        pendingKyc: pendingKycUsers,
        pendingKycTrend: -5.2, // Mock trend for pending KYC (negative is good)
        kycCompletionRate: kycCompletionRate,
        kycCompletionTrend: 2.3,
        totalEarnings: totalEarnings,
        earningsGrowthTrend: earningsGrowthTrend,
      );
    } catch (e) {
      print('❌ Error fetching dashboard stats: $e');
      // Return default stats on error
      return DashboardStats(
        totalUsers: 0,
        userGrowthTrend: 0,
        activeUsers: 0,
        activeUsersGrowthTrend: 0,
        pendingKyc: 0,
        pendingKycTrend: 0,
        kycCompletionRate: 0,
        kycCompletionTrend: 0,
        totalEarnings: 0,
        earningsGrowthTrend: 0,
      );
    }
  }

  // Get recent activity
  Future<List<ActivityItem>> getRecentActivity() async {
    try {
      print('🔍 Fetching recent activity...');
      
      final activities = <ActivityItem>[];
      
      // Fetch all users and process them locally (since we can't sort mixed field types in Firestore)
      final usersSnapshot = await _firestore.collection('users').get();
      
      final usersWithDates = <Map<String, dynamic>>[];
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        DateTime? createdAt;
        
        // Handle different createdAt field types
        final createdAtField = data['createdAt'];
        if (createdAtField is Timestamp) {
          createdAt = createdAtField.toDate();
        } else if (createdAtField is String) {
          try {
            createdAt = DateTime.parse(createdAtField);
          } catch (e) {
            print('Warning: Could not parse createdAt string: $createdAtField');
            // Skip this user if we can't parse the date
            continue;
          }
        }
        
        if (createdAt != null) {
          usersWithDates.add({
            ...data,
            'parsedCreatedAt': createdAt,
            'uid': doc.id,
          });
        }
      }
      
      // Sort by creation date (most recent first)
      usersWithDates.sort((a, b) => 
        (b['parsedCreatedAt'] as DateTime).compareTo(a['parsedCreatedAt'] as DateTime));
      
      // Add recent user registrations
      final recentUsers = usersWithDates.take(5);
      for (var userData in recentUsers) {
        final createdAt = userData['parsedCreatedAt'] as DateTime;
        final fullName = userData['fullName'] as String? ?? 'Unknown User';
        
        activities.add(ActivityItem(
          title: 'New user registration',
          description: '$fullName registered',
          time: _formatTimeAgo(createdAt),
          icon: 'person_add',
          iconColor: 'success',
          timestamp: createdAt,
        ));
      }
      
      // Add KYC status activities
      final kycUsers = usersWithDates.where((userData) {
        final kycStatus = userData['kycStatus'] as String?;
        return kycStatus == 'approved' || kycStatus == 'rejected';
      }).take(3);
      
      for (var userData in kycUsers) {
        final fullName = userData['fullName'] as String? ?? 'Unknown User';
        final kycStatus = userData['kycStatus'] as String? ?? 'unknown';
        final createdAt = userData['parsedCreatedAt'] as DateTime;
        
        activities.add(ActivityItem(
          title: kycStatus == 'approved' ? 'KYC approved' : 'KYC requires attention',
          description: '$fullName\'s KYC verification $kycStatus',
          time: _formatTimeAgo(createdAt.add(const Duration(hours: 2))), // Simulate KYC processing time
          icon: kycStatus == 'approved' ? 'verified_user' : 'warning',
          iconColor: kycStatus == 'approved' ? 'success' : 'warning',
          timestamp: createdAt.add(const Duration(hours: 2)),
        ));
      }
      
      // Add some mock financial activities
      final now = DateTime.now();
      activities.addAll([
        ActivityItem(
          title: 'Commission processed',
          description: 'Monthly commission payments processed',
          time: _formatTimeAgo(now.subtract(const Duration(hours: 6))),
          icon: 'payment',
          iconColor: 'success',
          timestamp: now.subtract(const Duration(hours: 6)),
        ),
        ActivityItem(
          title: 'System backup',
          description: 'Daily system backup completed successfully',
          time: _formatTimeAgo(now.subtract(const Duration(hours: 12))),
          icon: 'backup',
          iconColor: 'info',
          timestamp: now.subtract(const Duration(hours: 12)),
        ),
      ]);
      
      // Sort by timestamp (most recent first)
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      print('📝 Fetched ${activities.length} activity items');
      
      return activities.take(10).toList(); // Return top 10 activities
    } catch (e) {
      print('❌ Error fetching recent activity: $e');
      return [];
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }
}

class DashboardStats {
  final int totalUsers;
  final double userGrowthTrend;
  final int activeUsers;
  final double activeUsersGrowthTrend;
  final int pendingKyc;
  final double pendingKycTrend;
  final double kycCompletionRate;
  final double kycCompletionTrend;
  final double totalEarnings;
  final double earningsGrowthTrend;

  DashboardStats({
    required this.totalUsers,
    required this.userGrowthTrend,
    required this.activeUsers,
    required this.activeUsersGrowthTrend,
    required this.pendingKyc,
    required this.pendingKycTrend,
    required this.kycCompletionRate,
    required this.kycCompletionTrend,
    required this.totalEarnings,
    required this.earningsGrowthTrend,
  });
}

class ActivityItem {
  final String title;
  final String description;
  final String time;
  final String icon;
  final String iconColor;
  final DateTime timestamp;

  ActivityItem({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.timestamp,
  });
} 