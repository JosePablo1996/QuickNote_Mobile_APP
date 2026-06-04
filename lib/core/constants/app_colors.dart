// lib/core/constants/app_colors.dart
// Colores de la aplicación QuickNote (estilo LoginForm)

import 'package:flutter/material.dart';

class AppColors {
  // ============================================
  // COLORES PRINCIPALES (estilo LoginForm)
  // ============================================
  
  // Azul primario
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryBlueLight = Color(0xFF60A5FA);
  static const Color primaryBlueDark = Color(0xFF2563EB);
  
  // Púrpura secundario
  static const Color secondaryPurple = Color(0xFF8B5CF6);
  static const Color secondaryPurpleLight = Color(0xFFA78BFA);
  static const Color secondaryPurpleDark = Color(0xFF7C3AED);
  
  // Rosa acento
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentPinkLight = Color(0xFFF472B6);
  static const Color accentPinkDark = Color(0xFFDB2777);
  
  // Gradiente Login
  static const List<Color> loginGradient = [
    Color(0xFF3B82F6),  // Azul
    Color(0xFF8B5CF6),  // Púrpura
    Color(0xFFEC4899),  // Rosa
  ];
  
  // Gradiente para botones principales
  static const List<Color> primaryGradient = [
    Color(0xFF3B82F6),  // Azul
    Color(0xFF8B5CF6),  // Púrpura
  ];
  
  // Gradiente para éxito
  static const List<Color> successGradient = [
    Color(0xFF10B981),  // Verde
    Color(0xFF059669),  // Verde oscuro
  ];
  
  // Gradiente para error
  static const List<Color> errorGradient = [
    Color(0xFFEF4444),  // Rojo
    Color(0xFFDC2626),  // Rojo oscuro
  ];
  
  // Gradiente para advertencia
  static const List<Color> warningGradient = [
    Color(0xFFF59E0B),  // Ámbar
    Color(0xFFD97706),  // Ámbar oscuro
  ];
  
  // Gradiente para información
  static const List<Color> infoGradient = [
    Color(0xFF06B6D4),  // Cian
    Color(0xFF0891B2),  // Cian oscuro
  ];

  // ============================================
  // COLORES DE NOTAS
  // ============================================
  
  static const List<Color> noteColors = [
    Color(0xFF3B82F6),  // Azul
    Color(0xFFEF4444),  // Rojo
    Color(0xFF10B981),  // Verde
    Color(0xFFF59E0B),  // Ámbar
    Color(0xFF8B5CF6),  // Púrpura
    Color(0xFFEC4899),  // Rosa
    Color(0xFF06B6D4),  // Cian
    Color(0xFFF97316),  // Naranja
    Color(0xFF6366F1),  // Índigo
    Color(0xFF14B8A6),  // Teal
    Color(0xFF84CC16),  // Lima
    Color(0xFFA855F7),  // Violeta
  ];
  
  static const List<String> noteColorHexStrings = [
    '#3B82F6', '#EF4444', '#10B981', '#F59E0B',
    '#8B5CF6', '#EC4899', '#06B6D4', '#F97316',
    '#6366F1', '#14B8A6', '#84CC16', '#A855F7',
  ];

  // ============================================
  // MODO CLARO
  // ============================================
  
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightDivider = Color(0xFFF3F4F6);

  // ============================================
  // MODO OSCURO
  // ============================================
  
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFFD1D5DB);
  static const Color darkTextTertiary = Color(0xFF6B7280);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkDivider = Color(0xFF1F2937);

  // ============================================
  // COLORES DE ESTADO
  // ============================================
  
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ============================================
  // COLORES DE GLASSMORPHISM
  // ============================================
  
  static const Color glassBackground = Color(0x33FFFFFF);  // 20% blanco
  static const Color glassBackgroundDark = Color(0x331F2937);  // 20% gris oscuro
  static const Color glassBorder = Color(0x4DFFFFFF);  // 30% blanco
  static const Color glassBorderDark = Color(0x4D374151);  // 30% gris
  
  // ============================================
  // SOMBRAS
  // ============================================
  
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> cardShadowHover = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
  
  static const List<BoxShadow> glowShadow = [
    BoxShadow(
      color: Color(0x4D3B82F6),
      blurRadius: 20,
      offset: Offset(0, 0),
    ),
  ];
}

// Extension para obtener Color desde hex string
extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String toHex() => '#${value.toRadixString(16).substring(2)}';
}