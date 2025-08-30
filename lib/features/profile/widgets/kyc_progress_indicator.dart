import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/kyc_step_model.dart';

class KycProgressIndicator extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final List<KycStepModel> steps;
  final Function(int)? onStepTapped;

  const KycProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.steps,
    this.onStepTapped,
  });

  @override
  State<KycProgressIndicator> createState() => _KycProgressIndicatorState();
}

class _KycProgressIndicatorState extends State<KycProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Progress bar animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: (widget.currentStep + 1) / widget.totalSteps,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    // Pulse animation for current step
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Slide animation for step completion
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _startAnimations();
  }

  void _startAnimations() {
    _progressController.forward();
    _pulseController.repeat(reverse: true);
    _slideController.forward();
  }

  @override
  void didUpdateWidget(KycProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: (widget.currentStep + 1) / widget.totalSteps,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ));
      _progressController.forward(from: 0);
      _slideController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_progressAnimation, _slideAnimation]),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Container(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Enhanced Progress Info with Status
                _buildProgressHeader(isMobile),
                
                SizedBox(height: isMobile ? 8 : 12),
                
                // Animated Progress Bar with Segments
                _buildAnimatedProgressBar(isMobile),
                
                SizedBox(height: isMobile ? 12 : 16),
                
                // Animated Step Icons with Status
                _buildAnimatedStepIcons(isMobile),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressHeader(bool isMobile) {
    final approvedSteps = widget.steps.where((s) => s.status == KycStepStatus.approved).length;
    final rejectedSteps = widget.steps.where((s) => s.status == KycStepStatus.rejected).length;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step ${widget.currentStep + 1} of ${widget.totalSteps}',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
            if (approvedSteps > 0 || rejectedSteps > 0) ...[
              SizedBox(height: 2),
              Row(
                children: [
                  if (approvedSteps > 0) ...[
                    _buildStatusBadge(
                      '$approvedSteps Verified', 
                      AppColors.success100, 
                      AppColors.success600,
                      Icons.verified_outlined,
                      isMobile,
                    ),
                    if (rejectedSteps > 0) SizedBox(width: 6),
                  ],
                  if (rejectedSteps > 0)
                    _buildStatusBadge(
                      '$rejectedSteps Rejected', 
                      AppColors.error100, 
                      AppColors.error600,
                      Icons.cancel_outlined,
                      isMobile,
                    ),
                ],
              ),
            ],
          ],
        ),
        _buildPercentageBadge(isMobile),
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color bgColor, Color textColor, IconData icon, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8, 
        vertical: isMobile ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isMobile ? 10 : 12,
            color: textColor,
          ),
          SizedBox(width: 3),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 9 : 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageBadge(bool isMobile) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final percentage = (_progressAnimation.value * 100).round();
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 12, 
            vertical: isMobile ? 3 : 6,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary100, AppColors.primary50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary200, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.trending_up,
                size: isMobile ? 10 : 12,
                color: AppColors.primary700,
              ),
              SizedBox(width: 3),
              Text(
                '$percentage%',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary700,
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 10 : 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedProgressBar(bool isMobile) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: isMobile ? 6 : 8,
            decoration: BoxDecoration(
              color: AppColors.neutral200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: LinearProgressIndicator(
              value: _progressAnimation.value,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
              minHeight: isMobile ? 6 : 8,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedStepIcons(bool isMobile) {
    return SizedBox(
      height: isMobile ? 50 : 58,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.totalSteps, (index) {
            return _buildAnimatedStepIcon(index, isMobile);
          }),
        ),
      ),
    );
  }

  Widget _buildAnimatedStepIcon(int index, bool isMobile) {
    final step = index < widget.steps.length ? widget.steps[index] : null;
    final isCompleted = index < widget.currentStep;
    final isCurrent = index == widget.currentStep;
    final isFilled = step?.isFilled ?? false;
    
    // Can navigate if: current step, or completed/filled step, or approved step
    final canNavigate = (isCurrent || isCompleted || isFilled || step?.status == KycStepStatus.approved) 
        && widget.onStepTapped != null;
    
    // Compact sizes for mobile
    final double iconSize = isMobile ? (isCurrent ? 30 : 26) : (isCurrent ? 36 : 32);
    final double innerIconSize = isMobile ? (isCurrent ? 15 : 13) : (isCurrent ? 18 : 16);
    
    Color backgroundColor;
    Color iconColor;
    IconData iconData;
    bool showBorder = false;
    Color borderColor = Colors.transparent;
    bool showPulse = false;
    bool showShimmer = false;
    
    if (step != null) {
      switch (step.status) {
        case KycStepStatus.approved:
          backgroundColor = AppColors.success500;
          iconColor = Colors.white;
          iconData = Icons.verified;
          showShimmer = true;
          break;
        case KycStepStatus.rejected:
          backgroundColor = AppColors.error500;
          iconColor = Colors.white;
          iconData = Icons.cancel;
          break;
        case KycStepStatus.pending:
          if (isCurrent) {
            backgroundColor = AppColors.primary500;
            iconColor = Colors.white;
            iconData = step.icon;
            showPulse = true;
          } else if (isFilled) {
            backgroundColor = AppColors.info100;
            iconColor = AppColors.info600;
            iconData = Icons.edit_note;
            showBorder = true;
            borderColor = AppColors.info400;
          } else if (isCompleted) {
            backgroundColor = AppColors.warning100;
            iconColor = AppColors.warning600;
            iconData = Icons.pending;
            showBorder = true;
            borderColor = AppColors.warning400;
          } else {
            backgroundColor = AppColors.neutral200;
            iconColor = AppColors.textSecondary;
            iconData = step.icon;
          }
          break;
      }
    } else {
      backgroundColor = AppColors.neutral200;
      iconColor = AppColors.textSecondary;
      iconData = Icons.help_outline;
    }
    
    // Build the base icon
    Widget baseIcon = Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: showBorder ? Border.all(color: borderColor, width: 2) : null,
        boxShadow: isCurrent ? [
          BoxShadow(
            color: AppColors.primary300.withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ] : showShimmer ? [
          BoxShadow(
            color: AppColors.success300.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ] : null,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: innerIconSize,
      ),
    );
    
    // Apply animations without recursive references
    Widget animatedIcon = baseIcon;
    
    // Add pulse animation for current step
    if (showPulse && isCurrent) {
      animatedIcon = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: baseIcon, // Use baseIcon directly, not stepIcon
          );
        },
      );
    }
    
    // Add shimmer effect for approved steps
    if (showShimmer) {
      animatedIcon = AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Shimmer background
              Container(
                width: iconSize + 8,
                height: iconSize + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.success300.withValues(alpha: 0.3 * _pulseAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Original icon on top
              baseIcon,
            ],
          );
        },
      );
    }
    
    // Make clickable if navigation is allowed
    if (canNavigate) {
      animatedIcon = GestureDetector(
        onTap: () => widget.onStepTapped!(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(2),
          child: animatedIcon,
        ),
      );
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          animatedIcon,
          SizedBox(height: isMobile ? 2 : 4),
          // Animated status indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 2,
            width: isCurrent ? (isMobile ? 14 : 18) : (isMobile ? 10 : 14),
            decoration: BoxDecoration(
              color: step?.status == KycStepStatus.approved
                ? AppColors.success500
                : (isCurrent || isCompleted || isFilled)
                  ? AppColors.primary500 
                  : AppColors.neutral300,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          SizedBox(height: isMobile ? 1 : 2),
          // Step number with status
          Text(
            '${index + 1}',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: isMobile ? 8 : 9,
              color: step?.status == KycStepStatus.approved
                ? AppColors.success600
                : isCurrent 
                  ? AppColors.primary600 
                  : AppColors.textTertiary,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 