import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Transaction Type Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getTypeColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getTypeIcon(),
                        color: _getTypeColor(),
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Transaction Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTransactionTitle(),
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: isSmallScreen ? 16 : 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            transaction.description,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Amount and Status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatAmount(),
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _getAmountColor(),
                            fontSize: isSmallScreen ? 16 : 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            transaction.status.name.toUpperCase(),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Details Row
                Row(
                  children: [
                    // Customer Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            transaction.customerName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Package Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Package',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getPackageColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              transaction.packageType.name.toUpperCase(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: _getPackageColor(),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Date',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(transaction.createdAt),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Referral Commission Info (if applicable)
                if (transaction.type == TransactionType.commission) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          color: AppColors.success600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Referral Commission',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.success700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (transaction.referrerName != null)
                                Text(
                                  'Paid to: ${transaction.referrerName}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.success600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${(Transaction.commissionRate * 100).toInt()}%',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.success700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Transaction ID
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.textTertiary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ID: ${transaction.id}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTransactionTitle() {
    switch (transaction.type) {
      case TransactionType.payment:
        return 'Payment';
      case TransactionType.commission:
        return 'Commission';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.payout:
        return 'Payout';
    }
  }

  IconData _getTypeIcon() {
    switch (transaction.type) {
      case TransactionType.payment:
        return Icons.payment;
      case TransactionType.commission:
        return Icons.percent;
      case TransactionType.withdrawal:
        return Icons.money_off;
      case TransactionType.refund:
        return Icons.refresh;
      case TransactionType.payout:
        return Icons.payments_outlined;
    }
  }

  Color _getTypeColor() {
    switch (transaction.type) {
      case TransactionType.payment:
        return AppColors.success50;
      case TransactionType.commission:
        return AppColors.warning50;
      case TransactionType.withdrawal:
        return AppColors.error50;
      case TransactionType.refund:
        return AppColors.info50;
      case TransactionType.payout:
        return AppColors.primary50;
    }
  }

  Color _getStatusColor() {
    switch (transaction.status) {
      case TransactionStatus.completed:
        return AppColors.success500;
      case TransactionStatus.pending:
        return AppColors.warning500;
      case TransactionStatus.failed:
        return AppColors.error500;
      case TransactionStatus.cancelled:
        return AppColors.neutral500;
    }
  }

  Color _getPackageColor() {
    switch (transaction.packageType) {
      case PackageType.basic:
        return AppColors.info500;
      case PackageType.premium:
        return AppColors.warning500;
      case PackageType.enterprise:
        return AppColors.primary500;
    }
  }

  Color _getAmountColor() {
    switch (transaction.type) {
      case TransactionType.payment:
      case TransactionType.commission:
        return AppColors.success600;
      case TransactionType.withdrawal:
      case TransactionType.refund:
        return AppColors.error600;
      case TransactionType.payout:
        return AppColors.primary600;
    }
  }

  String _formatAmount() {
    final sign = (transaction.type == TransactionType.withdrawal || 
                  transaction.type == TransactionType.refund) ? '-' : '+';
    return '$sign₹${NumberFormat('#,##,###').format(transaction.amount)}';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
} 