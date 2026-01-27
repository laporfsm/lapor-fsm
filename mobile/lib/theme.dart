import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AppTheme {
  static const Color primaryColor = Color(
    0xFF1E3A8A,
  ); // Deep Blue (FSM/Undip vibe)
  static const Color secondaryColor = Color(0xFFF59E0B); // Amber (Alert/Action)
  static const Color emergencyColor = Color(0xFFDC2626); // Red (Emergency)
  static const Color supervisorColor = Color(
    0xFF3730A3,
  ); // Indigo 800 (Supervisor Theme)
  static const Color adminColor = Color(0xFF059669); // Emerald (Admin Theme)
  static const Color backgroundColor = Color(0xFFF3F4F6); // Light Gray

  // Standard border radius for cards
  static const double cardBorderRadius = 12.0;

  /// Get color for report status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.grey;
      case 'terverifikasi': // Supervisor ready
        return Colors.blue;
      case 'verifikasi': // Legacy
        return Colors.blue;
      case 'diproses': // Assigned/Waiting Technician
        return Colors.purple;
      case 'penanganan': // Working
        return Colors.orange;
      case 'onhold':
        return Colors.deepOrange;
      case 'selesai':
        return Colors.teal;
      case 'approved':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'recalled':
        return Colors.deepOrangeAccent;
      case 'archived':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  /// Get icon for report status
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return LucideIcons.clock;
      case 'terverifikasi':
        return LucideIcons.checkSquare;
      case 'verifikasi': // Legacy
        return LucideIcons.search;
      case 'diproses':
        return LucideIcons.userCheck;
      case 'penanganan':
        return LucideIcons.wrench;
      case 'onhold':
        return LucideIcons.pauseCircle;
      case 'selesai':
        return LucideIcons.checkCircle;
      case 'approved':
        return LucideIcons.checkCircle2;
      case 'ditolak':
        return LucideIcons.xCircle;
      case 'recalled':
        return LucideIcons.rotateCcw;
      case 'archived':
        return LucideIcons.archive;
      default:
        return LucideIcons.circle;
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: emergencyColor,
        background: backgroundColor,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
