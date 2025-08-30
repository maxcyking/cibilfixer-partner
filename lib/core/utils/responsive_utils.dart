import 'package:flutter/material.dart';

class ResponsiveUtils {
  static const double minScreenWidth = 360.0;
  static const double maxScreenWidth = 1200.0;
  
  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 768.0;
  static const double desktopBreakpoint = 1024.0;
  
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }
  
  /// Get scale factor based on screen width
  static double getScaleFactor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final clampedWidth = screenWidth.clamp(minScreenWidth, maxScreenWidth);
    return clampedWidth / minScreenWidth;
  }
  
  /// Get responsive font size
  static double getFontSize(BuildContext context, double baseFontSize) {
    final scaleFactor = getScaleFactor(context);
    final scaledSize = baseFontSize * scaleFactor;
    
    // Apply different scaling rates for different screen sizes
    if (isMobile(context)) {
      return scaledSize.clamp(baseFontSize * 0.9, baseFontSize * 1.2);
    } else if (isTablet(context)) {
      return scaledSize.clamp(baseFontSize * 1.0, baseFontSize * 1.3);
    } else {
      return scaledSize.clamp(baseFontSize * 1.1, baseFontSize * 1.4);
    }
  }
  
  /// Get responsive padding
  static EdgeInsets getPadding(BuildContext context, {
    double mobile = 16.0,
    double tablet = 20.0,
    double desktop = 24.0,
  }) {
    if (isMobile(context)) {
      return EdgeInsets.all(mobile);
    } else if (isTablet(context)) {
      return EdgeInsets.all(tablet);
    } else {
      return EdgeInsets.all(desktop);
    }
  }
  
  /// Get responsive margin
  static EdgeInsets getMargin(BuildContext context, {
    double mobile = 12.0,
    double tablet = 16.0,
    double desktop = 20.0,
  }) {
    if (isMobile(context)) {
      return EdgeInsets.all(mobile);
    } else if (isTablet(context)) {
      return EdgeInsets.all(tablet);
    } else {
      return EdgeInsets.all(desktop);
    }
  }
  
  /// Get responsive spacing
  static double getSpacing(BuildContext context, {
    double mobile = 16.0,
    double tablet = 20.0,
    double desktop = 24.0,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }
  
  /// Get responsive icon size
  static double getIconSize(BuildContext context, double baseSize) {
    final scaleFactor = getScaleFactor(context);
    return (baseSize * scaleFactor).clamp(baseSize * 0.8, baseSize * 1.5);
  }
  
  /// Get responsive border radius
  static double getBorderRadius(BuildContext context, {
    double mobile = 12.0,
    double tablet = 16.0,
    double desktop = 20.0,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }
  
  /// Get responsive avatar radius
  static double getAvatarRadius(BuildContext context, {
    double mobile = 20.0,
    double tablet = 24.0,
    double desktop = 28.0,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }
  
  /// Get responsive dialog constraints
  static BoxConstraints getDialogConstraints(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    if (isMobile(context)) {
      return BoxConstraints(
        maxWidth: screenSize.width * 0.95,
        maxHeight: screenSize.height * 0.9,
      );
    } else if (isTablet(context)) {
      return BoxConstraints(
        maxWidth: 600,
        maxHeight: screenSize.height * 0.85,
      );
    } else {
      return BoxConstraints(
        maxWidth: 800,
        maxHeight: screenSize.height * 0.8,
      );
    }
  }
  
  /// Get responsive text style with auto scaling
  static TextStyle getResponsiveTextStyle(
    BuildContext context,
    TextStyle baseStyle,
  ) {
    return baseStyle.copyWith(
      fontSize: getFontSize(context, baseStyle.fontSize ?? 14.0),
    );
  }
  
  /// Get responsive card elevation
  static double getCardElevation(BuildContext context) {
    if (isMobile(context)) {
      return 2.0;
    } else if (isTablet(context)) {
      return 4.0;
    } else {
      return 6.0;
    }
  }
  
  /// Get responsive bottom sheet height
  static double getBottomSheetHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    if (isMobile(context)) {
      return screenHeight * 0.92;
    } else {
      return screenHeight * 0.9;
    }
  }
} 