import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive_utils.dart';
import '../widgets/sidebar.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isMobileSidebarOpen = false;

  void _toggleMobileSidebar() {
    setState(() {
      _isMobileSidebarOpen = !_isMobileSidebarOpen;
    });
  }

  void _closeMobileSidebar() {
    setState(() {
      _isMobileSidebarOpen = false;
    });
  }

  void _navigateToRoute(String route) {
    context.go(route);
    // Close mobile sidebar after navigation
    if (ResponsiveUtils.isMobile(context) && _isMobileSidebarOpen) {
      _closeMobileSidebar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: isMobile
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: _toggleMobileSidebar,
              ),
              title: Text(
                _getPageTitle(currentRoute),
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            )
          : null,
      body: Stack(
        children: [
          // Main content area
          Row(
            children: [
              // Desktop sidebar
              if (!isMobile)
                Sidebar(
                  currentRoute: currentRoute,
                  onNavigate: _navigateToRoute,
                ),
              
              // Main content
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(
                    isMobile ? 12 : (isTablet ? 20 : 24),
                  ),
                  child: widget.child,
                ),
              ),
            ],
          ),

          // Mobile sidebar overlay
          if (isMobile && _isMobileSidebarOpen)
            Stack(
              children: [
                // Dark backdrop
                GestureDetector(
                  onTap: _closeMobileSidebar,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                
                // Sidebar
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    elevation: 16,
                    child: Sidebar(
                      currentRoute: currentRoute,
                      onNavigate: _navigateToRoute,
                      onClose: _closeMobileSidebar,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _getPageTitle(String route) {
    switch (route) {
      case '/dashboard':
        return 'Dashboard';
      case '/customers':
        return 'Customers';
      case '/leads':
        return 'Leads';
      case '/transactions':
        return 'Transactions';
      case '/referrals':
        return 'Referrals';
      case '/visits':
        return 'Visits';
      case '/profile':
        return 'Profile';
      default:
        return 'Partner Portal';
    }
  }
} 