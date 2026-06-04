// lib/screens/notes/trash_screen.dart
// Pantalla de papelera (notas eliminadas) - VERSIÓN CORREGIDA
// ✅ UI actualizada correctamente después de restaurar/eliminar
// ✅ Botón CANCELAR con color diferenciado
// ✅ Barra de selección sin desbordamiento
// ✅ Botones más pequeños y compactos
// ✅ Contador arriba de los botones en selección
// ✅ Sincronización con forceReload() del provider

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/models/note.dart';
import 'package:quicknote/providers/notes_provider.dart';
import 'package:quicknote/widgets/loading_indicator.dart';
import 'package:quicknote/widgets/view_toggle.dart';
import 'package:quicknote/widgets/toast_message.dart';

class _TrashScreenLogger {
  static void info(String message) => debugPrint('ℹ️ [TrashScreen] $message');
  static void success(String message) => debugPrint('✅ [TrashScreen] $message');
  static void error(String message) => debugPrint('❌ [TrashScreen] $message');
}

class TrashNoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onRestore;
  final VoidCallback onDeletePermanently;
  final VoidCallback onToggleFavorite;
  final VoidCallback onEdit;
  final VoidCallback onToggleArchive;
  final bool isSelected;
  final bool isGridMode;

  const TrashNoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onRestore,
    required this.onDeletePermanently,
    required this.onToggleFavorite,
    required this.onEdit,
    required this.onToggleArchive,
    this.isSelected = false,
    this.isGridMode = true,
  });

  Color get _noteColor => note.colorValue;
  Color get _backgroundColor => note.backgroundColor;
  SizeConfig get _sizeConfig => note.sizeConfig;
  ShapeConfig get _shapeConfig => note.shapeConfig;

  BorderRadius get _borderRadius => BorderRadius.circular(_shapeConfig.borderRadius);

  String get _deleteDate {
    final date = note.deletedAt ?? note.updatedAt;
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    if (diff.inDays < 30) return 'Hace ${(diff.inDays / 7).floor()} semanas';
    return 'Hace ${(diff.inDays / 30).floor()} meses';
  }

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

  Widget _buildGridCard(ThemeData theme, bool isDarkMode, bool isSmallScreen) {
    // Reducir tamaño de iconos para que quepan mejor
    final double iconSize = isSmallScreen ? 16.0 : 18.0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: _borderRadius,
          border: isSelected ? Border.all(color: Colors.red, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 14.0 : 16.0,
                        fontWeight: FontWeight.w600,
                        color: _noteColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note.isFavorite)
                    Icon(Icons.star, size: 12, color: Colors.amber),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _deleteDate,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 9.0 : 10.0,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                note.content,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 12.0 : 13.0,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: _sizeConfig.contentLines,
                overflow: TextOverflow.ellipsis,
              ),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: note.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _noteColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('#$tag', style: GoogleFonts.poppins(fontSize: isSmallScreen ? 8.0 : 9.0, color: _noteColor)),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Divider(color: isDarkMode ? Colors.white24 : Colors.grey.shade200),
              const SizedBox(height: 8),
              // Botones de acción más pequeños y compactos
              Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.start,
                children: [
                  _buildSmallActionIcon(Icons.restore, Colors.green, onRestore, 'Restaurar'),
                  _buildSmallActionIcon(Icons.edit, Colors.blue, onEdit, 'Editar'),
                  _buildSmallActionIcon(Icons.archive_outlined, Colors.teal, onToggleArchive, 'Archivar'),
                  _buildSmallActionIcon(
                    note.isFavorite ? Icons.star : Icons.star_border,
                    note.isFavorite ? Colors.amber : Colors.grey,
                    onToggleFavorite,
                    note.isFavorite ? 'Quitar favorito' : 'Marcar favorito',
                  ),
                  _buildSmallActionIcon(Icons.delete_forever, Colors.red, onDeletePermanently, 'Eliminar'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(ThemeData theme, bool isDarkMode, bool isSmallScreen) {
    // Reducir tamaño de iconos
    final double iconSize = isSmallScreen ? 14.0 : 16.0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 8.0 : 12.0),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: _borderRadius,
          border: isSelected ? Border.all(color: Colors.red, width: 2) : null,
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
            Container(
              width: double.infinity,
              height: isSmallScreen ? 3.0 : 4.0,
              decoration: BoxDecoration(
                color: _noteColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 14.0 : 16.0,
                            fontWeight: FontWeight.w600,
                            color: _noteColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (note.isFavorite)
                        Icon(Icons.star, size: 12, color: Colors.amber),
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _deleteDate,
                          style: GoogleFonts.poppins(fontSize: isSmallScreen ? 8.0 : 9.0, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    note.content,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12.0 : 13.0,
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (note.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: note.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _noteColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('#$tag', style: GoogleFonts.poppins(fontSize: isSmallScreen ? 8.0 : 9.0, color: _noteColor)),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 10, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        note.relativeTime,
                        style: GoogleFonts.poppins(fontSize: isSmallScreen ? 9.0 : 10.0, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: isDarkMode ? Colors.white24 : Colors.grey.shade200),
                  const SizedBox(height: 8),
                  // Botones de acción más pequeños y compactos
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.start,
                    children: [
                      _buildSmallActionIcon(Icons.restore, Colors.green, onRestore, 'Restaurar'),
                      _buildSmallActionIcon(Icons.edit, Colors.blue, onEdit, 'Editar'),
                      _buildSmallActionIcon(Icons.archive_outlined, Colors.teal, onToggleArchive, 'Archivar'),
                      _buildSmallActionIcon(
                        note.isFavorite ? Icons.star : Icons.star_border,
                        note.isFavorite ? Colors.amber : Colors.grey,
                        onToggleFavorite,
                        note.isFavorite ? 'Quitar favorito' : 'Marcar favorito',
                      ),
                      _buildSmallActionIcon(Icons.delete_forever, Colors.red, onDeletePermanently, 'Eliminar'),
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

  Widget _buildSmallActionIcon(IconData icon, Color color, VoidCallback? onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  ViewMode _viewMode = ViewMode.list;
  final Set<String> _selectedNotes = {};
  bool _isSelectionMode = false;
  bool _isProcessing = false;
  bool _isNavigating = false;

  void _goBack() {
    if (_isNavigating) return;
    _isNavigating = true;
    
    _TrashScreenLogger.info('🔙 Navegando de vuelta a notas');
    
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      try {
        context.go('/notes');
        _TrashScreenLogger.success('✅ Navegación exitosa');
      } catch (e) {
        _TrashScreenLogger.error('Error: $e');
      } finally {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _isNavigating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final notesState = ref.watch(notesProvider);
    final deletedNotes = notesState.deletedNotes;
    final isLoading = notesState.isLoading || _isProcessing;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    _TrashScreenLogger.info('📊 Estado papelera: ${deletedNotes.length} notas eliminadas');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack();
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: _buildAppBar(isDarkMode, deletedNotes.length, isSmallScreen),
        body: isLoading
            ? const Center(child: LoadingIndicator())
            : deletedNotes.isEmpty
                ? _buildEmptyState(isDarkMode, isSmallScreen)
                : Column(
                    children: [
                      _buildStatsBar(isDarkMode, deletedNotes, isSmallScreen),
                      _buildTopBar(isDarkMode, deletedNotes.length, isSmallScreen),
                      if (_isSelectionMode) _buildSelectionBar(isDarkMode, deletedNotes.length, isSmallScreen),
                      Expanded(
                        child: _viewMode == ViewMode.grid
                            ? _buildGridView(deletedNotes, isSmallScreen)
                            : _buildListView(deletedNotes, isSmallScreen),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode, bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_sweep, size: isSmallScreen ? 60.0 : 80.0, color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'La papelera está vacía',
            style: GoogleFonts.poppins(fontSize: isSmallScreen ? 16.0 : 18.0, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Las notas que elimines aparecerán aquí',
            style: GoogleFonts.poppins(fontSize: isSmallScreen ? 12.0 : 14.0, color: isDarkMode ? Colors.white38 : Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back),
            label: Text('Volver a notas', style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20.0 : 24.0, vertical: isSmallScreen ? 10.0 : 12.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode, int count, bool isSmallScreen) {
    return AppBar(
      title: Text('Papelera', style: GoogleFonts.poppins(fontSize: isSmallScreen ? 18.0 : 20.0)),
      centerTitle: true,
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _goBack,
        iconSize: isSmallScreen ? 22.0 : 24.0,
      ),
      actions: [
        if (count > 0 && !_isSelectionMode)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8.0 : 10.0, vertical: isSmallScreen ? 3.0 : 4.0),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 11.0 : 12.0)),
          ),
      ],
    );
  }

  Widget _buildStatsBar(bool isDarkMode, List<Note> notes, bool isSmallScreen) {
    final totalSize = notes.fold<int>(0, (sum, n) => sum + n.content.length);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8.0 : 12.0, horizontal: isSmallScreen ? 10.0 : 12.0),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.delete, '${notes.length}', 'Notas', Colors.red, isDarkMode, isSmallScreen),
          Container(width: 1, height: isSmallScreen ? 25.0 : 30.0, color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
          _buildStatItem(Icons.description, _formatFileSize(totalSize), 'Contenido', Colors.blue, isDarkMode, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color, bool isDarkMode, bool isSmallScreen) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: isSmallScreen ? 16.0 : 18.0, color: color),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: isSmallScreen ? 13.0 : 15.0, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
          Text(label, style: GoogleFonts.poppins(fontSize: isSmallScreen ? 8.0 : 10.0, color: isDarkMode ? Colors.white54 : Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isDarkMode, int count, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ViewToggle(
                currentMode: _viewMode,
                onModeChanged: (mode) => setState(() => _viewMode = mode),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_isSelectionMode)
            Row(
              children: [
                Expanded(
                  child: _buildMainActionButton(
                    icon: Icons.restore,
                    label: 'RESTAURAR TODO',
                    color: Colors.green,
                    onPressed: _restoreAllNotes,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMainActionButton(
                    icon: Icons.delete_sweep,
                    label: 'VACIAR TODO',
                    color: Colors.red,
                    onPressed: _emptyTrash,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMainActionButton(
                    icon: Icons.checklist,
                    label: 'SELECCIONAR',
                    color: Colors.blue,
                    onPressed: () => setState(() => _isSelectionMode = true),
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMainActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required bool isSmallScreen,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8.0 : 10.0, horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isSmallScreen ? 14.0 : 16.0, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 8.0 : 10.0,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(bool isDarkMode, int totalCount, bool isSmallScreen) {
    final isAllSelected = _selectedNotes.length == totalCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.0 : 16.0, vertical: isSmallScreen ? 8.0 : 10.0),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Contador arriba de los botones
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (isAllSelected) {
                        _selectedNotes.clear();
                      } else {
                        final allNotes = ref.read(notesProvider).deletedNotes;
                        _selectedNotes.addAll(allNotes.map((n) => n.id));
                      }
                    });
                  },
                  icon: Icon(isAllSelected ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.white, size: isSmallScreen ? 20.0 : 22.0),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_selectedNotes.length} seleccionada${_selectedNotes.length != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: isSmallScreen ? 12.0 : 14.0),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _selectedNotes.clear();
                    _isSelectionMode = false;
                  }),
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: Text('CANCELAR', style: TextStyle(color: Colors.white70, fontSize: isSmallScreen ? 10.0 : 11.0)),
                ),
              ],
            ),
          ),
          // Botones de acción más compactos
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _restoreSelectedNotes,
                  icon: Icon(Icons.restore, size: isSmallScreen ? 14.0 : 16.0, color: Colors.white),
                  label: Text('RESTAURAR', style: TextStyle(fontSize: isSmallScreen ? 9.0 : 11.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6.0 : 8.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _deleteSelectedNotes,
                  icon: Icon(Icons.delete_forever, size: isSmallScreen ? 14.0 : 16.0, color: Colors.white),
                  label: Text('ELIMINAR', style: TextStyle(fontSize: isSmallScreen ? 9.0 : 11.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6.0 : 8.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<Note> notes, bool isSmallScreen) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 1 : 2,
        childAspectRatio: isSmallScreen ? 0.85 : 0.75,
        crossAxisSpacing: isSmallScreen ? 8.0 : 12.0,
        mainAxisSpacing: isSmallScreen ? 8.0 : 12.0,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final isSelected = _selectedNotes.contains(note.id);
        
        return TrashNoteCard(
          note: note,
          onTap: _isSelectionMode ? () => _toggleSelection(note.id) : () => _openNote(note.id),
          onRestore: () => _restoreNote(note.id),
          onDeletePermanently: () => _deletePermanently(note.id),
          onToggleFavorite: () => _toggleFavorite(note.id),
          onEdit: () => _editNote(note.id),
          onToggleArchive: () => _toggleArchive(note.id),
          isSelected: isSelected,
          isGridMode: true,
        );
      },
    );
  }

  Widget _buildListView(List<Note> notes, bool isSmallScreen) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final isSelected = _selectedNotes.contains(note.id);
        
        return TrashNoteCard(
          note: note,
          onTap: _isSelectionMode ? () => _toggleSelection(note.id) : () => _openNote(note.id),
          onRestore: () => _restoreNote(note.id),
          onDeletePermanently: () => _deletePermanently(note.id),
          onToggleFavorite: () => _toggleFavorite(note.id),
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

  Future<void> _forceReload() async {
    if (mounted) {
      _TrashScreenLogger.info('🔄 Forzando recarga de notas...');
      await ref.read(notesProvider.notifier).loadNotes();
      setState(() {});
    }
  }

  Future<void> _restoreNote(String id) async {
    setState(() => _isProcessing = true);
    _TrashScreenLogger.info('🔄 Restaurando nota: $id');
    
    try {
      final result = await ref.read(notesProvider.notifier).restoreNote(id);
      await _forceReload();
      
      if (mounted) {
        setState(() => _isProcessing = false);
        if (result != null) {
          ToastMessage.success('Nota restaurada');
          _TrashScreenLogger.success('✅ Nota restaurada: $id');
        } else {
          ToastMessage.error('Error al restaurar la nota');
        }
      }
    } catch (e) {
      _TrashScreenLogger.error('❌ Error restaurando nota: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ToastMessage.error('Error al restaurar la nota');
      }
    }
  }

  Future<void> _restoreAllNotes() async {
    final confirmed = await _showConfirmDialog('Restaurar todo', '¿Restaurar todas las notas de la papelera?');
    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);
      _TrashScreenLogger.info('🔄 Restaurando todas las notas...');
      
      try {
        final notes = List<Note>.from(ref.read(notesProvider).deletedNotes);
        int successCount = 0;
        
        for (final note in notes) {
          final result = await ref.read(notesProvider.notifier).restoreNote(note.id);
          if (result != null) successCount++;
        }
        
        await _forceReload();
        
        if (mounted) {
          setState(() => _isProcessing = false);
          ToastMessage.success('$successCount notas restauradas');
          _TrashScreenLogger.success('✅ $successCount notas restauradas');
          
          if (ref.read(notesProvider).deletedNotes.isEmpty) {
            _goBack();
          }
        }
      } catch (e) {
        _TrashScreenLogger.error('❌ Error restaurando todas: $e');
        if (mounted) {
          setState(() => _isProcessing = false);
          ToastMessage.error('Error al restaurar notas');
        }
      }
    }
  }

  Future<void> _restoreSelectedNotes() async {
    final count = _selectedNotes.length;
    if (count == 0) {
      ToastMessage.warning('No hay notas seleccionadas');
      return;
    }
    
    setState(() => _isProcessing = true);
    _TrashScreenLogger.info('🔄 Restaurando $count notas seleccionadas...');
    
    try {
      int successCount = 0;
      for (final id in _selectedNotes) {
        final result = await ref.read(notesProvider.notifier).restoreNote(id);
        if (result != null) successCount++;
      }
      await _forceReload();
      
      if (mounted) {
        setState(() {
          _selectedNotes.clear();
          _isSelectionMode = false;
          _isProcessing = false;
        });
        ToastMessage.success('$successCount nota${successCount != 1 ? 's' : ''} restaurada${successCount != 1 ? 's' : ''}');
        _TrashScreenLogger.success('✅ $successCount notas restauradas');
      }
    } catch (e) {
      _TrashScreenLogger.error('❌ Error restaurando seleccionadas: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ToastMessage.error('Error al restaurar notas');
      }
    }
  }

  Future<void> _deletePermanently(String id) async {
    final confirmed = await _showConfirmDialog(
      'Eliminar permanentemente',
      '¿Eliminar esta nota permanentemente? Esta acción no se puede deshacer.',
    );
    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);
      _TrashScreenLogger.info('🗑️ Eliminando permanentemente nota: $id');
      
      try {
        final success = await ref.read(notesProvider.notifier).permanentlyDeleteNote(id);
        await _forceReload();
        
        if (mounted) {
          setState(() => _isProcessing = false);
          if (success) {
            ToastMessage.success('Nota eliminada permanentemente');
            _TrashScreenLogger.success('✅ Nota eliminada permanentemente: $id');
          } else {
            ToastMessage.error('Error al eliminar la nota');
          }
        }
      } catch (e) {
        _TrashScreenLogger.error('❌ Error eliminando permanentemente: $e');
        if (mounted) {
          setState(() => _isProcessing = false);
          ToastMessage.error('Error al eliminar la nota');
        }
      }
    }
  }

  Future<void> _deleteSelectedNotes() async {
    final count = _selectedNotes.length;
    if (count == 0) {
      ToastMessage.warning('No hay notas seleccionadas');
      return;
    }
    
    final confirmed = await _showConfirmDialog(
      'Eliminar seleccionadas',
      '¿Eliminar permanentemente $count nota${count != 1 ? 's' : ''}? Esta acción no se puede deshacer.',
    );
    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);
      _TrashScreenLogger.info('🗑️ Eliminando permanentemente $count notas...');
      
      try {
        for (final id in _selectedNotes) {
          await ref.read(notesProvider.notifier).permanentlyDeleteNote(id);
        }
        await _forceReload();
        
        if (mounted) {
          setState(() {
            _selectedNotes.clear();
            _isSelectionMode = false;
            _isProcessing = false;
          });
          ToastMessage.success('$count nota${count != 1 ? 's' : ''} eliminada${count != 1 ? 's' : ''} permanentemente');
          _TrashScreenLogger.success('✅ $count notas eliminadas permanentemente');
        }
      } catch (e) {
        _TrashScreenLogger.error('❌ Error eliminando seleccionadas: $e');
        if (mounted) {
          setState(() => _isProcessing = false);
          ToastMessage.error('Error al eliminar notas');
        }
      }
    }
  }

  Future<void> _emptyTrash() async {
    final confirmed = await _showConfirmDialog('Vaciar papelera', '¿Vaciar la papelera? Se eliminarán permanentemente todas las notas.');
    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);
      _TrashScreenLogger.info('🗑️ Vaciando papelera completa...');
      
      try {
        final success = await ref.read(notesProvider.notifier).emptyTrash();
        await _forceReload();
        
        if (mounted) {
          setState(() => _isProcessing = false);
          if (success) {
            ToastMessage.success('Papelera vaciada');
            _TrashScreenLogger.success('✅ Papelera vaciada');
            if (ref.read(notesProvider).deletedNotes.isEmpty) {
              _goBack();
            }
          } else {
            ToastMessage.error('Error al vaciar la papelera');
          }
        }
      } catch (e) {
        _TrashScreenLogger.error('❌ Error vaciando papelera: $e');
        if (mounted) {
          setState(() => _isProcessing = false);
          ToastMessage.error('Error al vaciar la papelera');
        }
      }
    }
  }

  Future<void> _toggleFavorite(String id) async {
    setState(() => _isProcessing = true);
    _TrashScreenLogger.info('⭐ Toggle favorito: $id');
    
    try {
      final result = await ref.read(notesProvider.notifier).toggleFavorite(id);
      await _forceReload();
      
      if (mounted) {
        setState(() => _isProcessing = false);
        if (result != null) {
          ToastMessage.success('Estado de favorito actualizado');
          _TrashScreenLogger.success('✅ Favorito toggled: $id');
        } else {
          ToastMessage.error('Error al actualizar favorito');
        }
      }
    } catch (e) {
      _TrashScreenLogger.error('❌ Error toggling favorito: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ToastMessage.error('Error al actualizar favorito');
      }
    }
  }

  Future<void> _toggleArchive(String id) async {
    setState(() => _isProcessing = true);
    _TrashScreenLogger.info('📦 Toggle archivo: $id');
    
    try {
      final result = await ref.read(notesProvider.notifier).toggleArchive(id);
      await _forceReload();
      
      if (mounted) {
        setState(() => _isProcessing = false);
        if (result != null) {
          ToastMessage.success('Estado de archivo actualizado');
          _TrashScreenLogger.success('✅ Archive toggled: $id');
        } else {
          ToastMessage.error('Error al actualizar archivo');
        }
      }
    } catch (e) {
      _TrashScreenLogger.error('❌ Error toggling archivo: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ToastMessage.error('Error al actualizar archivo');
      }
    }
  }

  void _openNote(String id) {
    context.push('/notes/$id');
  }

  void _editNote(String id) {
    context.push('/notes/$id/edit');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<bool?> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
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
            child: Text('Aceptar', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}