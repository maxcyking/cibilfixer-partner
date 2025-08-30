import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/lead_model.dart';

class LeadStatusDialog extends StatefulWidget {
  final String currentStatus;

  const LeadStatusDialog({
    super.key,
    required this.currentStatus,
  });

  @override
  State<LeadStatusDialog> createState() => _LeadStatusDialogState();
}

class _LeadStatusDialogState extends State<LeadStatusDialog> {
  late String _selectedStatus;
  final TextEditingController _remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Handle unknown statuses by defaulting to the first valid status if current status is not found
    final validStatuses = LeadStatus.values.map((s) => s.value).toList();
    if (validStatuses.contains(widget.currentStatus)) {
      _selectedStatus = widget.currentStatus;
    } else {
      // If the current status is not in our enum, default to 'NEW'
      _selectedStatus = LeadStatus.newLead.value;
    }
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit,
              color: AppColors.primary600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Update Lead Status',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Current Status: ',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.currentStatus),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.currentStatus,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              'New Status',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.neutral300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: Key('status_dropdown_${_selectedStatus}_${widget.currentStatus}'),
                  value: _selectedStatus,
                  isExpanded: true,
                  items: LeadStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status.value,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _getStatusColor(status.value),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              status.value,
                              style: AppTextStyles.bodyMedium,
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
            
            const SizedBox(height: 20),
            
            Text(
              'Remark (Optional)',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            TextField(
              controller: _remarkController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add a remark about this status change...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.neutral300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.neutral300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary500, width: 2),
                ),
                filled: true,
                fillColor: AppColors.neutral50,
              ),
            ),
            
            if (_selectedStatus == LeadStatus.convertedToCustomer.value) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.warning600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will create a customer account and Firebase user.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _selectedStatus == widget.currentStatus
              ? null
              : () {
                  final remark = _remarkController.text.trim();
                  Navigator.of(context).pop(<String, String?>{
                    'status': _selectedStatus,
                    'remark': remark.isEmpty ? null : remark,
                  });
                },
          icon: Icon(
            _selectedStatus == LeadStatus.convertedToCustomer.value
                ? Icons.person_add
                : Icons.update,
            size: 16,
          ),
          label: Text(_selectedStatus == LeadStatus.convertedToCustomer.value
              ? 'Convert to Customer'
              : 'Update Status'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedStatus == LeadStatus.convertedToCustomer.value
                ? AppColors.success500
                : AppColors.primary500,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'NEW':
        return AppColors.info500;
      case 'CONTACTED':
        return AppColors.warning500;
      case 'INTERESTED':
        return AppColors.success500;
      case 'NOT INTERESTED':
      case 'NO RESPONSE':
        return AppColors.error500;
      case 'CONVERTED TO CUSTOMER':
        return AppColors.success600;
      default:
        return AppColors.neutral500; // Handle unknown statuses
    }
  }
} 