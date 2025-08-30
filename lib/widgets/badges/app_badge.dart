import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum BadgeType { primary, secondary, success, error, warning, info, neutral }

class AppBadge extends StatelessWidget {
  final String text;
  final BadgeType type;
  final IconData? icon;
  final double? iconSize;

  const AppBadge({
    super.key,
    required this.text,
    this.type = BadgeType.primary,
    this.icon,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colors['background'],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize ?? 14,
              color: colors['foreground'],
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTextStyles.badgeText.copyWith(
              color: colors['foreground'],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getColors() {
    switch (type) {
      case BadgeType.primary:
        return {
          'background': AppColors.primary100,
          'foreground': AppColors.primary800,
        };
      case BadgeType.secondary:
        return {
          'background': AppColors.secondary100,
          'foreground': AppColors.secondary800,
        };
      case BadgeType.success:
        return {
          'background': AppColors.success100,
          'foreground': AppColors.success800,
        };
      case BadgeType.error:
        return {
          'background': AppColors.error100,
          'foreground': AppColors.error800,
        };
      case BadgeType.warning:
        return {
          'background': AppColors.warning100,
          'foreground': AppColors.warning800,
        };
      case BadgeType.info:
        return {
          'background': AppColors.info100,
          'foreground': AppColors.info800,
        };
      case BadgeType.neutral:
        return {
          'background': AppColors.neutral100,
          'foreground': AppColors.neutral800,
        };
    }
  }
} 