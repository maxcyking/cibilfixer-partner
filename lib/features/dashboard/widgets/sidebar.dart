import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../providers/auth_provider.dart' as app_auth;

class Sidebar extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;
  final VoidCallback? onClose;

  const Sidebar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isMobile = ResponsiveUtils.isMobile(context);
    
    if (isMobile) {
      return _buildMobileSidebar(context, user);
    } else {
      return _buildDesktopSidebar(context, user);
    }
  }

  Widget _buildMobileSidebar(BuildContext context, User? user) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      constraints: const BoxConstraints(maxWidth: 300),
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Partner Portal',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: Consumer<app_auth.AuthProvider>(
              builder: (context, authProvider, child) {
                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildNavItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      route: '/dashboard',
                      isSelected: currentRoute == '/dashboard',
                      onTap: () {
                        onNavigate('/dashboard');
                        onClose?.call();
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.people,
                      title: 'Customers',
                      route: '/customers',
                      isSelected: currentRoute == '/customers',
                      onTap: () {
                        onNavigate('/customers');
                        onClose?.call();
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.trending_up,
                      title: 'Leads',
                      route: '/leads',
                      isSelected: currentRoute == '/leads',
                      onTap: () {
                        onNavigate('/leads');
                        onClose?.call();
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.account_balance_wallet,
                      title: 'Transactions',
                      route: '/transactions',
                      isSelected: currentRoute == '/transactions',
                      onTap: () {
                        onNavigate('/transactions');
                        onClose?.call();
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.group_add,
                      title: 'Referrals',
                      route: '/referrals',
                      isSelected: currentRoute == '/referrals',
                      onTap: () {
                        onNavigate('/referrals');
                        onClose?.call();
                      },
                    ),
                    // Show visits only for sales representatives
                    if (authProvider.isSalesRepresentative)
                      _buildNavItem(
                        icon: Icons.location_on,
                        title: 'Visits',
                        route: '/visits',
                        isSelected: currentRoute == '/visits',
                        onTap: () {
                          onNavigate('/visits');
                          onClose?.call();
                        },
                      ),
                    _buildNavItem(
                      icon: Icons.person,
                      title: 'Profile',
                      route: '/profile',
                      isSelected: currentRoute == '/profile',
                      onTap: () {
                        onNavigate('/profile');
                        onClose?.call();
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Logout Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, User? user) {
    return Container(
      width: 250,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo/Brand Section
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Partner Portal',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: Consumer<app_auth.AuthProvider>(
              builder: (context, authProvider, child) {
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildNavItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      route: '/dashboard',
                      isSelected: currentRoute == '/dashboard',
                      onTap: () => onNavigate('/dashboard'),
                    ),
                    _buildNavItem(
                      icon: Icons.people,
                      title: 'Customers',
                      route: '/customers',
                      isSelected: currentRoute == '/customers',
                      onTap: () => onNavigate('/customers'),
                    ),
                    _buildNavItem(
                      icon: Icons.trending_up,
                      title: 'Leads',
                      route: '/leads',
                      isSelected: currentRoute == '/leads',
                      onTap: () => onNavigate('/leads'),
                    ),
                    _buildNavItem(
                      icon: Icons.account_balance_wallet,
                      title: 'Transactions',
                      route: '/transactions',
                      isSelected: currentRoute == '/transactions',
                      onTap: () => onNavigate('/transactions'),
                    ),
                    _buildNavItem(
                      icon: Icons.group_add,
                      title: 'Referrals',
                      route: '/referrals',
                      isSelected: currentRoute == '/referrals',
                      onTap: () => onNavigate('/referrals'),
                    ),
                    // Show visits only for sales representatives
                    if (authProvider.isSalesRepresentative)
                      _buildNavItem(
                        icon: Icons.location_on,
                        title: 'Visits',
                        route: '/visits',
                        isSelected: currentRoute == '/visits',
                        onTap: () => onNavigate('/visits'),
                      ),
                    _buildNavItem(
                      icon: Icons.person,
                      title: 'Profile',
                      route: '/profile',
                      isSelected: currentRoute == '/profile',
                      onTap: () => onNavigate('/profile'),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // User Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.email ?? 'User',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Partner',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required String route,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? AppColors.primary100 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.primary600 : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected ? AppColors.primary600 : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 