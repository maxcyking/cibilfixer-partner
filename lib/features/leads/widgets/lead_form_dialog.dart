import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/buttons/secondary_button.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../services/leads_service.dart';
import '../../../services/kyc_service.dart';
import '../../../core/utils/responsive_utils.dart';

class LeadFormDialog extends StatefulWidget {
  final VoidCallback? onLeadCreated;

  const LeadFormDialog({
    super.key,
    this.onLeadCreated,
  });

  @override
  State<LeadFormDialog> createState() => _LeadFormDialogState();
}

class _LeadFormDialogState extends State<LeadFormDialog>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final LeadsService _leadsService = LeadsService();
  final KycService _kycService = KycService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentStep = 0;
  bool _isLoading = false;
  String? _generatedCustomerId;
  String _panValidationError = '';
  
  // Form data
  final Map<String, dynamic> _formData = {
    // Step 1 - Personal Details
    'issue': '',
    'otherIssue': '',
    'fullName': '',
    'fatherName': '',
    'dob': '',
    'gender': '',
    'mobile': '',
    'pan': '',
    'aadhar': '',
    
    // Step 2 - Address & Documents
    'address': '',
    'village': '',
    'tehsilCity': '',
    'district': '',
    'state': '',
    'pin': '',
    'documents': <String, File>{},
    'referralCode': '',
    'remark': '',
    
    // Step 3 - Payment
    'transactionId': '',
  };
  
  // Form keys for validation
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();
  
  // Controllers
  final Map<String, TextEditingController> _controllers = {};
  
  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Personal Details',
      'icon': Icons.person,
      'description': 'Basic information about the applicant',
    },
    {
      'title': 'Address & Documents',
      'icon': Icons.location_on,
      'description': 'Address details and document upload',
    },
    {
      'title': 'Payment',
      'icon': Icons.payment,
      'description': 'Payment confirmation',
    },
  ];
  
  // Upload progress tracking
  final Map<String, double> _uploadProgress = {};
  bool _isUploading = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeControllers();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }
  
  void _initializeControllers() {
    final fields = [
      'issue', 'otherIssue', 'fullName', 'fatherName', 'dob', 'gender', 'mobile', 'pan', 'aadhar',
      'address', 'village', 'tehsilCity', 'district', 'state', 'pin', 'referralCode', 'remark',
      'transactionId',
    ];
    
    for (final field in fields) {
      _controllers[field] = TextEditingController();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      if (_validateCurrentStep()) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _animationController.reset();
        _animationController.forward();
      }
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _animationController.reset();
      _animationController.forward();
    }
  }
  
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        // Check form validation and PAN validation
        final formValid = _step1FormKey.currentState?.validate() ?? false;
        final panValid = _panValidationError.isEmpty && _controllers['pan']?.text.length == 10;
        
        if (!panValid && _panValidationError.isEmpty) {
          setState(() {
            _panValidationError = 'PAN number is required';
          });
        }
        
        return formValid && panValid;
      case 1:
        return _step2FormKey.currentState?.validate() ?? false;
      case 2:
        return _step3FormKey.currentState?.validate() ?? false;
      default:
        return false;
    }
  }
  
  Future<void> _submitForm() async {
    if (!_validateCurrentStep()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Generate unique random customer ID
      final customerId = await _generateUniqueCustomerId();
      
      // Store all form data
      for (final entry in _controllers.entries) {
        _formData[entry.key] = entry.value.text;
      }
      
      // Upload documents
      final documentUrls = await _uploadDocuments();
      
      // Prepare lead data
      final leadData = {
        ..._formData,
        'customerId': customerId,
        'documents': documentUrls,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      // Create lead
      final success = await _leadsService.createLead(leadData);
      
      if (success) {
        setState(() => _generatedCustomerId = customerId);
        _showSuccessDialog();
        if (widget.onLeadCreated != null) {
          widget.onLeadCreated!();
        }
      } else {
        _showErrorDialog('Failed to create lead. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Error creating lead: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  String _generateCustomerId() {
    // Generate CRM ID in format: CRM + 10 random digits
    final random = Random();
    final randomNumber = random.nextInt(10000000000); // 10 billion max
    final paddedNumber = randomNumber.toString().padLeft(10, '0');
    return 'CRM$paddedNumber';
  }
  
  Future<String> _generateUniqueCustomerId() async {
    try {
      String customerId;
      bool isUnique = false;
      int attempts = 0;
      const maxAttempts = 10;
      
      do {
        customerId = _generateCustomerId();
        attempts++;
        
        // Check if this ID already exists in the database
        final existingLead = await FirebaseFirestore.instance
            .collection('creditRequests')
            .where('customerId', isEqualTo: customerId)
            .limit(1)
            .get();
            
        final existingCustomer = await FirebaseFirestore.instance
            .collection('customers')
            .where('customerId', isEqualTo: customerId)
            .limit(1)
            .get();
            
        isUnique = existingLead.docs.isEmpty && existingCustomer.docs.isEmpty;
        
      } while (!isUnique && attempts < maxAttempts);
      
      if (!isUnique) {
        // If we couldn't generate a unique ID after max attempts, use timestamp fallback
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final numericPart = timestamp.substring(timestamp.length - 10);
        customerId = 'CRM$numericPart';
      }
      
      return customerId;
    } catch (e) {
      print('Error generating unique customer ID: $e');
      // Fallback to simple random generation
      return _generateCustomerId();
    }
  }
  
  Future<Map<String, String>> _uploadDocuments() async {
    final documentUrls = <String, String>{};
    final documents = _formData['documents'] as Map<String, File>;
    
    if (documents.isEmpty) return documentUrls;
    
    setState(() {
      _isUploading = true;
      _uploadProgress.clear();
    });
    
    // Generate a unique customer ID for storage path
    final customerId = await _generateUniqueCustomerId();
    
    for (final entry in documents.entries) {
      try {
        final url = await _kycService.uploadDocument(
          userId: customerId,
          stepId: 'lead_documents',
          documentType: entry.key,
          file: entry.value,
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _uploadProgress[entry.key] = progress;
              });
            }
          },
        );
        
        if (url != null) {
          documentUrls[entry.key] = url;
          debugPrint('✅ Successfully uploaded ${entry.key}: $url');
        }
      } catch (e) {
        debugPrint('❌ Error uploading ${entry.key}: $e');
        // Continue with other uploads even if one fails
      }
    }
    
    setState(() {
      _isUploading = false;
      _uploadProgress.clear();
    });
    
    return documentUrls;
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lead created successfully!'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer ID:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _generatedCustomerId ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PrimaryButton(
            text: 'Close',
            onPressed: () {
              Navigator.of(context).pop(); // Close success dialog
              Navigator.of(context).pop(); // Close form dialog
            },
          ),
        ],
      ),
    );
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          SecondaryButton(
            text: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _steps[_currentStep]['icon'],
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Lead',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _steps[_currentStep]['description'],
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: List.generate(_steps.length, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isActive
                              ? (isCompleted ? Colors.green : AppColors.primary)
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check
                              : _steps[index]['icon'],
                          color: isActive ? Colors.white : Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _steps[index]['title'],
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isActive
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (index < _steps.length - 1)
                  Container(
                    width: 40,
                    height: 2,
                    color: isCompleted ? Colors.green : Colors.grey.shade300,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildStep1() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _step1FormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Details',
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 24),
                
                // Issue Type
                _buildDropdownField(
                  'issue',
                  'Issue Type',
                  ['LOW SCORE', 'WRITE OFF', 'SETTLEMENT', 'OTHER ISSUE'],
                  Icons.report_problem,
                ),
                const SizedBox(height: 16),
                
                // Other Issue Text Field (shows when OTHER ISSUE is selected)
                if (_controllers['issue']?.text == 'OTHER ISSUE') ...[
                  _buildTextField(
                    'otherIssue',
                    'Please describe your issue',
                    Icons.description,
                    maxLines: 3,
                    validator: (value) {
                      if (_controllers['issue']?.text == 'OTHER ISSUE' && (value?.isEmpty ?? true)) {
                        return 'Please describe your issue';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Full Name
                _buildTextField(
                  'fullName',
                  'Full Name',
                  Icons.person,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Full name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Father's Name
                _buildTextField(
                  'fatherName',
                  "Father's Name",
                  Icons.person_outline,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return "Father's name is required";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Date of Birth
                _buildDateField(
                  'dob',
                  'Date of Birth',
                  Icons.calendar_today,
                ),
                const SizedBox(height: 16),
                
                // Gender
                _buildDropdownField(
                  'gender',
                  'Gender',
                  ['Male', 'Female', 'Other'],
                  Icons.person,
                ),
                const SizedBox(height: 16),
                
                // Mobile
                _buildTextField(
                  'mobile',
                  'Mobile Number',
                  Icons.phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Mobile number is required';
                    if (value!.length != 10) return 'Mobile number must be 10 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // PAN
                _buildPanField(
                  'pan',
                  'PAN Number',
                  Icons.credit_card,
                ),
                const SizedBox(height: 16),
                
                // Aadhar
                _buildTextField(
                  'aadhar',
                  'Aadhar Number',
                  Icons.badge,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Aadhar number is required';
                    if (value!.length != 12) return 'Aadhar number must be 12 digits';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStep2() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _step2FormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Address & Documents',
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 24),
                
                // Address
                _buildTextField(
                  'address',
                  'Address',
                  Icons.location_on,
                  maxLines: 3,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Address is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Village
                _buildTextField(
                  'village',
                  'Village',
                  Icons.location_city,
                ),
                const SizedBox(height: 16),
                
                // Tehsil/City
                _buildTextField(
                  'tehsilCity',
                  'Tehsil/City',
                  Icons.location_city,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Tehsil/City is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // District
                _buildTextField(
                  'district',
                  'District',
                  Icons.map,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'District is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // State
                _buildTextField(
                  'state',
                  'State',
                  Icons.map,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'State is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // PIN
                _buildTextField(
                  'pin',
                  'PIN Code',
                  Icons.pin_drop,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'PIN code is required';
                    if (value!.length != 6) return 'PIN code must be 6 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Documents Section
                Text(
                  'Documents',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 16),
                
                _buildDocumentUpload(),
                const SizedBox(height: 24),
                
                // Referral Code
                _buildTextField(
                  'referralCode',
                  'Referral Code (Optional)',
                  Icons.card_giftcard,
                ),
                const SizedBox(height: 16),
                
                // Remark
                _buildTextField(
                  'remark',
                  'Remark (Optional)',
                  Icons.note,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStep3() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _step3FormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment',
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 24),
                
                // Payment Info Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.payment,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Payment Information',
                            style: AppTextStyles.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Text(
                          'Please make the payment using the QR code below or UPI ID and enter the transaction ID to complete your request.',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'UPI ID:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'rameshwar@paytm',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () {
                                    // Copy UPI ID to clipboard
                                    Clipboard.setData(const ClipboardData(text: 'rameshwar@paytm'));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('UPI ID copied to clipboard'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 20),
                                  tooltip: 'Copy UPI ID',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Amount: ₹999',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.yellow.shade200),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Important:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '• Make sure to save the transaction ID after payment\n'
                              '• Enter the exact transaction ID as shown in your payment app\n'
                              '• Your request will be processed after payment verification',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Transaction ID
                _buildTextField(
                  'transactionId',
                  'Transaction ID',
                  Icons.receipt,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Transaction ID is required';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Summary Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: AppTextStyles.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow('Full Name', _controllers['fullName']?.text ?? ''),
                      _buildSummaryRow('Mobile', _controllers['mobile']?.text ?? ''),
                      _buildSummaryRow('Issue', _controllers['issue']?.text ?? ''),
                      _buildSummaryRow('District', _controllers['district']?.text ?? ''),
                      _buildSummaryRow('State', _controllers['state']?.text ?? ''),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextField(
    String key,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: _controllers[key],
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
  
  Widget _buildDropdownField(
    String key,
    String label,
    List<String> options,
    IconData icon,
  ) {
    return DropdownButtonFormField<String>(
      value: _controllers[key]?.text.isEmpty ?? true ? null : _controllers[key]?.text,
      onChanged: (value) {
        _controllers[key]?.text = value ?? '';
        // Trigger rebuild to show/hide conditional fields
        setState(() {});
      },
      validator: (value) {
        if (value?.isEmpty ?? true) return '$label is required';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: options.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
    );
  }
  
  Widget _buildDateField(
    String key,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: _controllers[key],
      readOnly: true,
      validator: (value) {
        if (value?.isEmpty ?? true) return '$label is required';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );
        
        if (date != null) {
          _controllers[key]?.text = DateFormat('yyyy-MM-dd').format(date);
        }
      },
    );
  }
  
  Widget _buildDocumentUpload() {
    final documents = _formData['documents'] as Map<String, File>;
    
    final documentTypes = [
      {'key': 'aadhar', 'label': 'Aadhar Card', 'icon': Icons.credit_card, 'required': true},
      {'key': 'pan', 'label': 'PAN Card', 'icon': Icons.credit_card, 'required': true},
      {'key': 'voterId', 'label': 'Voter ID', 'icon': Icons.how_to_vote, 'required': false},
      {'key': 'dl', 'label': 'Driving License', 'icon': Icons.drive_eta, 'required': false},
      {'key': 'cicReport', 'label': 'CIC Report', 'icon': Icons.description, 'required': false},
      {'key': 'bankDetails', 'label': 'Bank Details', 'icon': Icons.account_balance, 'required': false},
      {'key': 'other', 'label': 'Other Document', 'icon': Icons.attach_file, 'required': false},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Upload Documents',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Optional',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Upload clear photos or PDF copies of your documents',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        
        // Document grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveUtils.isMobile(context) ? 2 : 3,
            crossAxisSpacing: ResponsiveUtils.isMobile(context) ? 8 : 12,
            mainAxisSpacing: ResponsiveUtils.isMobile(context) ? 8 : 12,
            childAspectRatio: ResponsiveUtils.isMobile(context) ? 1.1 : 1.2,
          ),
          itemCount: documentTypes.length,
          itemBuilder: (context, index) {
            final docType = documentTypes[index];
            final key = docType['key'] as String;
            final label = docType['label'] as String;
            final icon = docType['icon'] as IconData;
            final isRequired = docType['required'] as bool;
            final hasFile = documents.containsKey(key);
            final file = documents[key];
            
            return _buildDocumentCard(
              key: key,
              label: label,
              icon: icon,
              isRequired: isRequired,
              hasFile: hasFile,
              file: file,
            );
          },
        ),
        
        if (documents.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${documents.length} document(s) ready for upload',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentCard({
    required String key,
    required String label,
    required IconData icon,
    required bool isRequired,
    required bool hasFile,
    File? file,
  }) {
    return InkWell(
      onTap: () => _pickDocument(key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasFile ? Colors.green.shade300 : Colors.grey.shade300,
            width: hasFile ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: hasFile ? Colors.green.shade50 : Colors.grey.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon and status
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasFile ? Colors.green.shade100 : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: hasFile ? Colors.green.shade600 : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                if (hasFile)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasFile ? Colors.green.shade800 : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Required badge
            if (isRequired) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Required',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            
            // File name
            if (hasFile && file != null) ...[
              const SizedBox(height: 4),
              Text(
                file.path.split('/').last,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            // Upload instruction
            if (!hasFile) ...[
              const SizedBox(height: 4),
              Text(
                'Tap to upload',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => _removeDocument(key),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete,
                        size: 12,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickDocument(String key) async {
    try {
      // Show file type selection dialog
      final fileType = await _showFileTypeDialog();
      if (fileType == null) return;
      
      File? selectedFile;
      
      if (fileType == 'image') {
        final ImagePicker picker = ImagePicker();
        final XFile? xFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        if (xFile != null) {
          selectedFile = File(xFile.path);
        }
      } else if (fileType == 'camera') {
        final ImagePicker picker = ImagePicker();
        final XFile? xFile = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        if (xFile != null) {
          selectedFile = File(xFile.path);
        }
      } else if (fileType == 'pdf') {
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          allowMultiple: false,
        );
        
        if (result != null && result.files.isNotEmpty) {
          selectedFile = File(result.files.first.path!);
        }
      }
      
      if (selectedFile != null) {
        // Validate file size (max 10MB)
        final fileSizeInBytes = selectedFile.lengthSync();
        const maxSizeInBytes = 10 * 1024 * 1024; // 10MB
        
        if (fileSizeInBytes > maxSizeInBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 10MB'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
        
        // Store the file
        final documents = _formData['documents'] as Map<String, File>;
        documents[key] = selectedFile;
        setState(() {});
        
        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getDocumentLabel(key)} selected successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Error selecting document: $e');
    }
  }

  Future<String?> _showFileTypeDialog() async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select File Type',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primary600),
                title: const Text('Choose Image from Gallery'),
                subtitle: const Text('JPEG, PNG'),
                onTap: () => Navigator.of(context).pop('image'),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primary600),
                title: const Text('Take Photo'),
                subtitle: const Text('Camera'),
                onTap: () => Navigator.of(context).pop('camera'),
              ),
              ListTile(
                leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Choose PDF Document'),
                subtitle: const Text('PDF files only'),
                onTap: () => Navigator.of(context).pop('pdf'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  String _getDocumentLabel(String key) {
    switch (key) {
      case 'aadhar':
        return 'Aadhar Card';
      case 'pan':
        return 'PAN Card';
      case 'voterId':
        return 'Voter ID';
      case 'dl':
        return 'Driving License';
      case 'cicReport':
        return 'CIC Report';
      case 'bankDetails':
        return 'Bank Details';
      case 'other':
        return 'Other Document';
      default:
        return 'Document';
    }
  }
  
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upload progress indicator
          if (_isUploading) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Uploading documents...',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (_uploadProgress.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._uploadProgress.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getDocumentLabel(entry.key),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            '${(entry.value * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Navigation buttons
          Row(
            children: [
              if (_currentStep > 0) ...[
                SecondaryButton(
                  text: 'Previous',
                  onPressed: _previousStep,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: PrimaryButton(
                  text: _currentStep == _steps.length - 1 ? 'Create Lead' : 'Next',
                  onPressed: (_isLoading || _isUploading) ? null : (_currentStep == _steps.length - 1 ? _submitForm : _nextStep),
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPanField(
    String key,
    String label,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: Colors.grey.shade600),
              ),
              Expanded(
                child: TextFormField(
                  controller: _controllers[key],
                  decoration: InputDecoration(
                    hintText: 'ABCDE1234F',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontFamily: 'monospace',
                    ),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLength: 10,
                  keyboardType: _getPanKeyboardType(_controllers[key]?.text ?? ''),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    PanInputFormatter(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _validatePan(value);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        // Format helper text
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Format: ABCDE1234F (5 letters + 4 digits + 1 letter)',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        // Validation error display
        if (_panValidationError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _panValidationError,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  TextInputType _getPanKeyboardType(String currentValue) {
    final length = currentValue.length;
    
    if (length < 5) {
      // First 5 characters should be letters
      return TextInputType.text;
    } else if (length < 9) {
      // Next 4 characters should be digits
      return TextInputType.number;
    } else {
      // Last character should be letter
      return TextInputType.text;
    }
  }

  void _validatePan(String value) {
    if (value.isEmpty) {
      _panValidationError = '';
      return;
    }

    // PAN format: ABCDE1234F
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    
    if (value.length == 10) {
      if (panRegex.hasMatch(value)) {
        _panValidationError = '';
      } else {
        _panValidationError = 'Invalid PAN format';
      }
    } else {
      // Show current progress
      final expectedFormat = 'ABCDE1234F';
      final currentFormat = value.padRight(10, '_');
      _panValidationError = 'Expected: $expectedFormat\nCurrent:  $currentFormat';
    }
  }

  void _removeDocument(String key) {
    final documents = _formData['documents'] as Map<String, File>;
    documents.remove(key);
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_getDocumentLabel(key)} removed'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Custom PAN Input Formatter
class PanInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase();
    final length = text.length;
    
    // Don't allow more than 10 characters
    if (length > 10) {
      return oldValue;
    }
    
    // Validate each character based on position
    for (int i = 0; i < length; i++) {
      final char = text[i];
      
      if (i < 5) {
        // First 5 characters must be letters
        if (!RegExp(r'[A-Z]').hasMatch(char)) {
          return oldValue;
        }
      } else if (i < 9) {
        // Next 4 characters must be digits
        if (!RegExp(r'[0-9]').hasMatch(char)) {
          return oldValue;
        }
      } else {
        // Last character must be letter
        if (!RegExp(r'[A-Z]').hasMatch(char)) {
          return oldValue;
        }
      }
    }
    
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
} 