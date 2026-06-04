// lib/providers/auto_backup_provider.dart
// Provider para Auto-Backup con Riverpod
// ✅ Expone el estado del auto-backup a la UI
// ✅ Permite activar/desactivar desde la UI
// ✅ Permite forzar backup manual
// ✅ CORREGIDO: Importaciones faltantes
// ✅ CORREGIDO: Uso de log en lugar de print

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicknote/core/services/auto_backup_service.dart';
import 'package:quicknote/models/note.dart';

// ============================================
// LOGGER
// ============================================

class _AutoBackupProviderLogger {
  static void info(String message) => log('ℹ️ [AutoBackupProvider] $message');
  static void success(String message) => log('✅ [AutoBackupProvider] $message');
  static void error(String message) => log('❌ [AutoBackupProvider] $message');
}

// ============================================
// PROVIDER DEL SERVICIO (SINGLETON)
// ============================================

final autoBackupServiceProvider = Provider<AutoBackupService>((ref) {
  final service = AutoBackupService();
  // Inicializar el servicio
  WidgetsBinding.instance.addPostFrameCallback((_) {
    service.init();
  });
  return service;
});

// ============================================
// STATE PROVIDER PARA EL ESTADO DEL AUTO-BACKUP
// ============================================

final autoBackupStateProvider = StateNotifierProvider<AutoBackupNotifier, AutoBackupState>((ref) {
  final service = ref.watch(autoBackupServiceProvider);
  return AutoBackupNotifier(service);
});

// ============================================
// NOTIFIER
// ============================================

class AutoBackupNotifier extends StateNotifier<AutoBackupState> {
  final AutoBackupService _service;

  AutoBackupNotifier(this._service) : super(const AutoBackupState()) {
    _subscribeToService();
  }

  void _subscribeToService() {
    // Escuchar cambios en el servicio
    _service.addListener((newState) {
      if (mounted) {
        state = newState;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ============================================
  // ACCIONES PÚBLICAS
  // ============================================

  /// Activar o desactivar auto-backup
  Future<void> toggleEnabled(bool enabled) async {
    _AutoBackupProviderLogger.info('Toggle enabled: $enabled');
    await _service.setEnabled(enabled);
  }

  /// Forzar backup manual
  Future<bool> forceBackup(List<Note> notes) async {
    _AutoBackupProviderLogger.info('Forzando backup manual...');
    return await _service.forceBackup(notes);
  }

  /// Establecer notas iniciales (para detectar cambios)
  void setInitialNotes(List<Note> notes) {
    _service.setInitialNotes(notes);
  }

  /// Notificar cambios en notas (desde NotesProvider)
  void notifyNotesChanged(List<Note> notes) {
    _service.notifyNotesChanged(notes);
  }

  /// Obtener estado actual
  AutoBackupState get currentState => state;
}

// ============================================
// PROVIDERS DERIVADOS (PARA ACCESO RÁPIDO)
// ============================================

/// Estado actual del auto-backup
final autoBackupStatusProvider = Provider<AutoBackupStatus>((ref) {
  return ref.watch(autoBackupStateProvider).status;
});

/// Si hay cambios pendientes
final autoBackupPendingChangesProvider = Provider<bool>((ref) {
  return ref.watch(autoBackupStateProvider).hasPendingChanges;
});

/// Cantidad de cambios pendientes
final autoBackupPendingCountProvider = Provider<int>((ref) {
  return ref.watch(autoBackupStateProvider).pendingChangesCount;
});

/// Si está realizando backup
final autoBackupIsBackingUpProvider = Provider<bool>((ref) {
  return ref.watch(autoBackupStateProvider).isBackingUp;
});

/// Última hora de backup
final autoBackupLastTimeProvider = Provider<DateTime?>((ref) {
  return ref.watch(autoBackupStateProvider).lastBackupTime;
});

/// Si el auto-backup está habilitado
final autoBackupEnabledProvider = Provider<bool>((ref) {
  return ref.watch(autoBackupStateProvider).isEnabled;
});

/// Texto amigable del estado
final autoBackupStatusTextProvider = Provider<String>((ref) {
  final state = ref.watch(autoBackupStateProvider);
  
  if (!state.isEnabled) return 'Desactivado';
  if (state.isBackingUp) return 'Guardando...';
  if (state.hasPendingChanges) return 'Cambios pendientes';
  if (state.status == AutoBackupStatus.success) return 'Último backup exitoso';
  if (state.status == AutoBackupStatus.error) return 'Error en backup';
  return 'Activo';
});

/// Color del estado (usando valores predeterminados)
final autoBackupStatusColorProvider = Provider<Color>((ref) {
  final state = ref.watch(autoBackupStateProvider);
  
  if (!state.isEnabled) return Colors.grey;
  if (state.isBackingUp) return Colors.blue;
  if (state.hasPendingChanges) return Colors.amber;
  if (state.status == AutoBackupStatus.success) return Colors.green;
  if (state.status == AutoBackupStatus.error) return Colors.red;
  return Colors.green;
});

/// Icono del estado (usando valores predeterminados)
final autoBackupStatusIconProvider = Provider<IconData>((ref) {
  final state = ref.watch(autoBackupStateProvider);
  
  if (!state.isEnabled) return Icons.power_off;
  if (state.isBackingUp) return Icons.sync;
  if (state.hasPendingChanges) return Icons.cloud_upload;
  if (state.status == AutoBackupStatus.success) return Icons.cloud_done;
  if (state.status == AutoBackupStatus.error) return Icons.error_outline;
  return Icons.cloud_queue;
});