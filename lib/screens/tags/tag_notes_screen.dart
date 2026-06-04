// lib/screens/tags/tag_notes_screen.dart
// Pantalla de notas filtradas por etiqueta - CON PERSONALIZACIÓN COMPLETA
// Similar a la versión de React de QuickNote
// ✅ Botón de exportación integrado en AppBar

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/models/note.dart';
import 'package:quicknote/providers/notes_provider.dart';
import 'package:quicknote/widgets/loading_indicator.dart';
import 'package:quicknote/widgets/empty_state.dart';
import 'package:quicknote/widgets/view_toggle.dart';
import 'package:quicknote/widgets/export_button.dart';  // ✅ NUEVO IMPORT
import 'package:quicknote/widgets/toast_message.dart';
import 'package:quicknote/core/utils/tag_utils.dart';

// ============================================
// TARJETA DE NOTA POR ETIQUETA PERSONALIZADA
// ============================================

class TagNoteCard extends StatelessWidget {
  final Note note;
  final String tagName;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleArchive;
  final bool isSelected;
  final bool isGridMode;

  const TagNoteCard({
    super.key,
    required this.note,
    required this.tagName,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onToggleArchive,
    this.isSelected = false,
    this.isGridMode = true,
  });

  Color get _noteColor => note.colorValue;
  Color get _backgroundColor => note.backgroundColor;
  Color get _tagColor => _getTagColor(tagName);
  IconConfig get _iconConfig => note.iconConfig;
  SizeConfig get _sizeConfig => note.sizeConfig;
  ShapeConfig get _shapeConfig => note.shapeConfig;

  Color _getTagColor(String tag) {
    final colorHex = TagUtils.getTagColor(tag);
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.purple;
    }
  }

  Widget _buildIcon(double size) {
    if (_iconConfig.value == NoteIcon.default_) {
      return Icon(Icons.edit_note, size: size, color: _noteColor);
    }
    return Text(_iconConfig.iconName, style: TextStyle(fontSize: size, color: _noteColor));
  }

  BorderRadius get _borderRadius => BorderRadius.circular(_shapeConfig.borderRadius);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (isGridMode) {
      return _buildGridCard(theme, isDarkMode);
    } else {
      return _buildListCard(theme, isDarkMode);
    }
  }

  Widget _buildGridCard(ThemeData theme, bool isDarkMode) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: _borderRadius,
          border: isSelected
              ? Border.all(color: _tagColor, width: 2)
              : Border.all(
                  color: _tagColor.withValues(alpha: 0.3),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: _tagColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Badge de etiqueta
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _tagColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tag, size: 10, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '#$tagName',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _noteColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(child: _buildIcon(18)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _noteColor,
                            fontSize: _sizeConfig.value == NoteSize.compact ? 14 : 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (note.isFavorite)
                        Icon(Icons.star, color: Colors.amber, size: 16),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    note.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: _sizeConfig.value == NoteSize.compact ? 12 : 13,
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                    ),
                    maxLines: _sizeConfig.contentLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  if (note.tags.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: note.tags.where((t) => t != tagName).take(2).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _tagColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(fontSize: 9, color: _tagColor),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        note.relativeTime,
                        style: theme.textTheme.bodySmall,
                      ),
                      Row(
                        children: [
                          _buildActionIcon(
                            icon: Icons.edit,
                            color: Colors.blue,
                            onTap: onEdit,
                            tooltip: 'Editar',
                          ),
                          const SizedBox(width: 8),
                          _buildActionIcon(
                            icon: Icons.archive_outlined,
                            color: Colors.teal,
                            onTap: onToggleArchive,
                            tooltip: 'Archivar',
                          ),
                          const SizedBox(width: 8),
                          _buildActionIcon(
                            icon: Icons.delete_outline,
                            color: Colors.red,
                            onTap: onDelete,
                            tooltip: 'Eliminar',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(ThemeData theme, bool isDarkMode) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: _borderRadius,
          border: isSelected
              ? Border.all(color: _tagColor, width: 2)
              : Border.all(
                  color: _tagColor.withValues(alpha: 0.3),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: _tagColor.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Indicador de color
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: _tagColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Icono
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _noteColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: _buildIcon(22)),
            ),
            const SizedBox(width: 12),
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _noteColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (note.isFavorite)
                        Icon(Icons.star, color: Colors.amber, size: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _tagColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '#$tagName',
                          style: TextStyle(fontSize: 9, color: _tagColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.content,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: _sizeConfig.value == NoteSize.compact ? 11 : 12,
                    ),
                    maxLines: _sizeConfig.value == NoteSize.compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (note.tags.isNotEmpty)
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            children: note.tags.where((t) => t != tagName).take(2).map((tag) {
                              return Text(
                                '#$tag',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: _tagColor,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      Text(
                        note.relativeTime,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Acciones
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    note.isFavorite ? Icons.star : Icons.star_border,
                    size: 20,
                    color: note.isFavorite ? Colors.amber : null,
                  ),
                  onPressed: onToggleFavorite,
                  tooltip: note.isFavorite ? 'Quitar favorito' : 'Marcar favorito',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                IconButton(
                  icon: const Icon(Icons.archive_outlined, size: 20),
                  color: Colors.teal,
                  onPressed: onToggleArchive,
                  tooltip: 'Archivar',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red,
                  onPressed: onDelete,
                  tooltip: 'Eliminar',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

// ============================================
// PANTALLA PRINCIPAL
// ============================================

class TagNotesScreen extends ConsumerStatefulWidget {
  final String tagName;

  const TagNotesScreen({super.key, required this.tagName});

  @override
  ConsumerState<TagNotesScreen> createState() => _TagNotesScreenState();
}

class _TagNotesScreenState extends ConsumerState<TagNotesScreen> {
  ViewMode _viewMode = ViewMode.grid;
  final Set<String> _selectedNotes = {};
  bool _isSelectionMode = false;
  bool _isProcessing = false;
  bool _showStats = false;
  String? _sortBy = 'updated_at';
  final bool _sortDescending = true;

  Color get _tagColor => _getTagColor(widget.tagName);
  String? get _tagIcon => TagUtils.getTagIcon(widget.tagName);

  Color _getTagColor(String tag) {
    final colorHex = TagUtils.getTagColor(tag);
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.purple;
    }
  }

  List<Note> _getSortedNotes(List<Note> notes) {
    final sorted = List<Note>.from(notes);
    sorted.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'created_at':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'updated_at':
        default:
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
      }
      return _sortDescending ? -comparison : comparison;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final notesState = ref.watch(notesProvider);
    final taggedNotes = notesState.activeNotes
        .where((n) => n.tags.contains(widget.tagName))
        .toList();
    final sortedNotes = _getSortedNotes(taggedNotes);
    final relatedTags = _getRelatedTags(taggedNotes, widget.tagName);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(isDarkMode, sortedNotes),
      body: notesState.isLoading
          ? const Center(child: LoadingIndicator())
          : sortedNotes.isEmpty
              ? _buildEmptyState(isDarkMode)
              : Column(
                  children: [
                    // Barra de estadísticas (expandible)
                    if (_showStats) _buildStatsBar(isDarkMode, sortedNotes),
                    // Barra de selección múltiple
                    if (_isSelectionMode) _buildSelectionBar(isDarkMode),
                    // Barra de acciones
                    if (!_isSelectionMode) _buildActionsBar(isDarkMode, sortedNotes.length, relatedTags),
                    // Lista de notas
                    Expanded(
                      child: _viewMode == ViewMode.grid
                          ? _buildGridView(sortedNotes)
                          : _buildListView(sortedNotes),
                    ),
                  ],
                ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode, List<Note> taggedNotes) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _tagColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _tagIcon ?? '🏷️',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '#${widget.tagName}',
              style: GoogleFonts.poppins(
                color: _tagColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      centerTitle: false,
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // ✅ BOTÓN DE EXPORTACIÓN AGREGADO
        if (taggedNotes.isNotEmpty)
          ExportButton(
            notes: taggedNotes,
            showLabel: false,
            iconSize: 22,
          ),
        if (taggedNotes.isNotEmpty && !_isSelectionMode)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _tagColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${taggedNotes.length}',
              style: TextStyle(color: _tagColor),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsBar(bool isDarkMode, List<Note> notes) {
    final favorites = notes.where((n) => n.isFavorite).length;
    final totalSize = notes.fold<int>(0, (sum, n) => sum + n.content.length);
    final oldestDate = notes.isNotEmpty
        ? notes.map((n) => n.createdAt).reduce((a, b) => a.isBefore(b) ? a : b)
        : null;
    final newestDate = notes.isNotEmpty
        ? notes.map((n) => n.createdAt).reduce((a, b) => a.isAfter(b) ? a : b)
        : null;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _tagColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _tagColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', '${notes.length}', _tagColor, isDarkMode),
              _buildStatItem('Favoritas', '$favorites', _tagColor, isDarkMode),
              _buildStatItem('Caracteres', _formatFileSize(totalSize), _tagColor, isDarkMode),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Más antigua', oldestDate != null ? _formatDate(oldestDate) : '-', _tagColor, isDarkMode),
              _buildStatItem('Más reciente', newestDate != null ? _formatDate(newestDate) : '-', _tagColor, isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isDarkMode) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsBar(bool isDarkMode, int count, List<String> relatedTags) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              // Selector de ordenamiento
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    icon: Icon(Icons.sort, size: 18),
                    dropdownColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'updated_at', child: Text('Última modificación')),
                      DropdownMenuItem(value: 'created_at', child: Text('Fecha creación')),
                      DropdownMenuItem(value: 'title', child: Text('Título')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortBy = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  Icons.bar_chart,
                  color: _showStats ? _tagColor : null,
                ),
                onPressed: () => setState(() => _showStats = !_showStats),
                tooltip: 'Estadísticas',
              ),
              IconButton(
                icon: const Icon(Icons.checklist),
                onPressed: () => setState(() => _isSelectionMode = true),
                tooltip: 'Seleccionar',
              ),
              ViewToggle(
                currentMode: _viewMode,
                onModeChanged: (mode) => setState(() => _viewMode = mode),
              ),
            ],
          ),
          if (relatedTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildRelatedTagsSection(isDarkMode, relatedTags),
            ),
        ],
      ),
    );
  }

  Widget _buildRelatedTagsSection(bool isDarkMode, List<String> relatedTags) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _tagColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tag, size: 14, color: _tagColor),
              const SizedBox(width: 6),
              Text(
                'Etiquetas relacionadas',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _tagColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: relatedTags.map((tag) {
              final tagColor = _getTagColor(tag);
              return GestureDetector(
                onTap: () => _navigateToTag(tag),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '#$tag',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: tagColor,
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

  Widget _buildSelectionBar(bool isDarkMode) {
    final notes = ref.read(notesProvider).activeNotes
        .where((n) => n.tags.contains(widget.tagName))
        .toList();
    final isAllSelected = _selectedNotes.length == notes.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _tagColor,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                if (isAllSelected) {
                  _selectedNotes.clear();
                } else {
                  final allNotes = ref.read(notesProvider).activeNotes
                      .where((n) => n.tags.contains(widget.tagName))
                      .toList();
                  _selectedNotes.addAll(allNotes.map((n) => n.id));
                }
              });
            },
            icon: Icon(
              isAllSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_selectedNotes.length} seleccionada${_selectedNotes.length != 1 ? 's' : ''}',
            style: const TextStyle(color: Colors.white),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() {
              _selectedNotes.clear();
              _isSelectionMode = false;
            }),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _deleteSelectedNotes,
            icon: const Icon(Icons.delete_forever, size: 16),
            label: const Text('ELIMINAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<Note> notes) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final isSelected = _selectedNotes.contains(note.id);
        
        return TagNoteCard(
          note: note,
          tagName: widget.tagName,
          onTap: _isSelectionMode
              ? () => _toggleSelection(note.id)
              : () => _openNote(note.id),
          onEdit: () => _editNote(note.id),
          onDelete: () => _deleteNote(note.id),
          onToggleFavorite: () => _toggleFavorite(note.id),
          onToggleArchive: () => _toggleArchive(note.id),
          isSelected: isSelected,
          isGridMode: true,
        );
      },
    );
  }

  Widget _buildListView(List<Note> notes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final isSelected = _selectedNotes.contains(note.id);
        
        return TagNoteCard(
          note: note,
          tagName: widget.tagName,
          onTap: _isSelectionMode
              ? () => _toggleSelection(note.id)
              : () => _openNote(note.id),
          onEdit: () => _editNote(note.id),
          onDelete: () => _deleteNote(note.id),
          onToggleFavorite: () => _toggleFavorite(note.id),
          onToggleArchive: () => _toggleArchive(note.id),
          isSelected: isSelected,
          isGridMode: false,
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _tagColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.tag,
              size: 50,
              color: _tagColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay notas con esta etiqueta',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea notas con la etiqueta #${widget.tagName}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('VOLVER A ETIQUETAS'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // ACCIONES
  // ============================================

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedNotes.contains(id)) {
        _selectedNotes.remove(id);
        if (_selectedNotes.isEmpty) _isSelectionMode = false;
      } else {
        _selectedNotes.add(id);
      }
    });
  }

  Future<void> _deleteNote(String id) async {
    final confirmed = await _showConfirmDialog(
      'Eliminar nota',
      '¿Eliminar esta nota permanentemente?',
    );
    if (confirmed) {
      setState(() => _isProcessing = true);
      
      await ref.read(notesProvider.notifier).deleteNote(id);
      await ref.read(notesProvider.notifier).loadNotes();
      
      setState(() => _isProcessing = false);
      ToastMessage.success(context, 'Nota eliminada');
    }
  }

  Future<void> _deleteSelectedNotes() async {
    final confirmed = await _showConfirmDialog(
      'Eliminar seleccionadas',
      '¿Eliminar ${_selectedNotes.length} nota${_selectedNotes.length != 1 ? 's' : ''}?',
    );
    if (confirmed) {
      setState(() => _isProcessing = true);
      
      for (final id in _selectedNotes) {
        await ref.read(notesProvider.notifier).deleteNote(id);
      }
      await ref.read(notesProvider.notifier).loadNotes();
      
      setState(() {
        _selectedNotes.clear();
        _isSelectionMode = false;
        _isProcessing = false;
      });
      
      ToastMessage.success(context, 'Notas eliminadas');
    }
  }

  Future<void> _toggleFavorite(String id) async {
    await ref.read(notesProvider.notifier).toggleFavorite(id);
    await ref.read(notesProvider.notifier).loadNotes();
    ToastMessage.success(context, 'Estado de favorito actualizado');
  }

  Future<void> _toggleArchive(String id) async {
    await ref.read(notesProvider.notifier).toggleArchive(id);
    await ref.read(notesProvider.notifier).loadNotes();
    ToastMessage.success(context, 'Nota archivada');
  }

  void _openNote(String id) {
    Navigator.pushNamed(context, '/notes/$id');
  }

  void _editNote(String id) {
    Navigator.pushNamed(context, '/notes/$id/edit');
  }

  void _navigateToTag(String tag) {
    Navigator.pushReplacementNamed(context, '/tags/$tag');
  }

  // ============================================
  // UTILIDADES
  // ============================================

  List<String> _getRelatedTags(List<Note> notes, String currentTag) {
    final tags = <String>{};
    for (final note in notes) {
      for (final tag in note.tags) {
        if (tag != currentTag) {
          tags.add(tag);
        }
      }
    }
    return tags.toList()..sort();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: GoogleFonts.poppins()),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Aceptar', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    ) ?? false;
  }
}