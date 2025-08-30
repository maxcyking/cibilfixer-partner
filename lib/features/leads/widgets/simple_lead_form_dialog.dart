import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/buttons/secondary_button.dart';
import '../../../services/leads_service.dart';
import '../../../providers/auth_provider.dart';
import 'dart:math';

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

class SimpleLeadFormDialog extends StatefulWidget {
  final VoidCallback? onLeadCreated;

  const SimpleLeadFormDialog({
    super.key,
    this.onLeadCreated,
  });

  @override
  State<SimpleLeadFormDialog> createState() => _SimpleLeadFormDialogState();
}

class _SimpleLeadFormDialogState extends State<SimpleLeadFormDialog>
    with TickerProviderStateMixin {
  final LeadsService _leadsService = LeadsService();
  final _formKey = GlobalKey<FormState>();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  String _panValidationError = '';
  
  // Form controllers
  final _issueController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _panController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  
  // Issue options
  final List<String> _issueOptions = [
    'Credit Score Issue',
    'Loan Rejection',
    'Credit Card Issue',
    'Other',
  ];
  
  String? _selectedIssue;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
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
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _issueController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _panController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    super.dispose();
  }



  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)), // Must be at least 18
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary500,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  String _generateCustomerId() {
    final random = Random();
    final randomNumber = random.nextInt(100000000);
    final paddedNumber = randomNumber.toString().padLeft(8, '0');
    return 'CRM$paddedNumber';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get user referral code
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userReferralCode = authProvider.userData?['myReferralCode'] ?? '';
      
      // Generate unique customer ID
      final customerId = _generateCustomerId();
      
      // Prepare lead data with empty strings for missing fields
      final leadData = {
        // Required fields from form
        'issue': _selectedIssue ?? '',
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'pan': _panController.text.trim().toUpperCase(),
        'mobile': _mobileController.text.trim(),
        'dob': _selectedDate?.toIso8601String() ?? '',
        
        // System fields
        'customerId': customerId,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'referralCode': userReferralCode,
        'isSeen': false,
        
        // Empty strings for fields not collected in simple form
        'otherIssue': '',
        'fatherName': '',
        'gender': '',
        'aadhar': '',
        'address': '',
        'village': '',
        'tehsilCity': '',
        'district': '',
        'state': '',
        'pin': '',
        'remark': '',
        'documents': <String, String>{},
        'documentNames': <String, String>{},
      };

      // Create lead
      final success = await _leadsService.createLead(leadData);

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Lead created successfully! Customer ID: $customerId'),
              ],
            ),
            backgroundColor: AppColors.success500,
            duration: Duration(seconds: 4),
          ),
        );
        
        // Close dialog and refresh leads
        Navigator.of(context).pop();
        widget.onLeadCreated?.call();
      } else if (mounted) {
        _showErrorDialog('Failed to create lead. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error creating lead: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary500,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add Quick Lead',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                // Form Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Issue Dropdown
                          _buildDropdownField(),
                          const SizedBox(height: 16),
                          
                          // Name Field
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Full name is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Email Field
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email ID',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Email is required';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // PAN Field
                          _buildPanTextField(),
                          const SizedBox(height: 16),
                          
                          // Mobile Field
                          _buildTextField(
                            controller: _mobileController,
                            label: 'Mobile Number (10 digits)',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Mobile number is required';
                              if (value!.length != 10) return 'Mobile number must be exactly 10 digits';
                              // Validate mobile number format (should start with 6-9)
                              if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
                                return 'Invalid mobile number format';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // DOB Field
                          _buildDateField(),
                          const SizedBox(height: 24),
                          
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              text: 'Create Lead',
                              onPressed: _isLoading ? null : _submitForm,
                              isLoading: _isLoading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedIssue,
        decoration: InputDecoration(
          labelText: 'Select Issue',
          prefixIcon: Icon(Icons.report_problem, color: AppColors.primary500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: _issueOptions.map((issue) {
          return DropdownMenuItem(
            value: issue,
            child: Text(issue),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedIssue = value;
          });
        },
        validator: (value) {
          if (value == null) return 'Please select an issue';
          return null;
        },
      ),
    );
  }

  Widget _buildPanTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _panController,
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
            if (value?.isEmpty ?? true) return 'PAN number is required';
            if (value!.length != 10) return 'PAN number must be 10 characters';
            // Validate PAN format: XXXXX####X (5 letters, 4 digits, 1 letter)
            final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
            if (!panRegex.hasMatch(value)) {
              return 'Invalid PAN format. Use XXXXX####X format';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'PAN Card Number',
            hintText: 'ABCDE1234F',
            prefixIcon: Icon(Icons.credit_card, color: AppColors.primary500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.neutral300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary500),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error500),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        // Format helper text
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 12,
                color: AppColors.neutral500,
              ),
              const SizedBox(width: 4),
              Text(
                'Format: XXXXX####X (5 letters, 4 digits, 1 letter)',
                style: TextStyle(
                  color: AppColors.neutral500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary500),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error500),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _dobController,
      readOnly: true,
      onTap: _selectDate,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Date of birth is required';
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Date of Birth',
        prefixIcon: Icon(Icons.calendar_today, color: AppColors.primary500),
        suffixIcon: Icon(Icons.arrow_drop_down, color: AppColors.primary500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary500),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error500),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
} 