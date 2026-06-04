// lib/screens/notes/note_detail_screen.dart
// Pantalla de detalle de nota - VERSIÓN CORREGIDA
// ✅ CORREGIDA: Validación correcta de existencia de notas
// ✅ CORREGIDA: Navegación segura con go() y push()
// ✅ MEJORADA: Logs detallados para depuración
// ✅ MEJORADA: Manejo de errores robusto

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/models/note.dart';
import 'package:quicknote/providers/notes_provider.dart';
import 'package:quicknote/widgets/loading_indicator.dart';
import 'package:quicknote/widgets/export_button.dart';
import 'package:quicknote/widgets/toast_message.dart';
import 'package:intl/intl.dart';

// ============================================
// LOGGER INTERNO MEJORADO
// ============================================

class _NoteDetailLogger {
  static void info(String message) {
    debugPrint('ℹ️ [NoteDetail] $message');
  }
  static void success(String message) {
    debugPrint('✅ [NoteDetail] $message');
  }
  static void error(String message) {
    debugPrint('❌ [NoteDetail] $message');
  }
  static void warning(String message) {
    debugPrint('⚠️ [NoteDetail] $message');
  }
}

// ============================================
// WIDGETS AUXILIARES
// ============================================

/// Badge de estado (Favorita/Archivada)
class StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de información (fechas)
class InfoCard extends StatelessWidget {
  final DateTime createdAt;
  final DateTime updatedAt;
  final Color accentColor;

  const InfoCard({
    super.key,
    required this.createdAt,
    required this.updatedAt,
    required this.accentColor,
  });

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_today,
            'Creada',
            _formatDate(createdAt),
            accentColor,
            isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.update,
            'Actualizada',
            _formatDate(updatedAt),
            accentColor,
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color accentColor,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: accentColor),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de etiquetas
class TagsCard extends StatelessWidget {
  final List<String> tags;
  final Color accentColor;
  final Function(String)? onTagTap;

  const TagsCard({
    super.key,
    required this.tags,
    required this.accentColor,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (tags.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tag, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Etiquetas',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${tags.length} ${tags.length == 1 ? 'etiqueta' : 'etiquetas'}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              return GestureDetector(
                onTap: onTagTap != null ? () => onTagTap!(tag) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '#$tag',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: accentColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de acciones rápidas
class QuickActionsCard extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleArchive;
  final VoidCallback onDelete;
  final bool isFavorite;
  final bool isArchived;
  final Color accentColor;

  const QuickActionsCard({
    super.key,
    required this.onEdit,
    required this.onToggleFavorite,
    required this.onToggleArchive,
    required this.onDelete,
    required this.isFavorite,
    required this.isArchived,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Acciones rápidas',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionButton(
                icon: Icons.edit,
                label: 'Editar',
                onTap: onEdit,
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: isFavorite ? Icons.star : Icons.star_border,
                label: isFavorite ? 'Favorita' : 'Favorito',
                onTap: onToggleFavorite,
                color: Colors.amber,
                isActive: isFavorite,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: isArchived ? Icons.unarchive : Icons.archive,
                label: isArchived ? 'Desarchivar' : 'Archivar',
                onTap: onToggleArchive,
                color: Colors.teal,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.delete_outline,
                label: 'Eliminar',
                onTap: onDelete,
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool isActive = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? color : color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: isActive ? color : color),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isActive ? color : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de personalización actual
class PersonalizationCard extends StatelessWidget {
  final Note note;
  final Color accentColor;

  const PersonalizationCard({
    super.key,
    required this.note,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconConfig = note.iconConfig;
    final sizeConfig = note.sizeConfig;
    final intensityConfig = note.intensityConfig;
    final shapeConfig = note.shapeConfig;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Personalización actual',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPersonalizationItem(
                  icon: Icons.emoji_emotions,
                  label: 'Icono',
                  value: iconConfig.label,
                  color: accentColor,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 12),
                _buildPersonalizationItem(
                  icon: Icons.crop,
                  label: 'Tamaño',
                  value: sizeConfig.label,
                  color: accentColor,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 12),
                _buildPersonalizationItem(
                  icon: Icons.opacity,
                  label: 'Intensidad',
                  value: intensityConfig.label,
                  color: accentColor,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 12),
                _buildPersonalizationItem(
                  icon: Icons.crop_square,
                  label: 'Forma',
                  value: shapeConfig.label,
                  color: accentColor,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 12),
                _buildPersonalizationItem(
                  icon: Icons.palette,
                  label: 'Color',
                  value: note.color,
                  color: accentColor,
                  isDarkMode: isDarkMode,
                  showColorPreview: true,
                  colorPreview: note.colorValue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizationItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDarkMode,
    bool showColorPreview = false,
    Color? colorPreview,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (showColorPreview && colorPreview != null)
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: colorPreview,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================
// PANTALLA PRINCIPAL - VERSIÓN CORREGIDA
// ============================================

class NoteDetailScreen extends ConsumerStatefulWidget {
  final String noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  bool _isLoading = true;
  bool _noteExists = true;
  Note? _note;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _NoteDetailLogger.info('📝 Inicializando NoteDetailScreen con ID: ${widget.noteId}');
    _loadNoteWithValidation();
  }

  /// ✅ MÉTODO MEJORADO: Valida existencia de la nota antes de cargar
  Future<void> _loadNoteWithValidation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _NoteDetailLogger.info('🔍 Buscando nota con ID: ${widget.noteId}');

    try {
      final notesState = ref.read(notesProvider);
      
      _NoteDetailLogger.info('📊 Estado actual - Notas: ${notesState.notes.length}, '
          'Archivadas: ${notesState.archivedNotes.length}, '
          'Eliminadas: ${notesState.deletedNotes.length}');

      // ✅ Buscar en TODAS las categorías
      Note? foundNote;

      // 1. Buscar en notas activas
      foundNote = notesState.notes.firstWhere(
        (n) => n.id == widget.noteId,
        orElse: () => Note(
          id: '',
          title: '',
          content: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // 2. Si no está en activas, buscar en archivadas
      if (foundNote.id.isEmpty) {
        _NoteDetailLogger.info('📦 Nota no encontrada en activas, buscando en archivadas...');
        foundNote = notesState.archivedNotes.firstWhere(
          (n) => n.id == widget.noteId,
          orElse: () => Note(
            id: '',
            title: '',
            content: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      // 3. Si no está en archivadas, buscar en eliminadas
      if (foundNote.id.isEmpty) {
        _NoteDetailLogger.warning('🗑️ Nota no encontrada en archivadas, buscando en eliminadas...');
        foundNote = notesState.deletedNotes.firstWhere(
          (n) => n.id == widget.noteId,
          orElse: () => Note(
            id: '',
            title: '',
            content: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      // ✅ Verificar si la nota existe
      if (foundNote.id.isNotEmpty && foundNote.id == widget.noteId) {
        _NoteDetailLogger.success('✅ Nota encontrada: "${foundNote.title}"');
        setState(() {
          _note = foundNote;
          _noteExists = true;
          _isLoading = false;
        });
      } else {
        _NoteDetailLogger.warning('⚠️ Nota NO encontrada en ninguna categoría');
        setState(() {
          _noteExists = false;
          _isLoading = false;
          _errorMessage = 'La nota no existe o ha sido eliminada';
        });
        
        // Mostrar mensaje y regresar después de 2 segundos
        if (mounted) {
          ToastMessage.error('Nota no encontrada');
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _goBack();
            }
          });
        }
      }
    } catch (e, stackTrace) {
      _NoteDetailLogger.error('❌ Error al cargar la nota: $e');
      _NoteDetailLogger.error('Stack trace: $stackTrace');
      
      setState(() {
        _isLoading = false;
        _noteExists = false;
        _errorMessage = 'Error al cargar la nota: $e';
      });
      
      if (mounted) {
        ToastMessage.error('Error al cargar la nota');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _goBack();
          }
        });
      }
    }
  }

  /// ✅ REFRESCAR NOTA (cuando se actualiza desde edición)
  Future<void> _refreshNote() async {
    _NoteDetailLogger.info('🔄 Refrescando nota...');
    await _loadNoteWithValidation();
  }

  /// ✅ NAVEGACIÓN SEGURA - Usa go() para evitar acumulación en el stack
  void _goBack() {
    _NoteDetailLogger.info('🔙 _goBack() llamado - Navegando a /notes');
    if (mounted) {
      // Limpiar el stack y navegar a notas
      context.go('/notes');
    }
  }

  void _safePush(String route) {
    if (mounted) {
      _NoteDetailLogger.info('📍 Push a: $route');
      context.push(route);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_note == null) return;
    
    _NoteDetailLogger.info('⭐ Toggle favorite para: ${_note!.title}');
    await ref.read(notesProvider.notifier).toggleFavorite(_note!.id);
    await _refreshNote();
    
    if (mounted) {
      ToastMessage.success(_note!.isFavorite ? '⭐ Añadida a favoritos' : '⭐ Eliminada de favoritos');
    }
  }

  Future<void> _toggleArchive() async {
    if (_note == null) return;
    
    final wasArchived = _note!.isArchived;
    _NoteDetailLogger.info('📦 Toggle archive para: ${_note!.title} (actual: ${wasArchived ? "archivada" : "activa"})');
    
    await ref.read(notesProvider.notifier).toggleArchive(_note!.id);
    await _refreshNote();
    
    if (mounted) {
      ToastMessage.success(wasArchived ? '📦 Nota restaurada' : '📦 Nota archivada');
    }
    
    // Si la nota fue archivada, salir después de un momento
    if (!wasArchived && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _goBack();
      });
    }
  }

  Future<void> _deleteNote() async {
    if (_note == null) return;
    
    _NoteDetailLogger.info('🗑️ Eliminar nota: ${_note!.title}');
    
    final confirmed = await _showConfirmDialog();
    if (confirmed && mounted) {
      final success = await ref.read(notesProvider.notifier).deleteNote(_note!.id);
      if (success && mounted) {
        ToastMessage.success('🗑️ Nota movida a la papelera');
        _goBack();
      } else if (mounted) {
        ToastMessage.error('Error al eliminar la nota');
      }
    }
  }

  void _editNote() {
    if (_note != null && mounted) {
      _NoteDetailLogger.info('✏️ Editando nota: ${_note!.title}');
      _safePush('/notes/${_note!.id}/edit');
    }
  }

  void _onTagTap(String tag) {
    if (mounted) {
      _NoteDetailLogger.info('# Tag tap: $tag');
      _safePush('/tags/$tag');
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar nota'),
        content: const Text('¿Eliminar esta nota permanentemente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // ✅ Estado de carga
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: const Center(child: LoadingIndicator()),
      );
    }

    // ✅ Estado de error/nota no encontrada - UI MEJORADA
    if (!_noteExists || _note == null || _note!.id.isEmpty) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Nota no encontrada'),
          centerTitle: true,
          backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Nota no encontrada',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'La nota que intentas abrir no existe o ha sido eliminada',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver a notas'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final note = _note!;
    final noteColor = note.colorValue;
    final iconConfig = note.iconConfig;
    final hasStatusBadges = note.isFavorite || note.isArchived;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // AppBar con gradiente
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: noteColor,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBack,
            ),
            actions: [
              // Botón de exportación
              ExportButton(
                note: note,
                showLabel: false,
                iconSize: 22,
              ),
              IconButton(
                icon: Icon(
                  note.isFavorite ? Icons.star : Icons.star_border,
                  color: Colors.white,
                ),
                onPressed: _toggleFavorite,
                tooltip: note.isFavorite ? 'Quitar favorito' : 'Marcar favorito',
              ),
              IconButton(
                icon: Icon(
                  note.isArchived ? Icons.unarchive : Icons.archive,
                  color: Colors.white,
                ),
                onPressed: _toggleArchive,
                tooltip: note.isArchived ? 'Desarchivar' : 'Archivar',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editNote();
                      break;
                    case 'delete':
                      _deleteNote();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                note.title,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      noteColor,
                      noteColor.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: iconConfig.value == NoteIcon.default_
                        ? Icon(Icons.edit_note, size: 40, color: Colors.white.withValues(alpha: 0.8))
                        : Text(
                            iconConfig.iconName,
                            style: TextStyle(fontSize: 40, color: Colors.white.withValues(alpha: 0.8)),
                          ),
                  ),
                ),
              ),
            ),
          ),
          
          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges de estado (Favorita/Archivada)
                  if (hasStatusBadges)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (note.isFavorite)
                            StatusBadge(
                              icon: Icons.star,
                              label: 'Favorita',
                              color: Colors.amber,
                            ),
                          if (note.isArchived)
                            StatusBadge(
                              icon: Icons.archive,
                              label: 'Archivada',
                              color: Colors.teal,
                            ),
                        ],
                      ),
                    ),
                  
                  // Contenido de la nota
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
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
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: noteColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Contenido',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          note.content.isEmpty ? 'Sin contenido' : note.content,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            height: 1.5,
                            color: isDarkMode ? Colors.white70 : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Información de fechas
                  InfoCard(
                    createdAt: note.createdAt,
                    updatedAt: note.updatedAt,
                    accentColor: noteColor,
                  ),
                  const SizedBox(height: 16),
                  
                  // Etiquetas
                  TagsCard(
                    tags: note.tags,
                    accentColor: noteColor,
                    onTagTap: _onTagTap,
                  ),
                  const SizedBox(height: 16),
                  
                  // Acciones rápidas
                  QuickActionsCard(
                    onEdit: _editNote,
                    onToggleFavorite: _toggleFavorite,
                    onToggleArchive: _toggleArchive,
                    onDelete: _deleteNote,
                    isFavorite: note.isFavorite,
                    isArchived: note.isArchived,
                    accentColor: noteColor,
                  ),
                  const SizedBox(height: 16),
                  
                  // Personalización actual
                  PersonalizationCard(
                    note: note,
                    accentColor: noteColor,
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}