import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/badges/app_badge.dart';
import '../../../models/lead_model.dart';

class LeadDetailsBottomSheet extends StatelessWidget {
  final Lead lead;

  const LeadDetailsBottomSheet({
    super.key,
    required this.lead,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      height: screenHeight * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.fullName,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${lead.customerId}',
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
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Personal Information', [
                    _buildDetailRow('Full Name', lead.fullName),
                    _buildDetailRow('Father\'s Name', lead.fatherName),
                    _buildDetailRow('Mobile', lead.mobile),
                    _buildDetailRow('Aadhar', lead.aadhar),
                    _buildDetailRow('PAN', lead.pan),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  _buildSection('Address Information', [
                    _buildDetailRow('Address', lead.address),
                    _buildDetailRow('District', lead.district),
                    _buildDetailRow('State', lead.state),
                    _buildDetailRow('PIN Code', lead.pin),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  _buildSection('Credit Information', [
                    _buildDetailRow('Issue', lead.issue),
                    _buildDetailRow('Transaction ID', lead.transactionId),
                  ]),
                  
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
        ],
      ),
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
} 