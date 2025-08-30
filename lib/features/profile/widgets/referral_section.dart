import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/buttons/secondary_button.dart';
import '../../../services/users_service.dart';
import '../../../models/user_model.dart';

class ReferralSection extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onReferralUpdated;

  const ReferralSection({
    super.key,
    required this.user,
    this.onReferralUpdated,
  });

  @override
  State<ReferralSection> createState() => _ReferralSectionState();
}

class _ReferralSectionState extends State<ReferralSection> {
  final UsersService _referralService = UsersService();
  final TextEditingController _referrerCodeController = TextEditingController();
  final bool _isLoading = false;
  bool _isGeneratingCode = false;
  bool _isAddingReferrer = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Referral System',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Show different content based on user role and referral status
          if (widget.user.role.toLowerCase() == 'sales representative' || widget.user.role.toLowerCase() == 'partner') ...[
            _buildMyReferralSection(),
            const SizedBox(height: 20),
            _buildReferralStatsSection(),
          ],
          
          // Show add referrer section if user doesn't have a referrer
          if (widget.user.referredBy == null || widget.user.referredBy!.isEmpty) ...[
            if (widget.user.role.toLowerCase() == 'sales representative' || widget.user.role.toLowerCase() == 'partner')
              const Divider(height: 32),
            _buildAddReferrerSection(),
          ] else ...[
            const Divider(height: 32),
            _buildCurrentReferrerSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildMyReferralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Referral Code',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        if (widget.user.myReferralCode != null && widget.user.myReferralCode!.isNotEmpty) ...[
          // Show existing referral code
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.myReferralCode!,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share this code to earn referrals',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _copyReferralCode(widget.user.myReferralCode!),
                  icon: Icon(
                    Icons.copy,
                    color: AppColors.primary600,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary100,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: 'Share Link',
                  onPressed: () => _shareReferralLink(widget.user.myReferralCode!),
                  icon: Icons.share,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SecondaryButton(
                  text: 'Copy Link',
                  onPressed: () => _copyReferralLink(widget.user.myReferralCode!),
                  icon: Icons.link,
                ),
              ),
            ],
          ),
        ] else ...[
          // Generate referral code button
          Text(
            'Generate your referral code to start earning from referrals',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            text: _isGeneratingCode ? 'Generating...' : 'Generate Referral Code',
            onPressed: _isGeneratingCode ? null : _generateReferralCode,
            isLoading: _isGeneratingCode,
          ),
        ],
      ],
    );
  }

  Widget _buildReferralStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '${widget.user.referrals}',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary600,
                  ),
                ),
                Text(
                  'Total Referrals',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.neutral200,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '₹${widget.user.earnings}',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.success600,
                  ),
                ),
                Text(
                  'Earnings',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddReferrerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Referrer Code',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'If someone referred you, enter their referral code here',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        
        TextField(
          controller: _referrerCodeController,
          decoration: InputDecoration(
            hintText: 'Enter referral code (e.g., JOHN1234)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.person_add, color: AppColors.textSecondary),
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            _referrerCodeController.value = _referrerCodeController.value.copyWith(
              text: value.toUpperCase(),
              selection: TextSelection.collapsed(offset: value.length),
            );
          },
        ),
        const SizedBox(height: 12),
        
        PrimaryButton(
          text: _isAddingReferrer ? 'Adding...' : 'Add Referrer',
          onPressed: _isAddingReferrer ? null : _addReferrer,
          isLoading: _isAddingReferrer,
        ),
      ],
    );
  }

  Widget _buildCurrentReferrerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Referred By',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.referredBy!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success700,
                      ),
                    ),
                    Text(
                      'You were referred by this code',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _generateReferralCode() async {
    setState(() {
      _isGeneratingCode = true;
    });

    try {
      final referralCode = await _referralService.generateReferralCode(
        widget.user.uid,
        widget.user.fullName,
      );

      if (referralCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Referral code generated: $referralCode'),
            backgroundColor: AppColors.success500,
          ),
        );
        widget.onReferralUpdated?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to generate referral code'),
            backgroundColor: AppColors.error500,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error500,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingCode = false;
      });
    }
  }

  Future<void> _addReferrer() async {
    final referrerCode = _referrerCodeController.text.trim().toUpperCase();
    
    if (referrerCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a referral code'),
          backgroundColor: AppColors.warning500,
        ),
      );
      return;
    }

    if (!_referralService.isValidReferralCodeFormat(referrerCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid referral code format'),
          backgroundColor: AppColors.error500,
        ),
      );
      return;
    }

    setState(() {
      _isAddingReferrer = true;
    });

    try {
      final success = await _referralService.updateReferrer(
        widget.user.uid,
        referrerCode,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added referrer: $referrerCode'),
            backgroundColor: AppColors.success500,
          ),
        );
        _referrerCodeController.clear();
        widget.onReferralUpdated?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid referral code or you already have a referrer'),
            backgroundColor: AppColors.error500,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error500,
        ),
      );
    } finally {
      setState(() {
        _isAddingReferrer = false;
      });
    }
  }

  void _copyReferralCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Referral code copied: $code'),
        backgroundColor: AppColors.success500,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyReferralLink(String code) {
    final link = _referralService.generateReferralLink(code);
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Referral link copied to clipboard'),
        backgroundColor: AppColors.success500,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareReferralLink(String code) {
    final link = _referralService.generateReferralLink(code);
    final text = '🎉 Join our platform using my referral code: $code\n\n📱 Download the app: $link\n\nStart your journey with us today!';
    
    Share.share(
      text,
      subject: 'Join with my referral code: $code',
    );
  }

  @override
  void dispose() {
    _referrerCodeController.dispose();
    super.dispose();
  }
} 