// lib/screens/notes/note_editor_screen.dart
// Pantalla de edición de nota - VERSIÓN SIMPLIFICADA
// ✅ Responsabilidad única: editar notas existentes
// ✅ Personalización avanzada en diálogo aparte
// ✅ Vista previa en vivo
// ✅ Selector de color, etiquetas y favorito/archivo

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/models/note.dart';
import 'package:quicknote/providers/notes_provider.dart';
import 'package:quicknote/screens/notes/advanced_customization_dialog.dart';
import 'package:quicknote/widgets/loading_indicator.dart';
import 'package:quicknote/widgets/tag_chip.dart';
import 'package:quicknote/widgets/toast_message.dart';
import 'package:quicknote/widgets/app_bottom_nav.dart';

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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
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
// SECCIÓN DE ETIQUETAS
// ============================================

class _TagsSection extends StatefulWidget {
  final List<String> tags;
  final Function(List<String>) onTagsChanged;
  final Color accentColor;

  const _TagsSection({
    required this.tags,
    required this.onTagsChanged,
    required this.accentColor,
  });

  @override
  State<_TagsSection> createState() => _TagsSectionState();
}

class _TagsSectionState extends State<_TagsSection> {
  final TextEditingController _tagController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase();
    if (tag.isEmpty) {
      setState(() => _error = 'La etiqueta no puede estar vacía');
      return;
    }
    if (tag.length > 30) {
      setState(() => _error = 'Máximo 30 caracteres');
      return;
    }
    if (widget.tags.contains(tag)) {
      setState(() => _error = 'Esta etiqueta ya existe');
      return;
    }
    if (widget.tags.length >= 10) {
      setState(() => _error = 'Máximo 10 etiquetas');
      return;
    }

    final newTags = [...widget.tags, tag];
    widget.onTagsChanged(newTags);
    _tagController.clear();
    setState(() => _error = null);
  }

  void _removeTag(String tag) {
    final newTags = widget.tags.where((t) => t != tag).toList();
    widget.onTagsChanged(newTags);
  }

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
                color: widget.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.tag, size: 16, color: widget.accentColor),
            ),
            const SizedBox(width: 8),
            Text(
              'Etiquetas',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            Text(
              '${widget.tags.length}/10',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: widget.accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...widget.tags.map((tag) => TagChip(
              tag: tag,
              onDelete: () => _removeTag(tag),
              showIcon: true,
            )),
            Container(
              height: 36,
              width: 120,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'Nueva',
                        hintStyle: TextStyle(fontSize: 12),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: _addTag,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.red),
            ),
          ),
      ],
    );
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
            maxLines: 3,
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
// PANTALLA PRINCIPAL - EDITOR
// ============================================

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String noteId;
  
  const NoteEditorScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  // Estados de personalización
  String _selectedColor = '#3B82F6';
  NoteShape _selectedShape = NoteShape.rounded;
  NoteIcon? _selectedIcon;
  NoteSize? _selectedSize;
  ColorIntensity? _selectedIntensity;
  List<String> _tags = [];
  bool _isFavorite = false;
  bool _isArchived = false;
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    setState(() => _isLoading = true);
    
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
    
    if (note.id.isNotEmpty && mounted) {
      _titleController.text = note.title;
      _contentController.text = note.content;
      _selectedColor = note.color;
      _selectedShape = note.shape;
      _selectedIcon = note.icon;
      _selectedSize = note.size;
      _selectedIntensity = note.colorIntensity;
      _tags = List.from(note.tags);
      _isFavorite = note.isFavorite;
      _isArchived = note.isArchived;
    } else if (mounted) {
      ToastMessage.error('Nota no encontrada');
      context.go('/notes');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'El título es requerido');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final noteUpdate = NoteUpdate(
      title: _titleController.text.trim(),
      content: _contentController.text,
      color: _selectedColor,
      shape: _selectedShape,
      icon: _selectedIcon,
      size: _selectedSize,
      colorIntensity: _selectedIntensity,
      isFavorite: _isFavorite,
      isArchived: _isArchived,
      tags: _tags,
    );

    final updated = await ref.read(notesProvider.notifier).updateNote(
      widget.noteId,
      noteUpdate,
    );

    if (mounted) {
      setState(() => _isSaving = false);
    }

    if (updated != null && mounted) {
      ToastMessage.success('Nota actualizada exitosamente');
      context.go('/notes/${widget.noteId}');
    } else if (mounted) {
      setState(() => _error = 'Error al actualizar la nota');
      ToastMessage.error('Error al actualizar la nota');
    }
  }

  Future<void> _openAdvancedCustomization() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AdvancedCustomizationDialog(
        initialShape: _selectedShape,
        initialIcon: _selectedIcon,
        initialSize: _selectedSize,
        initialIntensity: _selectedIntensity,
        accentColor: _getColorFromHex(_selectedColor),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (result['shape'] != null) _selectedShape = result['shape'] as NoteShape;
        if (result['icon'] != null) _selectedIcon = result['icon'] as NoteIcon?;
        if (result['size'] != null) _selectedSize = result['size'] as NoteSize?;
        if (result['intensity'] != null) _selectedIntensity = result['intensity'] as ColorIntensity?;
      });
      ToastMessage.success('Personalización actualizada');
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
          'Editar nota',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/notes/${widget.noteId}'),
        ),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
            tooltip: 'Favorito',
          ),
          IconButton(
            icon: Icon(_isArchived ? Icons.unarchive : Icons.archive),
            onPressed: () => setState(() => _isArchived = !_isArchived),
            tooltip: 'Archivar',
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveNote,
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vista previa en vivo
            _LivePreviewCard(
              title: _titleController.text,
              content: _contentController.text,
              color: _selectedColor,
              shape: _selectedShape,
              icon: _selectedIcon,
              size: _selectedSize,
              intensity: _selectedIntensity,
              tags: _tags,
            ),
            const SizedBox(height: 24),
            
            // Título
            TextField(
              controller: _titleController,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: const InputDecoration(
                hintText: 'Título de la nota',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            
            // Contenido
            TextField(
              controller: _contentController,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.grey.shade800,
              ),
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Escribe tu nota aquí...',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 24),
            
            // Selector de color
            _ColorSelector(
              selectedColor: _selectedColor,
              onColorSelected: (color) => setState(() => _selectedColor = color),
            ),
            const SizedBox(height: 24),
            
            // Sección de etiquetas
            _TagsSection(
              tags: _tags,
              onTagsChanged: (tags) => setState(() => _tags = tags),
              accentColor: _getColorFromHex(_selectedColor),
            ),
            const SizedBox(height: 24),
            
            // Botón de personalización avanzada
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openAdvancedCustomization,
                icon: const Icon(Icons.palette, size: 18),
                label: Text(
                  'Personalización avanzada',
                  style: GoogleFonts.poppins(),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Mensaje de error
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
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