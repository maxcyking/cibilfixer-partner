import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../models/user_model.dart';

class ProfileInfoCard extends StatelessWidget {
  final UserModel user;

  const ProfileInfoCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: user.fullName,
          ),
          
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email Address',
            value: user.email,
          ),
          
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Mobile Number',
            value: user.mobile,
          ),
          
          _buildInfoRow(
            icon: Icons.work_outline,
            label: 'Role',
            value: user.role.toUpperCase(),
          ),
          
          _buildInfoRow(
            icon: Icons.verified_outlined,
            label: 'Account Status',
            value: user.status.toUpperCase(),
            valueColor: user.isActive ? AppColors.success600 : AppColors.error600,
          ),
          
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Member Since',
            value: DateFormat('MMMM dd, yyyy').format(user.createdAt),
          ),
          
          if (user.earnings > 0)
            _buildInfoRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Total Earnings',
              value: '₹${user.earnings.toStringAsFixed(2)}',
              valueColor: AppColors.success600,
            ),
          
          if (user.referrals > 0)
            _buildInfoRow(
              icon: Icons.group_outlined,
              label: 'Total Referrals',
              value: user.referrals.toString(),
              valueColor: AppColors.primary600,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 