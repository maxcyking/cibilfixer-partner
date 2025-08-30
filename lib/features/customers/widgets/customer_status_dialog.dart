import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/customer_model.dart';

class CustomerStatusDialog extends StatefulWidget {
  final String currentStatus;

  const CustomerStatusDialog({
    super.key,
    required this.currentStatus,
  });

  @override
  State<CustomerStatusDialog> createState() => _CustomerStatusDialogState();
}

class _CustomerStatusDialogState extends State<CustomerStatusDialog> {
  late String _selectedStatus;
  final TextEditingController _remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Better status matching with normalization
    _selectedStatus = _findBestMatchingStatus(widget.currentStatus);
    print('🔍 Available statuses: ${CustomerStatus.values.map((e) => e.value).toList()}');
    print('🔍 Current status: "${widget.currentStatus}"');
    print('🔍 Selected status: "$_selectedStatus"');
  }

  // Improved status matching
  String _findBestMatchingStatus(String currentStatus) {
    final availableStatuses = CustomerStatus.values.map((e) => e.value).toList();
    
    // Direct match
    if (availableStatuses.contains(currentStatus)) {
      return currentStatus;
    }
    
    // Normalize and try to match
    final normalizedCurrent = currentStatus.toUpperCase()
        .replaceAll('_', ' ')
        .replaceAll('CONFERMATION', 'CONFIRMATION')
        .trim();
    
    for (final status in availableStatuses) {
      if (status.toUpperCase() == normalizedCurrent) {
        return status;
      }
    }
    
    // Fallback to first status
    return CustomerStatus.values.first.value;
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600, // Prevent overflow
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    'Update Customer Status',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.neutral100,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status: ${widget.currentStatus}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'New Status',
                      style: AppTextStyles.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          key: ValueKey('customer_status_dropdown_${widget.currentStatus}_${DateTime.now().millisecondsSinceEpoch}'),
                          value: _selectedStatus,
                          isExpanded: true,
                          items: CustomerStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status.value,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status.value),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      status.value,
                                      style: AppTextStyles.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedStatus = value);
                            }
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Remark (Optional)',
                      style: AppTextStyles.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    
                    TextField(
                      controller: _remarkController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add a remark about this status change...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.neutral300),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedStatus == widget.currentStatus
                          ? null
                          : () {
                              // Return proper Map<String, String> type
                              final result = <String, String>{
                                'status': _selectedStatus,
                              };
                              
                              final remark = _remarkController.text.trim();
                              if (remark.isNotEmpty) {
                                result['remark'] = remark;
                              }
                              
                              Navigator.of(context).pop(result);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Update Status',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
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

  Color _getStatusColor(String status) {
    final normalizedStatus = status.toUpperCase().trim();
    switch (normalizedStatus) {
      case 'PENDING FOR PAYMENT CONFERMATION':    // Old typo version
      case 'PENDING FOR PAYMENT CONFIRMATION':    // Corrected version
      case 'PENDING_PAYMENT_CONFIRMATION':        // Database format
        return AppColors.warning500;
      case 'IN PROCESSING WITH BANK/CIC':
      case 'IN PROCESSING WITH BANK/CIC 2 STEP':
        return AppColors.info500;
      case 'PENDING WITH BANK FOR PAYMENT':
      case 'PENDING WITH CIC':
      case 'PENDING WITH CUSTOMER FOR FULL PAYMENT':
        return AppColors.warning500;
      case 'FULL PAYMENT DONE':
      case 'COMPLETED':
        return AppColors.success500;
      case 'LOST':
        return AppColors.error500;
      default:
        return AppColors.neutral500;
    }
  }
} 