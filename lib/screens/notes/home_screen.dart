// lib/screens/notes/home_screen.dart
// Pantalla principal de notas - VERSIÓN DEFINITIVA CORREGIDA
// ✅ CORREGIDO: No modificar provider en initState/didChangeDependencies
// ✅ Uso de addPostFrameCallback para cargar datos después del primer frame
// ✅ Manejo correcto de recarga al volver de otras pantallas

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/providers/notes_provider.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:quicknote/screens/notes/export_modal.dart';
import 'package:quicknote/widgets/note_card.dart';
import 'package:quicknote/widgets/loading_indicator.dart';
import 'package:quicknote/widgets/empty_state.dart';
import 'package:quicknote/widgets/view_toggle.dart';
import 'package:quicknote/widgets/greeting_widget.dart';
import 'package:quicknote/widgets/left_menu.dart';
import 'package:quicknote/widgets/right_menu.dart';
import 'package:quicknote/widgets/toast_message.dart';
import 'package:quicknote/widgets/filters_widget.dart';
import 'package:quicknote/widgets/app_bottom_nav.dart';
import 'package:quicknote/widgets/export_button.dart';
import 'package:quicknote/widgets/cloud_restore_prompt.dart';
import 'package:quicknote/models/note.dart';

export 'package:quicknote/widgets/filters_widget.dart' show SortOption;

class _HomeScreenLogger {
  static void info(String message) => debugPrint('ℹ️ [HomeScreen] $message');
  static void success(String message) => debugPrint('✅ [HomeScreen] $message');
  static void error(String message) => debugPrint('❌ [HomeScreen] $message');
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  String _selectedTag = '';
  
  String _selectedIcon = 'all';
  String _selectedSize = 'all';
  String _selectedIntensity = 'all';
  SortOption _sortBy = SortOption.newest;
  ViewMode _viewMode = ViewMode.grid;
  final Set<String> _selectedNotes = {};
  bool _isSelectionMode = false;
  
  bool _isLeftMenuOpen = false;
  bool _isRightMenuOpen = false;
  
  final ScrollController _scrollController = ScrollController();
  bool _showFilters = true;
  double _lastScrollPosition = 0;
  
  bool _hasCheckedCloudRestore = false;
  bool _isRestoring = false;
  
  // ✅ Control para evitar recargas múltiples
  bool _isInitialLoad = true;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // ✅ CORREGIDO: Usar addPostFrameCallback para cargar después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ CORREGIDO: Recargar cuando se vuelve a esta pantalla, pero NO en el primer build
    if (!_isInitialLoad && !_isLoadingData) {
      _HomeScreenLogger.info('🔄 didChangeDependencies - Recargando notas...');
      _refreshNotes();
    }
  }

  Future<void> _loadInitialData() async {
    if (_isLoadingData) return;
    _isLoadingData = true;
    
    _HomeScreenLogger.info('📦 Cargando datos iniciales...');
    
    try {
      final notesState = ref.read(notesProvider);
      if (notesState.notes.isEmpty) {
        await ref.read(notesProvider.notifier).loadNotes();
      }
    } catch (e) {
      _HomeScreenLogger.error('❌ Error cargando datos iniciales: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
          _hasCheckedCloudRestore = true;
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _refreshNotes() async {
    if (_isLoadingData) return;
    _isLoadingData = true;
    
    _HomeScreenLogger.info('🔄 Refrescando notas...');
    
    try {
      await ref.read(notesProvider.notifier).loadNotes();
      _HomeScreenLogger.success('✅ Notas recargadas correctamente');
    } catch (e) {
      _HomeScreenLogger.error('❌ Error recargando notas: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  void _onScroll() {
    final currentPosition = _scrollController.position.pixels;
    if (currentPosition > _lastScrollPosition && currentPosition > 100) {
      if (_showFilters) setState(() => _showFilters = false);
    } else if (currentPosition < _lastScrollPosition) {
      if (!_showFilters) setState(() => _showFilters = true);
    }
    _lastScrollPosition = currentPosition;
  }

  void _openLeftMenu() => setState(() => _isLeftMenuOpen = true);
  void _closeLeftMenu() => setState(() => _isLeftMenuOpen = false);
  void _openRightMenu() => setState(() => _isRightMenuOpen = true);
  void _closeRightMenu() => setState(() => _isRightMenuOpen = false);

  void _navigateTo(String route) {
    _closeLeftMenu();
    _HomeScreenLogger.info('📍 Navegando a: $route');
    
    const mainRoutes = ['/notes', '/notes/archived', '/notes/favorites', '/settings', '/trash'];
    
    if (mainRoutes.contains(route)) {
      context.go(route);
    } else {
      context.push(route);
    }
  }

  void _syncNotes() async {
    _closeRightMenu();
    _HomeScreenLogger.info('🔄 Sincronizando notas manualmente...');
    await _refreshNotes();
    if (mounted) {
      ToastMessage.success('Notas sincronizadas');
    }
  }

  void _exportNotes() {
    _closeRightMenu();
    _showExportModal();
  }

  void _importNotes() {
    _closeRightMenu();
    ToastMessage.info('Importación - Próximamente');
  }

  void _showExportModal() {
    final notesState = ref.read(notesProvider);
    final notes = notesState.activeNotes;
    
    if (notes.isEmpty) {
      ToastMessage.warning('No hay notas para exportar');
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ExportModal(
        notes: notes,
        onExportComplete: () {
          ToastMessage.success('Exportación completada');
        },
      ),
    );
  }

  void _createNote() => context.push('/notes/new');
  void _openNote(String id) => context.push('/notes/$id');
  void _editNote(String id) => context.push('/notes/$id/edit');

  void _toggleFavorite(String id) {
    ref.read(notesProvider.notifier).toggleFavorite(id);
  }

  void _toggleArchive(String id) {
    ref.read(notesProvider.notifier).toggleArchive(id);
  }

  Future<void> _deleteNote(String id) async {
    final confirmed = await _showConfirmDialog(
      'Eliminar nota',
      '¿Eliminar esta nota permanentemente?',
    );
    if (confirmed && mounted) {
      final success = await ref.read(notesProvider.notifier).deleteNote(id);
      if (mounted && success) {
        ToastMessage.success('Nota eliminada');
        await _refreshNotes();
      } else if (mounted) {
        ToastMessage.error('Error al eliminar la nota');
      }
    }
  }

  Future<void> _deleteSelectedNotes() async {
    if (_selectedNotes.isEmpty) return;
    final confirmed = await _showConfirmDialog(
      'Eliminar notas',
      '¿Eliminar ${_selectedNotes.length} nota${_selectedNotes.length != 1 ? 's' : ''}?',
    );
    if (confirmed && mounted) {
      for (final id in _selectedNotes) {
        await ref.read(notesProvider.notifier).deleteNote(id);
      }
      await _refreshNotes();
      setState(() {
        _selectedNotes.clear();
        _isSelectionMode = false;
      });
      if (mounted) ToastMessage.success('Notas eliminadas');
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedNotes.contains(id)) {
        _selectedNotes.remove(id);
        if (_selectedNotes.isEmpty) _isSelectionMode = false;
      } else {
        _selectedNotes.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSearch() => setState(() => _searchQuery = '');
  
  void _clearAllFilters() {
    setState(() {
      _selectedIcon = 'all';
      _selectedSize = 'all';
      _selectedIntensity = 'all';
      _sortBy = SortOption.newest;
      _selectedTag = '';
    });
    ToastMessage.info('Filtros eliminados');
  }

  List<Note> _getFilteredNotes(NotesState state) {
    var notes = List<Note>.from(state.activeNotes);
    
    if (_searchQuery.isNotEmpty) {
      notes = notes.where((n) =>
        n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        n.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        n.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }
    
    if (_selectedTag.isNotEmpty) {
      notes = notes.where((n) => n.tags.contains(_selectedTag)).toList();
    }
    
    if (_selectedIcon != 'all') {
      notes = notes.where((n) => 
        (n.iconConfig.value.toString().split('.').last) == _selectedIcon
      ).toList();
    }
    
    if (_selectedSize != 'all') {
      notes = notes.where((n) => 
        n.sizeConfig.value.toString().split('.').last == _selectedSize
      ).toList();
    }
    
    if (_selectedIntensity != 'all') {
      notes = notes.where((n) => 
        n.intensityConfig.value.toString().split('.').last == _selectedIntensity
      ).toList();
    }
    
    notes.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case SortOption.titleAsc:
          comparison = a.title.compareTo(b.title);
          break;
        case SortOption.titleDesc:
          comparison = b.title.compareTo(a.title);
          break;
        case SortOption.favorites:
          comparison = (b.isFavorite ? 1 : 0).compareTo(a.isFavorite ? 1 : 0);
          break;
        case SortOption.updated:
          comparison = b.updatedAt.compareTo(a.updatedAt);
          break;
        case SortOption.newest:
          comparison = b.createdAt.compareTo(a.createdAt);
          break;
        case SortOption.oldest:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return comparison;
    });
    
    return notes;
  }

  List<String> _getAllTags(NotesState state) {
    final tags = <String>{};
    for (final note in state.activeNotes) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }

  bool get _hasActiveFilters {
    return _selectedIcon != 'all' ||
        _selectedSize != 'all' ||
        _selectedIntensity != 'all' ||
        _sortBy != SortOption.newest ||
        _selectedTag.isNotEmpty;
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.poppins()),
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
    final notesState = ref.watch(notesProvider);
    final user = ref.watch(currentUserProvider);
    final tags = _getAllTags(notesState);
    final filteredNotes = _getFilteredNotes(notesState);
    final activeNotes = notesState.activeNotes;
    
    // ✅ Mostrar loading solo en la primera carga
    final isLoading = _isInitialLoad && notesState.notes.isEmpty;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          body: isLoading
              ? const Center(child: LoadingIndicator())
              : Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDarkMode
                              ? const [Color(0xFF1E3A8A), Color(0xFF4C1D95), Color(0xFF831843)]
                              : const [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFEC4899)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      ),
                      child: SafeArea(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildIconButton(Icons.menu, _openLeftMenu),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.edit_note, size: 18, color: Colors.white),
                                      ),
                                      const SizedBox(width: 6),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          RichText(
                                            text: const TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: 'Quick',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: 'Note',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFFCD34D),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 40,
                                            height: 2,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFFF59E0B), Color(0xFF3B82F6)],
                                              ),
                                              borderRadius: BorderRadius.circular(1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      ExportButton(
                                        showLabel: false,
                                        iconSize: 22,
                                      ),
                                      const SizedBox(width: 4),
                                      _buildIconButton(Icons.search, _showSearchBar),
                                      _buildIconButton(Icons.more_vert, _openRightMenu),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            GreetingWidget(
                              userName: user?.name,
                              userAvatar: user?.avatar,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: _buildCategorySelector(tags),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    if (_searchQuery.isNotEmpty) _buildSearchBar(isDarkMode),
                    
                    const SizedBox(height: 8),
                    
                    AnimatedOpacity(
                      opacity: _showFilters ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: _showFilters ? null : 0,
                        child: _showFilters
                            ? FiltersWidget(
                                selectedIcon: _selectedIcon,
                                selectedSize: _selectedSize,
                                selectedIntensity: _selectedIntensity,
                                sortBy: _sortBy,
                                onIconChanged: (value) => setState(() => _selectedIcon = value),
                                onSizeChanged: (value) => setState(() => _selectedSize = value),
                                onIntensityChanged: (value) => setState(() => _selectedIntensity = value),
                                onSortChanged: (value) => setState(() => _sortBy = value),
                                onClearAll: _clearAllFilters,
                                showClearButton: true,
                                initiallyExpanded: false,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${filteredNotes.length}',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                filteredNotes.length == 1 ? 'nota' : 'notas',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                                ),
                              ),
                              if (_hasActiveFilters)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Filtros activos',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      color: _primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          ViewToggle(
                            currentMode: _viewMode,
                            onModeChanged: (mode) => setState(() => _viewMode = mode),
                          ),
                        ],
                      ),
                    ),
                    
                    if (_isSelectionMode) _buildSelectionBar(isDarkMode),
                    
                    Expanded(
                      child: filteredNotes.isEmpty
                          ? _searchQuery.isEmpty
                              ? EmptyState.notes(onCreate: _createNote)
                              : EmptyState.search(_searchQuery, onClear: _clearSearch)
                          : _buildNotesList(isDarkMode, filteredNotes),
                    ),
                  ],
                ),
          bottomNavigationBar: AppBottomNav(
            currentIndex: 0,
            onTabChanged: (index) {
              _HomeScreenLogger.info('Tab cambiada a índice: $index');
            },
          ),
        ),
        
        if (_isLeftMenuOpen)
          LeftMenu(
            isOpen: _isLeftMenuOpen,
            onClose: _closeLeftMenu,
            onNavigate: _navigateTo,
          ),
        if (_isRightMenuOpen)
          RightMenu(
            isOpen: _isRightMenuOpen,
            onClose: _closeRightMenu,
            onSync: _syncNotes,
            onExport: _exportNotes,
            onImport: _importNotes,
          ),
        
        if (_hasCheckedCloudRestore && !_isRestoring && activeNotes.isNotEmpty)
          CloudRestorePrompt(
            localNotes: activeNotes,
            onRestoreComplete: () async {
              setState(() => _isRestoring = true);
              await _refreshNotes();
              setState(() => _isRestoring = false);
              _HomeScreenLogger.success('✅ Restauración completada, notas recargadas');
            },
            onDismiss: () {
              _HomeScreenLogger.info('📱 CloudRestorePrompt descartado');
            },
          ),
      ],
    );
  }

  Color get _primaryColor => const Color(0xFF8B5CF6);

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(List<String> tags) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedTag.isEmpty ? null : _selectedTag,
          hint: const Row(
            children: [
              Icon(Icons.tag, size: 16, color: Colors.white70),
              SizedBox(width: 8),
              Text(
                'Todas las notas',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
          dropdownColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.list_alt, size: 16),
                  SizedBox(width: 8),
                  Text('Todas las notas'),
                ],
              ),
            ),
            ...tags.map((tag) {
              return DropdownMenuItem<String?>(
                value: tag,
                child: Row(
                  children: [
                    const Icon(Icons.tag, size: 16, color: Color(0xFF8B5CF6)),
                    const SizedBox(width: 8),
                    Text('#$tag'),
                  ],
                ),
              );
            }),
          ],
          onChanged: (value) => setState(() => _selectedTag = value ?? ''),
        ),
      ),
    );
  }

  void _showSearchBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        content: TextField(
          autofocus: true,
          onChanged: (value) {
            setState(() => _searchQuery = value);
            Navigator.pop(context);
          },
          style: GoogleFonts.poppins(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Buscar notas...',
            hintStyle: GoogleFonts.poppins(
              color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
            ),
            prefixIcon: Icon(Icons.search, color: _primaryColor),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode ? const Color(0xFF374151) : Colors.grey.shade50,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Buscando: $_searchQuery',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: _clearSearch,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _primaryColor,
      child: Row(
        children: [
          Text(
            '${_selectedNotes.length} seleccionada${_selectedNotes.length != 1 ? 's' : ''}',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() {
              _selectedNotes.clear();
              _isSelectionMode = false;
            }),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _deleteSelectedNotes,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ELIMINAR', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(bool isDarkMode, List<Note> notes) {
    if (_viewMode == ViewMode.grid) {
      return GridView.builder(
        controller: _scrollController,
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
          
          return GestureDetector(
            onLongPress: () => setState(() {
              _isSelectionMode = true;
              _selectedNotes.add(note.id);
            }),
            child: NoteCard(
              note: note,
              onTap: _isSelectionMode
                  ? () => _toggleSelection(note.id)
                  : () => _openNote(note.id),
              onEdit: () => _editNote(note.id),
              onDelete: () => _deleteNote(note.id),
              onToggleFavorite: () => _toggleFavorite(note.id),
              onToggleArchive: () => _toggleArchive(note.id),
              isSelected: isSelected,
              isGridMode: true,
            ),
          );
        },
      );
    } else {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          final isSelected = _selectedNotes.contains(note.id);
          
          return GestureDetector(
            onLongPress: () => setState(() {
              _isSelectionMode = true;
              _selectedNotes.add(note.id);
            }),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NoteCard(
                note: note,
                onTap: _isSelectionMode
                    ? () => _toggleSelection(note.id)
                    : () => _openNote(note.id),
                onEdit: () => _editNote(note.id),
                onDelete: () => _deleteNote(note.id),
                onToggleFavorite: () => _toggleFavorite(note.id),
                onToggleArchive: () => _toggleArchive(note.id),
                isSelected: isSelected,
                isGridMode: false,
              ),
            ),
          );
        },
      );
    }
  }
}