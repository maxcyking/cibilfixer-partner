import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

class KycGuard extends StatelessWidget {
  final Widget child;
  final bool showFullScreen;

  const KycGuard({
    super.key,
    required this.child,
    this.showFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // If KYC is completed or user is not authenticated, show the child
        if (!authProvider.requiresKyc) {
          return child;
        }

        // If KYC is required, show the KYC completion screen
        if (showFullScreen) {
          return const KycCompletionScreen();
        } else {
          // Show overlay for partial restrictions
          return Stack(
            children: [
              child,
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 400,
                      maxHeight: 600,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user,
                              size: 48,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'KYC Verification Required',
                              style: AppTextStyles.headlineMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please complete your KYC verification to access this feature.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  context.go('/profile');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Complete KYC'),
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
          );
        }
      },
    );
  }
}

class KycCompletionScreen extends StatelessWidget {
  const KycCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Responsive calculations
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;
    
    final horizontalPadding = isMobile ? 16.0 : isTablet ? 32.0 : 64.0;
    final verticalPadding = isMobile ? 16.0 : 24.0;
    final maxWidth = isMobile ? double.infinity : isTablet ? 500.0 : 600.0;
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: screenHeight,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Add some top spacing for better centering
                      SizedBox(height: isMobile ? 20 : 40),
                      
                      // Header
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(isMobile ? 20 : 24),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.verified_user,
                            size: isMobile ? 60 : 80,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 24 : 32),
                      
                      Text(
                        'KYC Verification Required',
                        style: (isMobile ? AppTextStyles.headlineMedium : AppTextStyles.headlineLarge).copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      
                      Text(
                        'To ensure security and compliance, please complete your KYC (Know Your Customer) verification.',
                        style: (isMobile ? AppTextStyles.bodyMedium : AppTextStyles.bodyLarge).copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isMobile ? 20 : 24),
                      
                      // KYC Status
                      Container(
                        padding: EdgeInsets.all(isMobile ? 12 : 16),
                        decoration: BoxDecoration(
                          color: _getStatusColor(authProvider.kycStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(authProvider.kycStatus).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getStatusIcon(authProvider.kycStatus),
                              color: _getStatusColor(authProvider.kycStatus),
                              size: isMobile ? 20 : 24,
                            ),
                            SizedBox(width: isMobile ? 8 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Status',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    _getStatusText(authProvider.kycStatus),
                                    style: (isMobile ? AppTextStyles.bodySmall : AppTextStyles.bodyMedium).copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(authProvider.kycStatus),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isMobile ? 20 : 32),
                      
                      // Restricted Features
                      _buildRestrictedFeatures(isMobile),
                      SizedBox(height: isMobile ? 20 : 32),
                      
                      // Complete KYC Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.go('/profile');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Complete KYC Verification',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      
                      // Logout Button
                      Center(
                        child: TextButton(
                          onPressed: () {
                            authProvider.signOut();
                            context.go('/login');
                          },
                          child: Text(
                            'Logout',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      
                      // Add bottom spacing
                      SizedBox(height: isMobile ? 20 : 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRestrictedFeatures(bool isMobile) {
    final restrictedFeatures = [
      'Generate new leads',
      'Add visits',
      'Share referral links',
      'Copy referral codes',
      'Full access to all features',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Restricted Features:',
          style: (isMobile ? AppTextStyles.bodySmall : AppTextStyles.bodyMedium).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        ...restrictedFeatures.map((feature) => Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 6 : 8),
          child: Row(
            children: [
              Icon(
                Icons.block,
                size: isMobile ? 14 : 16,
                color: Colors.red,
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Expanded(
                child: Text(
                  feature,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return 'KYC Completed';
      case 'approved':
        return 'KYC Approved';
      case 'pending':
        return 'KYC Pending Review';
      case 'rejected':
        return 'KYC Rejected';
      default:
        return 'KYC Not Started';
    }
  }
} 