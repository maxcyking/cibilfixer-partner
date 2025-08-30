import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/badges/app_badge.dart';
import '../../../models/customer_model.dart';
import 'package:intl/intl.dart';

class CustomerDetailsDialog extends StatelessWidget {
  final Customer customer;

  const CustomerDetailsDialog({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer Details'),
                const SizedBox(height: 4),
                Text(
                  customer.customerId,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppBadge(
            text: customer.status,
            type: _getStatusBadgeType(customer.status),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information
              _buildSection('Personal Information', [
                _buildDetailRow('Full Name', customer.fullName),
                _buildDetailRow('Father\'s Name', customer.fatherName),
                _buildDetailRow('Gender', customer.gender),
                _buildDetailRow('Date of Birth', _formatDate(customer.dobDate)),
                _buildDetailRow('Mobile', customer.mobile),
                _buildDetailRow('Email', customer.email ?? 'N/A'),
                _buildDetailRow('Aadhar', customer.aadhar),
                _buildDetailRow('PAN', customer.pan),
              ]),
              
              const SizedBox(height: 24),
              
              // Address Information
              _buildSection('Address Information', [
                _buildDetailRow('Address', customer.address),
                _buildDetailRow('Village', customer.village),
                _buildDetailRow('Tehsil/City', customer.tehsilCity),
                _buildDetailRow('District', customer.district),
                _buildDetailRow('State', customer.state),
                _buildDetailRow('PIN Code', customer.pin),
              ]),
              
              const SizedBox(height: 24),
              
              // Credit Information
              _buildSection('Credit Information', [
                _buildDetailRow('Issue', customer.issue),
                _buildDetailRow('Transaction ID', customer.transactionId),
                _buildDetailRow('Referral Code (Direct)', customer.referralCode.isEmpty ? 'N/A' : customer.referralCode),
                _buildDetailRow('Referral Code (Level 2)', customer.referralCode1.isEmpty ? 'N/A' : customer.referralCode1),
              ]),
              
              const SizedBox(height: 24),
              
              // Account Information
              _buildSection('Account Information', [
                _buildDetailRow('User ID', customer.userId ?? 'N/A'),
                _buildDetailRow('Email Login', customer.email ?? 'N/A'),
              ]),
              
              const SizedBox(height: 24),
              
              // Documents
              if (customer.documents.isNotEmpty) ...[
                _buildSection('Documents', [
                  ...customer.documents.entries.map((entry) =>
                    _buildDetailRow(
                      entry.key.toUpperCase(),
                      entry.value.toString(),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
              ],
              
              // Timeline
              _buildSection('Timeline', [
                _buildDetailRow('Created At', _formatDateTime(customer.createdAtDate)),
                _buildDetailRow('Updated At', _formatDateTime(customer.updatedAtDate)),
              ]),
              
              // Remarks
              if (customer.remark.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSection('Remarks', []),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    customer.remark,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
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
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  BadgeType _getStatusBadgeType(String status) {
    switch (status) {
      case 'PENDING FOR PAYMENT CONFERMATION':
        return BadgeType.warning;
      case 'IN PROCESSING WITH BANK/CIC':
      case 'IN PROCESSING WITH BANK/CIC 2 STEP':
        return BadgeType.info;
      case 'PENDING WITH BANK FOR PAYMENT':
      case 'PENDING WITH CIC':
      case 'PENDING WITH CUSTOMER FOR FULL PAYMENT':
        return BadgeType.warning;
      case 'FULL PAYMENT DONE':
      case 'COMPLETED':
        return BadgeType.success;
      case 'LOST':
        return BadgeType.error;
      default:
        return BadgeType.neutral;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM d, y').format(date);
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM d, y HH:mm').format(date);
  }
} 