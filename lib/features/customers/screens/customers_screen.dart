import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/customer_model.dart';
import '../../../models/user_model.dart';
import '../../../services/customers_service.dart';
import '../../../services/users_service.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/customer_details_view.dart';

enum SortOrder { newest, oldest }

enum GroupBy { none, status, paymentStatus }

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen>
    with TickerProviderStateMixin {
  final CustomersService _customersService = CustomersService();
  final UsersService _usersService = UsersService();

  // Filter state
  String _searchQuery = '';
  String? _selectedStatus;
  String? _selectedPaymentStatus;
  SortOrder _sortOrder = SortOrder.newest;
  GroupBy _groupBy = GroupBy.none;

  // Cache for partner names
  final Map<String, String> _partnerNamesCache = {};

  // Animation controller for payment strip
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Simple Header
        _buildSimpleHeader(),

        // Filter Bar
        _buildFilterBar(),

        // Customers List
        Expanded(
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final userReferralCode = authProvider.userData?['myReferralCode'];

              return FutureBuilder<List<Customer>>(
                future: _customersService.getCustomers(
                  referralCode: userReferralCode,
                  statusFilter: _selectedStatus,
                  searchQuery: _searchQuery,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }

                  final customers = snapshot.data ?? [];

                  if (customers.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Apply additional filters and sorting
                  final filteredCustomers = _applyFiltersAndSorting(
                    customers,
                    userReferralCode,
                  );

                  if (_groupBy == GroupBy.none) {
                    return _buildCustomersList(
                      filteredCustomers,
                      userReferralCode,
                    );
                  } else {
                    return _buildGroupedCustomersList(
                      filteredCustomers,
                      userReferralCode,
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleHeader() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
        Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.people_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Customers',
                    style: AppTextStyles.headlineLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Direct & Indirect Referrals',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
      child: Column(
        children: [
          // Main Header
          Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                Icons.people_rounded,
                    color: Colors.white,
                size: 32,
              ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Customers',
                        style: AppTextStyles.headlineLarge.copyWith(
                      fontWeight: FontWeight.bold,
                          color: Colors.white,
                    ),
                  ),
                      const SizedBox(height: 4),
                  Text(
                        'Direct & Indirect Referrals Dashboard',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
                  ),
              ),
            ],
          ),
        ),
        
          // Stats Section
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final userReferralCode = authProvider.userData?['myReferralCode'];
              
              return FutureBuilder<List<Customer>>(
            future: _customersService.getCustomers(
                  referralCode: userReferralCode,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingStats();
                  }

                  final customers = snapshot.data ?? [];
                  return _buildStatsCards(customers, userReferralCode);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStats() {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      child: Row(
        children: List.generate(
          4,
          (index) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 3 ? 12 : 0),
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
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
    );
  }

  Widget _buildStatsCards(List<Customer> customers, String? userReferralCode) {
    // Calculate statistics
    final stats = _calculateStats(customers, userReferralCode);

    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                  child: Column(
                    children: [
          // Top Row - Main Stats
          Row(
            children: [
              // Total Customers
              Expanded(
                child: _buildStatCard(
                  title: 'Total Customers',
                  value: stats['totalCustomers'].toString(),
                  icon: Icons.people,
                  color: Colors.white,
                  subtitle: 'All referrals',
                ),
              ),
              const SizedBox(width: 12),

              // Direct Referrals
              Expanded(
                child: _buildStatCard(
                  title: 'Direct',
                  value: stats['directReferrals'].toString(),
                  icon: Icons.person_add,
                  color: Colors.white,
                  subtitle: 'Your referrals',
                ),
              ),
              const SizedBox(width: 12),

              // Indirect Referrals
              Expanded(
                child: _buildStatCard(
                  title: 'Indirect',
                  value: stats['indirectReferrals'].toString(),
                  icon: Icons.group_add,
                  color: Colors.white,
                  subtitle: 'Via partners',
                ),
              ),
              const SizedBox(width: 12),

              // Completed
              Expanded(
                child: _buildStatCard(
                  title: 'Completed',
                  value: stats['completedCustomers'].toString(),
                  icon: Icons.check_circle,
                  color: Colors.white,
                  subtitle: 'Finished',
                ),
              ),
            ],
          ),

                      const SizedBox(height: 16),

          // Bottom Row - Payment & Activity Stats
          Row(
            children: [
              // Payment Stats
              Expanded(flex: 2, child: _buildPaymentStatsCard(stats)),
              const SizedBox(width: 12),

              // Recent Activity
              Expanded(flex: 2, child: _buildRecentActivityCard(stats)),
              const SizedBox(width: 12),

              // Growth Rate
              Expanded(child: _buildGrowthCard(stats)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color.withOpacity(0.9), size: 20),
              const Spacer(),
                      Text(
                value,
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
                      ),
                      const SizedBox(height: 8),
                      Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
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
              
  Widget _buildPaymentStatsCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Status',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats['paidCustomers']}',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Paid',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats['pendingPayments']}',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Pending',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Payment Progress Bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: stats['paymentCompletionRate'] / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${stats['paymentCompletionRate'].toStringAsFixed(1)}% completion rate',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
                  child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
                    children: [
                      Icon(
                Icons.timeline,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
                      Text(
                'Recent Activity',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats['thisWeekCustomers']}',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'This Week',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats['thisMonthCustomers']}',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'This Month',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
                      ),
                      const SizedBox(height: 8),
          if (stats['weeklyGrowth'] > 0)
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                      Text(
                  '+${stats['weeklyGrowth']}% from last week',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
                      ),
                    ],
                  ),
                );
              }
              
  Widget _buildGrowthCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.trending_up,
            color: Colors.white.withOpacity(0.9),
            size: 20,
          ),
          const SizedBox(height: 12),
          Text(
            '${stats['conversionRate'].toStringAsFixed(1)}%',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Conversion',
            style: AppTextStyles.labelMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Rate',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateStats(
    List<Customer> customers,
    String? userReferralCode,
  ) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));

    // Basic counts
    final totalCustomers = customers.length;
    final directReferrals =
        customers.where((c) => c.referralCode == userReferralCode).length;
    final indirectReferrals =
        customers
            .where(
              (c) =>
                  c.referralCode1 == userReferralCode &&
                  c.referralCode != userReferralCode,
            )
            .length;

    // Status-based counts
    final completedCustomers =
        customers
            .where(
              (c) =>
                  c.status.toLowerCase().contains('completed') ||
                  c.status.toLowerCase().contains('full payment done'),
            )
            .length;

    // Payment-based counts
    final paidCustomers =
        customers
            .where(
              (c) =>
                  c.paymentStatus.toLowerCase().contains('full payment done'),
            )
            .length;
    final pendingPayments =
        customers
            .where((c) => c.paymentStatus.toLowerCase().contains('pending'))
            .length;

    // Time-based counts
    final thisWeekCustomers =
        customers
            .where(
              (c) =>
                  c.createdAtDate != null &&
                  c.createdAtDate!.isAfter(startOfWeek),
            )
            .length;
    final thisMonthCustomers =
        customers
            .where(
              (c) =>
                  c.createdAtDate != null &&
                  c.createdAtDate!.isAfter(startOfMonth),
            )
            .length;
    final lastWeekCustomers =
        customers
            .where(
              (c) =>
                  c.createdAtDate != null &&
                  c.createdAtDate!.isAfter(startOfLastWeek) &&
                  c.createdAtDate!.isBefore(startOfWeek),
            )
            .length;

    // Calculate rates
    final paymentCompletionRate =
        totalCustomers > 0 ? (paidCustomers / totalCustomers * 100) : 0.0;
    final conversionRate =
        totalCustomers > 0 ? (completedCustomers / totalCustomers * 100) : 0.0;
    final weeklyGrowth =
        lastWeekCustomers > 0
            ? ((thisWeekCustomers - lastWeekCustomers) /
                lastWeekCustomers *
                100)
            : 0.0;

    return {
      'totalCustomers': totalCustomers,
      'directReferrals': directReferrals,
      'indirectReferrals': indirectReferrals,
      'completedCustomers': completedCustomers,
      'paidCustomers': paidCustomers,
      'pendingPayments': pendingPayments,
      'thisWeekCustomers': thisWeekCustomers,
      'thisMonthCustomers': thisMonthCustomers,
      'paymentCompletionRate': paymentCompletionRate,
      'conversionRate': conversionRate,
      'weeklyGrowth': weeklyGrowth,
    };
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search customers...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Filter Button
              _buildFilterButton(),
            ],
          ),

          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Sort Order
                _buildFilterChip(
                  label:
                      _sortOrder == SortOrder.newest
                          ? 'Newest First'
                          : 'Oldest First',
                  icon:
                      _sortOrder == SortOrder.newest
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                  onTap: () {
                    setState(() {
                      _sortOrder =
                          _sortOrder == SortOrder.newest
                              ? SortOrder.oldest
                              : SortOrder.newest;
                    });
                  },
                ),

                const SizedBox(width: 8),

                // Group By
                _buildFilterChip(
                  label: _getGroupByLabel(),
                  icon: Icons.group_work,
                  onTap: () => _showGroupByDialog(),
                ),

                const SizedBox(width: 8),

                // Status Filter
                if (_selectedStatus != null)
                  _buildFilterChip(
                    label: _selectedStatus!,
                    icon: Icons.close,
                    onTap: () {
                      setState(() {
                        _selectedStatus = null;
                      });
                    },
                  ),

                const SizedBox(width: 8),

                // Payment Status Filter
                if (_selectedPaymentStatus != null)
                  _buildFilterChip(
                    label: _selectedPaymentStatus!,
                    icon: Icons.close,
                    onTap: () {
                      setState(() {
                        _selectedPaymentStatus = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary500.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary500.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary500),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return IconButton(
      onPressed: () => _showFilterDialog(),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary500,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.filter_list, color: Colors.white, size: 20),
      ),
    );
  }

  List<Customer> _applyFiltersAndSorting(
    List<Customer> customers,
    String? userReferralCode,
  ) {
    var filtered = customers;

    // Apply payment status filter
    if (_selectedPaymentStatus != null) {
      filtered =
          filtered
              .where(
                (customer) => customer.paymentStatus.toLowerCase().contains(
                  _selectedPaymentStatus!.toLowerCase(),
                ),
              )
              .toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      final dateA = a.createdAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.createdAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);

      if (_sortOrder == SortOrder.newest) {
        return dateB.compareTo(dateA);
      } else {
        return dateA.compareTo(dateB);
      }
    });

    return filtered;
  }

  Widget _buildCustomersList(
    List<Customer> customers,
    String? userReferralCode,
  ) {
              return ListView.builder(
      padding: const EdgeInsets.all(16),
                    itemCount: customers.length,
                itemBuilder: (context, index) {
                      final customer = customers[index];
        return _buildEnhancedCustomerCard(customer, userReferralCode);
      },
    );
  }

  Widget _buildGroupedCustomersList(
    List<Customer> customers,
    String? userReferralCode,
  ) {
    Map<String, List<Customer>> groupedCustomers = {};

    for (final customer in customers) {
      String groupKey;
      if (_groupBy == GroupBy.status) {
        groupKey = customer.status;
      } else if (_groupBy == GroupBy.paymentStatus) {
        groupKey = customer.paymentStatus;
      } else {
        groupKey = 'All';
      }

      if (!groupedCustomers.containsKey(groupKey)) {
        groupedCustomers[groupKey] = [];
      }
      groupedCustomers[groupKey]!.add(customer);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedCustomers.keys.length,
      itemBuilder: (context, index) {
        final groupKey = groupedCustomers.keys.elementAt(index);
        final groupCustomers = groupedCustomers[groupKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.primary500.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _groupBy == GroupBy.status
                        ? Icons.info_outline
                        : Icons.payment,
                    size: 20,
                    color: AppColors.primary500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$groupKey (${groupCustomers.length})',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary500,
                    ),
                  ),
                ],
              ),
            ),

            // Group Customers
            ...groupCustomers.map(
              (customer) =>
                  _buildEnhancedCustomerCard(customer, userReferralCode),
            ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildAmountDueWidget(
    Customer customer, {
    bool showBackground = true,
    double fontSize = 12,
    double iconSize = 14,
    EdgeInsets padding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 4,
    ),
    BorderRadius? borderRadius,
    Color? backgroundColor,
    bool animated = true,
  }) {
    final bool hasAmountDue = customer.amountDue > 0;
    final String formattedAmount = '₹${customer.amountDue.toStringAsFixed(0)}';

    if (!hasAmountDue) return const SizedBox.shrink();

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        animated
            ? AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_animationController.value * 0.1),
                  child: Icon(
                    Icons.payments_outlined,
                    size: iconSize,
                    color: const Color(0xFF1D4ED8),
                  ),
                );
              },
            )
            : Icon(
              Icons.payments_outlined,
              size: iconSize,
              color: const Color(0xFF1D4ED8),
            ),
        const SizedBox(width: 6),
        Text(
          'Due: ',
          style: TextStyle(
            fontSize: fontSize * 0.9,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
        animated
            ? AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Color.lerp(
                      const Color(0xFF1D4ED8),
                      const Color(0xFF059669),
                      _animationController.value,
                    ),
                  ),
                );
              },
            )
            : Text(
              formattedAmount,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1D4ED8),
              ),
            ),
        const SizedBox(width: 4),
        animated
            ? AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animationController.value * 2 * 3.14159,
                  child: Icon(
                    Icons.flash_on,
                    size: iconSize * 0.85,
                    color: Color.lerp(
                      const Color(0xFFF59E0B),
                      const Color(0xFF10B981),
                      _animationController.value,
                    ),
                  ),
                );
              },
            )
            : Icon(
              Icons.flash_on,
              size: iconSize * 0.85,
              color: const Color(0xFFF59E0B),
        ),
      ],
    );

    if (!showBackground) return content;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.95),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _buildPaidBadgeWidget(
    Customer customer, {
    bool showBackground = true,
    double fontSize = 9,
    double iconSize = 12,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    BorderRadius? borderRadius,
    Color? backgroundColor,
    bool animated = true,
  }) {
    final bool isFullPaymentDone =
        customer.paymentStatus.toLowerCase().contains('full payment done') ||
        customer.paymentStatus.toLowerCase().contains('completed') ||
        customer.status.toLowerCase().contains('completed');

    if (!isFullPaymentDone) return const SizedBox.shrink();

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        animated
            ? AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_animationController.value * 0.2),
                  child: Icon(
                    Icons.check_circle,
                    size: iconSize,
                    color: const Color(0xFF059669),
                  ),
                );
              },
            )
            : Icon(
              Icons.check_circle,
              size: iconSize,
              color: const Color(0xFF059669),
            ),
        const SizedBox(width: 4),
        Text(
          'PAID',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF059669),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );

    if (!showBackground) return content;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.95),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _buildAnimatedPaymentStrip(Customer customer) {
    final bool isFullPaymentDone =
        customer.paymentStatus.toLowerCase().contains('full payment done') ||
        customer.paymentStatus.toLowerCase().contains('completed') ||
        customer.status.toLowerCase().contains('completed');

    final bool hasAmountDue = customer.amountDue > 0;
    final String formattedAmount = '₹${customer.amountDue.toStringAsFixed(0)}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors:
              isFullPaymentDone
                  ? [
                    const Color(0xFF10B981), // Emerald green
                    const Color(0xFF059669), // Deeper green
                    const Color(0xFF047857), // Forest green
                    const Color(0xFF10B981), // Back to emerald
                  ]
                  : hasAmountDue
                  ? [
                    const Color(0xFF3B82F6), // Blue
                    const Color(0xFF1D4ED8), // Deeper blue
                    const Color(0xFF1E40AF), // Navy blue
                    const Color(0xFF3B82F6), // Back to blue
                  ]
                  : [
                    const Color(0xFFF59E0B), // Amber
                    const Color(0xFFD97706), // Orange
                    const Color(0xFFB45309), // Dark orange
                    const Color(0xFFF59E0B), // Back to amber
                  ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color:
                isFullPaymentDone
                    ? const Color(0xFF10B981).withOpacity(0.4)
                    : hasAmountDue
                    ? const Color(0xFF3B82F6).withOpacity(0.4)
                    : const Color(0xFFF59E0B).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Moving shimmer effect
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      -1.0 + _animationController.value * 2,
                      0.0,
                    ),
                    end: Alignment(1.0 + _animationController.value * 2, 0.0),
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),

          // Sparkle effects
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final sparkleOffset =
                    (index * 0.3 + _animationController.value) % 1.0;
                return Positioned(
                  left: sparkleOffset * MediaQuery.of(context).size.width * 0.8,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEnhancedCustomerCard(
    Customer customer,
    String? userReferralCode,
  ) {
    final bool isIndirectReferral =
        userReferralCode != null &&
        customer.referralCode1 == userReferralCode &&
        customer.referralCode != userReferralCode;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Animated Payment Strip
            _buildAnimatedPaymentStrip(customer),

            // Main Card Content
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => CustomerDetailsView.show(context, customer),
                child: Padding(
                  padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                      // Header Row
          Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                          // Avatar
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary500,
                                  AppColors.primary600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                child: Text(
                                customer.fullName.isNotEmpty
                                    ? customer.fullName[0].toUpperCase()
                                    : 'C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                                  fontSize: 20,
                  ),
                ),
              ),
                          ),

                          const SizedBox(width: 12),

                          // Content area with flexible wrapping
              Expanded(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.start,
                              children: [
                                // Name and ID section
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 120,
                                  ),
                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      customer.fullName,
                                        style: AppTextStyles.titleMedium
                                            .copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                    ),
                                      const SizedBox(height: 4),
                    Text(
                      'ID: ${customer.customerId}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

                                // Status and referral section
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
              Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          customer.status,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  customer.status,
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                              color: _getStatusColor(
                                                customer.status,
                                              ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
                                    if (isIndirectReferral) ...[
                                      const SizedBox(height: 4),
                                      _buildReferralTag(customer.referralCode),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      // Info Grid
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(Icons.phone, customer.mobile),
              ),
              Expanded(
                            child: _buildInfoItem(
                              Icons.location_on,
                              customer.district,
                            ),
              ),
            ],
          ),

                      const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                            child: _buildInfoItem(
                              Icons.calendar_today,
                  customer.createdAtDate != null 
                    ? _formatDate(customer.createdAtDate!)
                                  : 'Unknown',
                            ),
                          ),
                          // Expanded(
                          //   child: _buildInfoItem(
                          //     Icons.payment,
                          //     customer.paymentStatus,
                          //     color: _getPaymentStatusColor(
                          //       customer.paymentStatus,
                          //     ),
                          //   ),
                          // ),
                          // Custom amount due in customer card
                          _buildAmountDueWidget(
                            customer,
                            fontSize: 11,
                            showBackground: false,
                          ),
                          SizedBox(height: 4),
                          // Custom paid badge as a tag
                          _buildPaidBadgeWidget(customer),
            ],
          ),
        ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralTag(String partnerReferralCode) {
    return FutureBuilder<String>(
      future: _getPartnerName(partnerReferralCode),
      builder: (context, snapshot) {
        final partnerName = snapshot.data ?? 'Partner';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.warning500.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning500.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
      children: [
              Icon(Icons.person_pin, size: 12, color: AppColors.warning600),
              const SizedBox(width: 4),
              Text(
                'via $partnerName',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.warning600,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> _getPartnerName(String referralCode) async {
    if (_partnerNamesCache.containsKey(referralCode)) {
      return _partnerNamesCache[referralCode]!;
    }

    try {
      final users = await _usersService.getUsersStream().first;
      final partner = users.firstWhere(
        (user) => user.myReferralCode == referralCode,
        orElse:
            () => UserModel(
              uid: '',
              email: '',
              fullName: 'Unknown Partner',
              mobile: '',
              role: '',
              status: '',
              kycStatus: '',
              isActive: false,
              earnings: 0,
              walletAmount: 0,
              referrals: 0,
              kycProgress: 0,
              createdAt: DateTime.now(),
            ),
      );

      _partnerNamesCache[referralCode] = partner.fullName;
      return partner.fullName;
    } catch (e) {
      print('Error fetching partner name: $e');
      return 'Partner';
    }
  }

  Widget _buildInfoItem(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: color ?? AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter Customers'),
            content: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status Filter
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Statuses'),
                        ),
                        ...CustomerStatus.values.map(
                          (status) => DropdownMenuItem(
                            value: status.value,
                            child: Text(status.value),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedStatus = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Payment Status Filter
                    DropdownButtonFormField<String>(
                      value: _selectedPaymentStatus,
                      decoration: const InputDecoration(
                        labelText: 'Payment Status',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Payment Statuses'),
                        ),
                        ...PaymentStatus.values.map(
                          (status) => DropdownMenuItem(
                            value: status.value,
                            child: Text(status.value),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedPaymentStatus = value;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedStatus = null;
                    _selectedPaymentStatus = null;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Clear'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          ),
    );
  }

  void _showGroupByDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Group By'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<GroupBy>(
                  title: const Text('No Grouping'),
                  value: GroupBy.none,
                  groupValue: _groupBy,
                  onChanged: (value) {
                    setState(() {
                      _groupBy = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<GroupBy>(
                  title: const Text('Group by Status'),
                  value: GroupBy.status,
                  groupValue: _groupBy,
                  onChanged: (value) {
                    setState(() {
                      _groupBy = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<GroupBy>(
                  title: const Text('Group by Payment Status'),
                  value: GroupBy.paymentStatus,
                  groupValue: _groupBy,
                  onChanged: (value) {
                    setState(() {
                      _groupBy = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  String _getGroupByLabel() {
    switch (_groupBy) {
      case GroupBy.none:
        return 'No Grouping';
      case GroupBy.status:
        return 'By Status';
      case GroupBy.paymentStatus:
        return 'By Payment';
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error500),
          const SizedBox(height: 16),
          Text('Unable to load customers', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('No customers yet', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Customers from your referrals will appear here',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    final normalizedStatus = status.toLowerCase();
    switch (normalizedStatus) {
      case 'completed':
      case 'full payment done':
        return AppColors.success500;
      case 'active':
        return AppColors.primary500;
      case 'pending':
      case 'pending for payment confirmation':
        return AppColors.warning500;
      case 'lost':
        return AppColors.error500;
      default:
        return AppColors.neutral500;
    }
  }

  Color _getPaymentStatusColor(String paymentStatus) {
    final normalized = paymentStatus.toLowerCase();
    switch (normalized) {
      case 'full payment done':
        return AppColors.success500;
      case 'partial payment':
        return AppColors.warning500;
      case 'pending':
        return AppColors.error500;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 
