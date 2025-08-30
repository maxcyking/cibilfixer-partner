import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../widgets/document_viewer.dart';
import '../../../models/customer_model.dart';
import 'package:intl/intl.dart';

class CustomerDetailsView extends StatelessWidget {
  final Customer customer;

  const CustomerDetailsView({
    super.key,
    required this.customer,
  });

  static Future<void> show(BuildContext context, Customer customer) async {
    // Add haptic feedback
    HapticFeedback.lightImpact();
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveUtils.isMobile(context);

    if (isMobile) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        useSafeArea: true,
        builder: (context) => CustomerDetailsBottomSheet(customer: customer),
      );
    } else {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CustomerDetailsDialog(customer: customer),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class CustomerDetailsBottomSheet extends StatefulWidget {
  final Customer customer;

  const CustomerDetailsBottomSheet({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailsBottomSheet> createState() => _CustomerDetailsBottomSheetState();
}

class _CustomerDetailsBottomSheetState extends State<CustomerDetailsBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              height: ResponsiveUtils.getBottomSheetHeight(context),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 24, tablet: 28, desktop: 32)),
                  topRight: Radius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 24, tablet: 28, desktop: 32)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Enhanced Handle Bar
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 14, desktop: 16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: ResponsiveUtils.getSpacing(context, mobile: 40, tablet: 45, desktop: 50),
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.neutral300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 10, desktop: 12)),
                        Text(
                          'Customer Details',
                          style: ResponsiveUtils.getResponsiveTextStyle(
                            context,
                            AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Enhanced Header
                  Container(
                    padding: ResponsiveUtils.getPadding(context, mobile: 20, tablet: 24, desktop: 28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary50,
                          Colors.white,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.neutral100,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Profile and Customer Info Row
                        Row(
                          children: [
                            // Enhanced Avatar
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary200.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: ResponsiveUtils.getAvatarRadius(context, mobile: 24, tablet: 26, desktop: 28),
                                backgroundColor: AppColors.primary100,
                                child: CircleAvatar(
                                  radius: ResponsiveUtils.getAvatarRadius(context, mobile: 22, tablet: 24, desktop: 26),
                                  backgroundColor: AppColors.primary50,
                                  child: Text(
                                    widget.customer.fullName.isNotEmpty 
                                        ? widget.customer.fullName[0].toUpperCase()
                                        : 'C',
                                    style: ResponsiveUtils.getResponsiveTextStyle(
                                      context,
                                      AppTextStyles.titleLarge.copyWith(
                                        color: AppColors.primary700,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 18, desktop: 20)),
                            
                            // Enhanced Customer Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.customer.fullName,
                                    style: ResponsiveUtils.getResponsiveTextStyle(
                                      context,
                                      AppTextStyles.headlineSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 4, tablet: 5, desktop: 6)),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 10, desktop: 12),
                                      vertical: ResponsiveUtils.getSpacing(context, mobile: 4, tablet: 5, desktop: 6),
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary100,
                                      borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 6, tablet: 7, desktop: 8)),
                                    ),
                                    child: Text(
                                      widget.customer.customerId,
                                      style: ResponsiveUtils.getResponsiveTextStyle(
                                        context,
                                        AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.primary700,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 18, desktop: 20)),
                        
                        // Enhanced Status Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 14, desktop: 16),
                            vertical: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 9, desktop: 10),
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.customer.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 20, tablet: 22, desktop: 24)),
                            border: Border.all(
                              color: _getStatusColor(widget.customer.status).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(widget.customer.status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 6, tablet: 7, desktop: 8)),
                              Text(
                                _getStatusDisplayText(widget.customer.status),
                                style: ResponsiveUtils.getResponsiveTextStyle(
                                  context,
                                  AppTextStyles.bodySmall.copyWith(
                                    color: _getStatusColor(widget.customer.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Enhanced Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: ResponsiveUtils.getPadding(context, mobile: 20, tablet: 24, desktop: 28),
                      physics: const BouncingScrollPhysics(),
                      child: CustomerDetailsContent(customer: widget.customer),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    final normalizedStatus = status.toLowerCase();
    switch (normalizedStatus) {
      case 'completed':
        return AppColors.success500;
      case 'full payment done':
        return AppColors.success600;
      case 'lost':
        return AppColors.error500;
      case 'pending for payment confermation':
      case 'pending for payment confirmation':
      case 'pending_payment_confirmation':
      case 'pending with bank for payment':
      case 'pending with customer for full payment':
        return AppColors.warning500;
      case 'in processing with bank/cic':
      case 'in processing with bank/cic 2 step':
        return AppColors.info500;
      default:
        return AppColors.neutral500;
    }
  }

  String _getStatusDisplayText(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }
}

class CustomerDetailsDialog extends StatefulWidget {
  final Customer customer;

  const CustomerDetailsDialog({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailsDialog> createState() => _CustomerDetailsDialogState();
}

class _CustomerDetailsDialogState extends State<CustomerDetailsDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
              child: Container(
                constraints: ResponsiveUtils.getDialogConstraints(context),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 16, tablet: 20, desktop: 24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Enhanced Header with Gradient
                    Container(
                      padding: ResponsiveUtils.getPadding(context, mobile: 24, tablet: 28, desktop: 32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary50,
                            Colors.white,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 16, tablet: 20, desktop: 24)),
                          topRight: Radius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 16, tablet: 20, desktop: 24)),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.neutral100,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Enhanced Avatar with Shadow
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary200.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: ResponsiveUtils.getAvatarRadius(context, mobile: 28, tablet: 30, desktop: 32),
                              backgroundColor: AppColors.primary100,
                              child: CircleAvatar(
                                radius: ResponsiveUtils.getAvatarRadius(context, mobile: 26, tablet: 28, desktop: 30),
                                backgroundColor: AppColors.primary50,
                                child: Text(
                                  widget.customer.fullName.isNotEmpty 
                                      ? widget.customer.fullName[0].toUpperCase()
                                      : 'C',
                                  style: ResponsiveUtils.getResponsiveTextStyle(
                                    context,
                                    AppTextStyles.headlineSmall.copyWith(
                                      color: AppColors.primary700,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 20, tablet: 22, desktop: 24)),
                          
                          // Enhanced Customer Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.customer.fullName,
                                  style: ResponsiveUtils.getResponsiveTextStyle(
                                    context,
                                    AppTextStyles.headlineMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 6, tablet: 7, desktop: 8)),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveUtils.getSpacing(context, mobile: 10, tablet: 12, desktop: 14),
                                    vertical: ResponsiveUtils.getSpacing(context, mobile: 6, tablet: 7, desktop: 8),
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary100,
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 8, tablet: 9, desktop: 10)),
                                  ),
                                  child: Text(
                                    widget.customer.customerId,
                                    style: ResponsiveUtils.getResponsiveTextStyle(
                                      context,
                                      AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.primary700,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Enhanced Status Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 18, desktop: 20),
                              vertical: ResponsiveUtils.getSpacing(context, mobile: 10, tablet: 11, desktop: 12),
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(widget.customer.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 24, tablet: 26, desktop: 28)),
                              border: Border.all(
                                color: _getStatusColor(widget.customer.status).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(widget.customer.status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 9, desktop: 10)),
                                Text(
                                  _getStatusDisplayText(widget.customer.status),
                                  style: ResponsiveUtils.getResponsiveTextStyle(
                                    context,
                                    AppTextStyles.bodyMedium.copyWith(
                                      color: _getStatusColor(widget.customer.status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 18, desktop: 20)),
                          
                          // Enhanced Close Button
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.neutral100,
                              borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 8, tablet: 9, desktop: 10)),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 8, tablet: 9, desktop: 10)),
                                child: Padding(
                                  padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 9, desktop: 10)),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: ResponsiveUtils.getIconSize(context, 20),
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                    ),
                    
                    // Enhanced Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: ResponsiveUtils.getPadding(context, mobile: 24, tablet: 28, desktop: 32),
                        physics: const BouncingScrollPhysics(),
                        child: CustomerDetailsContent(customer: widget.customer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    final normalizedStatus = status.toLowerCase();
    switch (normalizedStatus) {
      case 'completed':
        return AppColors.success500;
      case 'full payment done':
        return AppColors.success600;
      case 'lost':
        return AppColors.error500;
      case 'pending for payment confermation':
      case 'pending for payment confirmation':
      case 'pending_payment_confirmation':
      case 'pending with bank for payment':
      case 'pending with customer for full payment':
        return AppColors.warning500;
      case 'in processing with bank/cic':
      case 'in processing with bank/cic 2 step':
        return AppColors.info500;
      default:
        return AppColors.neutral500;
    }
  }

  String _getStatusDisplayText(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }
}

class CustomerDetailsContent extends StatelessWidget {
  final Customer customer;

  const CustomerDetailsContent({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced Quick Stats Section
        Container(
          padding: ResponsiveUtils.getPadding(context, mobile: 20, tablet: 22, desktop: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary50,
                AppColors.primary100.withOpacity(0.3),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 16, tablet: 18, desktop: 20)),
            border: Border.all(
              color: AppColors.primary200.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary100.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 9, desktop: 10)),
                    decoration: BoxDecoration(
                      color: AppColors.primary100,
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 8, tablet: 9, desktop: 10)),
                    ),
                    child: Icon(
                      Icons.insights_rounded,
                      size: ResponsiveUtils.getIconSize(context, 18),
                      color: AppColors.primary600,
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 14, desktop: 16)),
                  Expanded(
                    child: Text(
                      'Quick Overview',
                      style: ResponsiveUtils.getResponsiveTextStyle(
                        context,
                        AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 18, desktop: 20)),
              
              // Quick Stats Grid
              ResponsiveUtils.isMobile(context) 
                  ? Column(
                      children: [
                        _buildQuickStat(
                          context,
                          icon: Icons.person_outline_rounded,
                          label: 'Customer Since',
                          value: _formatDate(customer.createdAtDate),
                          isInRow: false,
                        ),
                        SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 18, desktop: 20)),
                        _buildQuickStat(
                          context,
                          icon: Icons.phone_outlined,
                          label: 'Contact',
                          value: customer.mobile,
                          isInRow: false,
                        ),
                        SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 18, desktop: 20)),
                        _buildQuickStat(
                          context,
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: '${customer.district}, ${customer.state}',
                          isInRow: false,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _buildQuickStat(
                          context,
                          icon: Icons.person_outline_rounded,
                          label: 'Customer Since',
                          value: _formatDate(customer.createdAtDate),
                          isInRow: true,
                        ),
                        SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 20, tablet: 22, desktop: 24)),
                        _buildQuickStat(
                          context,
                          icon: Icons.phone_outlined,
                          label: 'Contact',
                          value: customer.mobile,
                          isInRow: true,
                        ),
                        SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 20, tablet: 22, desktop: 24)),
                        _buildQuickStat(
                          context,
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: '${customer.district}, ${customer.state}',
                          isInRow: true,
                        ),
                      ],
                    ),
            ],
          ),
        ),
        
        SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 24, tablet: 26, desktop: 28)),
        
        // Personal Information Section
        _buildEnhancedSection(
          context,
          title: 'Personal Information',
          icon: Icons.person_outline_rounded,
          color: AppColors.info500,
          children: [
            _buildDetailRow(context, 'Full Name', customer.fullName),
            _buildDetailRow(context, 'Father\'s Name', customer.fatherName),
            _buildDetailRow(context, 'Gender', customer.gender),
            _buildDetailRow(context, 'Date of Birth', _formatDate(customer.dobDate)),
            _buildDetailRow(context, 'Mobile', customer.mobile),
            _buildDetailRow(context, 'Email', customer.email ?? 'N/A'),
          ],
        ),
        
        SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 24, tablet: 26, desktop: 28)),
        
        // Document Information Section
        _buildEnhancedSection(
          context,
          title: 'Document Information',
          icon: Icons.description_outlined,
          color: AppColors.warning500,
          children: [
            _buildDetailRow(context, 'Aadhar Number', customer.aadhar),
            _buildDetailRow(context, 'PAN Number', customer.pan),
            _buildDetailRow(context, 'Transaction ID', customer.transactionId),
          ],
        ),
        
        SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 24, tablet: 26, desktop: 28)),
        
        // Address Information Section
        _buildEnhancedSection(
          context,
          title: 'Address Information',
          icon: Icons.location_city_outlined,
          color: AppColors.success500,
          children: [
            _buildDetailRow(context, 'Address', customer.address),
            _buildDetailRow(context, 'Village', customer.village),
            _buildDetailRow(context, 'Tehsil/City', customer.tehsilCity),
            _buildDetailRow(context, 'District', customer.district),
            _buildDetailRow(context, 'State', customer.state),
            _buildDetailRow(context, 'PIN Code', customer.pin),
          ],
        ),
        
        SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 24, tablet: 26, desktop: 28)),
        
        // Credit Information Section
        _buildEnhancedSection(
          context,
          title: 'Credit Information',
          icon: Icons.credit_card_outlined,
          color: AppColors.error500,
          children: [
            _buildDetailRow(context, 'Issue', customer.issue),
            _buildDetailRow(context, 'Referral Code (Direct)', customer.referralCode.isEmpty ? 'N/A' : customer.referralCode),
            _buildDetailRow(context, 'Referral Code (Level 2)', customer.referralCode1.isEmpty ? 'N/A' : customer.referralCode1),
          ],
        ),
        
        SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 24, tablet: 26, desktop: 28)),
        
        // Account Information Section
        _buildEnhancedSection(
          context,
          title: 'Account Information',
          icon: Icons.account_circle_outlined,
          color: AppColors.primary500,
          children: [
            _buildDetailRow(context, 'Customer ID', customer.customerId),
            _buildDetailRow(context, 'User ID', customer.userId ?? 'N/A'),
            _buildDetailRow(context, 'Email Login', customer.email ?? 'N/A'),
          ],
        ),
        
        SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 24, tablet: 26, desktop: 28)),
        
        // Timeline Section
        _buildEnhancedSection(
          context,
          title: 'Timeline',
          icon: Icons.timeline_outlined,
          color: AppColors.neutral500,
          children: [
            _buildDetailRow(context, 'Account Created', _formatDateTime(customer.createdAtDate)),
            _buildDetailRow(context, 'Last Updated', _formatDateTime(customer.updatedAtDate)),
          ],
        ),
        
        // Documents Section
        if (customer.documents.isNotEmpty) ...[
          SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 24, tablet: 26, desktop: 28)),
          _buildEnhancedSection(
            context,
            title: 'Documents',
            icon: Icons.folder_outlined,
            color: AppColors.info500,
            children: [
              ...customer.documents.entries.map((entry) =>
                _buildDocumentRow(context, entry.key, entry.value.toString()),
              ),
            ],
          ),
        ],
        
        // Remarks Section
        if (customer.remark.isNotEmpty) ...[
          SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 24, tablet: 26, desktop: 28)),
          _buildEnhancedSection(
            context,
            title: 'Remarks',
            icon: Icons.note_outlined,
            color: AppColors.warning500,
            children: [],
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 14, desktop: 16)),
          Container(
            width: double.infinity,
            padding: ResponsiveUtils.getPadding(context, mobile: 16, tablet: 18, desktop: 20),
            decoration: BoxDecoration(
              color: AppColors.warning50,
              borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 12, tablet: 14, desktop: 16)),
              border: Border.all(
                color: AppColors.warning200,
                width: 1,
              ),
            ),
            child: Text(
              customer.remark,
              style: ResponsiveUtils.getResponsiveTextStyle(
                context,
                AppTextStyles.bodyMedium.copyWith(
                  height: 1.6,
                  color: AppColors.warning800,
                ),
              ),
            ),
          ),
        ],
        
        SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 24, tablet: 26, desktop: 28)),
      ],
    );
  }

  Widget _buildQuickStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isInRow = false,
  }) {
    final content = Container(
      padding: ResponsiveUtils.getPadding(context, mobile: 12, tablet: 14, desktop: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 10, tablet: 12, desktop: 14)),
        border: Border.all(
          color: AppColors.neutral200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 6, tablet: 7, desktop: 8)),
                decoration: BoxDecoration(
                  color: AppColors.primary100,
                  borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 6, tablet: 7, desktop: 8)),
                ),
                child: Icon(
                  icon,
                  size: ResponsiveUtils.getIconSize(context, 14),
                  color: AppColors.primary600,
                ),
              ),
              SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 9, desktop: 10)),
              Flexible(
                child: Text(
                  label,
                  style: ResponsiveUtils.getResponsiveTextStyle(
                    context,
                    AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 9, desktop: 10)),
          Text(
            value,
            style: ResponsiveUtils.getResponsiveTextStyle(
              context,
              AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    // Only use Expanded when inside a Row (desktop/tablet view)
    if (isInRow) {
      return Expanded(child: content);
    } else {
      return content;
    }
  }

  Widget _buildEnhancedSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 9, desktop: 10)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 8, tablet: 9, desktop: 10)),
              ),
              child: Icon(
                icon,
                size: ResponsiveUtils.getIconSize(context, 20),
                color: color,
              ),
            ),
            SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 14, desktop: 16)),
            Expanded(
              child: Text(
                title,
                style: ResponsiveUtils.getResponsiveTextStyle(
                  context,
                  AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 18, desktop: 20)),
        Container(
          padding: ResponsiveUtils.getPadding(context, mobile: 16, tablet: 18, desktop: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 12, tablet: 14, desktop: 16)),
            border: Border.all(
              color: AppColors.neutral200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 18, desktop: 20)),
      child: ResponsiveUtils.isMobile(context) 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ResponsiveUtils.getResponsiveTextStyle(
                    context,
                    AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 6, tablet: 7, desktop: 8)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 14, desktop: 16),
                    vertical: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 9, desktop: 10),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 8, tablet: 9, desktop: 10)),
                    border: Border.all(
                      color: AppColors.neutral200,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    value.isEmpty ? 'N/A' : value,
                    style: ResponsiveUtils.getResponsiveTextStyle(
                      context,
                      AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: ResponsiveUtils.getSpacing(context, mobile: 140, tablet: 150, desktop: 160),
                  child: Text(
                    label,
                    style: ResponsiveUtils.getResponsiveTextStyle(
                      context,
                      AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 18, desktop: 20)),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 14, desktop: 16),
                      vertical: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 9, desktop: 10),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 8, tablet: 9, desktop: 10)),
                      border: Border.all(
                        color: AppColors.neutral200,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      value.isEmpty ? 'N/A' : value,
                      style: ResponsiveUtils.getResponsiveTextStyle(
                        context,
                        AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDocumentRow(BuildContext context, String documentType, String documentUrl) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 18, desktop: 20)),
      child: Container(
        padding: ResponsiveUtils.getPadding(context, mobile: 16, tablet: 18, desktop: 20),
        decoration: BoxDecoration(
          color: AppColors.neutral50,
          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 12, tablet: 14, desktop: 16)),
          border: Border.all(
            color: AppColors.neutral200,
            width: 1,
          ),
        ),
        child: ResponsiveUtils.isMobile(context)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 9, desktop: 10)),
                        decoration: BoxDecoration(
                          color: AppColors.info100,
                          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 8, tablet: 9, desktop: 10)),
                        ),
                        child: Icon(
                          _getDocumentIcon(documentUrl),
                          size: ResponsiveUtils.getIconSize(context, 18),
                          color: AppColors.info600,
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 14, desktop: 16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              documentType.toUpperCase(),
                              style: ResponsiveUtils.getResponsiveTextStyle(
                                context,
                                AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 2, tablet: 3, desktop: 4)),
                            Text(
                              'Document Available',
                              style: ResponsiveUtils.getResponsiveTextStyle(
                                context,
                                AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 14, desktop: 16)),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.info50, AppColors.info100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 8, tablet: 9, desktop: 10)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            DocumentViewer.show(
                              context,
                              documentUrl: documentUrl,
                              documentName: '${documentType.toUpperCase()} Document',
                              documentType: documentType,
                            );
                          },
                          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 8, tablet: 9, desktop: 10)),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 18, desktop: 20),
                              vertical: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 14, desktop: 16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.visibility_rounded,
                                  size: ResponsiveUtils.getIconSize(context, 18),
                                  color: AppColors.info600,
                                ),
                                SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 9, desktop: 10)),
                                Text(
                                  'View Document',
                                  style: ResponsiveUtils.getResponsiveTextStyle(
                                    context,
                                    AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.info600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 10, tablet: 11, desktop: 12)),
                    decoration: BoxDecoration(
                      color: AppColors.info100,
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 10, tablet: 11, desktop: 12)),
                    ),
                    child: Icon(
                      _getDocumentIcon(documentUrl),
                      size: ResponsiveUtils.getIconSize(context, 20),
                      color: AppColors.info600,
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 18, desktop: 20)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          documentType.toUpperCase(),
                          style: ResponsiveUtils.getResponsiveTextStyle(
                            context,
                            AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 2, tablet: 3, desktop: 4)),
                        Text(
                          'Document Available',
                          style: ResponsiveUtils.getResponsiveTextStyle(
                            context,
                            AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.info50, AppColors.info100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 8, tablet: 9, desktop: 10)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          DocumentViewer.show(
                            context,
                            documentUrl: documentUrl,
                            documentName: '${documentType.toUpperCase()} Document',
                            documentType: documentType,
                          );
                        },
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, mobile: 8, tablet: 9, desktop: 10)),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 18, desktop: 20),
                            vertical: ResponsiveUtils.getSpacing(context, mobile: 10, tablet: 11, desktop: 12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility_rounded,
                                size: ResponsiveUtils.getIconSize(context, 18),
                                color: AppColors.info600,
                              ),
                              SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 9, desktop: 10)),
                              Text(
                                'View',
                                style: ResponsiveUtils.getResponsiveTextStyle(
                                  context,
                                  AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.info600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  IconData _getDocumentIcon(String documentUrl) {
    final extension = documentUrl.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
      return Icons.image_rounded;
    } else if (extension == 'pdf') {
      return Icons.picture_as_pdf_rounded;
    } else {
      return Icons.description_rounded;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }
} 