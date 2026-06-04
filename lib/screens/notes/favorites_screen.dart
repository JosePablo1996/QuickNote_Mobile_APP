// lib/screens/notes/favorites_screen.dart
// Pantalla de notas favoritas - VERSIÓN CON SOLO ICONOS
// ✅ CORREGIDO: PopScope con onPopInvokedWithResult (API actualizada)
// ✅ CORREGIDO: Condiciones de tipo bool (result != null)
// ✅ CORREGIDO: Uso de permanentlyDeleteNote en lugar de deleteNote(permanent:true)
// ✅ ICONOS GRANDES Y VISIBLES SIN ETIQUETAS DE TEXTO
// ✅ DISEÑO RESPONSIVO que se adapta a diferentes tamaños de pantalla
// ✅ ELIMINADO AppBottomNav - No es necesario en pantallas secundarias
// ✅ Navegación simplificada con go('/notes')

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/models/note.dart';
import 'package:quicknote/providers/notes_provider.dart';
import 'package:quicknote/widgets/loading_indicator.dart';
import 'package:quicknote/widgets/view_toggle.dart';
import 'package:quicknote/widgets/export_button.dart';
import 'package:quicknote/widgets/toast_message.dart';

class _FavoritesScreenLogger {
  static void info(String message) => debugPrint('ℹ️ [FavoritesScreen] $message');
  static void success(String message) => debugPrint('✅ [FavoritesScreen] $message');
  static void error(String message) => debugPrint('❌ [FavoritesScreen] $message');
}

class FavoriteNoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onUnfavorite;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onToggleArchive;
  final bool isSelected;
  final bool isGridMode;

  const FavoriteNoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onUnfavorite,
    required this.onDelete,
    required this.onEdit,
    required this.onToggleArchive,
    this.isSelected = false,
    this.isGridMode = true,
  });

  Color get _noteColor => note.colorValue;
  Color get _backgroundColor => note.backgroundColor;
  ShapeConfig get _shapeConfig => note.shapeConfig;
  SizeConfig get _sizeConfig => note.sizeConfig;
  IconConfig get _iconConfig => note.iconConfig;

  Widget _buildIcon(double size) {
    if (_iconConfig.value == NoteIcon.default_) {
      return Icon(Icons.star, size: size, color: _noteColor);
    }
    return Text(_iconConfig.iconName, style: TextStyle(fontSize: size, color: _noteColor));
  }

  BorderRadius get _borderRadius => BorderRadius.circular(_shapeConfig.borderRadius);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    if (isGridMode) {
      return _buildGridCard(theme, isDarkMode, isSmallScreen);
    } else {
      return _buildListCard(theme, isDarkMode, isSmallScreen);
    }
  }

  // ============================================
  // VISTA CUADRÍCULA (GRID)
  // ============================================

  Widget _buildGridCard(ThemeData theme, bool isDarkMode, bool isSmallScreen) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: _borderRadius,
          border: isSelected ? Border.all(color: theme.primaryColor, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con icono y título
              Row(
                children: [
                  Container(
                    width: isSmallScreen ? 40 : 48,
                    height: isSmallScreen ? 40 : 48,
                    decoration: BoxDecoration(
                      color: _noteColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: _buildIcon(isSmallScreen ? 22 : 28)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: _noteColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: isSmallScreen ? 10 : 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              note.relativeTime,
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 10 : 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Contenido de la nota
              Text(
                note.content,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 13 : 14,
                  height: 1.4,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                ),
                maxLines: _sizeConfig.contentLines,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              // Tags
              if (note.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: note.tags.take(3).map((tag) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _noteColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '#$tag',
                        style: GoogleFonts.poppins(fontSize: isSmallScreen ? 10 : 11, color: _noteColor),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              // Barra de acciones con SOLO ICONOS
              Divider(
                height: 1,
                color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón Editar
                  _buildActionIcon(
                    icon: Icons.edit,
                    color: Colors.blue,
                    onTap: onEdit,
                    tooltip: 'Editar',
                    size: isSmallScreen ? 26 : 30,
                  ),
                  // Botón Archivar
                  _buildActionIcon(
                    icon: Icons.archive_outlined,
                    color: Colors.teal,
                    onTap: onToggleArchive,
                    tooltip: 'Archivar',
                    size: isSmallScreen ? 26 : 30,
                  ),
                  // Botón Eliminar Favorito
                  _buildActionIcon(
                    icon: Icons.star_border,
                    color: Colors.amber,
                    onTap: onUnfavorite,
                    tooltip: 'Quitar de favoritos',
                    size: isSmallScreen ? 26 : 30,
                  ),
                  // Botón Eliminar Permanentemente
                  _buildActionIcon(
                    icon: Icons.delete_forever,
                    color: Colors.red,
                    onTap: onDelete,
                    tooltip: 'Eliminar permanentemente',
                    size: isSmallScreen ? 26 : 30,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // VISTA LISTA (LIST)
  // ============================================

  Widget _buildListCard(ThemeData theme, bool isDarkMode, bool isSmallScreen) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: _borderRadius,
          border: isSelected ? Border.all(color: theme.primaryColor, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              children: [
                Container(
                  width: isSmallScreen ? 36 : 44,
                  height: isSmallScreen ? 36 : 44,
                  decoration: BoxDecoration(
                    color: _noteColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: _buildIcon(isSmallScreen ? 20 : 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: _noteColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: isSmallScreen ? 10 : 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            note.relativeTime,
                            style: GoogleFonts.poppins(fontSize: isSmallScreen ? 10 : 11, color: Colors.grey.shade500),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('★', style: TextStyle(fontSize: 10, color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Contenido
            Text(
              note.content,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 12 : 13,
                height: 1.4,
                color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
              ),
              maxLines: _sizeConfig.value == NoteSize.compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Tags
            if (note.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: note.tags.take(3).map((tag) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _noteColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '#$tag',
                      style: GoogleFonts.poppins(fontSize: isSmallScreen ? 9 : 10, color: _noteColor),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            // Barra de acciones con SOLO ICONOS
            Divider(
              height: 1,
              color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón Editar
                _buildActionIcon(
                  icon: Icons.edit,
                  color: Colors.blue,
                  onTap: onEdit,
                  tooltip: 'Editar',
                  size: isSmallScreen ? 24 : 28,
                ),
                // Botón Archivar
                _buildActionIcon(
                  icon: Icons.archive_outlined,
                  color: Colors.teal,
                  onTap: onToggleArchive,
                  tooltip: 'Archivar',
                  size: isSmallScreen ? 24 : 28,
                ),
                // Botón Eliminar Favorito
                _buildActionIcon(
                  icon: Icons.star_border,
                  color: Colors.amber,
                  onTap: onUnfavorite,
                  tooltip: 'Quitar de favoritos',
                  size: isSmallScreen ? 24 : 28,
                ),
                // Botón Eliminar Permanentemente
                _buildActionIcon(
                  icon: Icons.delete_forever,
                  color: Colors.red,
                  onTap: onDelete,
                  tooltip: 'Eliminar permanentemente',
                  size: isSmallScreen ? 24 : 28,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // BOTÓN DE ACCIÓN CON SOLO ICONO (SIN TEXTO)
  // ============================================

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
    required double size,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: size,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// PANTALLA PRINCIPAL
// ============================================

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  ViewMode _viewMode = ViewMode.grid;
  final Set<String> _selectedNotes = {};
  bool _isSelectionMode = false;
  bool _isProcessing = false;
  bool _isNavigating = false;
  String _sortBy = 'updated_at';
  final bool _sortDescending = true;

  void _goBack() {
    if (_isNavigating) return;
    _isNavigating = true;
    
    _FavoritesScreenLogger.info('🔙 Navegando de vuelta a notas');
    
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      try {
        context.go('/notes');
        _FavoritesScreenLogger.success('✅ Navegación exitosa');
      } catch (e) {
        _FavoritesScreenLogger.error('Error: $e');
      } finally {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _isNavigating = false;
        });
      }
    });
  }

  List<Note> _getSortedFavorites(List<Note> notes) {
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
    final favoriteNotes = _getSortedFavorites(notesState.favoriteNotes);
    final isLoading = notesState.isLoading || _isProcessing;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack();
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: _buildAppBar(isDarkMode, favoriteNotes),
        body: SafeArea(
          child: isLoading
              ? const Center(child: LoadingIndicator())
              : favoriteNotes.isEmpty
                  ? _buildEmptyState(isDarkMode)
                  : Column(
                      children: [
                        if (!_isSelectionMode) _buildStatsBar(isDarkMode, favoriteNotes),
                        if (!_isSelectionMode) _buildActionsBar(isDarkMode),
                        if (_isSelectionMode) _buildSelectionBar(isDarkMode, favoriteNotes.length),
                        Expanded(
                          child: _viewMode == ViewMode.grid
                              ? _buildGridView(favoriteNotes)
                              : _buildListView(favoriteNotes),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline, size: 80, color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No hay notas favoritas',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Las notas que marques como favoritas aparecerán aquí',
            style: GoogleFonts.poppins(fontSize: 14, color: isDarkMode ? Colors.white38 : Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back),
            label: Text('Volver a notas', style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode, List<Note> favoriteNotes) {
    return AppBar(
      title: const Text('Favoritas'),
      centerTitle: true,
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _goBack,
      ),
      actions: [
        if (favoriteNotes.isNotEmpty)
          ExportButton(notes: favoriteNotes, showLabel: false, iconSize: 22),
        if (favoriteNotes.isNotEmpty && !_isSelectionMode)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('${favoriteNotes.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildStatsBar(bool isDarkMode, List<Note> notes) {
    final totalFavorites = notes.length;
    final recentFavorite = notes.isNotEmpty
        ? notes.map((n) => n.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b)
        : null;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF1E3A8A).withValues(alpha: 0.8), const Color(0xFF4C1D95).withValues(alpha: 0.8)]
              : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.star, '$totalFavorites', 'Favoritas', Colors.amber, isDarkMode),
          Container(width: 1, height: 25, color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
          _buildStatItem(
            Icons.favorite,
            recentFavorite != null ? _formatDate(recentFavorite) : '-',
            'Última',
            Colors.pink,
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color, bool isDarkMode) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: isDarkMode ? Colors.white54 : Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildActionsBar(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDarkMode ? Colors.white24 : Colors.grey.shade300, width: 0.8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                icon: const Icon(Icons.sort, size: 18),
                dropdownColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.black87),
                items: const [
                  DropdownMenuItem(value: 'updated_at', child: Text('Modificación')),
                  DropdownMenuItem(value: 'created_at', child: Text('Creación')),
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
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _isSelectionMode = true),
              icon: const Icon(Icons.checklist, size: 18),
              label: const Text('SELECCIONAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade400),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ViewToggle(
            currentMode: _viewMode,
            onModeChanged: (mode) => setState(() => _viewMode = mode),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(bool isDarkMode, int totalCount) {
    final isAllSelected = _selectedNotes.length == totalCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.amber,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                if (isAllSelected) {
                  _selectedNotes.clear();
                } else {
                  final allNotes = ref.read(notesProvider).favoriteNotes;
                  _selectedNotes.addAll(allNotes.map((n) => n.id));
                }
              });
            },
            icon: Icon(isAllSelected ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 8),
          Text('${_selectedNotes.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() {
              _selectedNotes.clear();
              _isSelectionMode = false;
            }),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _unfavoriteSelectedNotes,
            icon: const Icon(Icons.star_border, size: 18),
            label: const Text('QUITAR', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _deleteSelectedNotes,
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('ELIMINAR', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<Note> notes) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final isSelected = _selectedNotes.contains(note.id);
        
        return FavoriteNoteCard(
          note: note,
          onTap: _isSelectionMode ? () => _toggleSelection(note.id) : () => _openNote(note.id),
          onUnfavorite: () => _unfavoriteNote(note.id),
          onDelete: () => _deleteNote(note.id),
          onEdit: () => _editNote(note.id),
          onToggleArchive: () => _toggleArchive(note.id),
          isSelected: isSelected,
          isGridMode: true,
        );
      },
    );
  }

  Widget _buildListView(List<Note> notes) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final isSelected = _selectedNotes.contains(note.id);
        
        return FavoriteNoteCard(
          note: note,
          onTap: _isSelectionMode ? () => _toggleSelection(note.id) : () => _openNote(note.id),
          onUnfavorite: () => _unfavoriteNote(note.id),
          onDelete: () => _deleteNote(note.id),
          onEdit: () => _editNote(note.id),
          onToggleArchive: () => _toggleArchive(note.id),
          isSelected: isSelected,
          isGridMode: false,
        );
      },
    );
  }

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

  Future<void> _unfavoriteNote(String id) async {
    setState(() => _isProcessing = true);
    final result = await ref.read(notesProvider.notifier).toggleFavorite(id);
    await ref.read(notesProvider.notifier).loadNotes();
    setState(() => _isProcessing = false);
    
    if (result != null && mounted) {
      ToastMessage.success('Nota eliminada de favoritos');
      if (mounted && ref.read(notesProvider).favoriteNotes.isEmpty) {
        _goBack();
      }
    } else if (mounted) {
      ToastMessage.error('Error al quitar de favoritos');
    }
  }

  Future<void> _unfavoriteSelectedNotes() async {
    final count = _selectedNotes.length;
    setState(() => _isProcessing = true);
    
    for (final id in _selectedNotes) {
      await ref.read(notesProvider.notifier).toggleFavorite(id);
    }
    await ref.read(notesProvider.notifier).loadNotes();
    
    setState(() {
      _selectedNotes.clear();
      _isSelectionMode = false;
      _isProcessing = false;
    });
    
    ToastMessage.success('$count nota${count != 1 ? 's' : ''} eliminada${count != 1 ? 's' : ''} de favoritos');
    
    if (mounted && ref.read(notesProvider).favoriteNotes.isEmpty) {
      _goBack();
    }
  }

  /// ✅ CORREGIDO: Usa permanentlyDeleteNote
  Future<void> _deleteNote(String id) async {
    final confirmed = await _showConfirmDialog('Eliminar nota', '¿Eliminar esta nota permanentemente? Esta acción no se puede deshacer.');
    if (confirmed) {
      setState(() => _isProcessing = true);
      final success = await ref.read(notesProvider.notifier).permanentlyDeleteNote(id);
      await ref.read(notesProvider.notifier).loadNotes();
      setState(() => _isProcessing = false);
      if (mounted) {
        if (success) {
          ToastMessage.success('Nota eliminada permanentemente');
        } else {
          ToastMessage.error('Error al eliminar la nota');
        }
      }
    }
  }

  /// ✅ CORREGIDO: Usa permanentlyDeleteNote para múltiples notas
  Future<void> _deleteSelectedNotes() async {
    final count = _selectedNotes.length;
    final confirmed = await _showConfirmDialog('Eliminar seleccionadas', '¿Eliminar permanentemente $count nota${count != 1 ? 's' : ''}? Esta acción no se puede deshacer.');
    if (confirmed) {
      setState(() => _isProcessing = true);
      for (final id in _selectedNotes) {
        await ref.read(notesProvider.notifier).permanentlyDeleteNote(id);
      }
      await ref.read(notesProvider.notifier).loadNotes();
      setState(() {
        _selectedNotes.clear();
        _isSelectionMode = false;
        _isProcessing = false;
      });
      ToastMessage.success('$count nota${count != 1 ? 's' : ''} eliminada${count != 1 ? 's' : ''} permanentemente');
    }
  }

  Future<void> _toggleArchive(String id) async {
    setState(() => _isProcessing = true);
    final result = await ref.read(notesProvider.notifier).toggleArchive(id);
    await ref.read(notesProvider.notifier).loadNotes();
    setState(() => _isProcessing = false);
    
    if (result != null && mounted) {
      ToastMessage.success('Nota archivada');
    } else if (mounted) {
      ToastMessage.error('Error al archivar la nota');
    }
  }

  void _openNote(String id) {
    context.push('/notes/$id');
  }

  void _editNote(String id) {
    context.push('/notes/$id/edit');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: GoogleFonts.poppins())),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Eliminar', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}