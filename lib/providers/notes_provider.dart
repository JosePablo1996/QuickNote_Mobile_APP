// lib/providers/notes_provider.dart
// Provider para gestión de notas - VERSIÓN CORREGIDA CON RESTORE FROM BACKUP
// ✅ Integración con Auto-Backup
// ✅ CRUD completo de notas
// ✅ Soft delete (mover a papelera) y eliminación permanente
// ✅ Vaciar papelera completo
// ✅ CORREGIDO: replaceAllNotes ahora notifica correctamente a los listeners
// ✅ CORREGIDO: Recarga forzada del estado
// ✅ NUEVO: restoreFromBackup - Elimina notas actuales y crea nuevas desde backup

import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicknote/models/note.dart';
import 'package:quicknote/core/services/note_service.dart';
import 'package:quicknote/providers/auto_backup_provider.dart';

// ============================================
// LOGGER
// ============================================

class _NotesProviderLogger {
  static void info(String message) => log('ℹ️ [NotesProvider] $message');
  static void success(String message) => log('✅ [NotesProvider] $message');
  static void warning(String message) => log('⚠️ [NotesProvider] $message');
  static void error(String message) => log('❌ [NotesProvider] $message');
}

// ============================================
// ESTADO
// ============================================

class NotesState {
  final List<Note> notes;
  final List<Note> archivedNotes;
  final List<Note> deletedNotes;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final String? selectedTag;
  final String? selectedIcon;
  final String? selectedSize;
  final String? selectedIntensity;
  final String sortBy;
  final bool sortAscending;
  final Set<String> selectedNoteIds;

  const NotesState({
    this.notes = const [],
    this.archivedNotes = const [],
    this.deletedNotes = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.selectedTag,
    this.selectedIcon,
    this.selectedSize,
    this.selectedIntensity,
    this.sortBy = 'updated_at',
    this.sortAscending = false,
    this.selectedNoteIds = const {},
  });

  NotesState copyWith({
    List<Note>? notes,
    List<Note>? archivedNotes,
    List<Note>? deletedNotes,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? selectedTag,
    String? selectedIcon,
    String? selectedSize,
    String? selectedIntensity,
    String? sortBy,
    bool? sortAscending,
    Set<String>? selectedNoteIds,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      archivedNotes: archivedNotes ?? this.archivedNotes,
      deletedNotes: deletedNotes ?? this.deletedNotes,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTag: selectedTag ?? this.selectedTag,
      selectedIcon: selectedIcon ?? this.selectedIcon,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedIntensity: selectedIntensity ?? this.selectedIntensity,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      selectedNoteIds: selectedNoteIds ?? this.selectedNoteIds,
    );
  }

  // ============================================
  // GETTERS ÚTILES
  // ============================================

  List<Note> get activeNotes {
    return notes.where((n) => !n.isArchived && n.deletedAt == null).toList();
  }

  List<Note> get favoriteNotes {
    return activeNotes.where((n) => n.isFavorite).toList();
  }

  List<Note> get filteredNotes {
    var filtered = List<Note>.from(activeNotes);
    
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      filtered = filtered.where((n) =>
        n.title.toLowerCase().contains(searchQuery!.toLowerCase()) ||
        n.content.toLowerCase().contains(searchQuery!.toLowerCase()) ||
        n.tags.any((t) => t.toLowerCase().contains(searchQuery!.toLowerCase()))
      ).toList();
    }
    
    if (selectedTag != null && selectedTag!.isNotEmpty) {
      filtered = filtered.where((n) => n.tags.contains(selectedTag)).toList();
    }
    
    if (selectedIcon != null) {
      filtered = filtered.where((n) => n.icon?.toString().split('.').last == selectedIcon).toList();
    }
    
    if (selectedSize != null) {
      filtered = filtered.where((n) => n.size?.toString().split('.').last == selectedSize).toList();
    }
    
    if (selectedIntensity != null) {
      filtered = filtered.where((n) => n.colorIntensity?.toString().split('.').last == selectedIntensity).toList();
    }
    
    filtered.sort((a, b) {
      int comparison;
      switch (sortBy) {
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'created_at':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'updated_at':
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
        default:
          comparison = a.updatedAt.compareTo(b.updatedAt);
      }
      return sortAscending ? comparison : -comparison;
    });
    
    return filtered;
  }
}

// ============================================
// PROVIDER
// ============================================

final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  return NotesNotifier(ref);
});

// ============================================
// NOTIFIER
// ============================================

class NotesNotifier extends StateNotifier<NotesState> {
  final Ref _ref;
  final NoteService _noteService = NoteService();

  NotesNotifier(this._ref) : super(const NotesState()) {
    _init();
  }

  // ============================================
  // INICIALIZACIÓN
  // ============================================

  Future<void> _init() async {
    await loadNotes();
  }

  // ============================================
  // NOTIFICAR CAMBIOS AL AUTO-BACKUP
  // ============================================

  void _notifyAutoBackup() {
    final autoBackupNotifier = _ref.read(autoBackupStateProvider.notifier);
    autoBackupNotifier.notifyNotesChanged(state.activeNotes);
    _NotesProviderLogger.info('📢 Notificando cambios al auto-backup (${state.activeNotes.length} notas)');
  }

  // ============================================
  // CARGA DE NOTAS
  // ============================================

  Future<void> loadNotes() async {
    _NotesProviderLogger.info('🔄 Cargando notas...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final notes = await _noteService.getNotes(deleted: false);
      final archivedNotes = notes.where((n) => n.isArchived && n.deletedAt == null).toList();
      final deletedNotes = await _noteService.getDeletedNotes();

      state = state.copyWith(
        notes: notes,
        archivedNotes: archivedNotes,
        deletedNotes: deletedNotes,
        isLoading: false,
        error: null,
      );
      
      _NotesProviderLogger.success('✅ Notas cargadas: ${notes.length} totales');
      _NotesProviderLogger.info('   - Activas: ${state.activeNotes.length}');
      _NotesProviderLogger.info('   - Archivadas: ${archivedNotes.length}');
      _NotesProviderLogger.info('   - Eliminadas: ${deletedNotes.length}');

      final autoBackupNotifier = _ref.read(autoBackupStateProvider.notifier);
      autoBackupNotifier.setInitialNotes(state.activeNotes);
      
    } catch (e) {
      _NotesProviderLogger.error('❌ Error cargando notas: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ============================================
  // CRUD OPERACIONES
  // ============================================

  Future<Note?> createNote(NoteCreate noteData) async {
    _NotesProviderLogger.info('📝 Creando nueva nota: ${noteData.title}');
    
    try {
      final newNote = await _noteService.createNote(noteData);
      
      if (newNote != null) {
        final updatedNotes = [newNote, ...state.notes];
        state = state.copyWith(notes: updatedNotes);
        _NotesProviderLogger.success('✅ Nota creada: ${newNote.id}');
        _notifyAutoBackup();
        return newNote;
      }
      return null;
    } catch (e) {
      _NotesProviderLogger.error('❌ Error creando nota: $e');
      return null;
    }
  }

  Future<Note?> updateNote(String id, NoteUpdate updates) async {
    _NotesProviderLogger.info('✏️ Actualizando nota: $id');
    
    try {
      final updatedNote = await _noteService.updateNote(id, updates);
      
      if (updatedNote != null) {
        final updatedNotes = state.notes.map((n) => n.id == id ? updatedNote : n).toList();
        final updatedArchived = state.archivedNotes.map((n) => n.id == id ? updatedNote : n).toList();
        final updatedDeleted = state.deletedNotes.map((n) => n.id == id ? updatedNote : n).toList();
        
        state = state.copyWith(
          notes: updatedNotes,
          archivedNotes: updatedArchived,
          deletedNotes: updatedDeleted,
        );
        
        _NotesProviderLogger.success('✅ Nota actualizada: $id');
        _notifyAutoBackup();
        return updatedNote;
      }
      return null;
    } catch (e) {
      _NotesProviderLogger.error('❌ Error actualizando nota: $e');
      return null;
    }
  }

  /// Reemplazar todas las notas y notificar cambios
  Future<void> replaceAllNotes(List<Note> newNotes) async {
    _NotesProviderLogger.info('🔄 Reemplazando todas las notas (${newNotes.length} notas)');
    
    // Clasificar las notas
    final archivedNotes = newNotes.where((n) => n.isArchived && n.deletedAt == null).toList();
    final deletedNotes = newNotes.where((n) => n.deletedAt != null).toList();
    final activeNotes = newNotes.where((n) => !n.isArchived && n.deletedAt == null).toList();
    
    // Actualizar el estado local inmediatamente
    state = state.copyWith(
      notes: newNotes,
      archivedNotes: archivedNotes,
      deletedNotes: deletedNotes,
      isLoading: false,
    );
    
    _NotesProviderLogger.success('✅ Notas reemplazadas: ${activeNotes.length} activas, ${archivedNotes.length} archivadas, ${deletedNotes.length} eliminadas');
    
    // Notificar al auto-backup
    _notifyAutoBackup();
  }

  // ============================================
  // RESTAURACIÓN DESDE BACKUP - NUEVO MÉTODO
  // ============================================

  /// Restaurar notas desde un backup, eliminando las actuales del backend
  /// y creando las nuevas notas con IDs frescos
  Future<void> restoreFromBackup(List<Note> backupNotes) async {
    _NotesProviderLogger.info('🔄 Restaurando ${backupNotes.length} notas desde backup...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Obtener notas actuales para eliminar del backend
      final currentNotes = await _noteService.getNotes(deleted: false);
      _NotesProviderLogger.info('🗑️ Eliminando ${currentNotes.length} notas actuales del backend...');
      
      // 2. Eliminar todas las notas actuales del backend
      for (final note in currentNotes) {
        final success = await _noteService.deleteNote(note.id, permanent: true);
        if (!success) {
          _NotesProviderLogger.warning('⚠️ No se pudo eliminar nota: ${note.id}');
        }
      }
      
      // 3. Crear las nuevas notas en el backend (sin IDs, que el backend los genere)
      _NotesProviderLogger.info('📝 Creando ${backupNotes.length} nuevas notas en backend...');
      final createdNotes = <Note>[];
      
      for (int i = 0; i < backupNotes.length; i++) {
        final backupNote = backupNotes[i];
        
        // Crear NoteCreate sin ID (el backend generará uno nuevo)
        final noteCreate = NoteCreate(
          title: backupNote.title,
          content: backupNote.content,
          color: backupNote.color,
          shape: backupNote.shape,
          icon: backupNote.icon,
          size: backupNote.size,
          colorIntensity: backupNote.colorIntensity,
          isFavorite: backupNote.isFavorite,
          isArchived: backupNote.isArchived,
          tags: backupNote.tags,
        );
        
        final createdNote = await _noteService.createNote(noteCreate);
        if (createdNote != null) {
          createdNotes.add(createdNote);
          if ((i + 1) % 10 == 0 || i == backupNotes.length - 1) {
            _NotesProviderLogger.info('   Progreso: ${i + 1}/${backupNotes.length}');
          }
        } else {
          _NotesProviderLogger.error('❌ Error creando nota: ${backupNote.title}');
        }
      }
      
      _NotesProviderLogger.success('✅ ${createdNotes.length} notas creadas en backend');
      
      // 4. Actualizar estado local
      final archivedNotes = createdNotes.where((n) => n.isArchived && n.deletedAt == null).toList();
      final deletedNotes = createdNotes.where((n) => n.deletedAt != null).toList();
      
      state = state.copyWith(
        notes: createdNotes,
        archivedNotes: archivedNotes,
        deletedNotes: deletedNotes,
        isLoading: false,
      );
      
      _NotesProviderLogger.success('✅ Restauración completada: ${createdNotes.length} notas');
      
      // 5. Notificar al auto-backup
      _notifyAutoBackup();
      
    } catch (e) {
      _NotesProviderLogger.error('❌ Error en restauración: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // ============================================
  // ELIMINACIÓN Y PAPELERA
  // ============================================

  /// Soft delete - Mover nota a la papelera
  Future<bool> deleteNote(String id) async {
    _NotesProviderLogger.info('🗑️ Moviendo nota a papelera: $id');
    
    try {
      final success = await _noteService.deleteNote(id);
      if (success) {
        await loadNotes();
        _NotesProviderLogger.success('✅ Nota movida a papelera: $id');
        _notifyAutoBackup();
      }
      return success;
    } catch (e) {
      _NotesProviderLogger.error('❌ Error moviendo nota a papelera: $e');
      return false;
    }
  }

  /// Eliminación permanente - Borrar nota de la papelera
  Future<bool> permanentlyDeleteNote(String id) async {
    _NotesProviderLogger.info('🗑️ Eliminando nota permanentemente: $id');
    
    try {
      final success = await _noteService.deleteNote(id, permanent: true);
      if (success) {
        final updatedDeletedNotes = List<Note>.from(state.deletedNotes)
          ..removeWhere((n) => n.id == id);
        
        state = state.copyWith(deletedNotes: updatedDeletedNotes);
        _NotesProviderLogger.success('✅ Nota eliminada permanentemente: $id');
        _notifyAutoBackup();
      }
      return success;
    } catch (e) {
      _NotesProviderLogger.error('❌ Error eliminando nota permanentemente: $e');
      return false;
    }
  }

  /// Vaciar toda la papelera
  Future<bool> emptyTrash() async {
    _NotesProviderLogger.info('🗑️🗑️ Vaciando papelera completa...');
    
    try {
      int successCount = 0;
      final notesToDelete = List<Note>.from(state.deletedNotes);
      
      for (final note in notesToDelete) {
        final success = await _noteService.deleteNote(note.id, permanent: true);
        if (success) successCount++;
      }
      
      state = state.copyWith(deletedNotes: []);
      
      _NotesProviderLogger.success('✅ Papelera vaciada: $successCount notas eliminadas permanentemente');
      _notifyAutoBackup();
      return true;
    } catch (e) {
      _NotesProviderLogger.error('❌ Error vaciando papelera: $e');
      return false;
    }
  }

  /// Restaurar nota desde la papelera
  Future<Note?> restoreNote(String id) async {
    _NotesProviderLogger.info('🔄 Restaurando nota: $id');
    
    try {
      final restoredNote = await _noteService.restoreNote(id);
      
      if (restoredNote != null) {
        await loadNotes();
        _NotesProviderLogger.success('✅ Nota restaurada: $id');
        _notifyAutoBackup();
        return restoredNote;
      }
      return null;
    } catch (e) {
      _NotesProviderLogger.error('❌ Error restaurando nota: $e');
      return null;
    }
  }

  Future<Note?> toggleFavorite(String id) async {
    _NotesProviderLogger.info('⭐ Toggle favorito: $id');
    final note = await _noteService.toggleFavorite(id);
    if (note != null) {
      await loadNotes();
      _notifyAutoBackup();
    }
    return note;
  }

  Future<Note?> toggleArchive(String id) async {
    _NotesProviderLogger.info('📦 Toggle archivo: $id');
    final note = await _noteService.toggleArchive(id);
    if (note != null) {
      await loadNotes();
      _notifyAutoBackup();
    }
    return note;
  }

  // ============================================
  // OPERACIONES MASIVAS
  // ============================================

  Future<int> deleteMultipleNotes(Set<String> ids) async {
    _NotesProviderLogger.info('🗑️ Moviendo ${ids.length} notas a papelera');
    
    int successCount = 0;
    for (final id in ids) {
      final success = await deleteNote(id);
      if (success) successCount++;
    }
    
    _NotesProviderLogger.success('✅ $successCount notas movidas a papelera');
    return successCount;
  }

  Future<int> permanentlyDeleteMultipleNotes(Set<String> ids) async {
    _NotesProviderLogger.info('🗑️ Eliminando permanentemente ${ids.length} notas');
    
    int successCount = 0;
    for (final id in ids) {
      final success = await permanentlyDeleteNote(id);
      if (success) successCount++;
    }
    
    _NotesProviderLogger.success('✅ $successCount notas eliminadas permanentemente');
    return successCount;
  }

  Future<int> restoreMultipleNotes(Set<String> ids) async {
    _NotesProviderLogger.info('🔄 Restaurando ${ids.length} notas');
    
    int successCount = 0;
    for (final id in ids) {
      final restored = await restoreNote(id);
      if (restored != null) successCount++;
    }
    
    _NotesProviderLogger.success('✅ $successCount notas restauradas');
    return successCount;
  }

  // ============================================
  // FILTROS Y ORDENACIÓN
  // ============================================

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedTag(String? tag) {
    state = state.copyWith(selectedTag: tag);
  }

  void setSelectedIcon(String? icon) {
    state = state.copyWith(selectedIcon: icon);
  }

  void setSelectedSize(String? size) {
    state = state.copyWith(selectedSize: size);
  }

  void setSelectedIntensity(String? intensity) {
    state = state.copyWith(selectedIntensity: intensity);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void toggleSortOrder() {
    state = state.copyWith(sortAscending: !state.sortAscending);
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: null,
      selectedTag: null,
      selectedIcon: null,
      selectedSize: null,
      selectedIntensity: null,
    );
  }

  // ============================================
  // SELECCIÓN DE NOTAS
  // ============================================

  void toggleNoteSelection(String id) {
    final newSelection = Set<String>.from(state.selectedNoteIds);
    if (newSelection.contains(id)) {
      newSelection.remove(id);
    } else {
      newSelection.add(id);
    }
    state = state.copyWith(selectedNoteIds: newSelection);
  }

  void selectAllNotes() {
    final allIds = state.activeNotes.map((n) => n.id).toSet();
    state = state.copyWith(selectedNoteIds: allIds);
  }

  void clearSelection() {
    state = state.copyWith(selectedNoteIds: {});
  }

  void selectFavorites() {
    final favoriteIds = state.favoriteNotes.map((n) => n.id).toSet();
    state = state.copyWith(selectedNoteIds: favoriteIds);
  }

  // ============================================
  // UTILIDADES
  // ============================================

  Note? getNoteById(String id) {
    final note = state.notes.firstWhere(
      (n) => n.id == id,
      orElse: () => state.archivedNotes.firstWhere(
        (n) => n.id == id,
        orElse: () => state.deletedNotes.firstWhere(
          (n) => n.id == id,
          orElse: () => Note(
            id: '',
            title: '',
            content: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ),
    );
    return note.id.isNotEmpty ? note : null;
  }

  List<Note> getNotesByTag(String tag) {
    return state.activeNotes.where((n) => n.tags.contains(tag)).toList();
  }

  List<String> getAllTags() {
    final tags = <String>{};
    for (final note in state.activeNotes) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }
}

// ============================================
// PROVIDERS DERIVADOS
// ============================================

final activeNotesProvider = Provider<List<Note>>((ref) {
  return ref.watch(notesProvider).activeNotes;
});

final filteredNotesProvider = Provider<List<Note>>((ref) {
  return ref.watch(notesProvider).filteredNotes;
});

final favoriteNotesProvider = Provider<List<Note>>((ref) {
  return ref.watch(notesProvider).favoriteNotes;
});

final archivedNotesProvider = Provider<List<Note>>((ref) {
  return ref.watch(notesProvider).archivedNotes;
});

final deletedNotesProvider = Provider<List<Note>>((ref) {
  return ref.watch(notesProvider).deletedNotes;
});

final noteByIdProvider = Provider.family<Note?, String>((ref, id) {
  return ref.watch(notesProvider.notifier).getNoteById(id);
});

final notesCountProvider = Provider<int>((ref) {
  return ref.watch(notesProvider).activeNotes.length;
});

final isLoadingNotesProvider = Provider<bool>((ref) {
  return ref.watch(notesProvider).isLoading;
});

final selectedNoteIdsProvider = Provider<Set<String>>((ref) {
  return ref.watch(notesProvider).selectedNoteIds;
});

final hasSelectedNotesProvider = Provider<bool>((ref) {
  return ref.watch(notesProvider).selectedNoteIds.isNotEmpty;
});

final selectedNotesCountProvider = Provider<int>((ref) {
  return ref.watch(notesProvider).selectedNoteIds.length;
});

final allTagsProvider = Provider<List<String>>((ref) {
  return ref.watch(notesProvider.notifier).getAllTags();
});