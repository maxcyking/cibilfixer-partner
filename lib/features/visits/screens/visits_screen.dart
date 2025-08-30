import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../models/visit_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/visit_service.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/buttons/secondary_button.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../widgets/kyc_guard.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> with SingleTickerProviderStateMixin {
  final VisitService _visitService = VisitService();
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  
  late TabController _tabController;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _firmController = TextEditingController();
  final _villageController = TextEditingController();
  final _tehsilController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinController = TextEditingController();
  final _remarkController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isSubmitting = false;
  
  List<Visit> _visits = [];
  List<Visit> _filteredVisits = [];
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _firmController.dispose();
    _villageController.dispose();
    _tehsilController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pinController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    
    if (userId != null) {
      final visits = await _visitService.getUserVisits(userId);
      final stats = await _visitService.getVisitStats(userId);
      
      setState(() {
        _visits = visits;
        _filteredVisits = visits;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredVisits = _visits.where((visit) {
        return visit.name.toLowerCase().contains(query) ||
               visit.firmCompanyName.toLowerCase().contains(query) ||
               visit.village.toLowerCase().contains(query) ||
               visit.tehsilCity.toLowerCase().contains(query) ||
               visit.district.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;
      final userName = authProvider.userData?['fullName'] ?? '';
      
      if (userId != null) {
        final visit = Visit(
          id: '',
          userId: userId,
          userName: userName,
          dateOfVisit: _selectedDate,
          name: _nameController.text.trim(),
          firmCompanyName: _firmController.text.trim(),
          village: _villageController.text.trim(),
          tehsilCity: _tehsilController.text.trim(),
          district: _districtController.text.trim(),
          state: _stateController.text.trim(),
          pin: _pinController.text.trim(),
          remark: _remarkController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final success = await _visitService.addVisit(visit);
        
        if (success) {
          _clearForm();
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visit entry added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _tabController.animateTo(1); // Switch to visits list tab
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add visit entry. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      
      setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _firmController.clear();
    _villageController.clear();
    _tehsilController.clear();
    _districtController.clear();
    _stateController.clear();
    _pinController.clear();
    _remarkController.clear();
    setState(() => _selectedDate = DateTime.now());
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveUtils.isMobile(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Visits'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Add Visit'),
            Tab(text: 'My Visits'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                KycGuard(child: _buildAddVisitTab()),
                _buildVisitsListTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visit Statistics',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatsCards(),
          const SizedBox(height: 32),
          Text(
            'Recent Visits',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentVisits(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final stats = [
      {
        'title': 'Total Visits',
        'value': _stats['total']?.toString() ?? '0',
        'icon': Icons.location_on,
        'color': AppColors.primary,
      },
      {
        'title': 'This Month',
        'value': _stats['thisMonth']?.toString() ?? '0',
        'icon': Icons.calendar_month,
        'color': AppColors.success,
      },
      {
        'title': 'This Week',
        'value': _stats['thisWeek']?.toString() ?? '0',
        'icon': Icons.calendar_today,
        'color': AppColors.warning,
      },
      {
        'title': 'Today',
        'value': _stats['today']?.toString() ?? '0',
        'icon': Icons.today,
        'color': AppColors.info,
      },
    ];

    // Responsive layout
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);
    final aspectRatio = isMobile ? 1.1 : (isTablet ? 1.2 : 1.3);
    final spacing = isMobile ? 12.0 : 16.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return AppCard(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: isMobile ? 24 : 28,
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Flexible(
                  child: Text(
                    stat['value'] as String,
                    style: (isMobile 
                        ? AppTextStyles.titleLarge 
                        : AppTextStyles.headlineMedium).copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(height: isMobile ? 2 : 4),
                Flexible(
                  child: Text(
                    stat['title'] as String,
                    style: (isMobile 
                        ? AppTextStyles.bodySmall 
                        : AppTextStyles.bodyMedium).copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentVisits() {
    final recentVisits = _visits.take(5).toList();
    
    if (recentVisits.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.location_off,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No visits yet',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first visit to get started',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AppCard(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentVisits.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final visit = recentVisits[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(
                Icons.person,
                color: AppColors.primary,
              ),
            ),
            title: Text(
              visit.name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(visit.firmCompanyName),
                Text(
                  DateFormat('MMM dd, yyyy').format(visit.dateOfVisit),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          );
        },
      ),
    );
  }

  Widget _buildAddVisitTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Visit',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Date of Visit
            _buildDateField(),
            const SizedBox(height: 16),
            
            // Name
            _buildTextField(
              controller: _nameController,
              label: 'Name',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Firm/Company Name
            _buildTextField(
              controller: _firmController,
              label: 'Firm/Company Name',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter firm/company name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Address Section
            Text(
              'Address',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Village
            _buildTextField(
              controller: _villageController,
              label: 'Village',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter village';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Tehsil/City
            _buildTextField(
              controller: _tehsilController,
              label: 'Tehsil/City',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter tehsil/city';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // District
            _buildTextField(
              controller: _districtController,
              label: 'District',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter district';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // State
            _buildTextField(
              controller: _stateController,
              label: 'State',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter state';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // PIN
            _buildTextField(
              controller: _pinController,
              label: 'PIN',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter PIN';
                }
                if (value!.length != 6) {
                  return 'PIN must be 6 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Remark
            _buildTextField(
              controller: _remarkController,
              label: 'Remark',
              maxLines: 3,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter remark';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            
            // Submit Button
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Add Visit',
                    onPressed: _isSubmitting ? null : _submitForm,
                    isLoading: _isSubmitting,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SecondaryButton(
                    text: 'Clear',
                    onPressed: _clearForm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitsListTab() {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search visits...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
        
        // Visits List
        Expanded(
          child: _filteredVisits.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No visits found',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredVisits.length,
                  itemBuilder: (context, index) {
                    final visit = _filteredVisits[index];
                    return _buildVisitCard(visit);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVisitCard(Visit visit) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.name,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        visit.firmCompanyName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(visit.dateOfVisit),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Address
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Address',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    visit.fullAddress,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Remark
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remark',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    visit.remark,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date of Visit',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMMM dd, yyyy').format(_selectedDate),
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
} 