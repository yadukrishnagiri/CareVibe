import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pro Mode Design Tokens
/// VIP-grade clinical dashboard theme with dark background and glass morphism
class ProModeColors {
  // Background
  static const backgroundPrimary = Color(0xFF0B0F17); // deep charcoal
  
  // Surfaces (glass morphism)
  static Color surface([double opacity = 0.03]) => 
      Colors.white.withOpacity(opacity);
  static Color surfaceBorder([double opacity = 0.06]) => 
      Colors.white.withOpacity(opacity);
  
  // Accents
  static const accentPrimary = Color(0xFF2FD1C5); // teal - positive
  static const accentWarn = Color(0xFFFFC857); // amber - caution
  static const accentDanger = Color(0xFFFF6B6B); // soft red - alerts
  
  // Text
  static const textPrimary = Color(0xFFE6EEF3); // off-white
  static const textMuted = Color(0xFF9AA7B2);
  
  // Risk indicators
  static const riskLow = accentPrimary; // green/teal
  static const riskMedium = accentWarn; // amber
  static const riskHigh = accentDanger; // red
}

/// Pro Mode Typography Scale
class ProModeTypography {
  // Headline Large: 28px SemiBold
  static TextStyle headlineLarge(BuildContext context) => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: ProModeColors.textPrimary,
    height: 1.2,
  );
  
  // Headline Medium: 20px Medium
  static TextStyle headlineMedium(BuildContext context) => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: ProModeColors.textPrimary,
    height: 1.3,
  );
  
  // Body: 14px Regular
  static TextStyle body(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ProModeColors.textPrimary,
    height: 1.5,
  );
  
  // Mono: 12px (for formulas, codes)
  static TextStyle mono(BuildContext context) => GoogleFonts.robotoMono(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ProModeColors.textMuted,
    height: 1.4,
  );
  
  // Body Muted
  static TextStyle bodyMuted(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ProModeColors.textMuted,
    height: 1.5,
  );
}

/// Pro Mode Spacing (8pt base unit grid)
class ProModeSpacing {
  static const double xs = 4.0; // 0.5 units
  static const double sm = 8.0; // 1 unit
  static const double md = 16.0; // 2 units
  static const double lg = 24.0; // 3 units
  static const double xl = 32.0; // 4 units
  static const double xxl = 48.0; // 6 units
}

/// Glass morphism utility
class GlassMorphism {
  static BoxDecoration card({
    double surfaceOpacity = 0.03,
    double borderOpacity = 0.06,
    double radius = 14.0,
  }) {
    return BoxDecoration(
      color: ProModeColors.surface(surfaceOpacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: ProModeColors.surfaceBorder(borderOpacity),
        width: 1,
      ),
    );
  }
  
  static BoxDecoration elevated({
    double surfaceOpacity = 0.05,
    double borderOpacity = 0.1,
    double radius = 14.0,
    double blur = 20.0,
  }) {
    return BoxDecoration(
      color: ProModeColors.surface(surfaceOpacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: ProModeColors.surfaceBorder(borderOpacity),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: blur,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

/// Pro Mode Theme Extension
extension ProModeTheme on ThemeData {
  static ThemeData proMode() {
    final base = ThemeData.dark(useMaterial3: true);
    
    return base.copyWith(
      scaffoldBackgroundColor: ProModeColors.backgroundPrimary,
      colorScheme: ColorScheme.dark(
        primary: ProModeColors.accentPrimary,
        secondary: ProModeColors.accentWarn,
        error: ProModeColors.accentDanger,
        surface: ProModeColors.surface(0.03),
        onSurface: ProModeColors.textPrimary,
        onPrimary: ProModeColors.backgroundPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: ProModeColors.textPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: ProModeColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: ProModeColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: ProModeColors.textPrimary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: ProModeColors.textMuted,
        ),
      ),
      cardTheme: CardThemeData(
        color: ProModeColors.surface(0.03),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

