import 'package:flutter/material.dart';

/// Responsive breakpoints for different device types
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Device type enum
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Responsive utilities for adaptive layouts
class ResponsiveUtils {
  /// Get current device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < Breakpoints.mobile) {
      return DeviceType.mobile;
    } else if (width < Breakpoints.tablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }
  
  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }
  
  /// Check if device is tablet or larger
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }
  
  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }
  
  /// Get responsive padding based on device type
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16);
      case DeviceType.tablet:
        return const EdgeInsets.all(24);
      case DeviceType.desktop:
        return const EdgeInsets.all(32);
    }
  }
  
  /// Get responsive spacing based on device type
  static double getResponsiveSpacing(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 12;
      case DeviceType.tablet:
        return 16;
      case DeviceType.desktop:
        return 20;
    }
  }
  
  /// Get responsive font size multiplier
  static double getFontSizeMultiplier(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.tablet:
        return 1.15;
      case DeviceType.desktop:
        return 1.3;
    }
  }
  
  /// Get responsive card width (useful for centering content on large screens)
  static double getMaxContentWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return double.infinity;
      case DeviceType.tablet:
        return 700;
      case DeviceType.desktop:
        return 900;
    }
  }
  
  /// Get responsive grid column count
  static int getGridColumnCount(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 1;
      case DeviceType.tablet:
        return 2;
      case DeviceType.desktop:
        return 3;
    }
  }
  
  /// Get responsive chess board size
  static double getChessBoardSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final deviceType = getDeviceType(context);
    
    // Use smaller dimension to ensure board fits
    final smallerDimension = width < height ? width : height;
    
    switch (deviceType) {
      case DeviceType.mobile:
        return smallerDimension * 0.9; // 90% of screen width
      case DeviceType.tablet:
        return smallerDimension * 0.7; // 70% for tablets
      case DeviceType.desktop:
        return 600; // Fixed size for desktop
    }
  }
}

/// Responsive builder widget for custom layouts
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;
  
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });
  
  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    return builder(context, deviceType);
  }
}

/// Responsive layout widget with separate builders for each device type
class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveUtils.getDeviceType(context);
        
        switch (deviceType) {
          case DeviceType.mobile:
            return mobile(context);
          case DeviceType.tablet:
            return (tablet ?? mobile)(context);
          case DeviceType.desktop:
            return (desktop ?? tablet ?? mobile)(context);
        }
      },
    );
  }
}

/// Responsive text style helper
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  
  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });
  
  @override
  Widget build(BuildContext context) {
    final multiplier = ResponsiveUtils.getFontSizeMultiplier(context);
    final baseStyle = style ?? const TextStyle();
    
    return Text(
      text,
      style: baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 14) * multiplier,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
