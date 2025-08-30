import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../models/customer_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/packages_service.dart';
import '../../../services/transaction_service.dart';

class CustomerTile extends StatefulWidget {
  final Customer customer;
  final VoidCallback? onViewDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onRefresh;

  const CustomerTile({
    super.key,
    required this.customer,
    this.onViewDetails,
    this.onEdit,
    this.onRefresh,
  });

  @override
  State<CustomerTile> createState() => _CustomerTileState();
}

class _CustomerTileState extends State<CustomerTile> {
  final TransactionService _transactionService = TransactionService();
  final PackagesService _packagesService = PackagesService();
  bool _isProcessingPayment = false;
  final bool _isAssigningPackage = false;

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveUtils.isMobile(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                children: [
                  // Profile Circle
                  Container(
                    width: isSmallScreen ? 40 : 48,
                    height: isSmallScreen ? 40 : 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        widget.customer.fullName.isNotEmpty
                            ? widget.customer.fullName.split(' ').map((name) => name.isNotEmpty ? name[0] : '').join().toUpperCase()
                            : 'U',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Customer Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customer.fullName,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.customer.customerId,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: isSmallScreen ? 11 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions
                  _buildActionButtons(isSmallScreen),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Package Information (if assigned)
              if (widget.customer.hasPackage)
                _buildPackageInfo(),
              
              // Status Section
              _buildStatusSection(isSmallScreen),
              
              // Additional Info
              _buildAdditionalInfo(isSmallScreen),
              
              // Issue Section
              if (widget.customer.issue.isNotEmpty)
                _buildIssueSection(isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isSmallScreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Package Assignment Button
        if (!widget.customer.hasPackage)
          Container(
            decoration: BoxDecoration(
              color: AppColors.warning50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: _isAssigningPackage ? null : _showPackageAssignmentDialog,
              icon: _isAssigningPackage
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.warning600,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.assignment_outlined,
                      size: 20,
                      color: AppColors.warning600,
                    ),
              tooltip: 'Assign Package',
              padding: const EdgeInsets.all(8),
            ),
          ),
        
        if (!widget.customer.hasPackage) const SizedBox(width: 8),
        
        // Payment Button (only if package is assigned)
        if (widget.customer.hasPackage && !_isPaymentDone())
          Container(
            decoration: BoxDecoration(
              color: _isProcessingPayment ? AppColors.neutral100 : AppColors.success50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: _isProcessingPayment ? null : _showPaymentConfirmation,
              icon: _isProcessingPayment
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.success600,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.payment_rounded,
                      size: 20,
                      color: AppColors.success600,
                    ),
              tooltip: 'Mark Payment Done',
              padding: const EdgeInsets.all(8),
            ),
          ),
        
        // View Details Button
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: widget.onViewDetails,
            icon: Icon(
              Icons.remove_red_eye_outlined,
              size: 20,
              color: AppColors.primary600,
            ),
            tooltip: 'View Details',
            padding: const EdgeInsets.all(8),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Edit Button
        Container(
          decoration: BoxDecoration(
            color: AppColors.warning50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: widget.onEdit,
            icon: Icon(
              Icons.edit_outlined,
              size: 20,
              color: AppColors.warning600,
            ),
            tooltip: 'Edit Status',
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }

  Widget _buildPackageInfo() {
    return Column(
      children: [
        InkWell(
          onTap: () => _showPackageChangeDialog(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary200,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Package Assigned',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.customer.packageDisplayName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.customer.packagePriceDisplay,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.primary600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.customer.hasAmountDue) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Due: ${widget.customer.amountDueDisplay}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary600,
                      size: 16,
                    ),
                  ],
                ),
                if (widget.customer.hasAmountDue) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.error600,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Payment pending for ${widget.customer.amountDueDisplay}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error600,
                              fontWeight: FontWeight.w500,
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
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildStatusSection(bool isSmallScreen) {
    return Column(
      children: [
        Row(
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(widget.customer.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.customer.status.replaceAll('_', ' '),
                style: AppTextStyles.bodySmall.copyWith(
                  color: _getStatusColor(widget.customer.status),
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 11 : 12,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Payment Status Badge
            if (widget.customer.paymentStatus.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getPaymentStatusColor(widget.customer.paymentStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _getPaymentStatusColor(widget.customer.paymentStatus),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.customer.paymentStatus.replaceAll('_', ' '),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _getPaymentStatusColor(widget.customer.paymentStatus),
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 11 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            
            const Spacer(),
            
            // Created At
            Text(
              _formatDate(widget.customer.createdAtDate),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: isSmallScreen ? 11 : 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildAdditionalInfo(bool isSmallScreen) {
    return Column(
      children: [
        Row(
          children: [
            // Location
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${widget.customer.district}, ${widget.customer.state}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Mobile
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.customer.mobile,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildIssueSection(bool isSmallScreen) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.neutral200,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Issue',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 11 : 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.customer.issue,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: isSmallScreen ? 13 : 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning600;
      case 'approved':
        return AppColors.success600;
      case 'rejected':
        return AppColors.error600;
      case 'under_review':
        return AppColors.info600;
      case 'full payment done':
        return AppColors.success600;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'pending':
        return AppColors.warning600;
      case 'full payment done':
        return AppColors.success600;
      case 'partial payment':
        return AppColors.info600;
      case 'overdue':
        return AppColors.error600;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  bool _isPaymentDone() {
    return widget.customer.paymentStatus.toLowerCase() == 'full payment done';
  }

  void _showPackageAssignmentDialog() {
    // Package assignment disabled for read-only access
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Package assignment is not available for your user role.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showPaymentConfirmation() {
    // Payment confirmation disabled for read-only access
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment processing is not available for your user role.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _processPaymentWithDetails(Map<String, dynamic> paymentData) async {
    // Check if package is assigned
    if (!widget.customer.hasPackage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please assign a package before processing payment'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final adminId = authProvider.user?.uid ?? 'unknown';
      final adminName = authProvider.user?.displayName ?? 'Admin';

      final result = await _transactionService.markPaymentDoneWithDetails(
        customerId: widget.customer.customerId,
        adminId: adminId,
        adminName: adminName,
        amount: paymentData['amount'],
        paymentDate: paymentData['paymentDate'],
        paymentMethod: paymentData['paymentMethod'],
      );

      if (mounted) {
        if (result['success'] == true) {
          final isPartialPayment = paymentData['amount'] < widget.customer.amountDue;
          final remainingAmount = widget.customer.amountDue - paymentData['amount'];
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isPartialPayment 
                              ? 'Partial Payment Processed Successfully!'
                              : 'Payment Processed Successfully!',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (isPartialPayment)
                          Text(
                            'Remaining amount: ₹${remainingAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        if (result['referrerName'] != null)
                          Text(
                            'Commission paid to ${result['referrerName']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success500,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );

          widget.onRefresh?.call();
        } else {
          final errorMessage = result['message'] ?? 'Unknown error';
          
          // Show different messages based on error type
          String displayMessage = errorMessage;
          Color backgroundColor = AppColors.error;
          
          if (errorMessage.contains('assign a package')) {
            displayMessage = 'Please assign a package to this customer first';
            backgroundColor = AppColors.warning;
          } else if (errorMessage.contains('payment amount')) {
            displayMessage = 'Payment amount calculation issue. Please check customer package assignment.';
            backgroundColor = AppColors.warning;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to process payment: $displayMessage'),
              backgroundColor: backgroundColor,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  void _showPackageChangeDialog() {
    // Package change disabled for read-only access
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Package modifications are not available for your user role.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
} 