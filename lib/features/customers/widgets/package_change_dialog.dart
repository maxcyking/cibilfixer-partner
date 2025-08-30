import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/customer_model.dart';
import '../../../models/package_model.dart';
import '../../../services/packages_service.dart';
import '../../../services/customers_service.dart';

class PackageChangeDialog extends StatefulWidget {
  final Customer customer;
  final Function(Package) onPackageChanged;

  const PackageChangeDialog({
    super.key,
    required this.customer,
    required this.onPackageChanged,
  });

  @override
  State<PackageChangeDialog> createState() => _PackageChangeDialogState();
}

class _PackageChangeDialogState extends State<PackageChangeDialog> {
  final PackagesService _packagesService = PackagesService();
  final CustomersService _customersService = CustomersService();
  
  List<Package> _packages = [];
  Package? _selectedPackage;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final packages = await _packagesService.getPackages();
      setState(() {
        _packages = packages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load packages: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updatePackage() async {
    if (_selectedPackage == null) return;

    // Check if this is a downgrade (not allowed)
    final currentPackage = _packages.firstWhere(
      (p) => p.id == widget.customer.packageId,
      orElse: () => Package.createSimple(name: 'Unknown', price: widget.customer.packagePrice ?? 0.0),
    );
    
    if (_selectedPackage!.isDowngradeFrom(currentPackage)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Package downgrades are not allowed. You can only upgrade to higher-tier packages.'),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      // Use the new customer service method for package updates
      final success = await _customersService.updateCustomerPackage(
        customerId: widget.customer.id,
        packageId: _selectedPackage!.id,
        packageName: _selectedPackage!.name,
        packagePrice: _selectedPackage!.price,
        currentPackagePrice: widget.customer.packagePrice,
      );

      if (success) {
        if (mounted) {
          widget.onPackageChanged(_selectedPackage!);
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Failed to update package');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update package: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 700,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.upgrade,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Package',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Select a new package for ${widget.customer.fullName}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Current Package Info
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Package',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.customer.packageDisplayName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.customer.packagePriceDisplay,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (widget.customer.amountDue > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Due: ₹${widget.customer.amountDue.toStringAsFixed(0)}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Upgrade Policy Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.info.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upgrade Policy',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'You can only upgrade to higher-tier packages. Downgrades are not allowed to maintain service quality.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Package Selection
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _packages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No packages available',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _packages.length,
                          itemBuilder: (context, index) {
                            final package = _packages[index];
                            final isSelected = _selectedPackage?.id == package.id;
                            final isCurrent = widget.customer.packageId == package.id;
                            final priceDifference = package.price - (widget.customer.packagePrice ?? 0.0);
                            
                            // Check if this is a downgrade (not allowed)
                            final currentPackage = _packages.firstWhere(
                              (p) => p.id == widget.customer.packageId,
                              orElse: () => Package.createSimple(name: 'Unknown', price: widget.customer.packagePrice ?? 0.0),
                            );
                            final isDowngrade = package.isDowngradeFrom(currentPackage);
                            final isUpgrade = package.isUpgradeFrom(currentPackage);
                            final changeType = package.getChangeTypeFrom(currentPackage);
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? AppColors.primary.withOpacity(0.1) 
                                    : isDowngrade
                                        ? AppColors.neutral50
                                        : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected 
                                      ? AppColors.primary 
                                      : isDowngrade
                                          ? AppColors.neutral300
                                          : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: (isCurrent || isDowngrade) ? null : () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _selectedPackage = package;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Radio<Package>(
                                        value: package,
                                        groupValue: _selectedPackage,
                                        onChanged: (isCurrent || isDowngrade) ? null : (value) {
                                          setState(() {
                                            _selectedPackage = value;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  package.name,
                                                  style: AppTextStyles.titleMedium.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: isCurrent || isDowngrade 
                                                        ? AppColors.textTertiary 
                                                        : AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Package tier badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: package.tierColor.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    package.tier,
                                                    style: AppTextStyles.bodySmall.copyWith(
                                                      color: package.tierColor,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                                if (isCurrent) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.success.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      'Current',
                                                      style: AppTextStyles.bodySmall.copyWith(
                                                        color: AppColors.success,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                if (isDowngrade) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.error.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.lock_outline,
                                                          size: 12,
                                                          color: AppColors.error,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Restricted',
                                                          style: AppTextStyles.bodySmall.copyWith(
                                                            color: AppColors.error,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  '₹${package.price.toStringAsFixed(0)}',
                                                  style: AppTextStyles.titleMedium.copyWith(
                                                    color: isDowngrade ? AppColors.textTertiary : AppColors.success,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (!isCurrent && priceDifference != 0) ...[
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: priceDifference > 0 
                                                          ? AppColors.warning.withOpacity(0.2)
                                                          : AppColors.success.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      priceDifference > 0 
                                                          ? '+₹${priceDifference.toStringAsFixed(0)}'
                                                          : '-₹${(-priceDifference).toStringAsFixed(0)}',
                                                      style: AppTextStyles.bodySmall.copyWith(
                                                        color: priceDifference > 0 
                                                            ? AppColors.warning
                                                            : AppColors.success,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                if (isUpgrade) ...[
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.trending_up,
                                                          size: 12,
                                                          color: AppColors.primary,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Upgrade',
                                                          style: AppTextStyles.bodySmall.copyWith(
                                                            color: AppColors.primary,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (package.description.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                package.description,
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: isDowngrade ? AppColors.textTertiary : AppColors.textSecondary,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            // Downgrade restriction message
                                            if (isDowngrade) ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.error.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.info_outline,
                                                      size: 16,
                                                      color: AppColors.error,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'Package downgrades are not allowed. You can only upgrade to higher-tier packages.',
                                                        style: AppTextStyles.bodySmall.copyWith(
                                                          color: AppColors.error,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            
            // Actions
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
                      onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
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
                      onPressed: (_selectedPackage == null || _isUpdating) ? null : _updatePackage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isUpdating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Update Package',
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
      ),
    );
  }
} 