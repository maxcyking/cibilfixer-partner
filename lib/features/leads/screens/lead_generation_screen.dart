import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/buttons/secondary_button.dart';
import '../../../services/leads_service.dart';
import '../../../services/kyc_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/responsive_utils.dart';

// Custom PAN formatter to enforce XXXXX####X format
class PanTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.toUpperCase();
    
    // Remove any invalid characters
    String cleanText = '';
    for (int i = 0; i < newText.length && i < 10; i++) {
      if (i < 5) {
        // First 5 characters should be letters
        if (RegExp(r'[A-Z]').hasMatch(newText[i])) {
          cleanText += newText[i];
        }
      } else if (i < 9) {
        // Next 4 characters should be digits
        if (RegExp(r'[0-9]').hasMatch(newText[i])) {
          cleanText += newText[i];
        }
      } else {
        // Last character should be a letter
        if (RegExp(r'[A-Z]').hasMatch(newText[i])) {
          cleanText += newText[i];
        }
      }
    }
    
    return TextEditingValue(
      text: cleanText,
      selection: TextSelection.collapsed(offset: cleanText.length),
    );
  }
}

class LeadGenerationScreen extends StatefulWidget {
  const LeadGenerationScreen({super.key});

  @override
  State<LeadGenerationScreen> createState() => _LeadGenerationScreenState();
}

class _LeadGenerationScreenState extends State<LeadGenerationScreen>
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
  String? _generatedTrackingLink;
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
    
    // Step 2 - Address & Contact
    'address': '',
    'village': '',
    'tehsilCity': '',
    'district': '',
    'state': '',
    'pin': '',
    'remark': '',
    
    // Step 3 - Documents
    'documents': <String, dynamic>{},
    'documentNames': <String, String>{},
    'referralCode': '',
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
      'icon': Icons.person_outline,
      'description': 'Basic information',
      'color': Color(0xFF6366F1),
    },
    {
      'title': 'Address & Contact',
      'icon': Icons.location_on_outlined,
      'description': 'Location details',
      'color': Color(0xFF8B5CF6),
    },
    {
      'title': 'Documents',
      'icon': Icons.upload_file_outlined,
      'description': 'Upload documents',
      'color': Color(0xFF06B6D4),
    },
    {
      'title': 'Confirmation',
      'icon': Icons.check_circle_outline,
      'description': 'Lead created',
      'color': Color(0xFF10B981),
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
    _loadUserReferralCode();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  void _initializeControllers() {
    final fields = [
      'issue', 'otherIssue', 'fullName', 'fatherName', 'dob', 'gender',
      'mobile', 'pan', 'aadhar', 'address', 'village', 'tehsilCity',
      'district', 'state', 'pin', 'remark', 'referralCode'
    ];
    
    for (final field in fields) {
      _controllers[field] = TextEditingController();
    }
  }

  Future<void> _loadUserReferralCode() async {
    try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userReferralCode = authProvider.userData?['myReferralCode'] ?? '';
    
    if (userReferralCode.isNotEmpty) {
      _controllers['referralCode']?.text = userReferralCode;
      _formData['referralCode'] = userReferralCode;
      }
    } catch (e) {
      print('Error loading user referral code: $e');
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
      if (_validateCurrentStep()) {
      if (_currentStep < _steps.length - 1) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        
        // Restart animation for new step
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
      
      // Restart animation for previous step
      _animationController.reset();
      _animationController.forward();
    }
  }

  bool _validateCurrentStep() {
    print('🔍 Validating step $_currentStep');
    
    switch (_currentStep) {
      case 0:
        // Step 1: Personal Details validation
        final formValid = _step1FormKey.currentState?.validate() ?? false;
        final panValid = _panValidationError.isEmpty && _controllers['pan']?.text.length == 10;
        
        if (!panValid && _panValidationError.isEmpty) {
          setState(() {
            _panValidationError = 'PAN number must be 10 characters';
          });
        }
        
        print('  Step 1 validation: form=$formValid, pan=$panValid');
        return formValid && panValid;
        
      case 1:
        // Step 2: Address & Contact validation
        final formValid = _step2FormKey.currentState?.validate() ?? false;
        print('  Step 2 validation: form=$formValid');
        return formValid;
        
      case 2:
        // Step 3: Documents validation (optional for now)
        print('  Step 3 validation: documents can be optional');
        return true;
        
      default:
        return false;
    }
  }

  // Helper methods for form field building
  Widget _buildPanTextField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  const Color(0xFFF8FAFC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: _controllers['pan'],
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(10),
                PanTextInputFormatter(),
              ],
              onChanged: (value) {
                // Clear PAN validation error when user types correctly
                if (value.length == 10) {
                  final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
                  if (panRegex.hasMatch(value)) {
                    setState(() {
                      _panValidationError = '';
                    });
                  } else {
                    setState(() {
                      _panValidationError = 'Invalid PAN format';
                    });
                  }
                } else {
                  setState(() {
                    _panValidationError = '';
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'PAN number is required';
                }
                if (value.length != 10) {
                  return 'PAN number must be 10 characters';
                }
                // Validate PAN format: XXXXX####X (5 letters, 4 digits, 1 letter)
                final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
                if (!panRegex.hasMatch(value)) {
                  return 'Invalid PAN format. Use XXXXX####X format';
                }
                return null;
              },
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                labelText: 'PAN Number',
                hintText: 'ABCDE1234F',
                prefixIcon: Icon(
                  Icons.credit_card,
                  color: const Color(0xFF3B82F6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                filled: true,
                fillColor: Colors.transparent,
              ),
            ),
          ),
          // Format helper text
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  'Format: XXXXX####X (5 letters, 4 digits, 1 letter)',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              const Color(0xFFF8FAFC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextFormField(
          controller: _controllers[key],
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Icon(
                icon, 
                color: const Color(0xFF3B82F6),
                size: 22,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFF3B82F6), 
                width: 2.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFFEF4444), 
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFFEF4444), 
                width: 2.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            filled: true,
            fillColor: Colors.transparent,
          ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              const Color(0xFFF8FAFC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonFormField<String>(
          value: _controllers[key]?.text.isEmpty ?? true ? null : _controllers[key]?.text,
          onChanged: (value) {
            _controllers[key]?.text = value ?? '';
            setState(() {});
          },
          validator: (value) {
            if (value?.isEmpty ?? true) return '$label is required';
            return null;
          },
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Icon(
                icon, 
                color: const Color(0xFF3B82F6),
                size: 22,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFF3B82F6), 
                width: 2.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            filled: true,
            fillColor: Colors.transparent,
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(
                option,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateField(
    String key,
    String label,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              const Color(0xFFF8FAFC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextFormField(
          controller: _controllers[key],
          readOnly: true,
          validator: (value) {
            if (value?.isEmpty ?? true) return '$label is required';
            return null;
          },
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Icon(
                icon, 
                color: const Color(0xFF3B82F6),
                size: 22,
              ),
            ),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: const Color(0xFF3B82F6),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFF3B82F6), 
                width: 2.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            filled: true,
            fillColor: Colors.transparent,
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF3B82F6),
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Color(0xFF1E293B),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            
            if (date != null) {
              _controllers[key]?.text = DateFormat('yyyy-MM-dd').format(date);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPanField(
    String key,
    String label,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.neutral300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: AppColors.primary500),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _controllers[key],
                    decoration: InputDecoration(
                      labelText: label,
                      hintText: 'ABCDE1234F',
                      hintStyle: TextStyle(
                        color: AppColors.neutral400,
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
                color: AppColors.neutral500,
              ),
            ),
          ),
          // Validation error display
          if (_panValidationError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _panValidationError,
                style: TextStyle(
                  color: AppColors.error500,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
          child: Column(
            children: [
            // Modern Step Progress Indicator
            _buildStepProgressIndicator(),
            
            // Form Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                  _buildStep1PersonalDetails(),
                  _buildStep2AddressContact(),
                  _buildStep3Documents(),
                  _buildStep4Confirmation(),
                  ],
                ),
              ),
            
            // Navigation Buttons
            _buildNavigationButtons(),
            ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A), // Deep blue
            const Color(0xFF3B82F6), // Blue
            const Color(0xFF60A5FA), // Light blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              _currentStep < 3 ? _steps[_currentStep]['icon'] : Icons.check_circle,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  child: const Text('Generate New Lead'),
                ),
                const SizedBox(height: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.2,
                  ),
                  child: Text(
                    _currentStep < 3 ? _steps[_currentStep]['description'] : 'Lead generated successfully',
                  ),
                ),
              ],
            ),
          ),
          if (_currentStep < 3)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(_steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          final stepColor = _steps[index]['color'] as Color;
          
          return Expanded(
            child: Row(
              children: [
                // Step Circle
                Container(
                  width: 40,
                  height: 40,
                        decoration: BoxDecoration(
                    color: isCompleted || isActive ? stepColor : Colors.grey.shade300,
                          shape: BoxShape.circle,
                          boxShadow: isActive ? [
                            BoxShadow(
                        color: stepColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      )
                      ] : null,
                    ),
                      child: Icon(
                    isCompleted ? Icons.check : _steps[index]['icon'],
                    color: isCompleted || isActive ? Colors.white : Colors.grey.shade600,
                    size: 20,
                  ),
                ),
                
                // Step Info
                if (ResponsiveUtils.isDesktop(context)) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                      _steps[index]['title'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                            color: isActive ? stepColor : Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          _steps[index]['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
                ],
                
                // Connector Line
                if (index < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: index < _currentStep ? stepColor : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(1),
                      ),
                ),
              ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1PersonalDetails() {
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
                // Step Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1).withOpacity(0.1),
                        const Color(0xFF8B5CF6).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: const Color(0xFF6366F1),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Personal Details',
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Issue Type
                _buildDropdownField(
                  'issue',
                  'Issue Type',
                  ['CIBIL Report', 'Credit Score', 'Loan Application', 'Other'],
                  Icons.help_outline,
                ),
                
                // Other Issue (if selected)
                if (_formData['issue'] == 'Other')
                  _buildTextField(
                    'otherIssue',
                    'Please specify the issue',
                    Icons.description,
                    validator: (value) {
                      if (_formData['issue'] == 'Other' && (value == null || value.isEmpty)) {
                        return 'Please specify the issue';
                      }
                      return null;
                    },
                  ),
                
                // Personal Information
                _buildTextField(
                  'fullName',
                  'Full Name',
                  Icons.person,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                
                _buildTextField(
                  'fatherName',
                  'Father\'s Name',
                  Icons.person,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Father\'s name is required';
                    }
                    return null;
                  },
                ),
                
                // Date of Birth
                _buildDateField(
                  'dob',
                  'Date of Birth',
                  Icons.calendar_today,
                ),
                
                // Gender
                _buildDropdownField(
                  'gender',
                  'Gender',
                  ['Male', 'Female', 'Other'],
                  Icons.person_outline,
                ),
                
                // Mobile Number
                _buildTextField(
                  'mobile',
                  'Mobile Number (10 digits)',
                  Icons.phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mobile number is required';
                    }
                    if (value.length != 10) {
                      return 'Mobile number must be exactly 10 digits';
                    }
                    // Validate mobile number format (should start with 6-9)
                    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
                      return 'Invalid mobile number format';
                    }
                    return null;
                  },
                ),
                
                // PAN Number
                _buildPanTextField(),
                
                // Show PAN validation error
                if (_panValidationError.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _panValidationError,
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Aadhar Number
                _buildTextField(
                  'aadhar',
                  'Aadhar Number',
                  Icons.credit_card,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Aadhar number is required';
                    }
                    if (value.length != 12) {
                      return 'Aadhar number must be 12 digits';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2AddressContact() {
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
                // Step Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8B5CF6).withOpacity(0.1),
                        const Color(0xFF06B6D4).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: const Color(0xFF8B5CF6),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                Text(
                        'Address & Contact',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Address
                _buildTextField(
                  'address',
                  'Full Address',
                  Icons.home,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Address is required';
                    }
                    return null;
                  },
                ),
                
                // Village
                _buildTextField(
                  'village',
                  'Village',
                  Icons.location_city,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Village is required';
                    }
                    return null;
                  },
                ),
                
                // Tehsil/City
                _buildTextField(
                  'tehsilCity',
                  'Tehsil/City',
                  Icons.location_city,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tehsil/City is required';
                    }
                    return null;
                  },
                ),
                
                // District
                _buildTextField(
                  'district',
                  'District',
                  Icons.location_city,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'District is required';
                    }
                    return null;
                  },
                ),
                
                // State
                _buildTextField(
                  'state',
                  'State',
                  Icons.map,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'State is required';
                    }
                    return null;
                  },
                ),
                
                // PIN Code
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
                    if (value == null || value.isEmpty) {
                      return 'PIN code is required';
                    }
                    if (value.length != 6) {
                      return 'PIN code must be 6 digits';
                    }
                    return null;
                  },
                ),
                
                // Remark
                _buildTextField(
                  'remark',
                  'Remark (Optional)',
                  Icons.notes,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep3Documents() {
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
                // Step Header
                          Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF06B6D4).withOpacity(0.1),
                        const Color(0xFF10B981).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF06B6D4).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.upload_file_outlined,
                        color: const Color(0xFF06B6D4),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Documents',
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                ),
                const SizedBox(height: 24),
                
                // Document Upload Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Document Upload Guidelines',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                                color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                              'Upload clear photos or PDF copies of your documents. Supported formats: JPG, PNG, PDF',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Document Upload Section
                _buildDocumentUpload(),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep4Confirmation() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              
              // Success Message
              Text(
                'Lead Created Successfully!',
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                'Your lead has been submitted and is being processed',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Customer ID Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          color: const Color(0xFF3B82F6),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Customer ID',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Customer ID Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _generatedCustomerId ?? 'Loading...',
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3B82F6),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.copy_rounded,
                              color: const Color(0xFF3B82F6),
                            ),
                            onPressed: _generatedCustomerId != null
                                ? () {
                                    Clipboard.setData(
                                      ClipboardData(text: _generatedCustomerId!),
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                        content: const Text(
                                          'Customer ID copied to clipboard!'
                                        ),
                                        backgroundColor: const Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                  ),
                                );
                              }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: 'Create Another Lead',
                      onPressed: () {
                        // Reset form
                        setState(() {
                          _currentStep = 0;
                          _generatedCustomerId = null;
                          _generatedTrackingLink = null;
                          _panValidationError = '';
                          _formData.clear();
                          _formData.addAll({
                            'issue': '',
                            'otherIssue': '',
                            'fullName': '',
                            'fatherName': '',
                            'dob': '',
                            'gender': '',
                            'mobile': '',
                            'pan': '',
                            'aadhar': '',
                            'address': '',
                            'village': '',
                            'tehsilCity': '',
                            'district': '',
                            'state': '',
                            'pin': '',
                            'remark': '',
                            'documents': <String, dynamic>{},
                            'documentNames': <String, String>{},
                            'referralCode': '',
                          });
                        });
                        
                        // Clear controllers
                          for (final controller in _controllers.values) {
                            controller.clear();
                          }
                        
                        // Go back to first step
                        _pageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        
                        // Load referral code again
                        _loadUserReferralCode();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Done',
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    if (_currentStep == 3) {
      return const SizedBox.shrink(); // No navigation buttons on confirmation screen
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
                      child: Row(
                        children: [
          // Previous Button
          if (_currentStep > 0)
                          Expanded(
              child: SecondaryButton(
                text: 'Previous',
                onPressed: _previousStep,
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 16),
          
          // Next/Submit Button
                Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: PrimaryButton(
              text: _currentStep == 2 ? 'Create Lead' : 'Next',
                    onPressed: (_isLoading || _isUploading) 
                        ? null 
                        : (_currentStep == 2 ? _submitForm : _nextStep),
              isLoading: _isLoading || _isUploading,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
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

  Widget _buildDocumentUpload() {
    final documents = _formData['documents'] as Map<String, dynamic>;
    
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
              color: AppColors.success50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${documents.length} document(s) ready for upload',
                  style: TextStyle(
                    color: AppColors.success700,
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
    dynamic file,
  }) {
    return InkWell(
      onTap: () => _pickDocument(key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasFile ? AppColors.success300 : AppColors.neutral300,
            width: hasFile ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: hasFile ? AppColors.success50 : AppColors.neutral50,
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
                    color: hasFile ? AppColors.success100 : AppColors.neutral200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: hasFile ? AppColors.success600 : AppColors.neutral600,
                    size: 24,
                  ),
                ),
                if (hasFile)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.success500,
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
                color: hasFile ? AppColors.success800 : AppColors.neutral700,
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
                  color: AppColors.error100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Required',
                  style: TextStyle(
                    fontSize: 8,
                    color: AppColors.error700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            
            // File name
            if (hasFile && file != null) ...[
              const SizedBox(height: 4),
              Text(
                _getFileName(key),
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.success600,
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
                  color: AppColors.neutral500,
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
                        color: AppColors.error100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete,
                        size: 12,
                        color: AppColors.error600,
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
      
      dynamic selectedFile;
      String fileName = '';
      int fileSizeInBytes = 0;
      
      if (kIsWeb) {
        // Web platform handling
        if (fileType == 'pdf') {
          final FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            allowMultiple: false,
            withData: true, // Important for web - get bytes
          );
          
          if (result != null && result.files.isNotEmpty) {
            final pickedFile = result.files.first;
            selectedFile = pickedFile.bytes;
            fileName = pickedFile.name;
            fileSizeInBytes = pickedFile.size;
          }
        } else if (fileType == 'image') {
          final FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: false,
            withData: true, // Important for web - get bytes
          );
          
          if (result != null && result.files.isNotEmpty) {
            final pickedFile = result.files.first;
            selectedFile = pickedFile.bytes;
            fileName = pickedFile.name;
            fileSizeInBytes = pickedFile.size;
          }
        } else if (fileType == 'camera') {
          // Camera not available on web, fallback to image picker
          final FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: false,
            withData: true,
          );
          
          if (result != null && result.files.isNotEmpty) {
            final pickedFile = result.files.first;
            selectedFile = pickedFile.bytes;
            fileName = pickedFile.name;
            fileSizeInBytes = pickedFile.size;
          }
        }
      } else {
        // Mobile platform handling
        if (fileType == 'image') {
          final ImagePicker picker = ImagePicker();
          final XFile? xFile = await picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1024,
            maxHeight: 1024,
          );
          if (xFile != null) {
            selectedFile = File(xFile.path);
            fileName = xFile.name;
            fileSizeInBytes = await selectedFile.length();
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
            fileName = xFile.name;
            fileSizeInBytes = await selectedFile.length();
          }
        } else if (fileType == 'pdf') {
          final FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            allowMultiple: false,
          );
          
          if (result != null && result.files.isNotEmpty) {
            final pickedFile = result.files.first;
            selectedFile = File(pickedFile.path!);
            fileName = pickedFile.name;
            fileSizeInBytes = pickedFile.size;
          }
        }
      }
      
      if (selectedFile != null) {
        // Validate file size (max 10MB)
        const maxSizeInBytes = 10 * 1024 * 1024; // 10MB
        
        if (fileSizeInBytes > maxSizeInBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File size must be less than 10MB'),
                backgroundColor: AppColors.error500,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
        
        // Store the file and file name
        final documents = _formData['documents'] as Map<String, dynamic>;
        final documentNames = _formData['documentNames'] as Map<String, String>;
        documents[key] = selectedFile;
        documentNames[key] = fileName;
        setState(() {});
        
        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getDocumentLabel(key)} selected successfully'),
              backgroundColor: AppColors.success500,
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
                leading: Icon(Icons.picture_as_pdf, color: AppColors.error500),
                title: const Text('Choose PDF Document'),
                subtitle: const Text('PDF files only'),
                onTap: () => Navigator.of(context).pop('pdf'),
              ),
            ],
          ),
          actions: [
            SecondaryButton(
              text: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
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

  void _removeDocument(String key) {
    final documents = _formData['documents'] as Map<String, dynamic>;
    final documentNames = _formData['documentNames'] as Map<String, String>;
    documents.remove(key);
    documentNames.remove(key);
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_getDocumentLabel(key)} removed'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_validateCurrentStep()) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('🚀 Starting lead submission process...');
      
      // Generate unique random customer ID
      print('📝 Step 1: Generating unique customer ID...');
      final customerId = await _generateUniqueCustomerId();
      print('✅ Generated customer ID: $customerId');
      
      // Store all form data
      print('📝 Step 2: Collecting form data...');
      for (final entry in _controllers.entries) {
        _formData[entry.key] = entry.value.text;
        print('  - ${entry.key}: ${entry.value.text}');
      }
      
      // Verify critical fields are populated
      print('📝 Step 2.1: Verifying required fields...');
      final requiredFields = ['fullName', 'mobile', 'pan', 'aadhar'];
      for (final field in requiredFields) {
        final value = _formData[field]?.toString() ?? '';
        if (value.isEmpty) {
          print('❌ Critical field missing: $field');
          _showErrorDialog('Please fill in all required fields. Missing: $field');
          return;
        }
        print('  ✅ $field: $value');
      }
      
      // Upload documents with the same customer ID
      print('📝 Step 3: Uploading documents...');
      final documentUrls = await _uploadDocuments(customerId);
      print('✅ Documents uploaded: ${documentUrls.keys.toList()}');
      
      // Verify documents were uploaded
      print('📝 Step 3.1: Verifying document uploads...');
      if (documentUrls.isEmpty) {
        print('⚠️ No documents uploaded - this might be okay for some leads');
      } else {
        print('✅ ${documentUrls.length} documents uploaded successfully');
        documentUrls.forEach((key, url) {
          print('  - $key: ${url.substring(0, 50)}...');
        });
      }
      
      // Get user referral code
      print('📝 Step 4: Getting referral code...');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userReferralCode = authProvider.userData?['myReferralCode'] ?? '';
      print('✅ Referral code: $userReferralCode');
      
      // Verify referral code
      print('📝 Step 4.1: Verifying referral code...');
      if (userReferralCode.isEmpty) {
        print('⚠️ Warning: No referral code found for user');
        print('  - User authenticated: ${authProvider.isAuthenticated}');
        print('  - User data: ${authProvider.userData}');
      } else {
        print('✅ Valid referral code: $userReferralCode');
      }
      
      // Prepare lead data
      print('📝 Step 5: Preparing lead data...');
      final leadData = {
        ..._formData,
        'customerId': customerId,
        'documents': documentUrls,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'referralCode': userReferralCode,
        'isSeen': false,
      };
      
      // Remove empty documentNames to avoid confusion
      leadData.remove('documentNames');
      
      print('📊 Final lead data:');
      leadData.forEach((key, value) {
        if (key == 'documents') {
          print('  - $key: ${(value as Map).keys.toList()}');
        } else {
          print('  - $key: $value');
        }
      });
      
      // Final validation
      print('📝 Step 5.1: Final lead data validation...');
      if (leadData['customerId'] == null || leadData['customerId'].toString().isEmpty) {
        print('❌ CRITICAL: Customer ID is null or empty!');
        _showErrorDialog('Failed to generate customer ID. Please try again.');
        return;
      }
      
      if (leadData['fullName'] == null || leadData['fullName'].toString().isEmpty) {
        print('❌ CRITICAL: Full name is null or empty!');
        _showErrorDialog('Full name is required. Please check your input.');
        return;
      }
      
      print('✅ Lead data validation passed');
      
      // Create lead
      print('📝 Step 6: Creating lead in database...');
      final success = await _leadsService.createLead(leadData);
      
      if (success) {
        print('✅ Lead created successfully!');
        setState(() {
          _generatedCustomerId = customerId;
          _generatedTrackingLink = _generateTrackingLink(customerId);
          _currentStep++;
        });
        
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        print('❌ Lead creation failed - service returned false');
        _showErrorDialog('Failed to create lead. Please try again.');
      }
    } catch (e) {
      print('❌ Error during lead submission: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      _showErrorDialog('Error creating lead: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateCustomerId() {
    // Generate CRM ID in format: CRM + 8 random digits
    final random = Random();
    final randomNumber = random.nextInt(100000000); // 100 million max (8 digits)
    final paddedNumber = randomNumber.toString().padLeft(8, '0');
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

  String _generateTrackingLink(String customerId) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userReferralCode = authProvider.userData?['myReferralCode'] ?? '';
    return 'https://futurecapital.com/track?lead=$customerId&ref=$userReferralCode';
  }

  Future<Map<String, String>> _uploadDocuments(String customerId) async {
    final documentUrls = <String, String>{};
    final documents = _formData['documents'] as Map<String, dynamic>;
    final documentNames = _formData['documentNames'] as Map<String, String>;
    
    if (documents.isEmpty) return documentUrls;
    
    setState(() {
      _isUploading = true;
      _uploadProgress.clear();
    });
    
    // Use the provided customer ID for storage path
    print('📁 Using customer ID for document storage: $customerId');
    
    for (final entry in documents.entries) {
      try {
        String? url;
        final documentKey = entry.key;
        final documentData = entry.value;
        final fileName = documentNames[documentKey] ?? 'unknown_file';
        
        if (kIsWeb) {
          // For web, we have bytes
          if (documentData is Uint8List) {
            print('🌐 Uploading document bytes for web: ${entry.key}');
            url = await _kycService.uploadDocumentBytes(
              userId: customerId,
              stepId: 'lead_documents',
              documentType: documentKey,
              fileBytes: documentData,
              fileName: fileName,
              onProgress: (progress) {
                if (mounted) {
                  setState(() {
                    _uploadProgress[documentKey] = progress;
                  });
                }
              },
            );
            print('✅ Web document upload completed for ${entry.key}');
          }
        } else {
          // For mobile, we have File objects
          if (documentData is File) {
            url = await _kycService.uploadDocument(
              userId: customerId,
              stepId: 'lead_documents',
              documentType: documentKey,
              file: documentData,
              onProgress: (progress) {
                if (mounted) {
                  setState(() {
                    _uploadProgress[documentKey] = progress;
                  });
                }
              },
            );
          }
        }
        
        if (url != null) {
          documentUrls[documentKey] = url;
          debugPrint('✅ Successfully uploaded $documentKey: $url');
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: AppColors.error500, size: 28),
            const SizedBox(width: 12),
            const Text('Error'),
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

  void _copyTrackingLink() {
    if (_generatedTrackingLink != null) {
      Clipboard.setData(ClipboardData(text: _generatedTrackingLink!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Tracking link copied to clipboard!'),
            ],
          ),
          backgroundColor: AppColors.success500,
        ),
      );
    }
  }

  String _getFileName(String key) {
    final documentNames = _formData['documentNames'] as Map<String, String>;
    return documentNames[key] ?? 'Unknown file';
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