// lib/core/utils/restore_utils.dart
// Utilidades para modos de restauración de backups

import 'package:flutter/material.dart';
import 'package:quicknote/models/note.dart';

/// Modos de restauración disponibles
enum RestoreMode {
  replace,    // Reemplazar todas las notas actuales
  merge,      // Fusionar (conservar ambas, eliminar duplicados por ID)
  addOnly,    // Solo agregar nuevas notas (las que no existen localmente)
}

extension RestoreModeExtension on RestoreMode {
  String get displayName {
    switch (this) {
      case RestoreMode.replace:
        return 'Reemplazar todo';
      case RestoreMode.merge:
        return 'Fusionar';
      case RestoreMode.addOnly:
        return 'Solo agregar nuevas';
    }
  }

  String get description {
    switch (this) {
      case RestoreMode.replace:
        return 'Las notas actuales serán eliminadas y reemplazadas por las del backup.';
      case RestoreMode.merge:
        return 'Las notas se combinarán. Las notas con el mismo ID se actualizarán.';
      case RestoreMode.addOnly:
        return 'Solo se agregarán notas nuevas que no existan actualmente.';
    }
  }

  IconData get icon {
    switch (this) {
      case RestoreMode.replace:
        return Icons.delete_sweep;
      case RestoreMode.merge:
        return Icons.merge_type;
      case RestoreMode.addOnly:
        return Icons.add_circle_outline;
    }
  }

  Color get color {
    switch (this) {
      case RestoreMode.replace:
        return Colors.red;
      case RestoreMode.merge:
        return Colors.blue;
      case RestoreMode.addOnly:
        return Colors.green;
    }
  }
}

class RestoreUtils {
  // ============================================
  // APLICAR MODO DE RESTAURACIÓN
  // ============================================
  
  /// Aplica el modo de restauración seleccionado
  static List<Note> applyRestoreMode({
    required List<Note> currentNotes,
    required List<Note> backupNotes,
    required RestoreMode mode,
  }) {
    switch (mode) {
      case RestoreMode.replace:
        return _replaceNotes(backupNotes);
      case RestoreMode.merge:
        return _mergeNotes(currentNotes, backupNotes);
      case RestoreMode.addOnly:
        return _addOnlyNewNotes(currentNotes, backupNotes);
    }
  }

  /// Reemplazar todas las notas actuales
  static List<Note> _replaceNotes(List<Note> backupNotes) {
    return List.from(backupNotes);
  }

  /// Fusionar: conservar ambas, actualizar por ID
  static List<Note> _mergeNotes(List<Note> currentNotes, List<Note> backupNotes) {
    final Map<String, Note> notesMap = {};
    
    // Agregar todas las notas actuales
    for (final note in currentNotes) {
      notesMap[note.id] = note;
    }
    
    // Actualizar/Agregar notas del backup
    for (final note in backupNotes) {
      notesMap[note.id] = note;
    }
    
    return notesMap.values.toList();
  }

  /// Solo agregar notas nuevas (las que no existen en local)
  static List<Note> _addOnlyNewNotes(List<Note> currentNotes, List<Note> backupNotes) {
    final Set<String> existingIds = currentNotes.map((n) => n.id).toSet();
    final List<Note> result = List.from(currentNotes);
    
    for (final note in backupNotes) {
      if (!existingIds.contains(note.id)) {
        result.add(note);
      }
    }
    
    return result;
  }

  // ============================================
  // ESTADÍSTICAS DE RESTAURACIÓN
  // ============================================
  
  /// Obtener estadísticas de la restauración
  static RestoreStats getRestoreStats({
    required List<Note> currentNotes,
    required List<Note> backupNotes,
    required RestoreMode mode,
  }) {
    switch (mode) {
      case RestoreMode.replace:
        return RestoreStats(
          notesToAdd: backupNotes.length,
          notesToRemove: currentNotes.length,
          notesToUpdate: 0,
          totalAfterRestore: backupNotes.length,
        );
      case RestoreMode.merge:
        final existingIds = currentNotes.map((n) => n.id).toSet();
        final newNotes = backupNotes.where((n) => !existingIds.contains(n.id)).toList();
        final notesToUpdate = backupNotes.where((n) => existingIds.contains(n.id)).toList();
        
        return RestoreStats(
          notesToAdd: newNotes.length,
          notesToRemove: 0,
          notesToUpdate: notesToUpdate.length,
          totalAfterRestore: currentNotes.length + newNotes.length,
        );
      case RestoreMode.addOnly:
        final existingIds = currentNotes.map((n) => n.id).toSet();
        final newNotes = backupNotes.where((n) => !existingIds.contains(n.id)).toList();
        
        return RestoreStats(
          notesToAdd: newNotes.length,
          notesToRemove: 0,
          notesToUpdate: 0,
          totalAfterRestore: currentNotes.length + newNotes.length,
        );
    }
  }

  // ============================================
  // VALIDACIÓN DE RESTAURACIÓN
  // ============================================
  
  /// Verificar si la restauración es válida
  static bool isValidRestore(List<Note> backupNotes) {
    return backupNotes.isNotEmpty;
  }

  /// Obtener advertencias según el modo
  static String? getWarningMessage(RestoreMode mode, RestoreStats stats) {
    switch (mode) {
      case RestoreMode.replace:
        if (stats.notesToRemove > 0) {
          return '⚠️ Se eliminarán ${stats.notesToRemove} notas actuales. Esta acción no se puede deshacer.';
        }
        return null;
      case RestoreMode.merge:
        if (stats.notesToUpdate > 0) {
          return 'ℹ️ ${stats.notesToUpdate} notas existentes serán actualizadas con la información del backup.';
        }
        return null;
      case RestoreMode.addOnly:
        if (stats.notesToAdd == 0) {
          return 'ℹ️ No se encontraron notas nuevas para agregar.';
        }
        return null;
    }
  }

  /// Obtener texto de confirmación según el modo
  static String getConfirmationMessage(RestoreMode mode, RestoreStats stats) {
    switch (mode) {
      case RestoreMode.replace:
        return '¿Estás seguro de que quieres reemplazar TODAS tus notas actuales?\n\nSe eliminarán ${stats.notesToRemove} notas y se agregarán ${stats.notesToAdd} notas del backup.';
      case RestoreMode.merge:
        return '¿Estás seguro de que quieres fusionar las notas?\n\nSe agregarán ${stats.notesToAdd} notas nuevas y se actualizarán ${stats.notesToUpdate} notas existentes.';
      case RestoreMode.addOnly:
        return '¿Estás seguro de que quieres agregar solo las notas nuevas?\n\nSe agregarán ${stats.notesToAdd} notas nuevas.';
    }
  }
}

// ============================================
// MODELO DE ESTADÍSTICAS
// ============================================

class RestoreStats {
  final int notesToAdd;
  final int notesToRemove;
  final int notesToUpdate;
  final int totalAfterRestore;

  const RestoreStats({
    required this.notesToAdd,
    required this.notesToRemove,
    required this.notesToUpdate,
    required this.totalAfterRestore,
  });

  bool get hasChanges => notesToAdd > 0 || notesToRemove > 0 || notesToUpdate > 0;
  bool get isDestructive => notesToRemove > 0;
}