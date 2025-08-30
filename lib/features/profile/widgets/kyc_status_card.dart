import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/badges/app_badge.dart';
import '../../../models/user_model.dart';

class KycStatusCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onKycAction;

  const KycStatusCard({
    super.key,
    required this.user,
    required this.onKycAction,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: _getKycStatusColor(),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'KYC Verification',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              AppBadge(
                text: _getKycStatusText(),
                type: _getKycBadgeType(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress Section - Always show progress from database
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Completion Progress',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${user.kycProgress}%',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: _getProgressColor(),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: user.kycProgress / 100,
                backgroundColor: AppColors.neutral200,
                valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
          
          // Description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getKycStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getKycStatusColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getKycTitle(),
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getKycStatusColor(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getKycDescription(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: _getActionButtonText(),
              onPressed: onKycAction,
              icon: _getActionButtonIcon(),
            ),
          ),
          
          // Additional Info for incomplete KYC
          if (user.kycProgress > 0 && user.kycProgress < 100) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.info500,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Complete your KYC to access all features',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.info600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getKycStatusColor() {
    switch (user.kycStatus) {
      case 'completed':
        return AppColors.success500;
      case 'under_review':
        return AppColors.info500;
      case 'rejected':
        return AppColors.error500;
      default:
        return AppColors.warning500;
    }
  }

  String _getKycStatusText() {
    switch (user.kycStatus) {
      case 'completed':
        return 'Verified';
      case 'under_review':
        return 'Under Review';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  BadgeType _getKycBadgeType() {
    switch (user.kycStatus) {
      case 'completed':
        return BadgeType.success;
      case 'under_review':
        return BadgeType.info;
      case 'rejected':
        return BadgeType.error;
      default:
        return BadgeType.warning;
    }
  }

  Color _getProgressColor() {
    if (user.kycProgress >= 80) return AppColors.success500;
    if (user.kycProgress >= 50) return AppColors.warning500;
    return AppColors.error500;
  }

  String _getKycTitle() {
    if (user.kycProgress == 0) {
      return 'KYC Not Started';
    } else if (user.kycProgress < 100) {
      return 'KYC In Progress';
    } else {
      return 'KYC Completed';
    }
  }

  String _getKycDescription() {
    if (user.kycProgress == 0) {
      return 'Complete your KYC verification to access all platform features and ensure account security.';
    } else if (user.kycProgress < 100) {
      return 'Your KYC verification is ${user.kycProgress}% complete. Please finish the remaining steps.';
    } else {
      return 'Your KYC verification is complete. You have full access to all platform features.';
    }
  }

  String _getActionButtonText() {
    if (user.kycProgress == 0) {
      return 'Apply for KYC';
    } else if (user.kycProgress < 100) {
      return 'Continue KYC';
    } else {
      return 'View KYC Details';
    }
  }

  IconData _getActionButtonIcon() {
    if (user.kycProgress == 0) {
      return Icons.assignment_outlined;
    } else if (user.kycProgress < 100) {
      return Icons.update;
    } else {
      return Icons.visibility_outlined;
    }
  }
} 