// lib/screens/notes/advanced_customization_dialog.dart
// Diálogo para personalización avanzada de notas
// ✅ CORREGIDO: Manejo correcto de colores (hex string)
// ✅ Selector de forma, icono, tamaño, intensidad
// ✅ Vista previa en tiempo real

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/models/note.dart';

// ============================================
// SELECTOR DE FORMAS
// ============================================

class _ShapeSelector extends StatelessWidget {
  final NoteShape selectedShape;
  final Function(NoteShape) onShapeSelected;
  final Color accentColor;

  const _ShapeSelector({
    required this.selectedShape,
    required this.onShapeSelected,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.crop_square, size: 16, color: accentColor),
            ),
            const SizedBox(width: 8),
            Text(
              'Forma',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: noteShapes.map((shape) {
            final isSelected = selectedShape == shape.value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onShapeSelected(shape.value),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.15)
                        : (isDarkMode ? const Color(0xFF1F2937) : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(shape.borderRadius),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        shape.label,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? accentColor
                              : (isDarkMode ? Colors.white70 : Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ============================================
// SELECTOR DE ICONOS
// ============================================

class _IconSelector extends StatelessWidget {
  final NoteIcon? selectedIcon;
  final Function(NoteIcon?) onIconSelected;
  final Color accentColor;

  const _IconSelector({
    required this.selectedIcon,
    required this.onIconSelected,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.emoji_emotions, size: 16, color: accentColor),
            ),
            const SizedBox(width: 8),
            Text(
              'Icono',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            if (selectedIcon != null)
              GestureDetector(
                onTap: () => onIconSelected(null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Quitar icono',
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: noteIcons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final icon = noteIcons[index];
              final isSelected = selectedIcon == icon.value;
              
              return GestureDetector(
                onTap: () => onIconSelected(icon.value),
                child: Container(
                  width: 70,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.15)
                        : (isDarkMode ? const Color(0xFF1F2937) : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      icon.value == NoteIcon.default_
                          ? Icon(Icons.edit_note, color: isSelected ? accentColor : null, size: 28)
                          : Text(
                              icon.iconName,
                              style: TextStyle(
                                fontSize: 28,
                                color: isSelected ? accentColor : null,
                              ),
                            ),
                      const SizedBox(height: 6),
                      Text(
                        icon.label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: isSelected ? accentColor : (isDarkMode ? Colors.white70 : Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================
// SELECTOR DE TAMAÑOS
// ============================================

class _SizeSelector extends StatelessWidget {
  final NoteSize? selectedSize;
  final Function(NoteSize?) onSizeSelected;
  final Color accentColor;

  const _SizeSelector({
    required this.selectedSize,
    required this.onSizeSelected,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.crop, size: 16, color: accentColor),
            ),
            const SizedBox(width: 8),
            Text(
              'Tamaño',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: noteSizes.map((size) {
            final isSelected = selectedSize == size.value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSizeSelected(size.value),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.15)
                        : (isDarkMode ? const Color(0xFF1F2937) : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: size.value == NoteSize.compact ? 30 : (size.value == NoteSize.normal ? 40 : 50),
                        height: 4,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        size.label,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? accentColor
                              : (isDarkMode ? Colors.white70 : Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ============================================
// SELECTOR DE INTENSIDAD DE COLOR
// ============================================

class _IntensitySelector extends StatelessWidget {
  final ColorIntensity? selectedIntensity;
  final Function(ColorIntensity?) onIntensitySelected;
  final Color accentColor;

  const _IntensitySelector({
    required this.selectedIntensity,
    required this.onIntensitySelected,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.opacity, size: 16, color: accentColor),
            ),
            const SizedBox(width: 8),
            Text(
              'Intensidad de color',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: colorIntensities.map((intensity) {
            final isSelected = selectedIntensity == intensity.value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onIntensitySelected(intensity.value),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.15)
                        : (isDarkMode ? const Color(0xFF1F2937) : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: isSelected ? 0.5 : 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        intensity.label,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? accentColor
                              : (isDarkMode ? Colors.white70 : Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ============================================
// VISTA PREVIA EN VIVO (MINIATURA)
// ============================================

class _MiniPreviewCard extends StatelessWidget {
  final String colorHex;  // ← Ahora recibe hex string directamente
  final NoteShape shape;
  final NoteIcon? icon;
  final NoteSize? size;
  final ColorIntensity? intensity;
  final String title;
  final String content;

  const _MiniPreviewCard({
    required this.colorHex,
    required this.shape,
    this.icon,
    this.size,
    this.intensity,
    required this.title,
    required this.content,
  });

  Color get _noteColor => _getColorFromHex(colorHex);
  
  Color get _backgroundColor => getColorWithOpacity(colorHex, getIntensityConfig(intensity).bgOpacity);
  
  BorderRadius get _borderRadius => BorderRadius.circular(getShapeConfig(shape).borderRadius);
  SizeConfig get _sizeConfig => getSizeConfig(size);

  Widget _buildIcon(double iconSize) {
    final iconConfig = getIconConfig(icon);
    if (iconConfig.value == NoteIcon.default_) {
      return Icon(Icons.edit_note, size: iconSize, color: _noteColor);
    }
    return Text(iconConfig.iconName, style: TextStyle(fontSize: iconSize, color: _noteColor));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final displayTitle = title.isEmpty ? 'Título' : title;
    final displayContent = content.isEmpty ? 'Contenido de la nota...' : content;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: _borderRadius,
        boxShadow: [
          BoxShadow(
            color: _noteColor.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _noteColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: _buildIcon(18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  displayTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _noteColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            displayContent,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
            maxLines: _sizeConfig.contentLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    final buffer = StringBuffer();
    String cleanHex = hexColor;
    if (!cleanHex.startsWith('#')) {
      cleanHex = '#$cleanHex';
    }
    if (cleanHex.length == 6 || cleanHex.length == 7) {
      buffer.write('ff');
      buffer.write(cleanHex.replaceFirst('#', ''));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

// ============================================
// DIÁLOGO PRINCIPAL
// ============================================

class AdvancedCustomizationDialog extends StatefulWidget {
  final NoteShape initialShape;
  final NoteIcon? initialIcon;
  final NoteSize? initialSize;
  final ColorIntensity? initialIntensity;
  final Color accentColor;

  const AdvancedCustomizationDialog({
    super.key,
    required this.initialShape,
    this.initialIcon,
    this.initialSize,
    this.initialIntensity,
    required this.accentColor,
  });

  @override
  State<AdvancedCustomizationDialog> createState() => _AdvancedCustomizationDialogState();
}

class _AdvancedCustomizationDialogState extends State<AdvancedCustomizationDialog> {
  late NoteShape _selectedShape;
  late NoteIcon? _selectedIcon;
  late NoteSize? _selectedSize;
  late ColorIntensity? _selectedIntensity;

  @override
  void initState() {
    super.initState();
    _selectedShape = widget.initialShape;
    _selectedIcon = widget.initialIcon;
    _selectedSize = widget.initialSize;
    _selectedIntensity = widget.initialIntensity;
  }

  void _applyAndClose() {
    Navigator.of(context).pop({
      'shape': _selectedShape,
      'icon': _selectedIcon,
      'size': _selectedSize,
      'intensity': _selectedIntensity,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Convertir Color a hex string
    final colorHex = _colorToHex(widget.accentColor);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.palette, color: widget.accentColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalización avanzada',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'Personaliza el estilo de tu nota',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: widget.accentColor),
                  ),
                ],
              ),
            ),
            
            // Vista previa en vivo (mini)
            Padding(
              padding: const EdgeInsets.all(20),
              child: _MiniPreviewCard(
                colorHex: colorHex,
                shape: _selectedShape,
                icon: _selectedIcon,
                size: _selectedSize,
                intensity: _selectedIntensity,
                title: 'Vista previa',
                content: 'Así se verá tu nota con la personalización seleccionada.',
              ),
            ),
            
            // Contenido del diálogo (scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _ShapeSelector(
                      selectedShape: _selectedShape,
                      onShapeSelected: (shape) => setState(() => _selectedShape = shape),
                      accentColor: widget.accentColor,
                    ),
                    const SizedBox(height: 24),
                    _IconSelector(
                      selectedIcon: _selectedIcon,
                      onIconSelected: (icon) => setState(() => _selectedIcon = icon),
                      accentColor: widget.accentColor,
                    ),
                    const SizedBox(height: 24),
                    _SizeSelector(
                      selectedSize: _selectedSize,
                      onSizeSelected: (size) => setState(() => _selectedSize = size),
                      accentColor: widget.accentColor,
                    ),
                    const SizedBox(height: 24),
                    _IntensitySelector(
                      selectedIntensity: _selectedIntensity,
                      onIntensitySelected: (intensity) => setState(() => _selectedIntensity = intensity),
                      accentColor: widget.accentColor,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Botones de acción
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1F2937) : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancelar', style: GoogleFonts.poppins()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyAndClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Aplicar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _colorToHex(Color color) {
    final int hex = color.toARGB32();
    return '#${(hex & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}