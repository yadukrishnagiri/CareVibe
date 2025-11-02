import 'package:flutter/services.dart';

/// Haptic Feedback Helper for Pro Mode
/// Provides consistent haptic feedback mapping for clinical UI interactions
class HapticsHelper {
  /// Light impact - for small confirmations (tap KPI, toggle)
  static void light() {
    HapticFeedback.lightImpact();
  }
  
  /// Medium impact - for opening panels, acknowledging alerts
  static void medium() {
    HapticFeedback.mediumImpact();
  }
  
  /// Heavy impact - for critical alert acknowledgments
  static void heavy() {
    HapticFeedback.heavyImpact();
  }
  
  /// Selection click - for chip/toggle interactions
  static void selection() {
    HapticFeedback.selectionClick();
  }
  
  /// Soft notification - for alert arrivals
  static void notification() {
    // Use light impact for soft notification feel
    HapticFeedback.lightImpact();
  }
}

