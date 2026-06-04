// lib/widgets/note_form.dart
// Formulario simplificado para crear/editar notas

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/models/note.dart';
import 'package:quicknote/widgets/tag_chip.dart';
import 'package:quicknote/widgets/toast_message.dart';

class NoteForm extends StatefulWidget {
  final Note? initialNote;
  final Function(NoteCreate) onSubmit;
  final VoidCallback onCancel;
  final VoidCallback onCustomize;
  final bool isSubmitting;
  final bool isEditing;

  const NoteForm({
    super.key,
    this.initialNote,
    required this.onSubmit,
    required this.onCancel,
    required this.onCustomize,
    this.isSubmitting = false,
    this.isEditing = false,
  });

  @override
  State<NoteForm> createState() => _NoteFormState();
}

class _NoteFormState extends State<NoteForm> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagController;
  late bool _isFavorite;
  late String _color;
  late NoteShape _shape;
  late NoteIcon? _icon;
  late NoteSize? _size;
  late ColorIntensity? _colorIntensity;
  late List<String> _tags;
  
  bool _showPreview = false;
  String? _tagError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    _titleController = TextEditingController(text: widget.initialNote?.title ?? '');
    _contentController = TextEditingController(text: widget.initialNote?.content ?? '');
    _tagController = TextEditingController();
    _isFavorite = widget.initialNote?.isFavorite ?? false;
    _color = widget.initialNote?.color ?? '#3B82F6';
    _shape = widget.initialNote?.shape ?? NoteShape.rounded;
    _icon = widget.initialNote?.icon;
    _size = widget.initialNote?.size;
    _colorIntensity = widget.initialNote?.colorIntensity;
    _tags = List.from(widget.initialNote?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  int get _wordCount {
    final content = _contentController.text.trim();
    return content.isEmpty ? 0 : content.split(RegExp(r'\s+')).length;
  }

  int get _charCount => _contentController.text.length;

  bool get _canAddTag => _tags.length < 10 && _tagController.text.trim().isNotEmpty;

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase();
    if (tag.isEmpty) {
      setState(() => _tagError = 'La etiqueta no puede estar vacía');
      return;
    }
    if (tag.length > 30) {
      setState(() => _tagError = 'Máximo 30 caracteres');
      return;
    }
    if (_tags.contains(tag)) {
      setState(() => _tagError = 'Ya existe');
      return;
    }
    if (_tags.length >= 10) {
      setState(() => _tagError = 'Máximo 10 etiquetas');
      return;
    }

    setState(() {
      _tags.add(tag);
      _tagController.clear();
      _tagError = null;
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  String? _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      return 'El título es requerido';
    }
    if (_titleController.text.length > 200) {
      return 'Máximo 200 caracteres';
    }
    if (_contentController.text.length > 10000) {
      return 'Máximo 10,000 caracteres';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    final error = _validateForm();
    if (error != null) {
      ToastMessage.error(error);
      return;
    }

    setState(() => _isSubmitting = true);
    
    final noteData = NoteCreate(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      color: _color,
      shape: _shape,
      icon: _icon,
      size: _size,
      colorIntensity: _colorIntensity,
      isFavorite: _isFavorite,
      isArchived: widget.initialNote?.isArchived ?? false,
      tags: _tags,
    );
    
    await widget.onSubmit(noteData);
    
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSubmitting = widget.isSubmitting || _isSubmitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDarkMode),
          const SizedBox(height: 24),
          _buildTitleField(isDarkMode),
          const SizedBox(height: 20),
          _buildContentField(isDarkMode),
          const SizedBox(height: 20),
          _buildTagsSection(isDarkMode),
          const SizedBox(height: 20),
          _buildStatsRow(isDarkMode),
          const SizedBox(height: 20),
          _buildPreviewSection(isDarkMode),
          const SizedBox(height: 20),
          _buildCustomizeButton(isDarkMode),
          const SizedBox(height: 20),
          _buildActionButtons(isDarkMode, isSubmitting),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: const Icon(Icons.edit_note, size: 30, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          widget.isEditing ? '✏️ Editar nota' : '✨ Crear nueva nota',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              ).createShader(const Rect.fromLTWH(0, 0, 200, 30)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Completa los detalles básicos de tu nota',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.title, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text('Título', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(
              '${_titleController.text.length}/200',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: '¿Qué necesitas hacer?',
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            ),
            suffixIcon: _titleController.text.isNotEmpty
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildContentField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.description, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text('Descripción', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(
              '$_wordCount palabras · $_charCount caracteres',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _showPreview = !_showPreview),
              icon: Icon(_showPreview ? Icons.visibility_off : Icons.visibility, size: 16),
              label: Text(_showPreview ? 'Ocultar vista previa' : 'Mostrar vista previa'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF8B5CF6)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _showPreview
              ? _buildPreviewContent(isDarkMode)
              : TextField(
                  controller: _contentController,
                  style: GoogleFonts.poppins(),
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Describe tu nota en detalle...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPreviewContent(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
      ),
      child: _contentController.text.isEmpty
          ? Center(
              child: Text(
                'Sin contenido',
                style: GoogleFonts.poppins(color: Colors.grey.shade400),
              ),
            )
          : Text(
              _contentController.text,
              style: GoogleFonts.poppins(),
            ),
    );
  }

  Widget _buildTagsSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tag, size: 20, color: const Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Text('Etiquetas', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_tags.length}/10',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8B5CF6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    hintText: 'ej: trabajo, personal, idea',
                    hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    errorText: _tagError,
                    errorStyle: GoogleFonts.poppins(fontSize: 10),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _canAddTag ? _addTag : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Icon(Icons.add, size: 20),
              ),
            ],
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) => TagChip(
                tag: tag,
                onDelete: () => _removeTag(tag),
                showIcon: true,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDarkMode) {
    return Row(
      children: [
        _buildStatCard(Icons.text_fields, 'Palabras', _wordCount, isDarkMode),
        const SizedBox(width: 12),
        _buildStatCard(Icons.abc, 'Caracteres', _charCount, isDarkMode),
        const SizedBox(width: 12),
        _buildStatCard(Icons.tag, 'Etiquetas', _tags.length, isDarkMode),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isFavorite = !_isFavorite),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Icon(
                    _isFavorite ? Icons.star : Icons.star_border,
                    color: _isFavorite ? Colors.amber : Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isFavorite ? 'Sí' : 'No',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  Text('Favorita', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String label, int value, bool isDarkMode) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade500),
            const SizedBox(height: 4),
            Text('$value', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(bool isDarkMode) {
    final colorValue = Color(int.parse(_color.substring(1, 7), radix: 16));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.palette, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text('Vista previa', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorValue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorValue.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorValue.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit_note, size: 14, color: colorValue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _titleController.text.isEmpty ? 'Título de la nota' : _titleController.text,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _contentController.text.isEmpty ? 'Sin contenido' : _contentController.text,
                style: GoogleFonts.poppins(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: _tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorValue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('#$tag', style: GoogleFonts.poppins(fontSize: 10)),
                  )).toList(),
                ),
                if (_tags.length > 3)
                  Text('+${_tags.length - 3}', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomizeButton(bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.onCustomize,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.palette, size: 20),
            SizedBox(width: 8),
            Text('🎨 Personaliza tu experiencia', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isDarkMode, bool isSubmitting) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: isDarkMode ? Colors.white : Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.close, size: 20),
                SizedBox(width: 8),
                Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, size: 20),
                      SizedBox(width: 8),
                      Text('Crear nota', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}