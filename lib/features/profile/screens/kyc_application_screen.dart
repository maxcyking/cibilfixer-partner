import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/buttons/secondary_button.dart';
import '../../../models/user_model.dart';
import '../../../models/kyc_step_model.dart';
import '../widgets/kyc_step_widget.dart';
import '../widgets/kyc_progress_indicator.dart';
import '../../../services/kyc_service.dart';

class KycApplicationScreen extends StatefulWidget {
  final UserModel user;
  final bool isUpdate;

  const KycApplicationScreen({
    super.key,
    required this.user,
    this.isUpdate = false,
  });

  @override
  State<KycApplicationScreen> createState() => _KycApplicationScreenState();
}

class _KycApplicationScreenState extends State<KycApplicationScreen> {
  final PageController _pageController = PageController();
  final KycService _kycService = KycService();
  
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _hasExistingProgress = false;
  bool _isAutoSaving = false;
  
  late List<KycStepModel> _kycSteps;

  @override
  void initState() {
    super.initState();
    _initializeKycSteps();
    _loadKycProgressAndResume();
  }

  void _initializeKycSteps() {
    _kycSteps = [
      KycStepModel(
        id: 'personal_info',
        title: 'Personal Information',
        description: 'Provide your basic personal details',
        icon: Icons.person_outline,
        status: KycStepStatus.pending,
        fields: {
          'fatherName': '',
          'dateOfBirth': '',
          'gender': '',
          'maritalStatus': '',
        },
        isRequired: true,
      ),
      KycStepModel(
        id: 'contact_info',
        title: 'Contact Information',
        description: 'Verify your contact details',
        icon: Icons.contact_phone_outlined,
        status: KycStepStatus.pending,
        fields: {
          'mobileNumber': widget.user.mobile,
          'emailAddress': widget.user.email,
        },
        isRequired: true,
      ),
      KycStepModel(
        id: 'address_info',
        title: 'Address Details',
        description: 'Provide your current address',
        icon: Icons.location_on_outlined,
        status: KycStepStatus.pending,
        fields: {
          'address': '',
          'village': '',
          'tehsilCity': '',
          'district': '',
          'state': '',
          'pinCode': '',
        },
        isRequired: true,
      ),
      KycStepModel(
        id: 'document_info',
        title: 'Government Documents',
        description: 'Upload your government ID documents',
        icon: Icons.description_outlined,
        status: KycStepStatus.pending,
        fields: {
          'aadharNumber': '',
          'panNumber': '',
        },
        documents: {
          'aadharCard': null,
          'panCard': null,
        },
        isRequired: true,
      ),

      KycStepModel(
        id: 'experience_info',
        title: 'Work Experience',
        description: 'Tell us about your work experience',
        icon: Icons.work_outline,
        status: KycStepStatus.pending,
        fields: {
          'hasExperience': 'no',
          'experienceDetails': '',
          'currentCompany': '',
          'workingYears': '',
        },
        documents: {
          'experienceCertificate': null,
        },
        isRequired: false,
      ),
      KycStepModel(
        id: 'bank_info',
        title: 'Bank Details',
        description: 'Provide bank details for payouts',
        icon: Icons.account_balance_outlined,
        status: KycStepStatus.pending,
        fields: {
          'accountNumber': '',
          'bankName': '',
          'ifscCode': '',
          'accountHolderName': '',
          'branchName': '',
        },
        documents: {
          'bankPassbook': null,
        },
        isRequired: true,
      ),
    ];
  }

  Future<void> _loadKycProgressAndResume() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user has existing KYC progress
      _hasExistingProgress = await _kycService.hasKycProgress(widget.user.uid);
      
      if (_hasExistingProgress) {
        print('📍 Found existing KYC progress for user');
        
        // Load existing data
        final existingKycData = await _kycService.getKycData(widget.user.uid);
        if (existingKycData != null) {
          print('📊 Loaded KYC data keys: ${existingKycData.keys.toList()}');
          
          try {
          _updateStepsWithExistingData(existingKycData);
            
            // Count restored documents
            int totalRestoredDocuments = 0;
            for (final step in _kycSteps) {
              if (step.documents != null) {
                final restoredDocs = step.documents!.values.where((doc) => doc != null).length;
                totalRestoredDocuments += restoredDocs;
              }
            }
            
            if (totalRestoredDocuments > 0) {
              print('📄 Restored $totalRestoredDocuments document(s) from previous session');
              _showSuccessSnackBar('Restored $totalRestoredDocuments previously uploaded document(s)');
            }
          } catch (e) {
            print('❌ Error updating steps with existing data: $e');
            print('📍 Data format might be corrupted, falling back to fresh start');
            _showErrorSnackBar('Some saved data could not be restored. Starting fresh.');
            // Don't throw, just continue with fresh data
          }
        }
        
        // Get the step to resume from
        final resumeStep = await _kycService.getResumeStep(widget.user.uid);
        _currentStep = resumeStep.clamp(0, _kycSteps.length - 1);
        
        // Show resume dialog if user has significant progress
        if (_currentStep > 0) {
          await _showResumeDialog();
        }
        
        // Navigate to resume step
        if (_currentStep > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _pageController.animateToPage(
              _currentStep,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          });
        }
      } else {
        print('📍 No existing KYC progress found, starting fresh');
      }
    } catch (e) {
      print('❌ Error loading KYC progress: $e');
      _showErrorSnackBar('Failed to load KYC progress. Starting fresh.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showResumeDialog() async {
    final completionPercentage = await _kycService.getKycCompletionPercentage(widget.user.uid);
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.restore,
              color: AppColors.primary600,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text('Resume KYC Application',
            style: TextStyle(fontSize: 14),),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have an incomplete KYC application.',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Progress: $completionPercentage% complete',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: AppColors.neutral200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
            ),
            const SizedBox(height: 16),
            Text(
              'Would you like to continue where you left off or start over?',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startFresh();
            },
            child: Text(
              'Start Over',
              style: TextStyle(color: AppColors.error600),
            ),
          ),
          PrimaryButton(
            text: 'Continue',
            onPressed: () {
              Navigator.pop(context);
              // Continue from current step (already set)
            },
          ),
        ],
      ),
    );
  }

  void _startFresh() {
    setState(() {
      _currentStep = 0;
      _initializeKycSteps(); // Reset all steps
    });
    
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  /// Clear corrupted KYC data and start fresh
  Future<void> _clearCorruptedData() async {
    try {
      // Clear the corrupted data from Firestore
      await _kycService.clearKycData(widget.user.uid);
      print('🧹 Cleared corrupted KYC data');
      
      _showSuccessSnackBar('Cleared corrupted data. Starting fresh.');
      _startFresh();
    } catch (e) {
      print('❌ Error clearing corrupted data: $e');
      _showErrorSnackBar('Failed to clear data. Please try again.');
    }
  }

  void _updateStepsWithExistingData(Map<String, dynamic> kycData) {
    for (int i = 0; i < _kycSteps.length; i++) {
      final stepId = _kycSteps[i].id;
      if (kycData.containsKey(stepId) && kycData[stepId] != null) {
        final stepData = kycData[stepId];
        
        // Ensure stepData is a Map before processing
        if (stepData is Map<String, dynamic>) {
        // Update fields
          if (stepData.containsKey('fields') && stepData['fields'] != null) {
            try {
          final fields = Map<String, dynamic>.from(stepData['fields']);
              
              // Clean up legacy fields that are no longer used
              if (stepId == 'contact_info') {
                fields.remove('alternateNumber'); // Remove legacy alternate number field
                print('🧹 Cleaned up legacy alternateNumber field from contact_info');
              }
              
          _kycSteps[i] = _kycSteps[i].copyWith(fields: fields);
              print('✅ Restored fields for step $stepId: ${fields.keys.toList()}');
            } catch (e) {
              print('❌ Error restoring fields for step $stepId: $e');
            }
          }
          
          // Update documents with proper null checking
          if (stepData.containsKey('documents') && stepData['documents'] != null) {
            try {
              final documentsData = stepData['documents'];
              if (documentsData is Map<String, dynamic>) {
                final documents = Map<String, dynamic>.from(documentsData);
                _kycSteps[i] = _kycSteps[i].copyWith(documents: documents);
                
                // Count non-null documents
                final nonNullDocs = documents.values.where((doc) => doc != null).length;
                if (nonNullDocs > 0) {
                  print('✅ Restored $nonNullDocs document(s) for step $stepId: ${documents.keys.toList()}');
                }
              }
            } catch (e) {
              print('❌ Error restoring documents for step $stepId: $e');
            }
        }
        
        // Update status
        if (stepData.containsKey('status')) {
            try {
              final status = _parseKycStatus(stepData['status']?.toString());
          _kycSteps[i] = _kycSteps[i].copyWith(status: status);
              print('✅ Restored status for step $stepId: ${stepData['status']}');
            } catch (e) {
              print('❌ Error restoring status for step $stepId: $e');
            }
        }
        
        // Update rejection reason if rejected
          if (stepData.containsKey('rejectionReason') && stepData['rejectionReason'] != null) {
            try {
          _kycSteps[i] = _kycSteps[i].copyWith(
                rejectionReason: stepData['rejectionReason'].toString(),
          );
              print('✅ Restored rejection reason for step $stepId');
            } catch (e) {
              print('❌ Error restoring rejection reason for step $stepId: $e');
            }
          }
        } else {
          print('⚠️ Step data for $stepId is not a valid Map: ${stepData.runtimeType}');
        }
      }
    }
    setState(() {});
    print('📋 Updated ${_kycSteps.length} steps with existing data');
  }

  KycStepStatus _parseKycStatus(String? status) {
    if (status == null) return KycStepStatus.pending;
    
    switch (status.toLowerCase()) {
      case 'approved':
        return KycStepStatus.approved;
      case 'rejected':
        return KycStepStatus.rejected;
      case 'pending':
      case 'draft':
      default:
        return KycStepStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back action
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          // Show confirmation dialog for system back button
          _showBackConfirmationDialog();
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => _onBackPressed(),
        ),
        title: Text(
          widget.isUpdate ? 'Update KYC' : 'KYC Application',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isAutoSaving)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.success500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Saving...',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (_isSubmitting)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildKycContent(),
      bottomNavigationBar: _isLoading ? null : _buildBottomNavigation(),
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
            'Loading KYC data...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKycContent() {
    return Column(
      children: [
        // Progress Indicator
        KycProgressIndicator(
          currentStep: _currentStep,
          totalSteps: _kycSteps.length,
          steps: _kycSteps,
          onStepTapped: (stepIndex) => _navigateToStep(stepIndex),
        ),
        
        // Content
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentStep = index;
              });
            },
            itemCount: _kycSteps.length,
            itemBuilder: (context, index) {
              return KycStepWidget(
                step: _kycSteps[index],
                userId: widget.user.uid,
                onStepDataChanged: (updatedStep) {
                  setState(() {
                    _kycSteps[index] = updatedStep;
                  });
                  
                  // Auto-save when user makes changes
                  _autoSaveCurrentStep();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous Button
            if (_currentStep > 0)
              Expanded(
                child: SecondaryButton(
                  text: 'Previous',
                  onPressed: _isSubmitting ? null : _goToPreviousStep,
                  icon: Icons.arrow_back,
                ),
              ),
            
            if (_currentStep > 0) const SizedBox(width: 16),
            
            // Next/Submit Button
            Expanded(
              flex: _currentStep > 0 ? 1 : 2,
              child: PrimaryButton(
                text: _currentStep == _kycSteps.length - 1 ? 'Submit KYC' : 'Next',
                onPressed: _isSubmitting ? null : _goToNextStep,
                isLoading: _isSubmitting,
                icon: _currentStep == _kycSteps.length - 1 
                    ? Icons.check_circle 
                    : Icons.arrow_forward,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _goToNextStep() async {
    // Validate current step
    if (!_validateCurrentStep()) {
      return;
    }

    // Save current step to Firestore
    await _saveCurrentStepToFirestore();

    if (_currentStep < _kycSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Submit complete KYC
      await _submitCompleteKyc();
    }
  }

  bool _validateCurrentStep() {
    final currentStep = _kycSteps[_currentStep];
    
    // Check required fields
    for (final fieldKey in currentStep.fields.keys) {
      final value = currentStep.fields[fieldKey]?.toString().trim() ?? '';
      if (currentStep.isRequired && value.isEmpty) {
        _showValidationError('Please fill all required fields');
        return false;
      }
    }

    // Check required documents
    if (currentStep.documents != null) {
      for (final docKey in currentStep.documents!.keys) {
        if (currentStep.isRequired && currentStep.documents![docKey] == null) {
          _showValidationError('Please upload all required documents');
          return false;
        }
      }
    }

    return true;
  }

  Future<void> _saveCurrentStepToFirestore() async {
    try {
      final currentStep = _kycSteps[_currentStep];
      await _kycService.saveKycStep(
        userId: widget.user.uid,
        stepId: currentStep.id,
        stepData: currentStep.toMap(),
      );
      
      // Also save overall progress for resuming
      await _kycService.saveKycProgress(
        userId: widget.user.uid,
        currentStep: _currentStep,
        kycSteps: _kycSteps,
      );
      
      // Update step status to pending
      setState(() {
        _kycSteps[_currentStep] = currentStep.copyWith(
          status: KycStepStatus.pending,
        );
      });
      
      print('✅ Saved step $_currentStep and overall progress');
    } catch (e) {
      print('❌ Error saving KYC step: $e');
      _showErrorSnackBar('Failed to save step data. Please try again.');
    }
  }

  /// Auto-save current step data (called when user makes changes)
  void _autoSaveCurrentStep() async {
    setState(() {
      _isAutoSaving = true;
    });
    
    try {
      final currentStep = _kycSteps[_currentStep];
      await _kycService.autoSaveStepData(
        userId: widget.user.uid,
        stepId: currentStep.id,
        stepData: currentStep.toMap(),
      );
      
      // Small delay to show the saving indicator
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      print('❌ Auto-save failed: $e');
      // Don't show error to user for auto-save failures
    } finally {
      if (mounted) {
        setState(() {
          _isAutoSaving = false;
        });
      }
    }
  }

  Future<void> _submitCompleteKyc() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Calculate progress
      final completedSteps = _kycSteps.where((step) => 
        step.status == KycStepStatus.pending || 
        step.status == KycStepStatus.approved
      ).length;
      final progress = ((completedSteps / _kycSteps.length) * 100).round();

      // Submit complete KYC data
      await _kycService.submitCompleteKyc(
        userId: widget.user.uid,
        kycSteps: _kycSteps,
        progress: progress,
      );

      // Show success message
      _showSuccessDialog();

    } catch (e) {
      print('Error submitting KYC: $e');
      _showErrorSnackBar('Failed to submit KYC. Please try again.');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error500,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error500,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => _goToNextStep(),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success500,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success500,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text('KYC Submitted Successfully'),
          ],
        ),
        content: Text(
          'Your KYC application has been submitted successfully. We will review your documents and update the status within 2-3 business days.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          PrimaryButton(
            text: 'Continue',
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _onBackPressed([bool showConfirmation = true]) {
    if (_isSubmitting) return;
    
    if (showConfirmation) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Exit KYC Application?'),
          content: Text(
            'Your progress will be saved automatically. You can continue later from where you left off.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            PrimaryButton(
              text: 'Exit',
              onPressed: () {
                Navigator.pop(context); // Pop the dialog first
                
                // Use GoRouter to safely navigate back to profile
                context.go('/profile');
              },
            ),
          ],
        ),
      );
    } else {
      // Direct navigation for system back button
      context.go('/profile');
    }
  }

  void _showBackConfirmationDialog() {
    if (_isSubmitting) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Exit KYC Application?'),
        content: Text(
          'Your progress will be saved automatically. You can continue later from where you left off.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          PrimaryButton(
            text: 'Exit',
            onPressed: () {
              Navigator.pop(context); // Pop the dialog first
              context.go('/profile');
            },
          ),
        ],
      ),
    );
  }

  void _navigateToStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < _kycSteps.length) {
      _currentStep = stepIndex;
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
} 