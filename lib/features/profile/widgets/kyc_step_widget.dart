import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../widgets/badges/app_badge.dart';
import '../../../models/kyc_step_model.dart';
import '../../../services/kyc_service.dart';

class KycStepWidget extends StatefulWidget {
  final KycStepModel step;
  final Function(KycStepModel) onStepDataChanged;
  final String? userId;

  const KycStepWidget({
    super.key,
    required this.step,
    required this.onStepDataChanged,
    this.userId,
  });

  @override
  State<KycStepWidget> createState() => _KycStepWidgetState();
}

class _KycStepWidgetState extends State<KycStepWidget> {
  late Map<String, TextEditingController> _controllers;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controllers = {};
    for (final fieldKey in widget.step.fields.keys) {
      _controllers[fieldKey] = TextEditingController(
        text: widget.step.fields[fieldKey]?.toString() ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isVerified = widget.step.status == KycStepStatus.approved;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Status Card (if rejected)
          if (widget.step.isRejected) _buildRejectionCard(),
          
          // Verified Status Card (if approved)
          if (isVerified) _buildVerifiedCard(),
          
          // Step Form
          _buildStepForm(),
          
          // Documents Section (if applicable)
          if (widget.step.documents != null) ...[
            const SizedBox(height: 24),
            _buildDocumentsSection(),
          ],
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRejectionCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.error500,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Section Rejected',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.error600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (widget.step.rejectionReason?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                widget.step.rejectionReason!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please review and correct the information below, then resubmit.',
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
    );
  }

  Widget _buildVerifiedCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified,
                    color: AppColors.success600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Section Verified ✓',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.success700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'This section has been successfully verified by our team.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: AppColors.success600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your information is locked and cannot be edited. Contact support if you need to make changes.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success700,
                        fontWeight: FontWeight.w500,
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

  Widget _buildStepForm() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.step.icon,
                  color: AppColors.primary600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.step.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.step.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.step.isRequired)
                AppBadge(
                  text: 'Required',
                  type: BadgeType.warning,
                ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Form Fields
          ...widget.step.fields.keys.map((fieldKey) {
            return _buildFormField(fieldKey);
          }),
        ],
      ),
    );
  }

  Widget _buildFormField(String fieldKey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getFieldLabel(fieldKey),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isFieldRequired(fieldKey))
                Text(
                  ' *',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          _buildFieldInput(fieldKey),
        ],
      ),
    );
  }

  Widget _buildFieldInput(String fieldKey) {
    switch (fieldKey) {
      case 'gender':
        return _buildDropdownField(
          fieldKey,
          ['Male', 'Female', 'Other'],
        );
      
      case 'maritalStatus':
        return _buildDropdownField(
          fieldKey,
          ['Single', 'Married', 'Divorced', 'Widowed'],
        );
      
      case 'hasExperience':
        return _buildDropdownField(
          fieldKey,
          ['No', 'Yes'],
        );
      
      case 'dateOfBirth':
        return _buildDateField(fieldKey);
      
      case 'aadharNumber':
        return _buildTextField(
          fieldKey,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          hintText: 'Enter 12-digit Aadhar number',
        );
      
      case 'panNumber':
        return _buildTextField(
          fieldKey,
          inputFormatters: [
            UpperCaseTextFormatter(),
            LengthLimitingTextInputFormatter(10),
          ],
          hintText: 'Enter PAN number (e.g., ABCDE1234F)',
        );
      
      case 'pinCode':
        return _buildTextField(
          fieldKey,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          hintText: 'Enter 6-digit PIN code',
        );
      
      case 'mobileNumber':
        return _buildTextField(
          fieldKey,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          hintText: 'Enter 10-digit mobile number',
        );
      
      case 'emailAddress':
        return _buildTextField(
          fieldKey,
          keyboardType: TextInputType.emailAddress,
          hintText: 'Enter email address',
        );
      
      case 'accountNumber':
        return _buildTextField(
          fieldKey,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          hintText: 'Enter bank account number',
        );
      
      case 'ifscCode':
        return _buildTextField(
          fieldKey,
          inputFormatters: [
            UpperCaseTextFormatter(),
            LengthLimitingTextInputFormatter(11),
          ],
          hintText: 'Enter IFSC code (e.g., SBIN0001234)',
        );
      
      case 'experienceDetails':
      case 'address':
        return _buildTextField(
          fieldKey,
          maxLines: 3,
          hintText: 'Enter details...',
        );
      
      default:
        return _buildTextField(fieldKey);
    }
  }

  Widget _buildTextField(
    String fieldKey, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? hintText,
  }) {
    final bool isVerified = widget.step.status == KycStepStatus.approved;
    
    return TextFormField(
      controller: _controllers[fieldKey],
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      enabled: !isVerified,
      decoration: InputDecoration(
        hintText: isVerified 
          ? 'Verified and locked'
          : (hintText ?? 'Enter ${_getFieldLabel(fieldKey).toLowerCase()}'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isVerified ? AppColors.success300 : AppColors.neutral300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isVerified ? AppColors.success300 : AppColors.neutral300,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.success300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary500, width: 2),
        ),
        filled: true,
        fillColor: isVerified ? AppColors.success50 : AppColors.neutral50,
        contentPadding: const EdgeInsets.all(16),
        suffixIcon: isVerified ? Icon(
          Icons.verified,
          color: AppColors.success500,
          size: 20,
        ) : null,
      ),
      style: TextStyle(
        color: isVerified ? AppColors.success700 : AppColors.textPrimary,
        fontWeight: isVerified ? FontWeight.w600 : FontWeight.normal,
      ),
      onChanged: isVerified ? null : (value) => _updateFieldValue(fieldKey, value),
    );
  }

  Widget _buildDropdownField(String fieldKey, List<String> options) {
    final currentValue = widget.step.fields[fieldKey]?.toString();
    final bool isVerified = widget.step.status == KycStepStatus.approved;
    
    return DropdownButtonFormField<String>(
      value: options.contains(currentValue) ? currentValue : null,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isVerified ? AppColors.success300 : AppColors.neutral300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isVerified ? AppColors.success300 : AppColors.neutral300,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.success300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary500, width: 2),
        ),
        filled: true,
        fillColor: isVerified ? AppColors.success50 : AppColors.neutral50,
        contentPadding: const EdgeInsets.all(16),
        suffixIcon: isVerified ? Icon(
          Icons.verified,
          color: AppColors.success500,
          size: 20,
        ) : null,
      ),
      hint: Text(
        isVerified 
          ? 'Verified and locked'
          : 'Select ${_getFieldLabel(fieldKey).toLowerCase()}',
        style: TextStyle(
          color: isVerified ? AppColors.success600 : AppColors.textSecondary,
        ),
      ),
      style: TextStyle(
        color: isVerified ? AppColors.success700 : AppColors.textPrimary,
        fontWeight: isVerified ? FontWeight.w600 : FontWeight.normal,
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: isVerified ? null : (value) => _updateFieldValue(fieldKey, value ?? ''),
    );
  }

  Widget _buildDateField(String fieldKey) {
    final currentValue = widget.step.fields[fieldKey]?.toString() ?? '';
    final bool isVerified = widget.step.status == KycStepStatus.approved;
    
    return TextFormField(
      controller: _controllers[fieldKey],
      decoration: InputDecoration(
        hintText: isVerified 
          ? 'Verified and locked'
          : 'Select date of birth',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isVerified ? AppColors.success300 : AppColors.neutral300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isVerified ? AppColors.success300 : AppColors.neutral300,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.success300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary500, width: 2),
        ),
        filled: true,
        fillColor: isVerified ? AppColors.success50 : AppColors.neutral50,
        contentPadding: const EdgeInsets.all(16),
        suffixIcon: Icon(
          isVerified ? Icons.verified : Icons.calendar_today,
          color: isVerified ? AppColors.success500 : AppColors.textSecondary,
        ),
      ),
      style: TextStyle(
        color: isVerified ? AppColors.success700 : AppColors.textPrimary,
        fontWeight: isVerified ? FontWeight.w600 : FontWeight.normal,
      ),
      readOnly: true,
      enabled: !isVerified,
      onTap: isVerified ? null : () => _selectDate(fieldKey),
    );
  }

  Widget _buildDocumentsSection() {
    final bool isVerified = widget.step.status == KycStepStatus.approved;
    
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVerified ? Icons.verified : Icons.cloud_upload_outlined,
                color: isVerified ? AppColors.success600 : AppColors.primary600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isVerified ? 'Verified Documents' : 'Required Documents',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isVerified ? AppColors.success700 : AppColors.textPrimary,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'LOCKED',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success700,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          if (isVerified) ...[
            const SizedBox(height: 12),
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
                    Icons.lock_outline,
                    color: AppColors.success600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Documents are verified and cannot be modified.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          ...widget.step.documents!.keys.map((docKey) {
            return _buildDocumentUpload(docKey);
          }),
        ],
      ),
    );
  }

  Widget _buildDocumentUpload(String docKey) {
    final isUploaded = widget.step.documents![docKey] != null;
    final bool isVerified = widget.step.status == KycStepStatus.approved;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVerified 
          ? AppColors.success50 
          : (isUploaded ? AppColors.info50 : AppColors.neutral50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified 
            ? AppColors.success200
            : (isUploaded ? AppColors.info200 : AppColors.neutral200),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVerified 
                  ? Icons.verified
                  : (isUploaded ? Icons.check_circle : Icons.cloud_upload_outlined),
                color: isVerified 
                  ? AppColors.success600
                  : (isUploaded ? AppColors.info600 : AppColors.textSecondary),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getDocumentLabel(docKey),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isVerified ? AppColors.success700 : AppColors.textPrimary,
                  ),
                ),
              ),
              if (widget.step.isRequired && !isVerified)
                Text(
                  '*',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'VERIFIED',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success700,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            isVerified
              ? 'Document verified and locked'
              : (isUploaded 
                  ? 'Document uploaded successfully'
                  : 'Please upload ${_getDocumentLabel(docKey).toLowerCase()}'),
            style: AppTextStyles.bodySmall.copyWith(
              color: isVerified 
                ? AppColors.success700
                : (isUploaded ? AppColors.info700 : AppColors.textSecondary),
              fontWeight: isVerified ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (isVerified || _isUploading) ? null : () => _uploadDocument(docKey),
                  icon: Icon(
                    isVerified 
                      ? Icons.lock 
                      : (isUploaded ? Icons.refresh : Icons.upload),
                    size: 16,
                  ),
                  label: Text(
                    isVerified 
                      ? 'Locked'
                      : (isUploaded ? 'Replace Document' : 'Upload Document'),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isVerified 
                        ? AppColors.success400
                        : (isUploaded ? AppColors.primary600 : AppColors.neutral400),
                    ),
                    foregroundColor: isVerified 
                      ? AppColors.success600
                      : (isUploaded ? AppColors.primary600 : AppColors.textSecondary),
                  ),
                ),
              ),
              if (isUploaded) ...[
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _viewDocument(docKey),
                  icon: Icon(
                    Icons.visibility_outlined,
                    color: isVerified ? AppColors.success600 : AppColors.primary600,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: isVerified ? AppColors.success100 : AppColors.primary100,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getFieldLabel(String fieldKey) {
    switch (fieldKey) {
      case 'fatherName': return 'Father\'s Name';
      case 'dateOfBirth': return 'Date of Birth';
      case 'gender': return 'Gender';
      case 'maritalStatus': return 'Marital Status';
      case 'mobileNumber': return 'Mobile Number';
      case 'emailAddress': return 'Email Address';
      case 'address': return 'Address';
      case 'village': return 'Village/Area';
      case 'tehsilCity': return 'Tehsil/City';
      case 'district': return 'District';
      case 'state': return 'State';
      case 'pinCode': return 'PIN Code';
      case 'aadharNumber': return 'Aadhar Number';
      case 'panNumber': return 'PAN Number';
      case 'qualification': return 'Educational Qualification';
      case 'institution': return 'Institution/University';
      case 'passingYear': return 'Passing Year';
      case 'hasExperience': return 'Do you have work experience?';
      case 'experienceDetails': return 'Experience Details';
      case 'currentCompany': return 'Current Company';
      case 'workingYears': return 'Years of Experience';
      case 'accountNumber': return 'Account Number';
      case 'bankName': return 'Bank Name';
      case 'ifscCode': return 'IFSC Code';
      case 'accountHolderName': return 'Account Holder Name';
      case 'branchName': return 'Branch Name';
      default: return fieldKey.replaceAll('_', ' ').split(' ')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }
  }

  String _getDocumentLabel(String docKey) {
    switch (docKey) {
      case 'aadharCard': return 'Aadhar Card';
      case 'panCard': return 'PAN Card';
      case 'educationCertificate': return 'Education Certificate';
      case 'experienceCertificate': return 'Experience Certificate';
      case 'bankPassbook': return 'Bank Passbook/Cancel Cheque';
      default: return docKey.replaceAll('_', ' ').split(' ')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }
  }

  bool _isFieldRequired(String fieldKey) {
    return widget.step.isRequired && !['experienceDetails', 'currentCompany', 'workingYears', 'institution', 'passingYear', 'qualification'].contains(fieldKey);
  }

  void _updateFieldValue(String fieldKey, String value) {
    final updatedFields = Map<String, dynamic>.from(widget.step.fields);
    updatedFields[fieldKey] = value;
    
    final updatedStep = widget.step.copyWith(fields: updatedFields);
    widget.onStepDataChanged(updatedStep);
  }

  Future<void> _selectDate(String fieldKey) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary500,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      _controllers[fieldKey]?.text = formattedDate;
      _updateFieldValue(fieldKey, formattedDate);
    }
  }

  Future<void> _uploadDocument(String docKey) async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Show file type selection dialog
      final fileType = await _showFileTypeDialog();
      if (fileType == null) return;
      
      dynamic selectedFile;
      String fileName = '';
      
      if (kIsWeb) {
        // Web platform handling
        if (fileType == 'image' || fileType == 'camera') {
          // For web, camera is not available, so use gallery
          final FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: false,
            withData: true, // Important for web - get bytes
          );
          
          if (result != null && result.files.isNotEmpty) {
            final pickedFile = result.files.first;
            selectedFile = pickedFile.bytes;
            fileName = pickedFile.name;
          }
        } else if (fileType == 'pdf') {
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
          }
        }
      } else {
        // Mobile platform handling
      if (fileType == 'image') {
          final ImagePicker picker = ImagePicker();
          final XFile? xFile = await picker.pickImage(source: ImageSource.gallery);
          if (xFile != null) {
            selectedFile = File(xFile.path);
            fileName = xFile.name;
          }
      } else if (fileType == 'camera') {
          final ImagePicker picker = ImagePicker();
          final XFile? xFile = await picker.pickImage(source: ImageSource.camera);
          if (xFile != null) {
            selectedFile = File(xFile.path);
            fileName = xFile.name;
          }
        } else if (fileType == 'pdf') {
          final FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            allowMultiple: false,
          );
          
          if (result != null && result.files.isNotEmpty) {
            selectedFile = File(result.files.first.path!);
            fileName = result.files.first.name;
          }
        }
      }
      
      if (selectedFile != null) {
        final KycService kycService = KycService();
        
        String? downloadUrl;
        
        if (kIsWeb) {
          // For web, upload bytes directly
          downloadUrl = await kycService.uploadDocumentBytes(
            userId: widget.userId ?? 'dummy_user_id',
          stepId: widget.step.id,
          documentType: docKey,
            fileBytes: selectedFile as Uint8List,
            fileName: fileName,
          onProgress: (progress) {
            print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
          },
        );
        } else {
          // For mobile, upload file
          downloadUrl = await kycService.uploadDocument(
            userId: widget.userId ?? 'dummy_user_id',
            stepId: widget.step.id,
            documentType: docKey,
            file: selectedFile as File,
            onProgress: (progress) {
              print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
            },
          );
        }
        
        if (downloadUrl != null) {
          final updatedDocuments = Map<String, dynamic>.from(widget.step.documents!);
          updatedDocuments[docKey] = downloadUrl;
          
          final updatedStep = widget.step.copyWith(documents: updatedDocuments);
          widget.onStepDataChanged(updatedStep);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getDocumentLabel(docKey)} uploaded successfully'),
              backgroundColor: AppColors.success500,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload document: ${e.toString()}'),
          backgroundColor: AppColors.error500,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
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
                title: Text(kIsWeb ? 'Choose Image File' : 'Choose from Gallery'),
                subtitle: Text(
                  'JPEG, PNG formats',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () => Navigator.of(context).pop('image'),
              ),
              if (!kIsWeb) // Camera only available on mobile
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primary600),
                title: Text('Take Photo'),
                  subtitle: Text(
                    'Use camera',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                onTap: () => Navigator.of(context).pop('camera'),
              ),
              ListTile(
                leading: Icon(Icons.picture_as_pdf, color: AppColors.primary600),
                title: Text('Select PDF Document'),
                subtitle: Text(
                  'PDF files only',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () => Navigator.of(context).pop('pdf'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _viewDocument(String docKey) {
    final documentUrl = widget.step.documents?[docKey];
    if (documentUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document not found'),
          backgroundColor: AppColors.error500,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getDocumentLabel(docKey),
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildDocumentViewer(documentUrl),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Implement download functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Download functionality coming soon!'),
                          backgroundColor: AppColors.info500,
                        ),
                      );
                    },
                    icon: Icon(Icons.download),
                    label: Text('Download'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentViewer(String documentUrl) {
    if (documentUrl.toLowerCase().contains('.pdf')) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.neutral300),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf,
                size: 64,
                color: AppColors.error500,
              ),
              const SizedBox(height: 16),
              Text(
                'PDF Document',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'PDF viewer not implemented yet',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Open external PDF viewer or implement in-app viewer
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('External PDF viewer not implemented'),
                      backgroundColor: AppColors.info500,
                    ),
                  );
                },
                icon: Icon(Icons.open_in_new),
                label: Text('Open Externally'),
              ),
            ],
          ),
        ),
      );
    } else {
      // Image viewer
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.neutral300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            documentUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error500,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
} 