import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/customer_model.dart';

class CustomerFilterBottomSheet extends StatefulWidget {
  final String? initialStatus;
  final String? initialDistrict;
  final String? initialState;
  final Function(String? status, String? district, String? state) onApplyFilters;

  const CustomerFilterBottomSheet({
    super.key,
    this.initialStatus,
    this.initialDistrict,
    this.initialState,
    required this.onApplyFilters,
  });

  @override
  State<CustomerFilterBottomSheet> createState() => _CustomerFilterBottomSheetState();
}

class _CustomerFilterBottomSheetState extends State<CustomerFilterBottomSheet> {
  String? _selectedStatus;
  String? _selectedDistrict;
  String? _selectedState;

  // Common Indian states
  final List<String> _states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Puducherry'
  ];

  // Sample districts (you can expand this based on your needs)
  final List<String> _districts = [
    'Agra', 'Ahmedabad', 'Allahabad', 'Bangalore', 'Bhopal', 'Chennai',
    'Delhi', 'Gurgaon', 'Hyderabad', 'Indore', 'Jaipur', 'Kanpur',
    'Kolkata', 'Lucknow', 'Mumbai', 'Nagpur', 'Noida', 'Patna', 'Pune', 'Surat'
  ];

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'Filter Customers',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: Text(
                    'Clear All',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.error600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Filters
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Filter
                  _buildFilterSection(
                    'Status',
                    _selectedStatus,
                    CustomerStatus.values.map((e) => e.value).toList(),
                    (value) => setState(() => _selectedStatus = value),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // State Filter
                  _buildFilterSection(
                    'State',
                    _selectedState,
                    _states,
                    (value) => setState(() => _selectedState = value),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // District Filter
                  _buildFilterSection(
                    'District',
                    _selectedDistrict,
                    _districts,
                    (value) => setState(() => _selectedDistrict = value),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Apply Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.neutral300),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Apply Filters',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
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

  Widget _buildFilterSection(
    String title,
    String? selectedValue,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neutral300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              hint: Text('Select $title'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All'),
                ),
                ...options.map((option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                )),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  void _clearFilters() {
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