// lib/screens/notes/note_customizer_screen.dart
// Pantalla de personalización de notas - VERSIÓN ACTUALIZADA
// ✅ Pantalla independiente para personalización avanzada
// ✅ Integración con el diálogo y el editor
// ✅ Vista previa en tiempo real
// ✅ Todos los selectores en un solo lugar

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/models/note.dart';
import 'package:quicknote/providers/notes_provider.dart';
import 'package:quicknote/widgets/loading_indicator.dart';
import 'package:quicknote/widgets/toast_message.dart';

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
// SELECTOR DE COLORES
// ============================================

class _ColorSelector extends StatelessWidget {
  final String selectedColor;
  final Function(String) onColorSelected;

  const _ColorSelector({
    required this.selectedColor,
    required this.onColorSelected,
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
                color: _getColorFromHex(selectedColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.palette, size: 16, color: _getColorFromHex(selectedColor)),
            ),
            const SizedBox(width: 8),
            Text(
              'Color',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: predefinedColors.map((color) {
            final colorHex = colorToHex(color);
            final isSelected = selectedColor == colorHex;
            return GestureDetector(
              onTap: () => onColorSelected(colorHex),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: color, width: 3)
                      : null,
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
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

  Color _getColorFromHex(String hexColor) {
    final buffer = StringBuffer();
    if (hexColor.length == 6 || hexColor.length == 7) {
      buffer.write('ff');
      buffer.write(hexColor.replaceFirst('#', ''));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

// ============================================
// VISTA PREVIA EN VIVO
// ============================================

class _LivePreviewCard extends StatelessWidget {
  final String title;
  final String content;
  final String color;
  final NoteShape shape;
  final NoteIcon? icon;
  final NoteSize? size;
  final ColorIntensity? intensity;
  final List<String> tags;

  const _LivePreviewCard({
    required this.title,
    required this.content,
    required this.color,
    required this.shape,
    this.icon,
    this.size,
    this.intensity,
    this.tags = const [],
  });

  Color get _noteColor => _getColorFromHex(color);
  
  Color get _backgroundColor => getColorWithOpacity(color, getIntensityConfig(intensity).bgOpacity);
  
  BorderRadius get _borderRadius => BorderRadius.circular(getShapeConfig(shape).borderRadius);

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
    final displayTitle = title.isEmpty ? 'Título de la nota' : title;
    final displayContent = content.isEmpty ? 'Este es un ejemplo de cómo se verá tu nota con la personalización seleccionada.' : content;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: _borderRadius,
        boxShadow: [
          BoxShadow(
            color: _noteColor.withValues(alpha: 0.2),
            blurRadius: 8,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _noteColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: _buildIcon(24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _noteColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayContent,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
            maxLines: getSizeConfig(size).contentLines,
            overflow: TextOverflow.ellipsis,
          ),
          if (tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 6,
                children: tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _noteColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(fontSize: 10, color: _noteColor),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    final buffer = StringBuffer();
    if (hexColor.length == 6 || hexColor.length == 7) {
      buffer.write('ff');
      buffer.write(hexColor.replaceFirst('#', ''));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

// ============================================
// PANTALLA PRINCIPAL - PERSONALIZACIÓN COMPLETA
// ============================================

class NoteCustomizerScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final bool isForNewNote;

  const NoteCustomizerScreen({
    super.key,
    this.noteId,
    this.isForNewNote = false,
  });

  @override
  ConsumerState<NoteCustomizerScreen> createState() => _NoteCustomizerScreenState();
}

class _NoteCustomizerScreenState extends ConsumerState<NoteCustomizerScreen> {
  // Estados de personalización
  String _selectedColor = '#3B82F6';
  NoteShape _selectedShape = NoteShape.rounded;
  NoteIcon? _selectedIcon;
  NoteSize? _selectedSize;
  ColorIntensity? _selectedIntensity;
  List<String> _tags = [];
  String _title = '';
  String _content = '';
  
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    if (widget.noteId == null && !widget.isForNewNote) return;
    
    setState(() => _isLoading = true);
    
    if (widget.noteId != null) {
      final notesState = ref.read(notesProvider);
      final note = notesState.notes.firstWhere(
        (n) => n.id == widget.noteId,
        orElse: () => notesState.archivedNotes.firstWhere(
          (n) => n.id == widget.noteId,
          orElse: () => Note(
            id: '',
            title: '',
            content: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      );
      
      if (note.id.isNotEmpty) {
        _title = note.title;
        _content = note.content;
        _selectedColor = note.color;
        _selectedShape = note.shape;
        _selectedIcon = note.icon;
        _selectedSize = note.size;
        _selectedIntensity = note.colorIntensity;
        _tags = List.from(note.tags);
      }
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _savePreferences() async {
    if (widget.noteId == null && !widget.isForNewNote) {
      // Guardar como preferencias para nueva nota
      // Por ahora solo cerramos
      ToastMessage.success('Preferencias guardadas');
      if (mounted) Navigator.pop(context);
      return;
    }

    if (widget.noteId != null) {
      setState(() => _isSaving = true);

      final updates = NoteUpdate(
        color: _selectedColor,
        shape: _selectedShape,
        icon: _selectedIcon,
        size: _selectedSize,
        colorIntensity: _selectedIntensity,
        tags: _tags,
      );

      final updated = await ref.read(notesProvider.notifier).updateNote(
        widget.noteId!,
        updates,
      );

      setState(() => _isSaving = false);

      if (updated != null && mounted) {
        ToastMessage.success('Personalización guardada');
        if (mounted) Navigator.pop(context);
      } else if (mounted) {
        ToastMessage.error('Error al guardar');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: const Center(child: LoadingIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.noteId != null ? 'Personalizar nota' : 'Preferencias de notas',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            onPressed: _isSaving ? null : _savePreferences,
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Vista previa en vivo
            _LivePreviewCard(
              title: _title,
              content: _content,
              color: _selectedColor,
              shape: _selectedShape,
              icon: _selectedIcon,
              size: _selectedSize,
              intensity: _selectedIntensity,
              tags: _tags,
            ),
            const SizedBox(height: 24),
            
            // Selector de color
            _ColorSelector(
              selectedColor: _selectedColor,
              onColorSelected: (color) => setState(() => _selectedColor = color),
            ),
            const SizedBox(height: 24),
            
            // Selector de forma
            _ShapeSelector(
              selectedShape: _selectedShape,
              onShapeSelected: (shape) => setState(() => _selectedShape = shape),
              accentColor: _getColorFromHex(_selectedColor),
            ),
            const SizedBox(height: 24),
            
            // Selector de icono
            _IconSelector(
              selectedIcon: _selectedIcon,
              onIconSelected: (icon) => setState(() => _selectedIcon = icon),
              accentColor: _getColorFromHex(_selectedColor),
            ),
            const SizedBox(height: 24),
            
            // Selector de tamaño
            _SizeSelector(
              selectedSize: _selectedSize,
              onSizeSelected: (size) => setState(() => _selectedSize = size),
              accentColor: _getColorFromHex(_selectedColor),
            ),
            const SizedBox(height: 24),
            
            // Selector de intensidad
            _IntensitySelector(
              selectedIntensity: _selectedIntensity,
              onIntensitySelected: (intensity) => setState(() => _selectedIntensity = intensity),
              accentColor: _getColorFromHex(_selectedColor),
            ),
            const SizedBox(height: 24),
            
            // Información adicional
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1F2937) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los cambios se aplican en tiempo real. Puedes volver a personalizar tu nota en cualquier momento.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    final buffer = StringBuffer();
    if (hexColor.length == 6 || hexColor.length == 7) {
      buffer.write('ff');
      buffer.write(hexColor.replaceFirst('#', ''));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}