import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../widgets/update_banner.dart';
import '../../../services/dashboard_service.dart';
import '../../../services/version_service.dart';
import '../../../services/customers_service.dart';
import '../../../services/leads_service.dart';
import '../../../services/commission_transaction_service.dart';
import '../../../models/customer_model.dart';
import '../../../models/commission_transaction_model.dart';
import '../../../providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final DashboardService _dashboardService = DashboardService();
  final VersionService _versionService = VersionService();
  final CustomersService _customersService = CustomersService();
  final LeadsService _leadsService = LeadsService();
  final CommissionTransactionService _commissionService = CommissionTransactionService();
  DashboardStats? _stats;
  List<ActivityItem> _activities = [];
  UpdateInfo? _updateInfo;
  bool _isLoading = true;
  bool _showUpdateBanner = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _checkForUpdates();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);
      
      final stats = await _dashboardService.getDashboardStats();
      final activities = await _dashboardService.getRecentActivity();
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _activities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final updateInfo = await _versionService.checkForUpdate();
      if (mounted) {
        setState(() {
          _updateInfo = updateInfo;
        });
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;
    
    final horizontalPadding = isMobile ? 16.0 : isTablet ? 20.0 : 24.0;
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated Wallet Header Strip
            _buildAnimatedWalletHeader(),
            
            SizedBox(height: isMobile ? 16 : 20),
            
            // Header
            _buildHeader(),
            
            // Update Banner
            if (_updateInfo != null && _updateInfo!.shouldShowUpdate && _showUpdateBanner)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: UpdateBanner(
                updateInfo: _updateInfo!,
                onDismiss: () {
                  setState(() {
                    _showUpdateBanner = false;
                  });
                },
                ),
              ),
            
            SizedBox(height: isMobile ? 24 : 32),
            
            // Enhanced Payment & Earnings Chart
            _buildPaymentEarningsChart(),
            
            SizedBox(height: isMobile ? 20 : 24),
            
            // Enhanced Lead vs Customer Chart
            _buildLeadCustomerComparisonChart(),
            
            SizedBox(height: isMobile ? 24 : 32),
            
            // Enhanced Customer Stats Section
            _buildEnhancedCustomerStatsSection(),
            
            SizedBox(height: isMobile ? 24 : 32),
            
            
            // Recent Activity
            _buildRecentActivity(),
            
            SizedBox(height: isMobile ? 24 : 32),
            
           
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedWalletHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final walletAmount = authProvider.userData?['walletAmount']?.toDouble() ?? 0.0;
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1200;
        
        // Determine gradient colors based on wallet amount
        List<Color> gradientColors;
        IconData walletIcon;
        String statusText;
        Color statusColor;
        
        if (walletAmount >= 10000) {
          // High amount - Premium Gold gradient
          gradientColors = [
            const Color(0xFFFFD700), // Gold
            const Color(0xFFFFB300), // Amber
            const Color(0xFFFF8F00), // Deep Orange
            const Color(0xFFE65100), // Dark Orange
          ];
          walletIcon = Icons.diamond_rounded;
          statusText = 'PREMIUM';
          statusColor = const Color(0xFFFFD700);
        } else if (walletAmount >= 5000) {
          // Good amount - Emerald gradient
          gradientColors = [
            const Color(0xFF10B981), // Emerald
            const Color(0xFF059669), // Darker emerald
            const Color(0xFF047857), // Forest green
            const Color(0xFF065F46), // Dark green
          ];
          walletIcon = Icons.account_balance_wallet_rounded;
          statusText = 'EXCELLENT';
          statusColor = const Color(0xFF10B981);
        } else if (walletAmount >= 1000) {
          // Medium amount - Blue gradient
          gradientColors = [
            const Color(0xFF3B82F6), // Blue
            const Color(0xFF2563EB), // Darker blue
            const Color(0xFF1D4ED8), // Navy blue
            const Color(0xFF1E40AF), // Dark navy
          ];
          walletIcon = Icons.savings_rounded;
          statusText = 'GOOD';
          statusColor = const Color(0xFF3B82F6);
        } else {
          // Low amount - Gradient from orange to red
          gradientColors = [
            const Color(0xFFF59E0B), // Amber
            const Color(0xFFEF4444), // Red
            const Color(0xFFDC2626), // Darker red
            const Color(0xFFB91C1C), // Dark red
          ];
          walletIcon = Icons.wallet_rounded;
          statusText = 'GROW';
          statusColor = const Color(0xFFF59E0B);
        }
        
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : isTablet ? 12 : 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: gradientColors[1].withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 16),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
              children: [
              // Animated background patterns
              Positioned(
                top: -30,
                right: -30,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animationController.value * 2 * 3.14159,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(60),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: -_animationController.value * 1.5 * 3.14159,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Shimmer overlay
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.0 + _animationController.value * 2, -0.5),
                        end: Alignment(1.0 + _animationController.value * 2, 0.5),
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                    ),
                  );
                },
              ),
              
              // Main content
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 24,
                  vertical: isMobile ? 16 : 20,
                ),
                child: Row(
                  children: [
                    // Wallet icon with animation
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_animationController.value * 0.1),
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 12 : 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              walletIcon,
                              color: Colors.white,
                              size: isMobile ? 24 : 28,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(width: isMobile ? 16 : 20),
                    
                    // Wallet amount and label
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                            'Wallet Balance',
                            style: (isMobile ? AppTextStyles.bodySmall : AppTextStyles.bodyMedium).copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: isMobile ? 4 : 6),
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Text(
                                '₹${walletAmount.toStringAsFixed(0)}',
                                style: (isMobile ? AppTextStyles.headlineLarge : AppTextStyles.displaySmall).copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              );
                            },
                ),
              ],
            ),
                    ),
                    
                    // Status badge with animation
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 8 : 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                        children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.6),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                          Text(
                                statusText,
                                style: (isMobile ? AppTextStyles.labelSmall : AppTextStyles.labelMedium).copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Sparkle effects
              ...List.generate(5, (index) {
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final sparkleOffset = (index * 0.2 + _animationController.value) % 1.0;
                    final sparkleOpacity = (0.5 + 0.5 * ((_animationController.value + index * 0.2) % 1.0));
                    
                    return Positioned(
                      left: sparkleOffset * (screenWidth - 100),
                      top: 10 + (index % 2) * 30,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(sparkleOpacity * 0.8),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(sparkleOpacity * 0.4),
                              blurRadius: 6,
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
      },
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back!',
          style: isMobile ? AppTextStyles.headlineLarge : AppTextStyles.displaySmall,
            ),
        SizedBox(height: isMobile ? 4 : 8),
            Text(
              'Here\'s what\'s happening with your platform today.',
          style: (isMobile ? AppTextStyles.bodyMedium : AppTextStyles.bodyLarge).copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
      ],
    );
  }

  Widget _buildEnhancedCustomerStatsSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userReferralCode = authProvider.userData?['myReferralCode'];
        
        return FutureBuilder<List<Customer>>(
          future: _customersService.getCustomers(referralCode: userReferralCode),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingCustomerStatsCards();
            }
            
            final customers = snapshot.data ?? [];
            final stats = _calculateCustomerStats(customers, userReferralCode);
            
            return _buildEnhancedCustomerStatsCards(stats);
          },
        );
      },
    );
  }
  
    Widget _buildLoadingCustomerStatsCards() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.primary100.withOpacity(0.3),
            AppColors.neutral50,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Section Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: isMobile ? 12 : 16,
            ),
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
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary500.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: isMobile ? 18 : 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          Text(
                        'Customer Insights',
                        style: (isMobile ? AppTextStyles.titleLarge : AppTextStyles.headlineMedium).copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Real-time analytics',
                            style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 20 : 24),
          
          // Loading Stats Grid with Shimmer Effect
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 2 : isTablet ? 2 : 4,
            crossAxisSpacing: isMobile ? 12 : 16,
            mainAxisSpacing: isMobile ? 12 : 16,
            childAspectRatio: isMobile ? 1.0 : isTablet ? 1.2 : 1.1,
            children: List.generate(4, (index) {
              final colors = [
                [const Color(0xFF6366F1), const Color(0xFF4F46E5), const Color(0xFF4338CA)], // Indigo
                [const Color(0xFF059669), const Color(0xFF047857), const Color(0xFF065F46)], // Emerald
                [const Color(0xFFD97706), const Color(0xFFB45309), const Color(0xFF92400E)], // Amber
                [const Color(0xFF7C3AED), const Color(0xFF6D28D9), const Color(0xFF5B21B6)], // Violet
              ];
              
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors[index],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colors[index][0].withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: colors[index][1].withOpacity(0.2),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Stack(
                          children: [
                    // Glassmorphism overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    // Loading indicator
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(height: isMobile ? 8 : 12),
                          Container(
                            width: 60,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
  
    Widget _buildEnhancedCustomerStatsCards(Map<String, dynamic> stats) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.primary100.withOpacity(0.3),
            AppColors.neutral50,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          // Enhanced Section Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: isMobile ? 12 : 16,
            ),
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
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary500.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: isMobile ? 18 : 22,
                  ),
                ),
                const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                        'Customer Insights',
                        style: (isMobile ? AppTextStyles.titleLarge : AppTextStyles.headlineMedium).copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Real-time analytics',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 20 : 24),
          
          // Enhanced Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 2 : isTablet ? 2 : 4,
            crossAxisSpacing: isMobile ? 12 : 16,
            mainAxisSpacing: isMobile ? 12 : 16,
            childAspectRatio: isMobile ? 1.0 : isTablet ? 1.2 : 1.1,
            children: [
              _buildEnhancedStatCard(
                'Total Customers',
                '${stats['totalCustomers']}',
                Icons.people_rounded,
                [const Color(0xFF6366F1), const Color(0xFF4F46E5), const Color(0xFF4338CA)], // Indigo gradient
                'All customers',
              ),
              _buildEnhancedStatCard(
                'Direct Referrals',
                '${stats['directReferrals']}',
                Icons.person_add_rounded,
                [const Color(0xFF059669), const Color(0xFF047857), const Color(0xFF065F46)], // Emerald gradient
                'Direct signups',
              ),
              _buildEnhancedStatCard(
                'Indirect Referrals',
                '${stats['indirectReferrals']}',
                Icons.group_add_rounded,
                [const Color(0xFFD97706), const Color(0xFFB45309), const Color(0xFF92400E)], // Amber gradient
                'Network effect',
              ),
              _buildEnhancedStatCard(
                'Completed',
                '${stats['completedCustomers']}',
                Icons.check_circle_rounded,
                [const Color(0xFF7C3AED), const Color(0xFF6D28D9), const Color(0xFF5B21B6)], // Violet gradient
                'Successful deals',
              ),
            ],
          ),
          
          SizedBox(height: isMobile ? 20 : 24),
          
          // Enhanced Summary Card
          _buildEnhancedSummaryCard(stats),
        ],
      ),
    );
  }
  
    Widget _buildEnhancedStatCard(
    String title,
    String value,
    IconData icon,
    List<Color> gradientColors,
    String subtitle,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: gradientColors[1].withOpacity(0.2),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern overlay
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
          Positioned(
            bottom: -10,
            left: -10,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          
          // Main content
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and Trend Row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: isMobile ? 18 : 22,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.trending_up,
                            color: Colors.white.withOpacity(0.9),
                            size: isMobile ? 10 : 14,
                              ),
                          const SizedBox(width: 4),
                              Text(
                            'LIVE',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 8 : 9,
                            ),
                              ),
                            ],
                          ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Value with enhanced typography
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    value,
                    style: (isMobile ? AppTextStyles.headlineMedium : AppTextStyles.displaySmall).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: isMobile ? 2 : 8),
                
                // Title with better styling
                          Text(
                  title,
                  style: (isMobile ? AppTextStyles.bodySmall : AppTextStyles.bodyMedium).copyWith(
                    color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                            ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                          ),
                
                SizedBox(height: isMobile ? 2 : 4),
                
                // Subtitle with refined styling
                          Text(
                  subtitle,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: isMobile ? 2 : 12),
                
                // Progress indicator
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.7, // You can make this dynamic based on actual data
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEnhancedSummaryCard(Map<String, dynamic> stats) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    final totalCustomers = stats['totalCustomers'] as int;
    final completedCustomers = stats['completedCustomers'] as int;
    final completionRate = totalCustomers > 0 ? completedCustomers / totalCustomers : 0.0;
    final directReferrals = stats['directReferrals'] as int;
    final indirectReferrals = stats['indirectReferrals'] as int;
    final totalReferrals = directReferrals + indirectReferrals;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.neutral50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
            // Header
                          Row(
                            children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.success500, AppColors.success600],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    color: Colors.white,
                    size: isMobile ? 16 : 18,
                  ),
                              ),
                              const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Performance Summary',
                    style: (isMobile ? AppTextStyles.titleMedium : AppTextStyles.titleLarge).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                              ),
                            ],
                          ),
            
            SizedBox(height: isMobile ? 16 : 20),
            
            // Metrics Row
              Row(
                children: [
                  Expanded(
                  child: _buildMetricItem(
                    'Completion Rate',
                    '${(completionRate * 100).toStringAsFixed(1)}%',
                    Icons.check_circle_outline,
                    completionRate,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: _buildMetricItem(
                    'Total Referrals',
                    '$totalReferrals',
                    Icons.share_rounded,
                    totalReferrals > 0 ? 1.0 : 0.0,
                            ),
                          ),
                        ],
                      ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricItem(String label, String value, IconData icon, double progress) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
              icon,
              size: isMobile ? 16 : 18,
              color: AppColors.primary600,
            ),
            const SizedBox(width: 8),
                  Expanded(
              child: Text(
                label,
                style: (isMobile ? AppTextStyles.bodySmall : AppTextStyles.bodyMedium).copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
                              ),
                            ],
                          ),
        const SizedBox(height: 8),
                              Text(
          value,
          style: (isMobile ? AppTextStyles.headlineSmall : AppTextStyles.headlineMedium).copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.neutral200,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary500, AppColors.primary600],
                ),
                borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
        ),
      ],
    );
  }
  
  Map<String, dynamic> _calculateCustomerStats(List<Customer> customers, String? userReferralCode) {
    final totalCustomers = customers.length;
    final directReferrals = customers.where((c) => 
      c.referralCode == userReferralCode).length;
    final indirectReferrals = customers.where((c) => 
      c.referralCode1 == userReferralCode && c.referralCode != userReferralCode).length;
    final completedCustomers = customers.where((c) => 
      c.status.toLowerCase().contains('completed') || 
      c.status.toLowerCase().contains('full payment done')).length;
    
    return {
      'totalCustomers': totalCustomers,
      'directReferrals': directReferrals,
      'indirectReferrals': indirectReferrals,
      'completedCustomers': completedCustomers,
    };
  }

  Widget _buildPaymentEarningsChart() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userReferralCode = authProvider.userData?['myReferralCode'];
        final userId = authProvider.user?.uid;
        
        return FutureBuilder<Map<String, List<FlSpot>>>(
          future: _getPaymentEarningsData(userReferralCode, userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingPaymentChart();
            }
            
            final chartData = snapshot.data ?? {};
            
            return _buildPaymentChart(chartData);
          },
        );
      },
    );
  }

  Widget _buildLeadCustomerComparisonChart() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userReferralCode = authProvider.userData?['myReferralCode'];
        
        return FutureBuilder<Map<String, List<FlSpot>>>(
          future: _getLeadCustomerData(userReferralCode),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingLeadChart();
            }
            
            final chartData = snapshot.data ?? {};
            
            return _buildLeadChart(chartData);
          },
        );
      },
    );
  }

  Future<Map<String, List<FlSpot>>> _getPaymentEarningsData(String? userReferralCode, String? userId) async {
    try {
      final now = DateTime.now();
      final last30Days = now.subtract(const Duration(days: 30));
      
      final transactions = userId != null ? await _commissionService.getUserCommissionTransactions(userId) : <CommissionTransaction>[];
      
      final Map<String, List<FlSpot>> chartData = {
        'walletAmount': [],
      };
      
      double cumulativeWalletAmount = 0.0;
      
      for (int i = 0; i < 30; i++) {
        final date = last30Days.add(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        
        // Calculate wallet amount increase for this day (commissions received)
        final dayCommissions = transactions.where((t) => 
          t.createdAt.isAfter(dayStart) && 
          t.createdAt.isBefore(dayEnd) &&
          (t.type == 'commission' || t.type == 'earning')
        ).fold(0.0, (sum, t) => sum + t.amount);
        
        cumulativeWalletAmount += dayCommissions;
        
        chartData['walletAmount']!.add(FlSpot(i.toDouble(), cumulativeWalletAmount));
      }
      
      return chartData;
    } catch (e) {
      print('Error loading wallet data: $e');
      return {
        'walletAmount': [],
      };
    }
  }

  Future<Map<String, List<FlSpot>>> _getLeadCustomerData(String? userReferralCode) async {
    try {
      final now = DateTime.now();
      final last30Days = now.subtract(const Duration(days: 30));
      
      final customers = await _customersService.getCustomers(referralCode: userReferralCode);
      final leads = await _leadsService.getLeads(referralCode: userReferralCode);
      
      final Map<String, List<FlSpot>> chartData = {
        'customers': [],
        'leads': [],
      };
      
      for (int i = 0; i < 30; i++) {
        final date = last30Days.add(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        
        // Count customers for this day
        final dayCustomers = customers.where((c) => 
          c.createdAtDate != null && 
          c.createdAtDate!.isAfter(dayStart) && 
          c.createdAtDate!.isBefore(dayEnd)
        ).length;
        
        // Count leads for this day
        final dayLeads = leads.where((l) {
          try {
            final leadDate = DateTime.parse(l.createdAt);
            return leadDate.isAfter(dayStart) && leadDate.isBefore(dayEnd);
          } catch (e) {
            return false;
          }
        }).length;
        
        chartData['customers']!.add(FlSpot(i.toDouble(), dayCustomers.toDouble()));
        chartData['leads']!.add(FlSpot(i.toDouble(), dayLeads.toDouble()));
      }
      
      return chartData;
    } catch (e) {
      print('Error loading lead/customer data: $e');
      return {
        'customers': [],
        'leads': [],
      };
    }
  }

  Widget _buildLoadingPaymentChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.info100, AppColors.info50],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.info600,
                  size: isMobile ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
                          Text(
                'Wallet Balance Analytics',
                style: (isMobile ? AppTextStyles.titleMedium : AppTextStyles.titleLarge).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),
          Container(
            height: isMobile ? 220 : 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.info50.withOpacity(0.5),
                  AppColors.neutral50,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingLeadChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.success100, AppColors.success50],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.compare_arrows_rounded,
                  color: AppColors.success600,
                  size: isMobile ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
                          Text(
                'Leads vs Customers Comparison',
                style: (isMobile ? AppTextStyles.titleMedium : AppTextStyles.titleLarge).copyWith(
                  fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
          SizedBox(height: isMobile ? 16 : 24),
          Container(
            height: isMobile ? 220 : 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.success50.withOpacity(0.5),
                  AppColors.neutral50,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentChart(Map<String, List<FlSpot>> chartData) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.info100, AppColors.info50],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.info600,
                  size: isMobile ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
                  Expanded(
                child: Text(
                  'Wallet Balance (Last 30 Days)',
                  style: (isMobile ? AppTextStyles.titleMedium : AppTextStyles.titleLarge).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: isMobile ? 16 : 24),
          
          // Legend
          if (!isMobile) _buildPaymentChartLegend(),
          if (!isMobile) const SizedBox(height: 16),
          
          // Chart
          SizedBox(
            height: isMobile ? 220 : isTablet ? 280 : 320,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: _getSmartYInterval(chartData),
                  verticalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.neutral200,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: AppColors.neutral200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: isMobile ? 10 : 5,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % (isMobile ? 10 : 5) == 0) {
                          final date = DateTime.now().subtract(Duration(days: 30 - value.toInt()));
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              DateFormat('M/d').format(date),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: _getSmartYInterval(chartData),
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            _formatYAxisValue(value),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppColors.neutral200),
                ),
                minX: 0,
                maxX: 29,
                minY: 0,
                maxY: _getSmartMaxY(chartData),
                lineBarsData: [
                  // Wallet Amount line with light blue colors
                  LineChartBarData(
                    spots: chartData['walletAmount'] ?? [],
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.info400,
                        AppColors.info500,
                        AppColors.info600,
                      ],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: !isMobile,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: AppColors.info500,
                          strokeWidth: 3,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.info200.withOpacity(0.4),
                          AppColors.info100.withOpacity(0.2),
                          AppColors.info50.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Mobile Legend
          if (isMobile) ...[
            const SizedBox(height: 16),
            _buildPaymentChartLegend(),
          ],
        ],
      ),
    );
  }

  Widget _buildLeadChart(Map<String, List<FlSpot>> chartData) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    
    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                Icons.compare_arrows_rounded,
                color: AppColors.success600,
                size: isMobile ? 20 : 24,
                              ),
                              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Leads vs Customers (Last 30 Days)',
                  style: (isMobile ? AppTextStyles.titleMedium : AppTextStyles.titleLarge).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                              ),
                            ],
                          ),
          SizedBox(height: isMobile ? 16 : 24),
          
          // Legend
          if (!isMobile) _buildLeadCustomerLegend(),
          if (!isMobile) const SizedBox(height: 16),
          
          // Chart
          SizedBox(
            height: isMobile ? 220 : isTablet ? 280 : 320,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: _getSmartYInterval(chartData),
                  verticalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.neutral200,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: AppColors.neutral200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: isMobile ? 10 : 5,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % (isMobile ? 10 : 5) == 0) {
                          final date = DateTime.now().subtract(Duration(days: 30 - value.toInt()));
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              DateFormat('M/d').format(date),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: _getSmartYInterval(chartData),
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            _formatYAxisValue(value),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppColors.neutral200),
                ),
                minX: 0,
                maxX: 29,
                minY: 0,
                maxY: _getSmartMaxY(chartData),
                lineBarsData: [
                  // Customers line
                  LineChartBarData(
                    spots: chartData['customers'] ?? [],
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary500.withOpacity(0.8),
                        AppColors.primary600,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: !isMobile,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary500,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary500.withOpacity(0.2),
                          AppColors.primary500.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Leads line
                  LineChartBarData(
                    spots: chartData['leads'] ?? [],
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success500.withOpacity(0.8),
                        AppColors.success600,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: !isMobile,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.success500,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
          
          // Mobile Legend
          if (isMobile) ...[
                          const SizedBox(height: 16),
            _buildLeadCustomerLegend(),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentChartLegend() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Wrap(
      spacing: isMobile ? 16 : 24,
      runSpacing: 8,
      children: [
        _buildLegendItem(
          'Wallet Balance (₹)',
          AppColors.info500,
          Icons.currency_rupee_rounded,
        ),
      ],
    );
  }

  Widget _buildLeadCustomerLegend() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Wrap(
      spacing: isMobile ? 16 : 24,
      runSpacing: 8,
      children: [
        _buildLegendItem(
          'Customers',
          AppColors.primary500,
          Icons.people_rounded,
        ),
        _buildLegendItem(
          'Leads',
          AppColors.success500,
          Icons.trending_up_rounded,
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isMobile ? 12 : 16,
          height: isMobile ? 12 : 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          icon,
          size: isMobile ? 14 : 16,
          color: color,
        ),
        const SizedBox(width: 4),
                          Text(
          label,
          style: (isMobile ? AppTextStyles.labelSmall : AppTextStyles.labelMedium).copyWith(
                              color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
    );
  }

  double _getSmartYInterval(Map<String, List<FlSpot>> chartData) {
    final maxY = _getSmartMaxY(chartData);
    if (maxY <= 10) return 1.0;
    if (maxY <= 20) return 2.0;
    if (maxY <= 50) return 5.0;
    if (maxY <= 100) return 10.0;
    if (maxY <= 200) return 20.0;
    if (maxY <= 500) return 50.0;
    if (maxY <= 1000) return 100.0;
    return 100.0; // Default to 100 for very large numbers
  }

  double _getSmartMaxY(Map<String, List<FlSpot>> chartData) {
    double maxY = 0;
    
    for (final spots in chartData.values) {
      for (final spot in spots) {
        if (spot.y > maxY) {
          maxY = spot.y;
        }
      }
    }
    
    return maxY > 0 ? maxY * 1.2 : 10; // Add 20% padding or minimum of 10
  }

  String _formatYAxisValue(double value) {
    if (value < 1000) return value.toInt().toString();
    if (value < 1000000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  Widget _buildRecentActivity() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
            
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
            Row(
              children: [
            Expanded(
              child: Text(
                  'Recent Activity',
                style: isMobile ? AppTextStyles.titleLarge : AppTextStyles.headlineMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            isMobile 
              ? IconButton(
                  onPressed: _loadDashboardData,
                  icon: Icon(
                    Icons.refresh,
                    size: 20,
                    color: AppColors.primary600,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              : TextButton.icon(
                  onPressed: _loadDashboardData,
                  icon: Icon(
                    Icons.refresh,
                    size: 16,
                    color: AppColors.primary600,
                  ),
                  label: Text(
                    'Refresh',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary600,
                      ),
                    ),
                  ),
                ],
            ),
            const SizedBox(height: 16),
            
        // Activity Content
            AppCard(
              child: _activities.isEmpty
                  ? Padding(
                  padding: EdgeInsets.all(isMobile ? 30 : 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                        size: isMobile ? 40 : 48,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No recent activity',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Activity will appear here as users interact with the platform',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: _activities.asMap().entries.map((entry) {
                        final index = entry.key;
                        final activity = entry.value;
                        
                        return Column(
                          children: [
                            _buildActivityItem(
                              activity.title,
                              activity.description,
                              activity.time,
                              _getIconData(activity.icon),
                              _getIconColor(activity.iconColor),
                            ),
                            if (index < _activities.length - 1)
                              const Divider(height: 24),
                          ],
                        );
                      }).toList(),
                    ),
            ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String description,
    String time,
    IconData icon,
    Color iconColor,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12),
      child: Row(
      children: [
        Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
              size: isMobile ? 18 : 22,
            color: iconColor,
          ),
        ),
          SizedBox(width: isMobile ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                  style: (isMobile ? AppTextStyles.bodyMedium : AppTextStyles.titleSmall).copyWith(
                    fontWeight: FontWeight.w600,
                              ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
              ),
            ],
          ),
        ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
          time,
              style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
          ),
        ),
      ],
                          ),
    );
  }

  String _formatNumber(int number) {
    return NumberFormat('#,##0').format(number);
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0').format(amount);
  }

  String _formatTrend(double trend) {
    final sign = trend >= 0 ? '+' : '';
    return '$sign${trend.toStringAsFixed(1)}%';
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'person_add':
        return Icons.person_add;
      case 'verified_user':
        return Icons.verified_user;
      case 'warning':
        return Icons.warning;
      case 'payment':
        return Icons.payment;
      case 'backup':
        return Icons.backup;
      default:
        return Icons.info;
    }
  }

  Color _getIconColor(String colorName) {
    switch (colorName) {
      case 'success':
        return AppColors.success500;
      case 'warning':
        return AppColors.warning500;
      case 'info':
        return AppColors.info500;
      default:
        return AppColors.primary500;
    }
  }
} 