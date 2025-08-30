import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'lead_filter_bottom_sheet.dart';

class LeadFilterBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final String? currentStatus;
  final String? currentDistrict;
  final String? currentState;
  final Function(String? status, String? district, String? state) onFiltersChanged;
  final TextEditingController searchController;

  const LeadFilterBar({
    super.key,
    required this.onSearchChanged,
    this.currentStatus,
    this.currentDistrict,
    this.currentState,
    required this.onFiltersChanged,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = currentStatus != null || currentDistrict != null || currentState != null;
    final filterCount = [currentStatus, currentDistrict, currentState].where((f) => f != null).length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name, customer ID, mobile, or Aadhar...',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.neutral300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.neutral300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary500, width: 2),
                ),
                filled: true,
                fillColor: AppColors.neutral50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Filter Button
          _buildFilterButton(context, hasActiveFilters, filterCount),
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, bool hasActiveFilters, int filterCount) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasActiveFilters ? AppColors.primary600 : AppColors.neutral200,
          width: hasActiveFilters ? 2 : 1,
        ),
        color: hasActiveFilters ? AppColors.primary50 : Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFilterBottomSheet(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasActiveFilters ? Icons.filter_alt : Icons.filter_list_outlined,
                  size: 20,
                  color: hasActiveFilters ? AppColors.primary600 : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  hasActiveFilters ? 'Filters ($filterCount)' : 'Filters',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: hasActiveFilters ? AppColors.primary600 : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LeadFilterBottomSheet(
        initialStatus: currentStatus,
        initialDistrict: currentDistrict,
        initialState: currentState,
        onApplyFilters: onFiltersChanged,
      ),
    );
  }
} 