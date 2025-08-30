import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../widgets/cards/app_card.dart';

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String trend;
  final bool trendUp;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.trend,
    required this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    
    // Responsive padding
    final cardPadding = isMobile ? 8.0 : (isTablet ? 10.0 : 12.0);
    
    // Responsive font sizes
    final valueFontSize = ResponsiveUtils.getFontSize(context, isMobile ? 16 : (isTablet ? 18 : 20));
    final titleFontSize = ResponsiveUtils.getFontSize(context, isMobile ? 10 : (isTablet ? 11 : 12));
    final trendFontSize = ResponsiveUtils.getFontSize(context, isMobile ? 8 : (isTablet ? 9 : 10));
    
    // Responsive icon size
    final iconSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);
    
    // Responsive spacing
    final verticalSpacing = isMobile ? 6.0 : (isTablet ? 8.0 : 10.0);
    final horizontalSpacing = isMobile ? 4.0 : (isTablet ? 6.0 : 8.0);

    return AppCard(
      padding: EdgeInsets.all(cardPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row with Icon and Trend
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Container
                    Container(
                      padding: EdgeInsets.all(horizontalSpacing),
                      decoration: BoxDecoration(
                        color: AppColors.primary100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        icon,
                        size: iconSize,
                        color: AppColors.primary600,
                      ),
                    ),
                    
                    // Trend Badge
                    if (trend.isNotEmpty)
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalSpacing * 0.75,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: trendUp
                                ? AppColors.success100
                                : AppColors.error100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                trendUp
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: trendFontSize + 2,
                                color: trendUp
                                    ? AppColors.success600
                                    : AppColors.error600,
                              ),
                              SizedBox(width: horizontalSpacing * 0.5),
                              Flexible(
                                child: Text(
                                  trend,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: trendUp
                                        ? AppColors.success700
                                        : AppColors.error700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: trendFontSize,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              SizedBox(height: verticalSpacing),
              
              // Value and Title
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Value
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: AppTextStyles.headlineLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: valueFontSize,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: verticalSpacing * 0.3),
                    
                    // Title
                    Flexible(
                      child: Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: titleFontSize,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: isMobile ? 1 : 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 