import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/commission_transaction_model.dart';
import '../../../services/commission_transaction_service.dart';
import '../../../services/payout_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/cards/app_card.dart';

// Unified transaction model for display
class UnifiedTransaction {
  final String id;
  final double amount;
  final DateTime createdAt;
  final String description;
  final String status;
  final TransactionType type;
  final String? customerName;
  final String? customerId;
  final String? referrerName;
  final String? packageType;
  final double? commissionAmount;
  final Map<String, dynamic>? metadata;
  final DateTime? completedAt;

  UnifiedTransaction({
    required this.id,
    required this.amount,
    required this.createdAt,
    required this.description,
    required this.status,
    required this.type,
    this.customerName,
    this.customerId,
    this.referrerName,
    this.packageType,
    this.commissionAmount,
    this.metadata,
    this.completedAt,
  });

  // Create from commission transaction (credit)
  factory UnifiedTransaction.fromCommission(CommissionTransaction commission) {
    return UnifiedTransaction(
      id: commission.id,
      amount: commission.amount,
      createdAt: commission.createdAt,
      description: commission.description,
      status: commission.status,
      type: TransactionType.credit,
      customerName: commission.customerName,
      customerId: commission.customerId,
      referrerName: commission.referrerName,
      packageType: commission.packageType,
      commissionAmount: commission.commissionAmount,
      metadata: commission.metadata.toMap(),
      completedAt: commission.completedAt,
    );
  }

  // Create from payout transaction (debit)
  factory UnifiedTransaction.fromPayout(Map<String, dynamic> payout) {
    return UnifiedTransaction(
      id: payout['id'] ?? '',
      amount: (payout['amount'] ?? 0.0).toDouble(),
      createdAt: payout['createdAt']?.toDate() ?? DateTime.now(),
      description: payout['description'] ?? 'Payout transaction',
      status: payout['status'] ?? 'pending',
      type: TransactionType.debit,
      metadata: {
        'paymentMethod': payout['paymentMethod'],
        'bankAccount': payout['bankAccount'],
        'upiId': payout['upiId'],
      },
      completedAt: payout['completedAt']?.toDate(),
    );
  }

  String get formattedAmount {
    return '₹${NumberFormat('#,##0.00').format(amount)}';
  }

  bool get isCredit => type == TransactionType.credit;
  bool get isDebit => type == TransactionType.debit;
}

enum TransactionType { credit, debit }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with TickerProviderStateMixin {
  final CommissionTransactionService _commissionService = CommissionTransactionService();
  final PayoutService _payoutService = PayoutService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  late AnimationController _headerAnimationController;
  late Animation<double> _headerOpacityAnimation;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  
  List<UnifiedTransaction> _transactions = [];
  List<UnifiedTransaction> _filteredTransactions = [];
  Map<String, dynamic> _stats = {};
  double _totalPayouts = 0.0;
  bool _isLoading = true;
  bool _isHeaderExpanded = true;
  String _selectedFilter = 'all';
  
  final List<Map<String, String>> _filterOptions = [
    {'value': 'all', 'label': 'All Transactions'},
    {'value': 'credit', 'label': 'Credits (Commissions)'},
    {'value': 'debit', 'label': 'Debits (Payouts)'},
    {'value': 'completed', 'label': 'Completed'},
    {'value': 'pending', 'label': 'Pending'},
    {'value': 'failed', 'label': 'Failed'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _loadTransactions();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _headerOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOut,
      ),
    );
    
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
      ),
    );
    
    _fadeAnimationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final scrollOffset = _scrollController.offset;
      final shouldShrink = scrollOffset > 100;
      
      if (shouldShrink && _isHeaderExpanded) {
        setState(() => _isHeaderExpanded = false);
        _headerAnimationController.forward();
      } else if (!shouldShrink && !_isHeaderExpanded) {
        setState(() => _isHeaderExpanded = true);
        _headerAnimationController.reverse();
      }
    });
  }

  Future<void> _loadTransactions() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    
    try {
      // Load transactions and payout data in parallel
      final results = await Future.wait([
        _commissionService.getUserCommissionTransactions(user.uid),
        _commissionService.getCommissionStats(user.uid),
        _payoutService.getUserPayoutHistory(user.uid),
      ]);

      final commissions = results[0] as List<CommissionTransaction>;
      final stats = results[1] as Map<String, dynamic>;
      final payouts = results[2] as List;

      // Combine transactions
      final allUnifiedTransactions = <UnifiedTransaction>[];
      
      // Add commission transactions (credits)
      for (final commission in commissions) {
        allUnifiedTransactions.add(UnifiedTransaction.fromCommission(commission));
      }
      
      // Add payout transactions (debits)
      for (final payout in payouts) {
        if (payout is Map<String, dynamic>) {
          allUnifiedTransactions.add(UnifiedTransaction.fromPayout(payout));
        }
      }

      // Sort by date (newest first)
      allUnifiedTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Calculate total payouts
      double totalPayouts = 0.0;
      for (final payout in payouts) {
        if (payout is Map<String, dynamic>) {
          totalPayouts += (payout['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      setState(() {
        _transactions = allUnifiedTransactions;
        _filteredTransactions = allUnifiedTransactions;
        _stats = stats;
        _totalPayouts = totalPayouts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterTransactions() {
    List<UnifiedTransaction> filtered = _transactions;

    // Apply status filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((t) {
        if (_selectedFilter == 'credit') return t.isCredit;
        if (_selectedFilter == 'debit') return t.isDebit;
        return t.status.toLowerCase() == _selectedFilter;
      }).toList();
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((t) {
        final customerName = t.customerName?.toLowerCase() ?? '';
        final customerId = t.customerId?.toLowerCase() ?? '';
        final description = t.description.toLowerCase();
        final amount = t.amount.toString();
        
        return customerName.contains(query) ||
            customerId.contains(query) ||
            description.contains(query) ||
            amount.contains(query);
      }).toList();
    }

    setState(() => _filteredTransactions = filtered);
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _fadeAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
            _buildShrinkableHeader(),
                  SliverToBoxAdapter(
                    child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                            children: [
                    _buildSearchAndFilter(),
                    const SizedBox(height: 16),
                    _buildTransactionsList(),
                  ],
                                  ),
                                ),
                              ),
                            ],
                          ),
      ),
    );
  }

  Widget _buildShrinkableHeader() {
    return SliverAppBar(
      expandedHeight: _getExpandedHeight(),
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: AnimatedBuilder(
          animation: _headerOpacityAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: 1.0 - _headerOpacityAnimation.value,
              child: Text(
                'My Transactions',
                style: AppTextStyles.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary500,
                AppColors.primary600,
                AppColors.primary700,
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
            child: Padding(
                    padding: EdgeInsets.all(
                      _getResponsivePadding(constraints.maxWidth),
                    ),
              child: AnimatedBuilder(
                animation: _headerOpacityAnimation,
                builder: (context, child) {
                        return AnimatedOpacity(
                    opacity: _headerOpacityAnimation.value,
                          duration: const Duration(milliseconds: 300),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                              _buildResponsiveHeaderTitle(constraints.maxWidth),
                              SizedBox(
                                height: _getResponsiveSpacing(
                                  constraints.maxWidth,
                                ),
                              ),
                              _buildResponsiveStatsCards(constraints.maxWidth),
                      ],
                    ),
                  );
                },
              ),
                  ),
                );
              },
            ),
                              ),
                            ),
                          ),
    );
  }

  double _getExpandedHeight() {
    return MediaQuery.of(context).size.width < 600 ? 400.0 : 350.0;
  }

  double _getResponsivePadding(double screenWidth) {
    if (screenWidth < 600) return 16.0; // Mobile
    if (screenWidth < 1200) return 20.0; // Tablet
    return 24.0; // Desktop
  }

  double _getResponsiveSpacing(double screenWidth) {
    if (screenWidth < 600) return 16.0; // Mobile
    if (screenWidth < 1200) return 18.0; // Tablet
    return 20.0; // Desktop
  }

  Widget _buildResponsiveHeaderTitle(double screenWidth) {
    final isMobile = screenWidth < 600;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
            ),
            child: Icon(
              Icons.receipt_long,
              color: Colors.white,
              size: isMobile ? 24.0 : 28.0,
            ),
          ),
          SizedBox(width: isMobile ? 12.0 : 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commission Transactions',
                  style: (isMobile
                          ? AppTextStyles.headlineMedium
                          : AppTextStyles.headlineLarge)
                      .copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your earning history & analytics',
                  style: (isMobile
                          ? AppTextStyles.bodyMedium
                          : AppTextStyles.bodyLarge)
                      .copyWith(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveStatsCards(double screenWidth) {
    if (_isLoading) {
      return _buildResponsiveLoadingStatsCards(screenWidth);
    }

    final enhancedStats = _calculateEnhancedStats();
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    if (isMobile) {
      return _buildMobileStatsLayout(enhancedStats);
    } else if (isTablet) {
      return _buildTabletStatsLayout(enhancedStats);
    } else {
      return _buildDesktopStatsLayout(enhancedStats);
    }
  }

  Widget _buildMobileStatsLayout(Map<String, dynamic> stats) {
    return Column(
        children: [
        // Top Row - 2 Cards
        Row(
          children: [
            Expanded(
              child: _buildResponsiveMainStatCard(
                title: 'Total Earnings',
                value: '₹${(stats['totalEarnings'] ?? 0.0).toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet,
                color: Colors.white,
                subtitle: 'All time',
                trend: (stats['earningsGrowth'] ?? 0) > 0 ? 'up' : 'down',
                trendValue:
                    '${(stats['earningsGrowth'] ?? 0.0).toStringAsFixed(1)}%',
                isMobile: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildResponsiveMainStatCard(
                title: 'Transactions',
                value: (stats['totalTransactions'] ?? 0).toString(),
                icon: Icons.receipt,
                color: Colors.white,
                subtitle: 'Total count',
                trend: (stats['transactionGrowth'] ?? 0) > 0 ? 'up' : 'down',
                trendValue:
                    '${(stats['transactionGrowth'] ?? 0.0).toStringAsFixed(1)}%',
                isMobile: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Second Row - 1 Card
        _buildResponsiveMainStatCard(
          title: 'This Month',
          value: '₹${(stats['thisMonthCommission'] ?? 0.0).toStringAsFixed(0)}',
          icon: Icons.calendar_today,
          color: Colors.white,
          subtitle: '${stats['thisMonthTransactions'] ?? 0} transactions',
          trend: (stats['earningsGrowth'] ?? 0) > 0 ? 'up' : 'down',
          trendValue: '${(stats['earningsGrowth'] ?? 0.0).toStringAsFixed(1)}%',
          isMobile: true,
        ),
        const SizedBox(height: 12),
        ],
      );
    }

  Widget _buildTabletStatsLayout(Map<String, dynamic> stats) {
    return Column(
      children: [
        // Top Row - 3 Cards
        Row(
      children: [
        Expanded(
              child: _buildResponsiveMainStatCard(
                title: 'Total Earnings',
                value: '₹${(stats['totalEarnings'] ?? 0.0).toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet,
                color: Colors.white,
                subtitle: 'All time',
                trend: (stats['earningsGrowth'] ?? 0) > 0 ? 'up' : 'down',
                trendValue:
                    '${(stats['earningsGrowth'] ?? 0.0).toStringAsFixed(1)}%',
                isMobile: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
              child: _buildResponsiveMainStatCard(
                title: 'Transactions',
                value: (stats['totalTransactions'] ?? 0).toString(),
                icon: Icons.receipt,
                color: Colors.white,
                subtitle: 'Total count',
                trend: (stats['transactionGrowth'] ?? 0) > 0 ? 'up' : 'down',
                trendValue:
                    '${(stats['transactionGrowth'] ?? 0.0).toStringAsFixed(1)}%',
                isMobile: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildResponsiveMainStatCard(
                title: 'This Month',
                value:
                    '₹${(stats['thisMonthCommission'] ?? 0.0).toStringAsFixed(0)}',
                icon: Icons.calendar_today,
                color: Colors.white,
                subtitle: '${stats['thisMonthTransactions'] ?? 0} transactions',
                trend: (stats['earningsGrowth'] ?? 0) > 0 ? 'up' : 'down',
                trendValue:
                    '${(stats['earningsGrowth'] ?? 0.0).toStringAsFixed(1)}%',
                isMobile: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDesktopStatsLayout(Map<String, dynamic> stats) {
    return Column(
      children: [
        // Top Row - 3 Cards
        Row(
          children: [
            Expanded(
              child: _buildResponsiveMainStatCard(
                title: 'Total Earnings',
                value: '₹${(stats['totalEarnings'] ?? 0.0).toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet,
                color: Colors.white,
                subtitle: 'All time',
                trend: (stats['earningsGrowth'] ?? 0) > 0 ? 'up' : 'down',
                trendValue:
                    '${(stats['earningsGrowth'] ?? 0.0).toStringAsFixed(1)}%',
                isMobile: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildResponsiveMainStatCard(
                title: 'Transactions',
                value: (stats['totalTransactions'] ?? 0).toString(),
                icon: Icons.receipt,
                color: Colors.white,
                subtitle: 'Total count',
                trend: (stats['transactionGrowth'] ?? 0) > 0 ? 'up' : 'down',
                trendValue:
                    '${(stats['transactionGrowth'] ?? 0.0).toStringAsFixed(1)}%',
                isMobile: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildResponsiveMainStatCard(
                title: 'This Month',
                value:
                    '₹${(stats['thisMonthCommission'] ?? 0.0).toStringAsFixed(0)}',
                icon: Icons.calendar_today,
                color: Colors.white,
                subtitle: '${stats['thisMonthTransactions'] ?? 0} transactions',
                trend: (stats['earningsGrowth'] ?? 0) > 0 ? 'up' : 'down',
                trendValue:
                    '${(stats['earningsGrowth'] ?? 0.0).toStringAsFixed(1)}%',
                isMobile: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildResponsiveMainStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required String trend,
    required String trendValue,
    required bool isMobile,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
                        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
                          children: [
              Icon(
                  icon,
                color: color.withOpacity(0.9),
                size: isMobile ? 18.0 : 20.0,
              ),
              const Spacer(),
              if (trendValue != 'Current')
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trend == 'up' ? Icons.trending_up : Icons.trending_down,
                      color:
                          trend == 'up' ? Colors.green[300] : Colors.red[300],
                      size: isMobile ? 14.0 : 16.0,
                    ),
                    const SizedBox(width: 4),
                            Text(
                      trendValue,
                      style: (isMobile
                              ? AppTextStyles.labelSmall
                              : AppTextStyles.labelMedium)
                          .copyWith(
                            color:
                                trend == 'up'
                                    ? Colors.green[300]
                                    : Colors.red[300],
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: isMobile ? 6.0 : 8.0),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
            value,
              style: (isMobile
                      ? AppTextStyles.titleLarge
                      : AppTextStyles.headlineMedium)
                  .copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 4),
                            Text(
            title,
            style: (isMobile
                    ? AppTextStyles.labelSmall
                    : AppTextStyles.labelMedium)
                .copyWith(
                  color: color.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            subtitle,
            style: AppTextStyles.labelSmall.copyWith(
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveLoadingStatsCards(double screenWidth) {
    final isMobile = screenWidth < 600;
    final cardHeight = isMobile ? 90.0 : 110.0;
    final cardPadding = isMobile ? 12.0 : 16.0;

    if (isMobile) {
      return Column(
        children: [
          // Top row - 2 cards
          Row(
            children: List.generate(
              2,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 1 ? 12 : 0),
                  height: cardHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(cardPadding),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Second row - 1 card
          Container(
            height: cardHeight,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(cardPadding),
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Third row - 1 card
          Container(
            height: cardHeight,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(cardPadding),
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Fourth row - 2 cards
          Row(
            children: List.generate(
              2,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 1 ? 12 : 0),
                  height: cardHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(cardPadding),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                  height: cardHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(cardPadding),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                  height: cardHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(cardPadding),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Map<String, dynamic> _calculateEnhancedStats() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEarnings =
        authProvider.userData?['earnings'] ??
        0; // Total earnings from user data
    final userCreatedAt = authProvider.userData?['createdAt'];

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);

    // Parse user creation date
    DateTime? joinedDate;
    if (userCreatedAt != null) {
      try {
        if (userCreatedAt is String) {
          joinedDate = DateTime.parse(userCreatedAt);
        } else if (userCreatedAt.toDate != null) {
          joinedDate = userCreatedAt.toDate();
        }
      } catch (e) {
        print('Error parsing user creation date: $e');
      }
    }
    joinedDate ??= DateTime.now().subtract(
      const Duration(days: 30),
    ); // Fallback

    // This month's transactions
    final thisMonthTransactions =
        _transactions.where((t) => t.createdAt.isAfter(startOfMonth)).toList();

    // This month's commission
    final thisMonthCommission = thisMonthTransactions.fold<double>(
      0.0,
      (sum, t) => sum + t.amount,
    );

    // Calculate total transactions count
    final totalTransactions = _transactions.length;

    // Calculate months since joining
    final monthsSinceJoining =
        (now.difference(joinedDate).inDays / 30.44)
            .ceil(); // Average days per month
    final monthsSinceJoiningClamped =
        monthsSinceJoining > 0 ? monthsSinceJoining : 1;

    // Calculate average commission per month
    final avgCommissionPerMonth = userEarnings / monthsSinceJoiningClamped;

    // Calculate growth rates
    final lastMonthTransactions =
        _transactions
            .where(
              (t) =>
                  t.createdAt.isAfter(startOfLastMonth) &&
                  t.createdAt.isBefore(startOfMonth),
            )
            .toList();

    final lastMonthCommission = lastMonthTransactions.fold<double>(
      0.0,
      (sum, t) => sum + t.amount,
    );

    final earningsGrowth =
        lastMonthCommission > 0
            ? ((thisMonthCommission - lastMonthCommission) /
                lastMonthCommission *
                100)
            : (thisMonthCommission > 0 ? 100.0 : 0.0);

    final transactionGrowth =
        lastMonthTransactions.isNotEmpty
            ? ((thisMonthTransactions.length - lastMonthTransactions.length) /
                lastMonthTransactions.length *
                100)
            : (thisMonthTransactions.isNotEmpty ? 100.0 : 0.0);

    // Calculate this week's data
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekTransactions =
        _transactions.where((t) => t.createdAt.isAfter(startOfWeek)).toList();
    final thisWeekCommission = thisWeekTransactions.fold<double>(
      0.0,
      (sum, t) => sum + t.amount,
    );

    // Calculate last week for growth comparison
    final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));
    final lastWeekTransactions =
        _transactions
            .where(
              (t) =>
                  t.createdAt.isAfter(startOfLastWeek) &&
                  t.createdAt.isBefore(startOfWeek),
            )
            .toList();
    final lastWeekCommission = lastWeekTransactions.fold<double>(
      0.0,
      (sum, t) => sum + t.amount,
    );

    final weeklyGrowth =
        lastWeekCommission > 0
            ? ((thisWeekCommission - lastWeekCommission) /
                lastWeekCommission *
                100)
            : (thisWeekCommission > 0 ? 100.0 : 0.0);

    return {
      'totalEarnings': userEarnings.toDouble(), // From user's earnings field
      'totalTransactions': totalTransactions,
      'thisMonthCommission': thisMonthCommission,
      'thisMonthTransactions': thisMonthTransactions.length,
      'thisWeekCommission': thisWeekCommission,
      'thisWeekTransactions': thisWeekTransactions.length,
      'weeklyGrowth': weeklyGrowth,
      'earningsGrowth': earningsGrowth,
      'transactionGrowth': transactionGrowth,
      'avgCommissionPerMonth': avgCommissionPerMonth,
      'monthsSinceJoining': monthsSinceJoiningClamped,
      'joinedDate': joinedDate,
      'totalPayouts': _totalPayouts,
      'availableForPayout': userEarnings.toDouble() - _totalPayouts,
      'avgTransactionValue':
          totalTransactions > 0
              ? (userEarnings.toDouble() / totalTransactions)
              : 0.0,
      'completionRate': 100.0, // Assuming all transactions shown are completed
      'completedTransactions':
          totalTransactions, // All transactions are completed
      'pendingTransactions': 0, // No pending transactions for now
    };
  }

  Widget _buildSearchAndFilter() {
    return Column(
      children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
                            ),
                          ],
                        ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => _filterTransactions(),
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Filter Chips
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filterOptions.length,
            itemBuilder: (context, index) {
              final option = _filterOptions[index];
              final isSelected = _selectedFilter == option['value'];
              
                            return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 8,
                  right: index == _filterOptions.length - 1 ? 0 : 0,
                ),
                child: FilterChip(
                  label: Text(option['label']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = option['value']!);
                    _filterTransactions();
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primary.withOpacity(0.1),
                  checkmarkColor: AppColors.primary,
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    color:
                        isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            },
                      ),
                    ),
                ],
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TransactionTileSkeleton(),
              ),
            ),
    );
  }

    if (_filteredTransactions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children:
          _filteredTransactions.map((transaction) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTransactionTile(transaction),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionTile(UnifiedTransaction transaction) {
    final isCredit = transaction.isCredit;
    final amountColor = isCredit ? AppColors.success600 : AppColors.error600;
    final iconColor = isCredit ? AppColors.success500 : AppColors.error500;
    final icon = isCredit ? Icons.add_circle : Icons.remove_circle;
    
    return GestureDetector(
      onTap: () => _showTransactionDetails(transaction),
      child: AppCard(
        child: Container(
        padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCredit 
                ? AppColors.success200.withOpacity(0.3)
                : AppColors.error200.withOpacity(0.3),
              width: 1,
            ),
          ),
        child: Column(
          children: [
              // Main transaction row
            Row(
              children: [
                  // Transaction type icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                  
                  // Transaction details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Text(
                          isCredit ? 'Commission Received' : 'Payout Processed',
                  style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                        const SizedBox(height: 2),
                        Text(
                          isCredit 
                            ? 'From: ${transaction.customerName ?? 'N/A'}'
                            : 'Payout to your account',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (transaction.customerId != null) ...[
                          const SizedBox(height: 2),
                      Text(
                        'ID: ${transaction.customerId}',
                        style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                        ),
                      ),
                        ],
                    ],
                  ),
                ),
                  
                  // Amount and status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCredit ? Icons.add : Icons.remove,
                            color: amountColor,
                            size: 16,
                          ),
                    Text(
                      transaction.formattedAmount,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                              color: amountColor,
                      ),
                    ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(transaction.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        transaction.status.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _getStatusColor(transaction.status),
                          fontWeight: FontWeight.w600,
                            fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
              
              const SizedBox(height: 12),
              
              // Transaction description
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.neutral50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
              transaction.description,
                  style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
            const SizedBox(height: 12),
              
              // Date and tap to view more
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                        size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.createdAt),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
                  Text(
                    'Tap to view details',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(UnifiedTransaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TransactionDetailsBottomSheet(transaction: transaction),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return AppColors.success600;
      case 'pending':
        return AppColors.warning600;
      case 'failed':
      case 'cancelled':
        return AppColors.error600;
      default:
        return AppColors.info600;
    }
  }

  Widget _buildDetailsGrid(UnifiedTransaction transaction) {
    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            'Amount',
            transaction.formattedAmount,
            Icons.attach_money,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDetailItem(
            'Type',
            transaction.isCredit ? 'Credit' : 'Debit',
            Icons.swap_horiz,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            Text(
                value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadata(UnifiedTransaction transaction) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetadataItem(
                  'Amount',
                  transaction.formattedAmount,
                ),
              ),
              Expanded(
                child: _buildMetadataItem(
                  'Type',
                  transaction.isCredit ? 'Credit' : 'Debit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetadataItem(
                  'Status',
                  transaction.status.toUpperCase(),
                ),
              ),
              Expanded(
                child: _buildMetadataItem(
                  'Referrer',
                  transaction.referrerName ?? 'N/A',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your commission transactions will appear here',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}

// Transaction Details Bottom Sheet Widget
class _TransactionDetailsBottomSheet extends StatelessWidget {
  final UnifiedTransaction transaction;

  const _TransactionDetailsBottomSheet({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final amountColor = isCredit ? AppColors.success600 : AppColors.error600;
    final iconColor = isCredit ? AppColors.success500 : AppColors.error500;
    final backgroundColor = isCredit ? AppColors.success50 : AppColors.error50;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCredit ? Icons.trending_up : Icons.trending_down,
                      color: iconColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCredit ? 'Commission Received' : 'Payout Processed',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Transaction Details',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Amount display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCredit ? Icons.add : Icons.remove,
                          color: amountColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          transaction.formattedAmount,
                          style: AppTextStyles.headlineLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(transaction.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        transaction.status.toUpperCase(),
                        style: AppTextStyles.labelMedium.copyWith(
                          color: _getStatusColor(transaction.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Transaction details
              _buildDetailSection(
                'Transaction Information',
                [
                  _DetailItem(
                    label: 'Transaction ID',
                    value: transaction.id,
                    icon: Icons.fingerprint,
                  ),
                  _DetailItem(
                    label: 'Description',
                    value: transaction.description,
                    icon: Icons.description,
                  ),
                  _DetailItem(
                    label: 'Date & Time',
                    value: DateFormat('dd MMM yyyy, hh:mm a').format(transaction.createdAt),
                    icon: Icons.access_time,
                  ),
                  if (transaction.completedAt != null)
                    _DetailItem(
                      label: 'Completed At',
                      value: DateFormat('dd MMM yyyy, hh:mm a').format(transaction.completedAt!),
                      icon: Icons.check_circle,
                    ),
                ],
              ),
              
              if (isCredit) ...[
                const SizedBox(height: 24),
                _buildDetailSection(
                  'Commission Details',
                  [
                    if (transaction.customerName != null)
                      _DetailItem(
                        label: 'Customer Name',
                        value: transaction.customerName!,
                        icon: Icons.person,
                      ),
                    if (transaction.customerId != null)
                      _DetailItem(
                        label: 'Customer ID',
                        value: transaction.customerId!,
                        icon: Icons.badge,
                      ),
                    if (transaction.referrerName != null)
                      _DetailItem(
                        label: 'Referred By',
                        value: transaction.referrerName!,
                        icon: Icons.person_add,
                      ),
                    if (transaction.packageType != null)
                      _DetailItem(
                        label: 'Package Type',
                        value: transaction.packageType!.toUpperCase(),
                        icon: Icons.inventory_2,
                      ),
                    if (transaction.commissionAmount != null)
                      _DetailItem(
                        label: 'Commission Amount',
                        value: '₹${NumberFormat('#,##0.00').format(transaction.commissionAmount)}',
                        icon: Icons.account_balance_wallet,
                      ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 24),
                _buildDetailSection(
                  'Payout Details',
                  [
                    if (transaction.metadata?['paymentMethod'] != null)
                      _DetailItem(
                        label: 'Payment Method',
                        value: transaction.metadata!['paymentMethod'].toString().toUpperCase(),
                        icon: Icons.payment,
                      ),
                    if (transaction.metadata?['bankAccount'] != null)
                      _DetailItem(
                        label: 'Bank Account',
                        value: transaction.metadata!['bankAccount'].toString(),
                        icon: Icons.account_balance,
                      ),
                    if (transaction.metadata?['upiId'] != null)
                      _DetailItem(
                        label: 'UPI ID',
                        value: transaction.metadata!['upiId'].toString(),
                        icon: Icons.qr_code,
                      ),
                  ],
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<_DetailItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items
                .asMap()
                .entries
                .map((entry) => _buildDetailRow(
                      entry.value,
                      isLast: entry.key == items.length - 1,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(_DetailItem item, {required bool isLast}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.neutral200,
                  width: 1,
                ),
              ),
      ),
      child: Row(
        children: [
          Icon(
            item.icon,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return AppColors.success600;
      case 'pending':
        return AppColors.warning600;
      case 'failed':
      case 'cancelled':
        return AppColors.error600;
      default:
        return AppColors.info600;
    }
  }
}

class _DetailItem {
  final String label;
  final String value;
  final IconData icon;

  const _DetailItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTileSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 200,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
