import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TransactionStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const TransactionStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary500,
            AppColors.primary600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact stats grid
            if (isMobile)
              _buildMobileStatsGrid()
            else
              _buildDesktopStatsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileStatsGrid() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top row - main stats
            Row(
              children: [
            Expanded(
              child: _buildCompactStatItem(
                'Revenue',
                '₹${_formatNumber(stats['totalRevenue']?.toDouble() ?? 0.0)}',
                Icons.trending_up,
                AppColors.success400,
              ),
            ),
            const SizedBox(width: 12),
                Expanded(
              child: _buildCompactStatItem(
                'Commissions',
                '₹${_formatNumber(stats['totalCommissions']?.toDouble() ?? 0.0)}',
                Icons.account_balance_wallet,
                AppColors.warning400,
                        ),
                      ),
                    ],
                  ),
        const SizedBox(height: 12),
        // Bottom row - count stats
                  Row(
                    children: [
                      Expanded(
              child: _buildCompactStatItem(
                          'Transactions',
                          '${stats['totalTransactions'] ?? 0}',
                Icons.receipt,
                          AppColors.info400,
                        ),
                      ),
            const SizedBox(width: 12),
                      Expanded(
              child: _buildCompactStatItem(
                          'Payments',
                          '${stats['completedPayments'] ?? 0}',
                Icons.payment,
                AppColors.secondary400,
                        ),
                      ),
                    ],
                  ),
      ],
    );
  }

  Widget _buildDesktopStatsGrid() {
    return Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Total Revenue',
                          '₹${_formatNumber(stats['totalRevenue']?.toDouble() ?? 0.0)}',
            Icons.trending_up,
                          AppColors.success400,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatItem(
            'Commissions',
                          '₹${_formatNumber(stats['totalCommissions']?.toDouble() ?? 0.0)}',
            Icons.account_balance_wallet,
                          AppColors.warning400,
                        ),
                      ),
        const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatItem(
            'Transactions',
                          '${stats['totalTransactions'] ?? 0}',
            Icons.receipt,
                          AppColors.info400,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatItem(
            'Payments',
                          '${stats['completedPayments'] ?? 0}',
            Icons.payment,
            AppColors.secondary400,
                        ),
                      ),
                    ],
    );
  }

  Widget _buildCompactStatItem(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 16,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
                const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 10000000) {
      return '${(number / 10000000).toStringAsFixed(1)}Cr';
    } else if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(1)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return NumberFormat('#,##0').format(number);
    }
  }
} 