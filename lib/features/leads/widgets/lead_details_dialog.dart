import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/badges/app_badge.dart';
import '../../../models/lead_model.dart';
import 'package:intl/intl.dart';

class LeadDetailsDialog extends StatelessWidget {
  final Lead lead;

  const LeadDetailsDialog({
    super.key,
    required this.lead,
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
                Text('Lead Details'),
                const SizedBox(height: 4),
                Text(
                  lead.customerId,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppBadge(
            text: lead.status,
            type: _getStatusBadgeType(lead.status),
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
                _buildDetailRow('Full Name', lead.fullName),
                _buildDetailRow('Father\'s Name', lead.fatherName),
                _buildDetailRow('Gender', lead.gender),
                _buildDetailRow('Date of Birth', _formatDate(lead.dobDate)),
                _buildDetailRow('Mobile', lead.mobile),
                _buildDetailRow('Aadhar', lead.aadhar),
                _buildDetailRow('PAN', lead.pan),
              ]),
              
              const SizedBox(height: 24),
              
              // Address Information
              _buildSection('Address Information', [
                _buildDetailRow('Address', lead.address),
                _buildDetailRow('Village', lead.village),
                _buildDetailRow('Tehsil/City', lead.tehsilCity),
                _buildDetailRow('District', lead.district),
                _buildDetailRow('State', lead.state),
                _buildDetailRow('PIN Code', lead.pin),
              ]),
              
              const SizedBox(height: 24),
              
              // Credit Information
              _buildSection('Credit Information', [
                _buildDetailRow('Issue', lead.issue),
                _buildDetailRow('Transaction ID', lead.transactionId),
                _buildDetailRow('Referral Code', lead.referralCode.isEmpty ? 'N/A' : lead.referralCode),
              ]),
              
              const SizedBox(height: 24),
              
              // Documents
              if (lead.documents.isNotEmpty) ...[
                _buildSection('Documents', [
                  ...lead.documents.entries.map((entry) =>
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
                _buildDetailRow('Created At', _formatDateTime(lead.createdAtDate)),
                _buildDetailRow('Updated At', _formatDateTime(lead.updatedAtDate)),
              ]),
              
              // Remarks
              if (lead.remark.isNotEmpty) ...[
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
                    lead.remark,
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
      case 'NEW':
        return BadgeType.info;
      case 'CONTACTED':
        return BadgeType.warning;
      case 'INTERESTED':
        return BadgeType.success;
      case 'NOT INTERESTED':
      case 'NO RESPONSE':
        return BadgeType.error;
      case 'CONVERTED TO CUSTOMER':
        return BadgeType.success;
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