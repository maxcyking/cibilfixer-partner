import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/lead_model.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/buttons/secondary_button.dart';

class LeadFilterBottomSheet extends StatefulWidget {
  final String? initialStatus;
  final String? initialDistrict;
  final String? initialState;
  final Function(String? status, String? district, String? state) onApplyFilters;

  const LeadFilterBottomSheet({
    super.key,
    this.initialStatus,
    this.initialDistrict,
    this.initialState,
    required this.onApplyFilters,
  });

  @override
  State<LeadFilterBottomSheet> createState() => _LeadFilterBottomSheetState();
}

class _LeadFilterBottomSheetState extends State<LeadFilterBottomSheet> {
  String? _selectedStatus;
  String? _selectedDistrict;
  String? _selectedState;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _selectedDistrict = widget.initialDistrict;
    _selectedState = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  'Filter Leads',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_hasActiveFilters())
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: Text(
                      'Clear All',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Filters
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Filter
                  _buildFilterSection(
                    title: 'Status',
                    child: _buildStatusFilter(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // District Filter
                  _buildFilterSection(
                    title: 'District',
                    child: _buildDistrictFilter(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // State Filter
                  _buildFilterSection(
                    title: 'State',
                    child: _buildStateFilter(),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Apply Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Reset',
                    onPressed: _clearAllFilters,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    text: 'Apply Filters',
                    onPressed: _applyFilters,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LeadStatus.values.map((status) {
        final isSelected = _selectedStatus == status.value;
        return FilterChip(
          label: Text(status.value),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedStatus = selected ? status.value : null;
            });
          },
          selectedColor: AppColors.primary100,
          checkmarkColor: AppColors.primary600,
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? AppColors.primary600 : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDistrictFilter() {
    // Common districts in India - you can customize this list
    final districts = [
      'Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Chennai',
      'Kolkata', 'Pune', 'Ahmedabad', 'Jaipur', 'Lucknow',
      'Kanpur', 'Nagpur', 'Indore', 'Thane', 'Bhopal',
      'Visakhapatnam', 'Pimpri', 'Patna', 'Vadodara', 'Ghaziabad',
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedDistrict,
        hint: const Text('Select District'),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('All Districts'),
          ),
          ...districts.map((district) => DropdownMenuItem<String>(
            value: district,
            child: Text(district),
          )),
        ],
        onChanged: (value) {
          setState(() {
            _selectedDistrict = value;
          });
        },
      ),
    );
  }

  Widget _buildStateFilter() {
    // Indian states - you can customize this list
    final states = [
      'Maharashtra', 'Delhi', 'Karnataka', 'Telangana', 'Tamil Nadu',
      'West Bengal', 'Gujarat', 'Rajasthan', 'Uttar Pradesh', 'Madhya Pradesh',
      'Bihar', 'Odisha', 'Kerala', 'Punjab', 'Haryana',
      'Assam', 'Jharkhand', 'Chhattisgarh', 'Uttarakhand', 'Himachal Pradesh',
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedState,
        hint: const Text('Select State'),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('All States'),
          ),
          ...states.map((state) => DropdownMenuItem<String>(
            value: state,
            child: Text(state),
          )),
        ],
        onChanged: (value) {
          setState(() {
            _selectedState = value;
          });
        },
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedStatus != null || _selectedDistrict != null || _selectedState != null;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedDistrict = null;
      _selectedState = null;
    });
  }

  void _applyFilters() {
    widget.onApplyFilters(_selectedStatus, _selectedDistrict, _selectedState);
    Navigator.of(context).pop();
  }
} 