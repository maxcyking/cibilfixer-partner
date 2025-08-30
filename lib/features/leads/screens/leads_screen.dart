import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../widgets/badges/app_badge.dart';
import '../../../models/lead_model.dart';
import '../../../services/leads_service.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/lead_details_bottom_sheet.dart';
import '../widgets/lead_filter_bar.dart';
import '../widgets/simple_lead_form_dialog.dart';
import 'lead_generation_screen.dart';
import 'package:intl/intl.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen>
    with TickerProviderStateMixin {
  final LeadsService _leadsService = LeadsService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Lead> _leads = [];
  List<Lead> _filteredLeads = [];
  String? _selectedStatus;
  String? _selectedDistrict;
  String? _selectedState;
  bool _isLoading = true;
  Map<String, int> _stats = {};
  
  // Animation controllers
  late AnimationController _scrollAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _statsAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isHeaderCollapsed = false;
  static const double _scrollThreshold = 120.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupScrollListener();
    _loadLeads();
    _loadStats();
  }

  void _setupAnimations() {
    _scrollAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scrollAnimationController,
      curve: Curves.easeInOut,
    ));

    _statsAnimation = Tween<double>(
      begin: 1.0,
      end: 0.4,
    ).animate(CurvedAnimation(
      parent: _scrollAnimationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final isScrolled = _scrollController.offset > _scrollThreshold;
      if (isScrolled != _isHeaderCollapsed) {
        setState(() {
          _isHeaderCollapsed = isScrolled;
        });
        
        if (_isHeaderCollapsed) {
          _scrollAnimationController.forward();
        } else {
          _scrollAnimationController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _scrollAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadLeads() async {
    setState(() => _isLoading = true);
    
    try {
      // Get the logged-in user's referral code
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userReferralCode = authProvider.userData?['myReferralCode'];
      
      print('📋 Loading leads for user referral code: $userReferralCode');
      
      if (userReferralCode == null || userReferralCode.isEmpty) {
        print('⚠️ No referral code found for user, showing empty leads list');
        if (mounted) {
          setState(() {
            _leads = [];
            _filteredLeads = [];
            _isLoading = false;
          });
        }
        return;
      }
      
      final leads = await _leadsService.getLeads(
        statusFilter: _selectedStatus,
        searchQuery: _searchController.text,
        referralCode: userReferralCode,
      );
      
      print('📋 Loaded ${leads.length} user-specific leads');
      
      if (mounted) {
        setState(() {
          _leads = leads;
          _filteredLeads = _filterLeads(leads);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leads: $e')),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      // Get the logged-in user's referral code
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userReferralCode = authProvider.userData?['myReferralCode'];
      
      print('📊 Loading stats for user referral code: $userReferralCode');
      
      if (userReferralCode == null || userReferralCode.isEmpty) {
        print('⚠️ No referral code found for user, showing empty stats');
        if (mounted) {
          setState(() => _stats = {
            'total': 0,
            'NEW': 0,
            'CONTACTED': 0,
            'INTERESTED': 0,
            'NOT INTERESTED': 0,
            'NO RESPONSE': 0,
            'CONVERTED TO CUSTOMER': 0,
          });
        }
        return;
      }
      
      final stats = await _leadsService.getLeadStats(referralCode: userReferralCode);
      print('📊 Loaded user-specific stats: $stats');
      
      if (mounted) {
        setState(() => _stats = stats);
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  List<Lead> _filterLeads(List<Lead> leads) {
    return leads.where((lead) {
      // Search filter
      if (_searchController.text.isNotEmpty) {
        final searchLower = _searchController.text.toLowerCase();
        if (!lead.fullName.toLowerCase().contains(searchLower) &&
            !lead.customerId.toLowerCase().contains(searchLower) &&
            !lead.mobile.contains(_searchController.text) &&
            !lead.aadhar.contains(_searchController.text)) {
          return false;
        }
      }
      
      // Status filter
      if (_selectedStatus != null && lead.status != _selectedStatus) {
        return false;
      }
      
      // District filter
      if (_selectedDistrict != null && lead.district != _selectedDistrict) {
        return false;
      }
      
      // State filter
      if (_selectedState != null && lead.state != _selectedState) {
        return false;
      }
      
      return true;
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredLeads = _filterLeads(_leads);
    });
  }

  void _onFiltersChanged(String? status, String? district, String? state) {
    setState(() {
      _selectedStatus = status;
      _selectedDistrict = district;
      _selectedState = state;
      _filteredLeads = _filterLeads(_leads);
    });
  }



  // Read-only access - no status updates for partners/sales representatives
  void _showReadOnlyLeadDetails(Lead lead) {
    // Show read-only lead details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildReadOnlyLeadDetails(lead),
    );
  }

  Widget _buildReadOnlyLeadDetails(Lead lead) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppColors.primary600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
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
                      Text(
                        'Customer ID: ${lead.customerId}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Lead Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReadOnlyDetailRow('Mobile', lead.mobile, Icons.phone),
                const SizedBox(height: 16),
                _buildReadOnlyDetailRow('Aadhar', lead.aadhar, Icons.credit_card),
                const SizedBox(height: 16),
                _buildReadOnlyDetailRow('Date of Birth', lead.dob, Icons.cake),
                const SizedBox(height: 16),
                _buildReadOnlyDetailRow('Father\'s Name', lead.fatherName, Icons.person),
                const SizedBox(height: 16),
                _buildReadOnlyDetailRow('Gender', lead.gender, Icons.wc),
                const SizedBox(height: 16),
                _buildReadOnlyDetailRow('Issue', lead.issue, Icons.warning),
                const SizedBox(height: 16),
                _buildReadOnlyDetailRow('Location', '${lead.district}, ${lead.state}', Icons.location_on),
                const SizedBox(height: 16),
                _buildReadOnlyDetailRow('Status', lead.status, Icons.info),
                const SizedBox(height: 16),
                _buildReadOnlyDetailRow('Created', _formatDate(lead.createdAtDate), Icons.calendar_today),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyDetailRow(String label, String? value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value ?? 'N/A',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showConvertConfirmationDialog(Lead lead) async {
    if (!mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add,
                  color: AppColors.success600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Convert to Customer',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Text(
                  'Are you sure you want to convert this lead to a customer?',
                  style: AppTextStyles.bodyMedium,
                ),
            const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Details:',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.info700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Name', lead.fullName),
                      _buildInfoRow('Customer ID', lead.customerId),
                      _buildInfoRow('Email', '${lead.customerId.toLowerCase()}@futurecapital.com'),
                      _buildInfoRow('Password', _generatePasswordFromDob(lead.dob)),
                    ],
                  ),
                ),
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
                      Icon(Icons.info_outline, color: AppColors.warning600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will create a Firebase user account and move the lead to customers collection.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warning700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
            ),
        ),
        actions: [
          TextButton(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop(false);
                }
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
          ),
            ElevatedButton.icon(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Convert'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ),
        ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      // Small delay to ensure dialog is fully closed
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
      _convertToCustomer(lead.id);
    }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.info600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateLeadStatus(String leadId, String newStatus, String? remark) async {
    try {
      final success = await _leadsService.updateLeadStatus(leadId, newStatus, remark: remark);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Lead status updated successfully'),
              ],
            ),
            backgroundColor: AppColors.success500,
          ),
        );
        _loadLeads();
        _loadStats();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Failed to update lead status'),
              ],
            ),
            backgroundColor: AppColors.error500,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error500,
          ),
        );
      }
    }
  }

  Future<void> _convertToCustomer(String leadId) async {
    if (!mounted) return;
    
    // Use a completer to track dialog state more reliably
    bool isDialogShowing = false;
    BuildContext? dialogContext;
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          dialogContext = context;
          isDialogShowing = true;
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.success500),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Converting to customer...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Perform the conversion
      final success = await _leadsService.convertLeadToCustomer(leadId);
      
      // Close dialog safely
      if (isDialogShowing && dialogContext != null && mounted) {
        try {
          Navigator.of(dialogContext!).pop();
          isDialogShowing = false;
          dialogContext = null;
        } catch (e) {
          print('⚠️ Error closing dialog: $e');
        }
        
        // Small delay to ensure dialog is fully closed
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      // Show result message
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.person_add, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Lead successfully converted to customer'),
                  ),
                ],
              ),
              backgroundColor: AppColors.success500,
              duration: const Duration(seconds: 4),
            ),
          );
          
          // Refresh data
          _loadLeads();
          _loadStats();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text('Failed to convert lead to customer'),
                ],
              ),
              backgroundColor: AppColors.error500,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error in _convertToCustomer: $e');
      
      // Close dialog safely if still showing
      if (isDialogShowing && dialogContext != null && mounted) {
        try {
          Navigator.of(dialogContext!).pop();
          isDialogShowing = false;
          dialogContext = null;
        } catch (dialogError) {
          print('⚠️ Error closing dialog in catch: $dialogError');
        }
        
        // Small delay to ensure dialog is fully closed
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppColors.error500,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _showLeadDetails(Lead lead) async {
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LeadDetailsBottomSheet(lead: lead),
    );
  }

  String _generatePasswordFromDob(String dob) {
    try {
      final date = DateTime.parse(dob);
      return DateFormat('ddMMyyyy').format(date);
    } catch (e) {
      return 'fc${DateTime.now().year}';
    }
  }

  void _navigateToAddLead() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LeadGenerationScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadLeads(); // Refresh leads if a new lead was created
      }
    });
  }

  Widget _buildFloatingActionButton() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.userData?['role'] ?? 'partner';
    final requiresKyc = authProvider.requiresKyc;
    
    if (userRole?.toString().toLowerCase() == 'sales representative') {
      return FloatingActionButton.extended(
        onPressed: requiresKyc ? null : () => _navigateToAddLead(),
        icon: Icon(Icons.add_rounded),
        label: Text('Generate Lead'),
        backgroundColor: requiresKyc ? Colors.grey : AppColors.primary500,
        foregroundColor: Colors.white,
        elevation: requiresKyc ? 0 : 8,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
      );
    } else {
      return FloatingActionButton.extended(
        onPressed: requiresKyc ? null : () => _showSimpleLeadForm(),
        icon: Icon(Icons.person_add_rounded),
        label: Text('Add Quick Lead'),
        backgroundColor: requiresKyc ? Colors.grey : AppColors.success500,
        foregroundColor: Colors.white,
        elevation: requiresKyc ? 0 : 8,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
      );
    }
  }

  void _showSimpleLeadForm() {
    showDialog(
      context: context,
      builder: (context) => SimpleLeadFormDialog(
        onLeadCreated: () {
          _loadLeads(); // Refresh leads after creation
        },
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;
    final isMobile = screenWidth <= 768;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _buildFloatingActionButton(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
        children: [
            // Animated Header with Stats and Filters
            AnimatedBuilder(
              animation: _headerAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor.withOpacity(_isHeaderCollapsed ? 0.1 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
            child: Column(
              children: [
                      // Collapsed Search Bar (shows when scrolled)
                      if (_isHeaderCollapsed) ...[
                        Container(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          child: Row(
                            children: [
                              // Collapsed Search Icon
                              AnimatedBuilder(
                                animation: _headerAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _headerAnimation.value,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.primary200),
                                      ),
                                      child: Icon(
                                        Icons.search,
                                        color: AppColors.primary600,
                                        size: 20,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              
                              // Collapsed Filter Button
                              AnimatedBuilder(
                                animation: _headerAnimation,
                                builder: (context, child) {
                                  final hasFilters = _selectedStatus != null || 
                                                   _selectedDistrict != null || 
                                                   _selectedState != null;
                                  final filterCount = [_selectedStatus, _selectedDistrict, _selectedState]
                                      .where((f) => f != null).length;
                                  
                                  return Transform.scale(
                                    scale: _headerAnimation.value,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: hasFilters ? AppColors.primary50 : AppColors.neutral50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: hasFilters ? AppColors.primary200 : AppColors.neutral200,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                      children: [
                                          Icon(
                                            hasFilters ? Icons.filter_alt : Icons.filter_list_outlined,
                                            color: hasFilters ? AppColors.primary600 : AppColors.textSecondary,
                                            size: 18,
                    ),
                                          if (hasFilters) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary500,
                                                borderRadius: BorderRadius.circular(10),
                    ),
                                              child: Text(
                                                filterCount.toString(),
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              
                              const Spacer(),
                              
                              // Results count
                              Text(
                                '${_filteredLeads.length} leads',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Stats Cards Row (always visible with height animation)
                      if (_stats.isNotEmpty) ...[
                        AnimatedBuilder(
                          animation: _statsAnimation,
                          builder: (context, child) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 16 : 24,
                                vertical: 12,
                              ),
                              child: SizedBox(
                                height: (isMobile ? 80 : (isTablet ? 90 : 100)) * _statsAnimation.value,
                                child: _buildStatsCards(isMobile, isTablet, isDesktop),
                              ),
                            );
                          },
                        ),
                      ],
                      
                      // Full Filter Bar (shows when not scrolled)
                      if (!_isHeaderCollapsed) ...[
                        LeadFilterBar(
                          onSearchChanged: _onSearchChanged,
                          currentStatus: _selectedStatus,
                          currentDistrict: _selectedDistrict,
                          currentState: _selectedState,
                          onFiltersChanged: _onFiltersChanged,
                          searchController: _searchController,
                    ),
                  ],
                    ],
                  ),
                );
              },
          ),
          
          // Leads List
          Expanded(
            child: _isLoading
                  ? _buildLoadingState()
                : _filteredLeads.isEmpty
                      ? _buildEmptyState()
                      : _buildLeadsList(isMobile, isTablet, isDesktop),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(bool isMobile, bool isTablet, bool isDesktop) {
    final statsList = [
      {'label': 'Total', 'count': _stats['total'] ?? 0, 'color': AppColors.primary500, 'icon': Icons.group},
      {'label': 'New', 'count': _stats[LeadStatus.newLead.value] ?? 0, 'color': AppColors.info500, 'icon': Icons.fiber_new},
      {'label': 'Contacted', 'count': _stats[LeadStatus.contacted.value] ?? 0, 'color': AppColors.warning500, 'icon': Icons.phone},
      {'label': 'Interested', 'count': _stats[LeadStatus.interested.value] ?? 0, 'color': AppColors.success500, 'icon': Icons.thumb_up},
      {'label': 'Converted', 'count': _stats[LeadStatus.convertedToCustomer.value] ?? 0, 'color': AppColors.success600, 'icon': Icons.person_add},
    ];

    if (isMobile) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: statsList.length,
        itemBuilder: (context, index) {
          final stat = statsList[index];
          return Container(
            width: 140,
            margin: EdgeInsets.only(right: index < statsList.length - 1 ? 12 : 0),
            child: _buildStatCard(
              stat['label'] as String,
              stat['count'] as int,
              stat['color'] as Color,
              stat['icon'] as IconData,
              isMobile,
            ),
          );
        },
      );
    }

    return Row(
      children: statsList.map((stat) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            child: _buildStatCard(
              stat['label'] as String,
              stat['count'] as int,
              stat['color'] as Color,
              stat['icon'] as IconData,
              isMobile,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon, bool isMobile) {
    return AppCard(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: isMobile ? 14 : 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
                        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                Text(
                  count.toString(),
                  style: (isMobile ? AppTextStyles.titleMedium : AppTextStyles.titleLarge).copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                            Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
                              ),
                            ),
                          ],
                        ),
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
            'Loading leads...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textTertiary,
              ),
            ),
          const SizedBox(height: 24),
            Text(
            'No leads found',
            style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Leads will appear here when credit requests are submitted',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            ),
          ],
        ),
    );
  }

  Widget _buildLeadsList(bool isMobile, bool isTablet, bool isDesktop) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      itemCount: _filteredLeads.length,
      itemBuilder: (context, index) {
        final lead = _filteredLeads[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + (index * 30)),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: _buildLeadCard(lead, isDesktop, isMobile),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeadCard(Lead lead, bool isDesktop, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          InkWell(
            onTap: () => _showReadOnlyLeadDetails(lead),
            borderRadius: BorderRadius.circular(12),
            child: AppCard(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      // Avatar with status color
                      Container(
                        width: isMobile ? 40 : 48,
                        height: isMobile ? 40 : 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getStatusColor(lead.status),
                              _getStatusColor(lead.status).withOpacity(0.7),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: isMobile ? 20 : 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Name and Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    lead.fullName,
                                    style: (isMobile ? AppTextStyles.titleSmall : AppTextStyles.titleMedium).copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AppBadge(
                                  text: lead.status,
                                  type: _getStatusBadgeType(lead.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'ID: ${lead.customerId}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Action Menu
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'view':
                              _showReadOnlyLeadDetails(lead);
                              break;
                          }
                        },
                        icon: Icon(
                          Icons.more_vert,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                const Text('View Details'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  
                  // Details Grid
                  if (isDesktop) ...[
                    Row(
                      children: [
                        Expanded(child: _buildDetailItem('Mobile', lead.mobile, Icons.phone, isMobile)),
                        Expanded(child: _buildDetailItem('Issue', lead.issue, Icons.warning, isMobile)),
                        Expanded(child: _buildDetailItem('Location', '${lead.district}, ${lead.state}', Icons.location_on, isMobile)),
                        Expanded(child: _buildDetailItem('Created', _formatDate(lead.createdAtDate), Icons.calendar_today, isMobile)),
                      ],
                    ),
                  ] else ...[
                    _buildDetailItem('Mobile', lead.mobile, Icons.phone, isMobile),
                    const SizedBox(height: 12),
                    _buildDetailItem('Issue', lead.issue, Icons.warning, isMobile),
                    const SizedBox(height: 12),
                    _buildDetailItem('Location', '${lead.district}, ${lead.state}', Icons.location_on, isMobile),
                    const SizedBox(height: 12),
                    _buildDetailItem('Created', _formatDate(lead.createdAtDate), Icons.calendar_today, isMobile),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value, IconData icon, bool isMobile) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
          icon,
            size: isMobile ? 14 : 16,
          color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value ?? 'N/A',
                style: (isMobile ? AppTextStyles.bodySmall : AppTextStyles.bodyMedium).copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
        return AppColors.neutral500;
    }
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
} 