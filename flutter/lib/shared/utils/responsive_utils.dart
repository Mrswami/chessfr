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
}
