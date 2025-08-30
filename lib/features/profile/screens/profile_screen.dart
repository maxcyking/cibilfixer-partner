import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../../services/kyc_service.dart';
import '../widgets/kyc_status_card.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/referral_section.dart';
import '../screens/kyc_application_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final KycService _kycService = KycService();
  bool _isLoading = true;
  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? '';
    
    try {
      // Get KYC progress from database users collection
      final kycProgress = authProvider.userData?['kycProgress'] ?? 0;
      final kycStatus = authProvider.userData?['kycStatus'] ?? 'pending';

      // Create user model with real data from database
      _userModel = UserModel(
        uid: userId,
        email: authProvider.user?.email ?? '',
        fullName: authProvider.userData?['fullName'] ?? 'User',
        mobile: authProvider.userData?['mobile'] ?? '+91 9876543210',
        role: authProvider.userData?['role'] ?? 'partner',
        status: 'active',
        kycStatus: kycStatus,
        myReferralCode: authProvider.userData?['myReferralCode'],
        referredBy: authProvider.userData?['referredBy'],
        isActive: true,
        earnings: authProvider.userData?['earnings'] ?? 0,
        walletAmount: authProvider.userData?['walletAmount']?.toDouble() ?? 0.0,
        referrals: authProvider.userData?['referrals'] ?? 0,
        kycProgress:
            kycProgress, // Real progress from database users collection
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user profile: $e');
      // Fallback to default data in case of error
      _userModel = UserModel(
        uid: userId,
        email: authProvider.user?.email ?? '',
        fullName: authProvider.userData?['fullName'] ?? 'User',
        mobile: authProvider.userData?['mobile'] ?? '+91 9876543210',
        role: authProvider.userData?['role'] ?? 'partner',
        status: 'active',
        kycStatus: authProvider.userData?['kycStatus'] ?? 'pending',
        myReferralCode: authProvider.userData?['myReferralCode'],
        referredBy: authProvider.userData?['referredBy'],
        isActive: true,
        earnings: authProvider.userData?['earnings'] ?? 0,
        walletAmount: authProvider.userData?['walletAmount']?.toDouble() ?? 0.0,
        referrals: authProvider.userData?['referrals'] ?? 0,
        kycProgress: authProvider.userData?['kycProgress'] ?? 0,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Profile',
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshProfile,
            icon: Icon(Icons.refresh, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildProfileContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_userModel == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error500),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.error600,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(text: 'Retry', onPressed: _loadUserProfile),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final horizontalPadding = isMobile ? 12.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          _buildProfileHeader(),
          
          const SizedBox(height: 24),
          
          // Personal Information
          ProfileInfoCard(user: _userModel!),
          
          const SizedBox(height: 24),
          
          // KYC Status Section - Only show if KYC is not approved or complete
          if (_userModel!.kycStatus.toLowerCase() != 'approved' && 
              _userModel!.kycStatus.toLowerCase() != 'complete') ...[
            KycStatusCard(user: _userModel!, onKycAction: _handleKycAction),
          const SizedBox(height: 24),
          ],
          
          // Referral Section
          ReferralSection(
            user: _userModel!,
            onReferralUpdated: _loadUserProfile,
          ),
          
          const SizedBox(height: 24),
          
          // Account Actions
          _buildAccountActions(),
          
          const SizedBox(height: 24),
          
          // Danger Zone
          _buildDangerZone(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final cardPadding = isMobile ? 16.0 : 24.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.primary100.withOpacity(0.3),
            AppColors.neutral50,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Enhanced Section Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: isMobile ? 12 : 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary500,
                  AppColors.primary600,
                  AppColors.primary700,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary500.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: isMobile ? 18 : 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Information',
                        style: (isMobile ? AppTextStyles.titleLarge : AppTextStyles.headlineMedium).copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Manage your account details',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
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
                          color: _userModel!.isActive ? Colors.greenAccent : Colors.redAccent,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: (_userModel!.isActive ? Colors.greenAccent : Colors.redAccent).withOpacity(0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _userModel!.isActive ? 'ACTIVE' : 'INACTIVE',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Profile Content
          Row(
        children: [
          // Profile Picture
          Stack(
            children: [
              CircleAvatar(
                    radius: isMobile ? 32 : 40,
                backgroundColor: AppColors.primary100,
                child: Text(
                  _userModel!.fullName.isNotEmpty 
                      ? _userModel!.fullName[0].toUpperCase()
                      : 'U',
                      style: (isMobile
                              ? AppTextStyles.headlineMedium
                              : AppTextStyles.headlineLarge)
                          .copyWith(
                    color: AppColors.primary600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt,
                        size: isMobile ? 14 : 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          
              SizedBox(width: isMobile ? 12 : 20),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userModel!.fullName,
                      style: (isMobile
                              ? AppTextStyles.titleLarge
                              : AppTextStyles.headlineMedium)
                          .copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: isMobile ? 2 : 4),
                    Text(
                      _userModel!.email,
                      style: (isMobile
                              ? AppTextStyles.bodySmall
                              : AppTextStyles.bodyMedium)
                          .copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
              ],
            ),
          ),
          
          // Edit Button
          IconButton(
            onPressed: _editProfile,
            icon: Icon(
              Icons.edit_outlined,
              color: AppColors.primary600,
                  size: isMobile ? 20 : 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.all(isMobile ? 8 : 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary200,
                    width: 1,
                  ),
                ),
                child: Text(
                  _userModel!.role.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _userModel!.isActive ? AppColors.success100 : AppColors.error100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _userModel!.isActive ? AppColors.success200 : AppColors.error200,
                    width: 1,
                  ),
                ),
                child: Text(
                  _userModel!.isActive ? 'Active' : 'Inactive',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _userModel!.isActive ? AppColors.success700 : AppColors.error700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Actions',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildActionTile(
            icon: Icons.security,
            title: 'Security Settings',
            subtitle: 'Manage password and security preferences',
            onTap: () => _showSecuritySettings(),
          ),
          
          _buildActionTile(
            icon: Icons.notifications_outlined,
            title: 'Notification Preferences',
            subtitle: 'Control your notification settings',
            onTap: () => _showNotificationSettings(),
          ),
          
          _buildActionTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help or contact support',
            onTap: () => _showHelpSupport(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_outlined, color: AppColors.error500, size: 20),
              const SizedBox(width: 8),
              Text(
                'Danger Zone',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.error600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          OutlinedButton.icon(
            onPressed: _deactivateAccount,
            icon: Icon(Icons.block, size: 16, color: AppColors.error600),
            label: Text(
              'Deactivate Account',
              style: TextStyle(color: AppColors.error600),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.error600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleKycAction() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => KycApplicationScreen(
          user: _userModel!,
          isUpdate: _userModel!.kycProgress > 0,
        ),
      ),
    ).then((_) {
      // Refresh profile when returning from KYC application
      _loadUserProfile();
    });
  }

  void _editProfile() {
    // TODO: Implement edit profile functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit profile functionality coming soon!'),
        backgroundColor: AppColors.info500,
      ),
    );
  }

  void _showSecuritySettings() {
    // TODO: Implement security settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Security settings coming soon!'),
        backgroundColor: AppColors.info500,
      ),
    );
  }

  void _showNotificationSettings() {
    // TODO: Implement notification settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification settings coming soon!'),
        backgroundColor: AppColors.info500,
      ),
    );
  }

  void _showHelpSupport() {
    // TODO: Implement help & support
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Help & support coming soon!'),
        backgroundColor: AppColors.info500,
      ),
    );
  }

  void _deactivateAccount() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
                Icon(Icons.warning, color: AppColors.error500),
            const SizedBox(width: 8),
            Text('Deactivate Account'),
          ],
        ),
        content: Text(
          'Are you sure you want to deactivate your account? This action cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deactivation
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error600,
            ),
            child: Text(
              'Deactivate',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshProfile() {
    _loadUserProfile();
  }
} 
