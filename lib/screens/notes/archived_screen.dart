// lib/screens/notes/archived_screen.dart
// Pantalla de notas archivadas - VERSIÓN CORREGIDA
// ✅ CORREGIDO: Uso correcto del provider
// ✅ CORREGIDO: Getters correctos del estado

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

class _ArchivedScreenLogger {
  static void info(String message) => debugPrint('ℹ️ [ArchivedScreen] $message');
  static void success(String message) => debugPrint('✅ [ArchivedScreen] $message');
  static void error(String message) => debugPrint('❌ [ArchivedScreen] $message');
}

class ArchivedNoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final bool isSelected;
  final bool isGridMode;

  const ArchivedNoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onRestore,
    required this.onDelete,
    required this.onToggleFavorite,
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
      return Icon(Icons.archive, size: size, color: _noteColor);
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
          border: isSelected ? Border.all(color: Colors.teal, width: 2) : null,
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
                  if (note.isFavorite)
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.star, size: isSmallScreen ? 14 : 18, color: Colors.amber),
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
                  _buildActionIcon(
                    icon: Icons.restore,
                    color: Colors.teal,
                    onTap: onRestore,
                    tooltip: 'Restaurar',
                    size: isSmallScreen ? 26 : 30,
                  ),
                  _buildActionIcon(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    onTap: onDelete,
                    tooltip: 'Mover a papelera',
                    size: isSmallScreen ? 26 : 30,
                  ),
                  _buildActionIcon(
                    icon: note.isFavorite ? Icons.star : Icons.star_border,
                    color: note.isFavorite ? Colors.amber : Colors.grey,
                    onTap: onToggleFavorite,
                    tooltip: note.isFavorite ? 'Quitar favorito' : 'Marcar favorito',
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
          border: isSelected ? Border.all(color: Colors.teal, width: 2) : null,
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
                              color: Colors.teal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Archivada', style: TextStyle(fontSize: 10, color: Colors.teal)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (note.isFavorite)
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.star, size: isSmallScreen ? 14 : 16, color: Colors.amber),
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
                _buildActionIcon(
                  icon: Icons.restore,
                  color: Colors.teal,
                  onTap: onRestore,
                  tooltip: 'Restaurar',
                  size: isSmallScreen ? 24 : 28,
                ),
                _buildActionIcon(
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  onTap: onDelete,
                  tooltip: 'Mover a papelera',
                  size: isSmallScreen ? 24 : 28,
                ),
                _buildActionIcon(
                  icon: note.isFavorite ? Icons.star : Icons.star_border,
                  color: note.isFavorite ? Colors.amber : Colors.grey,
                  onTap: onToggleFavorite,
                  tooltip: note.isFavorite ? 'Quitar favorito' : 'Marcar favorito',
                  size: isSmallScreen ? 24 : 28,
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
// PANTALLA PRINCIPAL - CORREGIDA
// ============================================

class ArchivedScreen extends ConsumerStatefulWidget {
  const ArchivedScreen({super.key});

  @override
  ConsumerState<ArchivedScreen> createState() => _ArchivedScreenState();
}

class _ArchivedScreenState extends ConsumerState<ArchivedScreen> {
  ViewMode _viewMode = ViewMode.grid;
  final Set<String> _selectedNotes = {};
  bool _isSelectionMode = false;
  bool _isProcessing = false;
  bool _isNavigating = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _ArchivedScreenLogger.info('📦 Inicializando pantalla de archivados...');
    setState(() => _isProcessing = true);
    
    // Cargar notas si es necesario
    final notesState = ref.read(notesProvider);
    if (notesState.notes.isEmpty) {
      _ArchivedScreenLogger.info('🔄 Cargando notas por primera vez...');
      await ref.read(notesProvider.notifier).loadNotes();
    }
    
    setState(() {
      _isProcessing = false;
      _isInitialized = true;
    });
    _ArchivedScreenLogger.success('✅ Inicialización completada');
  }

  /// Obtener notas archivadas del estado
  List<Note> _getArchivedNotes() {
    final notesState = ref.read(notesProvider);
    // ✅ CORREGIDO: Filtrar notas archivadas del estado notes
    final archivedNotes = notesState.notes.where((note) => note.isArchived && note.deletedAt == null).toList();
    _ArchivedScreenLogger.info('📊 Notas archivadas: ${archivedNotes.length} de ${notesState.notes.length} totales');
    return archivedNotes;
  }

  void _goBack() {
    if (_isNavigating) return;
    _isNavigating = true;
    
    _ArchivedScreenLogger.info('🔙 Navegando de vuelta a notas');
    
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      try {
        context.go('/notes');
        _ArchivedScreenLogger.success('✅ Navegación exitosa');
      } catch (e) {
        _ArchivedScreenLogger.error('Error: $e');
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
    
    // ✅ CORREGIDO: Usar isLoading del estado correctamente
    final isLoading = notesState.isLoading || _isProcessing || !_isInitialized;
    final archivedNotes = _getArchivedNotes();

    _ArchivedScreenLogger.info('🏗️ Build - isLoading: $isLoading, archivedNotes: ${archivedNotes.length}');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack();
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: _buildAppBar(isDarkMode, archivedNotes),
        body: SafeArea(
          child: isLoading
              ? const Center(child: LoadingIndicator())
              : archivedNotes.isEmpty
                  ? _buildEmptyState(isDarkMode)
                  : Column(
                      children: [
                        if (!_isSelectionMode) _buildStatsBar(isDarkMode, archivedNotes),
                        if (!_isSelectionMode) _buildActionsBar(isDarkMode),
                        if (_isSelectionMode) _buildSelectionBar(isDarkMode, archivedNotes.length),
                        Expanded(
                          child: _viewMode == ViewMode.grid
                              ? _buildGridView(archivedNotes)
                              : _buildListView(archivedNotes),
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
          Icon(Icons.archive_outlined, size: 80, color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No hay notas archivadas',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Las notas que archives aparecerán aquí',
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

  PreferredSizeWidget _buildAppBar(bool isDarkMode, List<Note> archivedNotes) {
    return AppBar(
      title: const Text('Archivadas'),
      centerTitle: true,
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _goBack,
      ),
      actions: [
        if (archivedNotes.isNotEmpty)
          ExportButton(notes: archivedNotes, showLabel: false, iconSize: 22),
        if (archivedNotes.isNotEmpty && !_isSelectionMode)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${archivedNotes.length}', style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildStatsBar(bool isDarkMode, List<Note> notes) {
    final totalSize = notes.fold<int>(0, (sum, n) => sum + n.content.length);
    final totalNotes = notes.length;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.archive, '$totalNotes', 'Notas', Colors.teal, isDarkMode),
          Container(width: 1, height: 30, color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
          _buildStatItem(Icons.description, _formatFileSize(totalSize), 'Contenido', Colors.blue, isDarkMode),
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
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _restoreAllNotes,
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('RESTAURAR TODO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade400),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _isSelectionMode = true),
            icon: const Icon(Icons.checklist, size: 18),
            label: const Text('SELECCIONAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      color: Colors.teal,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                if (isAllSelected) {
                  _selectedNotes.clear();
                } else {
                  final notes = _getArchivedNotes();
                  _selectedNotes.addAll(notes.map((n) => n.id));
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
            onPressed: _restoreSelectedNotes,
            icon: const Icon(Icons.restore, size: 18),
            label: const Text('RESTAURAR', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _deleteSelectedNotes,
            icon: const Icon(Icons.delete_outline, size: 18),
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
        
        return ArchivedNoteCard(
          note: note,
          onTap: _isSelectionMode ? () => _toggleSelection(note.id) : () => _openNote(note.id),
          onRestore: () => _restoreNote(note.id),
          onDelete: () => _deleteNote(note.id),
          onToggleFavorite: () => _toggleFavorite(note.id),
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
        
        return ArchivedNoteCard(
          note: note,
          onTap: _isSelectionMode ? () => _toggleSelection(note.id) : () => _openNote(note.id),
          onRestore: () => _restoreNote(note.id),
          onDelete: () => _deleteNote(note.id),
          onToggleFavorite: () => _toggleFavorite(note.id),
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

  Future<void> _restoreNote(String id) async {
    setState(() => _isProcessing = true);
    final note = await ref.read(notesProvider.notifier).toggleArchive(id);
    await ref.read(notesProvider.notifier).loadNotes();
    setState(() => _isProcessing = false);
    
    if (note != null && mounted) {
      ToastMessage.success('Nota restaurada');
      final remainingArchived = _getArchivedNotes();
      if (remainingArchived.isEmpty) {
        _goBack();
      }
    } else if (mounted) {
      ToastMessage.error('Error al restaurar la nota');
    }
  }

  Future<void> _restoreAllNotes() async {
    final notes = _getArchivedNotes();
    if (notes.isEmpty) {
      ToastMessage.info('No hay notas archivadas');
      return;
    }
    
    final confirmed = await _showConfirmDialog('Restaurar todo', '¿Restaurar todas las notas archivadas?');
    if (confirmed) {
      setState(() => _isProcessing = true);
      for (final note in notes) {
        await ref.read(notesProvider.notifier).toggleArchive(note.id);
      }
      await ref.read(notesProvider.notifier).loadNotes();
      setState(() => _isProcessing = false);
      ToastMessage.success('Todas las notas restauradas');
      if (mounted && _getArchivedNotes().isEmpty) {
        _goBack();
      }
    }
  }

  Future<void> _restoreSelectedNotes() async {
    final count = _selectedNotes.length;
    setState(() => _isProcessing = true);
    
    for (final id in _selectedNotes) {
      await ref.read(notesProvider.notifier).toggleArchive(id);
    }
    await ref.read(notesProvider.notifier).loadNotes();
    
    setState(() {
      _selectedNotes.clear();
      _isSelectionMode = false;
      _isProcessing = false;
    });
    
    ToastMessage.success('$count nota${count != 1 ? 's' : ''} restaurada${count != 1 ? 's' : ''}');
    if (mounted && _getArchivedNotes().isEmpty) {
      _goBack();
    }
  }

  Future<void> _deleteNote(String id) async {
    final confirmed = await _showConfirmDialog(
      'Mover a papelera',
      '¿Mover esta nota a la papelera? Podrás restaurarla después.',
    );
    if (confirmed) {
      setState(() => _isProcessing = true);
      final success = await ref.read(notesProvider.notifier).deleteNote(id);
      await ref.read(notesProvider.notifier).loadNotes();
      setState(() => _isProcessing = false);
      if (mounted) {
        if (success) {
          ToastMessage.success('Nota movida a la papelera');
          if (_getArchivedNotes().isEmpty) {
            _goBack();
          }
        } else {
          ToastMessage.error('Error al mover la nota');
        }
      }
    }
  }

  Future<void> _deleteSelectedNotes() async {
    final count = _selectedNotes.length;
    final confirmed = await _showConfirmDialog(
      'Mover a papelera',
      '¿Mover $count nota${count != 1 ? 's' : ''} a la papelera? Podrás restaurarlas después.',
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
      ToastMessage.success('$count nota${count != 1 ? 's' : ''} movida${count != 1 ? 's' : ''} a la papelera');
      if (mounted && _getArchivedNotes().isEmpty) {
        _goBack();
      }
    }
  }

  Future<void> _toggleFavorite(String id) async {
    final note = await ref.read(notesProvider.notifier).toggleFavorite(id);
    if (note != null && mounted) {
      ToastMessage.success('Estado de favorito actualizado');
    }
  }

  void _openNote(String id) {
    context.push('/notes/$id');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(title == 'Restaurar todo' ? 'Restaurar' : 'Mover a papelera', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}