import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../providers/auth_provider.dart' as app_auth;
import '../../../services/referral_service.dart';
import '../../../services/system_settings_service.dart';
import '../../../services/customers_service.dart';
import '../../../models/user_model.dart';
import '../../../models/customer_model.dart';
import '../../../models/commission_transaction_model.dart';

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen>
    with TickerProviderStateMixin {
  final ReferralService _referralService = ReferralService();
  final SystemSettingsService _systemSettingsService = SystemSettingsService();
  final CustomersService _customersService = CustomersService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  
  Map<String, dynamic> _stats = {};
  List<UserModel> _referredUsers = [];
  List<Customer> _referredCustomers = [];
  List<CommissionTransaction> _commissionTransactions = [];
  List<Map<String, dynamic>> _recentActivities = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeAnimations();
    _loadReferralData();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimationController.forward();
  }

  Future<void> _loadReferralData() async {
    final user = FirebaseAuth.instance.currentUser;
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final userReferralCode = authProvider.userData?['myReferralCode'];
    
    if (user == null || userReferralCode == null) return;

    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _referralService.getReferralStats(userReferralCode, user.uid),
        _referralService.getReferredUsers(userReferralCode),
        _referralService.getReferredCustomers(userReferralCode),
        _referralService.getCommissionTransactions(user.uid),
        _referralService.getRecentActivities(userReferralCode, user.uid),
        _systemSettingsService.getCommissionSettings(),
        _customersService.getCustomers(referralCode: userReferralCode),
      ]);
      
      final originalStats = results[0] as Map<String, dynamic>;
      final commissionSettings = results[5] as Map<String, dynamic>;
      final allReferredCustomers = results[6] as List<Customer>;
      
      // Calculate pending amounts based on commission settings and customer amount due
      final directReferrerRate = commissionSettings['directReferrerRate'] ?? 0.1;
      double totalPendingAmount = 0.0;
      double totalAmountDue = 0.0;
      double totalAmountPaid = 0.0;
      
      for (final customer in allReferredCustomers) {
        totalAmountDue += customer.amountDue;
        
        // Calculate amount paid (packagePrice - amountDue)
        final amountPaid = (customer.packagePrice ?? 0.0) - customer.amountDue;
        totalAmountPaid += amountPaid;
        
        // Calculate pending commission (commission rate * amount due)
        if (customer.amountDue > 0) {
          totalPendingAmount += customer.amountDue * directReferrerRate;
        }
      }
      
      // Enhance stats with real pending amount calculation
      final enhancedStats = Map<String, dynamic>.from(originalStats);
      enhancedStats['pendingEarnings'] = totalPendingAmount;
      enhancedStats['totalAmountDue'] = totalAmountDue;
      enhancedStats['totalAmountPaid'] = totalAmountPaid;
      enhancedStats['commissionRate'] = directReferrerRate;
      
      setState(() {
        _stats = enhancedStats;
        _referredUsers = results[1] as List<UserModel>;
        _referredCustomers = allReferredCustomers;
        _commissionTransactions = results[3] as List<CommissionTransaction>;
        _recentActivities = results[4] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading referral data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _shareReferralCode(String referralCode) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    
    if (authProvider.requiresKyc) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Complete KYC verification to share referral code'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final message = 'Join CibilFixer using my referral code: $referralCode\n\n'
        'Get access to premium financial services and exclusive benefits!\n'
        'Download the app now: https://futurecapital.com/download';
    
    Share.share(message, subject: 'Join CibilFixer with my referral code');
  }

  void _copyReferralCode(String referralCode) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    
    if (authProvider.requiresKyc) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Complete KYC verification to copy referral code'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    Clipboard.setData(ClipboardData(text: referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Referral code copied to clipboard!'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _loadReferralData,
          color: AppColors.primary,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: ResponsiveUtils.getPadding(context),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(height: _getResponsiveSpacing(8, 12, 16)),
                    _buildWelcomeSection(),
                    SizedBox(height: _getResponsiveSpacing(16, 20, 24)),
                    _buildReferralCodeCard(),
                    SizedBox(height: _getResponsiveSpacing(20, 24, 28)),
                    _buildStatsGrid(),
                    SizedBox(height: _getResponsiveSpacing(20, 24, 28)),
                    _buildTabSection(),
                    SizedBox(height: _getResponsiveSpacing(16, 20, 24)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getResponsiveSpacing(double mobile, double tablet, double desktop) {
    if (ResponsiveUtils.isDesktop(context)) return desktop;
    if (ResponsiveUtils.isTablet(context)) return tablet;
    return mobile;
  }

  Widget _buildWelcomeSection() {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, child) {
        final userName = authProvider.userData?['name'] ?? 'Partner';
        
        return Container(
          padding: EdgeInsets.all(_getResponsiveSpacing(16, 20, 24)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
                AppColors.secondary.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(_getResponsiveSpacing(16, 20, 24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(_getResponsiveSpacing(12, 14, 16)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(_getResponsiveSpacing(12, 14, 16)),
                ),
                child: Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: _getResponsiveSpacing(28, 32, 36),
                ),
              ),
              SizedBox(width: _getResponsiveSpacing(12, 16, 20)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $userName!',
                      style: TextStyle(
                        fontSize: _getResponsiveSpacing(18, 20, 24),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage your referrals and track earnings',
                      style: TextStyle(
                        fontSize: _getResponsiveSpacing(12, 14, 16),
                        color: Colors.white.withOpacity(0.9),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReferralCodeCard() {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, child) {
        final userReferralCode = authProvider.userData?['myReferralCode'] ?? '';
        
        return Container(
          padding: EdgeInsets.all(_getResponsiveSpacing(16, 20, 24)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_getResponsiveSpacing(16, 20, 24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.card_giftcard_rounded,
                    color: AppColors.primary,
                    size: _getResponsiveSpacing(20, 22, 24),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Your Referral Code',
                    style: TextStyle(
                      fontSize: _getResponsiveSpacing(14, 16, 18),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: _getResponsiveSpacing(12, 14, 16)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _getResponsiveSpacing(16, 18, 20),
                  vertical: _getResponsiveSpacing(12, 14, 16),
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(_getResponsiveSpacing(12, 14, 16)),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        userReferralCode.isEmpty ? 'Loading...' : userReferralCode,
                        style: TextStyle(
                          fontSize: _getResponsiveSpacing(16, 18, 20),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          icon: Icons.copy_rounded,
                          onPressed: () => _copyReferralCode(userReferralCode),
                          tooltip: 'Copy Code',
                        ),
                        SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.share_rounded,
                          onPressed: () => _shareReferralCode(userReferralCode),
                          tooltip: 'Share Code',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(_getResponsiveSpacing(8, 9, 10)),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: _getResponsiveSpacing(16, 18, 20),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_isLoading) {
      return _buildLoadingGrid();
    }

    final crossAxisCount = ResponsiveUtils.isDesktop(context) 
        ? 4 
        : ResponsiveUtils.isTablet(context) 
            ? 2 
            : 2;

    final statsData = [
      {
        'title': 'Total Referrals',
        'value': _stats['totalReferrals']?.toString() ?? '0',
        'subtitle': 'Users joined',
        'icon': Icons.people_rounded,
        'color': Colors.blue,
        'trend': '+${_stats['thisMonthCustomers'] ?? 0} this month',
      },
      {
        'title': 'Active Customers',
        'value': _stats['totalCustomers']?.toString() ?? '0',
        'subtitle': 'Paying customers',
        'icon': Icons.verified_user_rounded,
        'color': Colors.green,
        'trend': '${(_stats['conversionRate'] ?? 0).toStringAsFixed(1)}% conversion',
      },
      {
        'title': 'Total Earnings',
        'value': '₹${NumberFormat('#,##,###').format(_stats['totalEarnings'] ?? 0)}',
        'subtitle': 'Commission earned',
        'icon': Icons.account_balance_wallet_rounded,
        'color': Colors.orange,
        'trend': '+₹${NumberFormat('#,##,###').format(_stats['thisMonthEarnings'] ?? 0)} this month',
      },
      {
        'title': 'Pending Amount',
        'value': '₹${NumberFormat('#,##,###').format(_stats['pendingEarnings'] ?? 0)}',
        'subtitle': 'From amount due',
        'icon': Icons.schedule_rounded,
        'color': Colors.purple,
        'trend': '${((_stats['commissionRate'] ?? 0.1) * 100).toStringAsFixed(0)}% commission rate',
      },
    ];

    final additionalStatsData = [
      // {
      //   'title': 'Total Amount Due',
      //   'value': '₹${NumberFormat('#,##,###').format(_stats['totalAmountDue'] ?? 0)}',
      //   'subtitle': 'From customers',
      //   'icon': Icons.payment_rounded,
      //   'color': Colors.red,
      //   'trend': '${_referredCustomers.where((c) => c.amountDue > 0).length} pending customers',
      // },
      // {
      //   'title': 'Amount Paid',
      //   'value': '₹${NumberFormat('#,##,###').format(_stats['totalAmountPaid'] ?? 0)}',
      //   'subtitle': 'By customers',
      //   'icon': Icons.check_circle_rounded,
      //   'color': Colors.green,
      //   'trend': '${_referredCustomers.where((c) => c.paymentStatus.toLowerCase().contains('done')).length} paid customers',
      // },
    ];

    return Column(
      children: [
        // Main stats grid
        GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: _getResponsiveSpacing(12, 16, 20),
        mainAxisSpacing: _getResponsiveSpacing(12, 16, 20),
        childAspectRatio: ResponsiveUtils.isMobile(context) ? 1.1 : 1.2,
      ),
      itemCount: statsData.length,
      itemBuilder: (context, index) {
        final stat = statsData[index];
        return _buildStatCard(stat);
      },
        ),
        
        if (additionalStatsData.isNotEmpty) ...[
          SizedBox(height: _getResponsiveSpacing(12, 16, 20)),
          
          // Additional stats grid  
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveUtils.isDesktop(context) ? 2 : 2,
              crossAxisSpacing: _getResponsiveSpacing(12, 16, 20),
              mainAxisSpacing: _getResponsiveSpacing(12, 16, 20),
              childAspectRatio: ResponsiveUtils.isMobile(context) ? 1.1 : 1.2,
            ),
            itemCount: additionalStatsData.length,
            itemBuilder: (context, index) {
              final stat = additionalStatsData[index];
              return _buildStatCard(stat);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Container(
      padding: EdgeInsets.all(_getResponsiveSpacing(16, 18, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getResponsiveSpacing(16, 18, 20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(_getResponsiveSpacing(8, 9, 10)),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  stat['icon'],
                  color: stat['color'],
                  size: _getResponsiveSpacing(18, 20, 22),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: Colors.green,
                  size: _getResponsiveSpacing(12, 14, 16),
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSpacing(12, 14, 16)),
          Text(
            stat['value'],
            style: TextStyle(
              fontSize: _getResponsiveSpacing(18, 20, 24),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            stat['title'],
            style: TextStyle(
              fontSize: _getResponsiveSpacing(12, 13, 14),
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: _getResponsiveSpacing(8, 9, 10)),
          Text(
            stat['trend'],
            style: TextStyle(
              fontSize: _getResponsiveSpacing(10, 11, 12),
              color: Colors.green.shade600,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    final crossAxisCount = ResponsiveUtils.isDesktop(context) ? 4 : 2;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: _getResponsiveSpacing(12, 16, 20),
        mainAxisSpacing: _getResponsiveSpacing(12, 16, 20),
        childAspectRatio: ResponsiveUtils.isMobile(context) ? 1.1 : 1.2,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => _buildLoadingCard(),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: EdgeInsets.all(_getResponsiveSpacing(16, 18, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getResponsiveSpacing(16, 18, 20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: _getResponsiveSpacing(32, 36, 40),
                height: _getResponsiveSpacing(32, 36, 40),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Spacer(),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSpacing(12, 14, 16)),
          Container(
            width: double.infinity,
            height: _getResponsiveSpacing(20, 22, 26),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity * 0.7,
            height: _getResponsiveSpacing(12, 13, 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getResponsiveSpacing(16, 20, 24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_getResponsiveSpacing(16, 20, 24)),
                topRight: Radius.circular(_getResponsiveSpacing(16, 20, 24)),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: _getResponsiveSpacing(12, 13, 14),
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: _getResponsiveSpacing(12, 13, 14),
              ),
              tabs: [
                Tab(text: 'Referred Users'),
                Tab(text: 'Customers'),
                Tab(text: 'Transactions'),
                Tab(text: 'Activities'),
              ],
            ),
          ),
          SizedBox(
            height: _getResponsiveSpacing(300, 350, 400),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReferredUsersTab(),
                _buildCustomersTab(),
                _buildTransactionsTab(),
                _buildActivitiesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferredUsersTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_referredUsers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No Referred Users Yet',
        subtitle: 'Share your referral code to start earning!',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(_getResponsiveSpacing(16, 18, 20)),
      itemCount: _referredUsers.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = _referredUsers[index];
        return _buildUserTile(user);
      },
    );
  }

  Widget _buildCustomersTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_referredCustomers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.verified_user_outlined,
        title: 'No Customers Yet',
        subtitle: 'Keep referring to get your first customer!',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(_getResponsiveSpacing(16, 18, 20)),
      itemCount: _referredCustomers.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final customer = _referredCustomers[index];
        return _buildCustomerTile(customer);
      },
    );
  }

  Widget _buildTransactionsTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_commissionTransactions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No Transactions Yet',
        subtitle: 'Your commission earnings will appear here',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(_getResponsiveSpacing(16, 18, 20)),
      itemCount: _commissionTransactions.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final transaction = _commissionTransactions[index];
        return _buildTransactionTile(transaction);
      },
    );
  }

  Widget _buildActivitiesTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_recentActivities.isEmpty) {
      return _buildEmptyState(
        icon: Icons.timeline_outlined,
        title: 'No Recent Activities',
        subtitle: 'Your referral activities will be shown here',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(_getResponsiveSpacing(16, 18, 20)),
      itemCount: _recentActivities.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final activity = _recentActivities[index];
        return _buildActivityTile(activity);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_getResponsiveSpacing(24, 28, 32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: _getResponsiveSpacing(48, 56, 64),
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: _getResponsiveSpacing(16, 18, 20)),
            Text(
              title,
              style: TextStyle(
                fontSize: _getResponsiveSpacing(16, 18, 20),
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: _getResponsiveSpacing(12, 14, 16),
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(UserModel user) {
    return Container(
      padding: EdgeInsets.all(_getResponsiveSpacing(12, 14, 16)),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(_getResponsiveSpacing(12, 14, 16)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: _getResponsiveSpacing(16, 18, 20),
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: _getResponsiveSpacing(12, 14, 16),
              ),
            ),
          ),
          SizedBox(width: _getResponsiveSpacing(12, 14, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty ? user.fullName : 'Unknown User',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: _getResponsiveSpacing(12, 14, 16),
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: _getResponsiveSpacing(10, 11, 12),
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Active',
              style: TextStyle(
                fontSize: _getResponsiveSpacing(9, 10, 11),
                color: Colors.green.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTile(Customer customer) {
    final statusColor = customer.paymentStatus.toLowerCase().contains('done') 
        ? Colors.green 
        : customer.paymentStatus.toLowerCase().contains('pending')
            ? Colors.orange
            : Colors.red;

    final amountPaid = (customer.packagePrice ?? 0.0) - customer.amountDue;
    final commissionRate = _stats['commissionRate'] ?? 0.1;
    final pendingCommission = customer.amountDue * commissionRate;

    return Container(
      padding: EdgeInsets.all(_getResponsiveSpacing(16, 18, 20)),
      margin: EdgeInsets.only(bottom: _getResponsiveSpacing(8, 10, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getResponsiveSpacing(12, 14, 16)),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
        children: [
          CircleAvatar(
                radius: _getResponsiveSpacing(18, 20, 22),
            backgroundColor: statusColor.withOpacity(0.1),
            child: Text(
              customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : 'C',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                    fontSize: _getResponsiveSpacing(14, 16, 18),
              ),
            ),
          ),
          SizedBox(width: _getResponsiveSpacing(12, 14, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.fullName.isNotEmpty ? customer.fullName : 'Unknown Customer',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                        fontSize: _getResponsiveSpacing(14, 16, 18),
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: _getResponsiveSpacing(12, 13, 14),
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4),
                Text(
                          customer.mobile,
                  style: TextStyle(
                            fontSize: _getResponsiveSpacing(11, 12, 13),
                    color: AppColors.textSecondary,
                  ),
                        ),
                      ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              customer.paymentStatus,
              style: TextStyle(
                fontSize: _getResponsiveSpacing(9, 10, 11),
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: _getResponsiveSpacing(12, 14, 16)),
          
          // Customer Details
          Container(
            padding: EdgeInsets.all(_getResponsiveSpacing(12, 14, 16)),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(_getResponsiveSpacing(8, 10, 12)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Customer ID',
                        customer.customerId,
                        Icons.badge_outlined,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Package',
                        customer.packageName ?? 'Not assigned',
                        Icons.inventory_2_outlined,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _getResponsiveSpacing(8, 10, 12)),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Amount Due',
                        '₹${customer.amountDue.toStringAsFixed(0)}',
                        Icons.payments_outlined,
                        valueColor: Colors.red.shade600,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Amount Paid',
                        '₹${amountPaid.toStringAsFixed(0)}',
                        Icons.check_circle_outline,
                        valueColor: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
                if (customer.amountDue > 0) ...[
                  SizedBox(height: _getResponsiveSpacing(8, 10, 12)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(_getResponsiveSpacing(8, 10, 12)),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: _getResponsiveSpacing(14, 16, 18),
                          color: Colors.purple.shade600,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Pending Commission: ',
                          style: TextStyle(
                            fontSize: _getResponsiveSpacing(11, 12, 13),
                            color: Colors.purple.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹${pendingCommission.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: _getResponsiveSpacing(11, 12, 13),
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '(${(commissionRate * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: _getResponsiveSpacing(10, 11, 12),
                            color: Colors.purple.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: _getResponsiveSpacing(12, 13, 14),
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: _getResponsiveSpacing(10, 11, 12),
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: _getResponsiveSpacing(11, 12, 13),
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTransactionTile(CommissionTransaction transaction) {
    final statusColor = transaction.status.toLowerCase() == 'completed' 
        ? Colors.green 
        : transaction.status.toLowerCase() == 'pending'
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: EdgeInsets.all(_getResponsiveSpacing(12, 14, 16)),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(_getResponsiveSpacing(12, 14, 16)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(_getResponsiveSpacing(8, 9, 10)),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: statusColor,
              size: _getResponsiveSpacing(16, 18, 20),
            ),
          ),
          SizedBox(width: _getResponsiveSpacing(12, 14, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${NumberFormat('#,##,###').format(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: _getResponsiveSpacing(14, 16, 18),
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy').format(transaction.createdAt),
                  style: TextStyle(
                    fontSize: _getResponsiveSpacing(10, 11, 12),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              transaction.status.toUpperCase(),
              style: TextStyle(
                fontSize: _getResponsiveSpacing(9, 10, 11),
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(Map<String, dynamic> activity) {
    IconData icon;
    Color color;
    
    switch (activity['type']) {
      case 'customer':
        icon = Icons.person_add_rounded;
        color = Colors.green;
        break;
      case 'user':
        icon = Icons.people_rounded;
        color = Colors.blue;
        break;
      case 'transaction':
        icon = Icons.account_balance_wallet_rounded;
        color = Colors.orange;
        break;
      default:
        icon = Icons.timeline_rounded;
        color = Colors.purple;
    }

    return Container(
      padding: EdgeInsets.all(_getResponsiveSpacing(12, 14, 16)),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(_getResponsiveSpacing(12, 14, 16)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(_getResponsiveSpacing(8, 9, 10)),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: _getResponsiveSpacing(16, 18, 20),
            ),
          ),
          SizedBox(width: _getResponsiveSpacing(12, 14, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? 'Activity',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: _getResponsiveSpacing(12, 14, 16),
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  activity['subtitle'] ?? 'Recent activity',
                  style: TextStyle(
                    fontSize: _getResponsiveSpacing(10, 11, 12),
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            activity['time'] ?? 'Now',
            style: TextStyle(
              fontSize: _getResponsiveSpacing(9, 10, 11),
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 