// lib/widgets/tag_chip.dart
// Chip para mostrar etiquetas - CON DISEÑO COMPLETO
// Similar a la versión de React de QuickNote

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================
// TIPOS DE TAMAÑO
// ============================================

enum TagChipSize {
  small,
  medium,
  large,
}

extension TagChipSizeExtension on TagChipSize {
  double get fontSize {
    switch (this) {
      case TagChipSize.small:
        return 10;
      case TagChipSize.medium:
        return 12;
      case TagChipSize.large:
        return 14;
    }
  }

  double get iconSize {
    switch (this) {
      case TagChipSize.small:
        return 10;
      case TagChipSize.medium:
        return 12;
      case TagChipSize.large:
        return 14;
    }
  }

  double get paddingHorizontal {
    switch (this) {
      case TagChipSize.small:
        return 8;
      case TagChipSize.medium:
        return 10;
      case TagChipSize.large:
        return 12;
    }
  }

  double get paddingVertical {
    switch (this) {
      case TagChipSize.small:
        return 3;
      case TagChipSize.medium:
        return 4;
      case TagChipSize.large:
        return 6;
    }
  }
}

// ============================================
// UTILIDADES DE TAGS (integradas)
// ============================================

class TagUtils {
  static const Map<String, String> _tagColors = {
    'trabajo': '#3B82F6',
    'personal': '#8B5CF6',
    'importante': '#EF4444',
    'idea': '#F59E0B',
    'proyecto': '#10B981',
    'estudio': '#EC4899',
    'casa': '#06B6D4',
    'compras': '#F97316',
    'salud': '#84CC16',
    'viaje': '#14B8A6',
  };

  static const Map<String, String> _tagIcons = {
    'trabajo': '💼',
    'personal': '👤',
    'importante': '⚠️',
    'idea': '💡',
    'proyecto': '📊',
    'estudio': '📚',
    'casa': '🏠',
    'compras': '🛒',
    'salud': '❤️',
    'viaje': '✈️',
  };

  static String getTagColor(String tag) {
    final normalizedTag = tag.trim().toLowerCase();
    return _tagColors[normalizedTag] ?? '#8B5CF6';
  }

  static String? getTagIcon(String tag) {
    final normalizedTag = tag.trim().toLowerCase();
    return _tagIcons[normalizedTag];
  }
}

// ============================================
// WIDGET PRINCIPAL
// ============================================

class TagChip extends StatelessWidget {
  final String tag;
  final int? count;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isSelected;
  final bool showIcon;
  final TagChipSize size;
  final bool clickable;
  final EdgeInsets? customPadding;

  const TagChip({
    super.key,
    required this.tag,
    this.count,
    this.onTap,
    this.onDelete,
    this.isSelected = false,
    this.showIcon = true,
    this.size = TagChipSize.medium,
    this.clickable = true,
    this.customPadding,
  });

  Color get _tagColor {
    final colorHex = TagUtils.getTagColor(tag);
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (e) {
      return const Color(0xFF8B5CF6);
    }
  }

  String? get _tagIcon => TagUtils.getTagIcon(tag);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determinar si el chip es clickeable
    final isClickable = clickable && onTap != null;
    
    // Colores según estado
    final backgroundColor = isSelected
        ? _tagColor
        : isDarkMode
            ? _tagColor.withValues(alpha: 0.15)
            : _tagColor.withValues(alpha: 0.1);
    
    final borderColor = isSelected
        ? _tagColor
        : _tagColor.withValues(alpha: 0.5);
    
    final textColor = isSelected
        ? Colors.white
        : _tagColor;
    
    final iconColor = isSelected
        ? Colors.white.withValues(alpha: 0.9)
        : _tagColor;

    // Padding personalizado o por defecto
    final padding = customPadding ?? EdgeInsets.symmetric(
      horizontal: size.paddingHorizontal,
      vertical: size.paddingVertical,
    );

    // Widget base del chip
    final chip = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: _tagColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono
          if (showIcon && _tagIcon != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                _tagIcon!,
                style: TextStyle(
                  fontSize: size.iconSize + 2,
                  color: iconColor,
                ),
              ),
            ),
          if (showIcon && _tagIcon == null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.tag,
                size: size.iconSize,
                color: iconColor,
              ),
            ),
          
          // Nombre de la etiqueta
          Text(
            '#$tag',
            style: GoogleFonts.poppins(
              fontSize: size.fontSize,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: textColor,
            ),
          ),
          
          // Contador (opcional)
          if (count != null && count! > 0)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : _tagColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatCount(count!),
                  style: GoogleFonts.poppins(
                    fontSize: size.fontSize - 2,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            ),
          
          // Botón de eliminar (opcional)
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.close,
                  size: size.iconSize,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.8)
                      : textColor.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );

    // Envolver con GestureDetector si es clickeable
    if (isClickable) {
      return GestureDetector(
        onTap: onTap,
        child: chip,
      );
    }

    return chip;
  }

  String _formatCount(int count) {
    if (count > 99) return '99+';
    return '$count';
  }
}

// ============================================
// VARIANTES PREDEFINIDAS
// ============================================

/// Variante para usar en listas (tamaño pequeño)
class TagChipSmall extends StatelessWidget {
  final String tag;
  final int? count;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isSelected;
  final bool showIcon;

  const TagChipSmall({
    super.key,
    required this.tag,
    this.count,
    this.onTap,
    this.onDelete,
    this.isSelected = false,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return TagChip(
      tag: tag,
      count: count,
      onTap: onTap,
      onDelete: onDelete,
      isSelected: isSelected,
      showIcon: showIcon,
      size: TagChipSize.small,
    );
  }
}

/// Variante para usar en tarjetas (tamaño mediano)
class TagChipMedium extends StatelessWidget {
  final String tag;
  final int? count;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isSelected;
  final bool showIcon;

  const TagChipMedium({
    super.key,
    required this.tag,
    this.count,
    this.onTap,
    this.onDelete,
    this.isSelected = false,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return TagChip(
      tag: tag,
      count: count,
      onTap: onTap,
      onDelete: onDelete,
      isSelected: isSelected,
      showIcon: showIcon,
      size: TagChipSize.medium,
    );
  }
}

/// Variante para usar en encabezados (tamaño grande)
class TagChipLarge extends StatelessWidget {
  final String tag;
  final int? count;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isSelected;
  final bool showIcon;

  const TagChipLarge({
    super.key,
    required this.tag,
    this.count,
    this.onTap,
    this.onDelete,
    this.isSelected = false,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return TagChip(
      tag: tag,
      count: count,
      onTap: onTap,
      onDelete: onDelete,
      isSelected: isSelected,
      showIcon: showIcon,
      size: TagChipSize.large,
    );
  }
}

/// Variante para modo selección (con checkbox visual)
class TagChipSelectable extends StatelessWidget {
  final String tag;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showIcon;

  const TagChipSelectable({
    super.key,
    required this.tag,
    this.count,
    required this.isSelected,
    required this.onTap,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return TagChip(
      tag: tag,
      count: count,
      onTap: onTap,
      isSelected: isSelected,
      showIcon: showIcon,
      size: TagChipSize.medium,
      clickable: true,
    );
  }
}

/// Variante solo lectura (sin interacción)
class TagChipReadOnly extends StatelessWidget {
  final String tag;
  final int? count;
  final bool showIcon;

  const TagChipReadOnly({
    super.key,
    required this.tag,
    this.count,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return TagChip(
      tag: tag,
      count: count,
      showIcon: showIcon,
      clickable: false,
    );
  }
}