// lib/core/services/auto_backup_service.dart
// Servicio de Auto-Backup con detección de cambios
// ✅ Detecta cambios en las notas mediante hash
// ✅ Debounce de 30 segundos después del último cambio
// ✅ Backup automático en segundo plano
// ✅ Notificaciones de estado
// ✅ CORREGIDO: Importación de SharedPreferences
// ✅ CORREGIDO: Campo no utilizado eliminado

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote/models/note.dart';
import 'package:quicknote/core/services/backup_service.dart';

// ============================================
// LOGGER
// ============================================

class _AutoBackupLogger {
  static void info(String message) => log('ℹ️ [AutoBackup] $message');
  static void success(String message) => log('✅ [AutoBackup] $message');
  static void error(String message) => log('❌ [AutoBackup] $message');
  static void warn(String message) => log('⚠️ [AutoBackup] $message');
}

// ============================================
// ESTADO DEL AUTO-BACKUP
// ============================================

enum AutoBackupStatus {
  idle,           // Sin actividad
  pending,        // Cambios pendientes (esperando debounce)
  backingUp,      // Realizando backup
  success,        // Backup completado
  error,          // Error en backup
}

class AutoBackupState {
  final AutoBackupStatus status;
  final DateTime? lastBackupTime;
  final int pendingChangesCount;
  final String? lastError;
  final bool isEnabled;

  const AutoBackupState({
    this.status = AutoBackupStatus.idle,
    this.lastBackupTime,
    this.pendingChangesCount = 0,
    this.lastError,
    this.isEnabled = true,
  });

  AutoBackupState copyWith({
    AutoBackupStatus? status,
    DateTime? lastBackupTime,
    int? pendingChangesCount,
    String? lastError,
    bool? isEnabled,
  }) {
    return AutoBackupState(
      status: status ?? this.status,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      pendingChangesCount: pendingChangesCount ?? this.pendingChangesCount,
      lastError: lastError ?? this.lastError,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  bool get hasPendingChanges => pendingChangesCount > 0;
  bool get isBackingUp => status == AutoBackupStatus.backingUp;
  bool get isIdle => status == AutoBackupStatus.idle;
}

// ============================================
// CONFIGURACIÓN
// ============================================

class AutoBackupConfig {
  final int debounceDelayMs;      // Tiempo de espera después del último cambio
  final int minNotesToBackup;     // Mínimo de notas para hacer backup
  final bool enabledByDefault;    // Habilitado por defecto
  final bool syncToCloud;         // Sincronizar con la nube automáticamente

  const AutoBackupConfig({
    this.debounceDelayMs = 30000,    // 30 segundos
    this.minNotesToBackup = 1,       // Mínimo 1 nota
    this.enabledByDefault = true,
    this.syncToCloud = true,         // Subir a la nube automáticamente
  });
}

// ============================================
// SERVICIO PRINCIPAL
// ============================================

class AutoBackupService {
  static final AutoBackupService _instance = AutoBackupService._internal();
  factory AutoBackupService() => _instance;
  AutoBackupService._internal();

  // Dependencias
  final BackupService _backupService = BackupService();

  // Estado interno
  AutoBackupState _state = const AutoBackupState();
  Timer? _debounceTimer;
  String _lastNotesHash = '';
  List<Note> _lastNotes = [];
  bool _isInitialized = false;
  AutoBackupConfig _config = const AutoBackupConfig();

  // Listeners para notificar cambios
  final List<void Function(AutoBackupState)> _listeners = [];

  // Getters públicos
  AutoBackupState get state => _state;
  bool get isEnabled => _state.isEnabled;

  // ============================================
  // INICIALIZACIÓN
  // ============================================

  Future<void> init({AutoBackupConfig? config}) async {
    if (_isInitialized) return;

    _config = config ?? const AutoBackupConfig();
    await _backupService.init();
    await _loadSavedState();

    _isInitialized = true;
    _AutoBackupLogger.success('Auto-Backup inicializado (debounce: ${_config.debounceDelayMs}ms)');
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('auto_backup_enabled') ?? _config.enabledByDefault;
      final lastBackupStr = prefs.getString('auto_backup_last_time');
      final lastBackup = lastBackupStr != null ? DateTime.parse(lastBackupStr) : null;

      _state = _state.copyWith(
        isEnabled: enabled,
        lastBackupTime: lastBackup,
      );

      _AutoBackupLogger.info('Estado cargado: enabled=$enabled, lastBackup=$lastBackup');
    } catch (e) {
      _AutoBackupLogger.warn('Error cargando estado: $e');
    }
  }

  Future<void> _saveEnabledState(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_backup_enabled', enabled);
    } catch (e) {
      _AutoBackupLogger.warn('Error guardando estado: $e');
    }
  }

  Future<void> _saveLastBackupTime(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auto_backup_last_time', time.toIso8601String());
    } catch (e) {
      _AutoBackupLogger.warn('Error guardando lastBackupTime: $e');
    }
  }

  // ============================================
  // DETECCIÓN DE CAMBIOS
  // ============================================

  /// Calcula un hash único de las notas para detectar cambios
  String _calculateNotesHash(List<Note> notes) {
    // Simplificamos la información para el hash
    final simplified = notes.map((n) => {
      'id': n.id,
      'updated_at': n.updatedAt.toIso8601String(),
      'title': n.title,
      'content_length': n.content.length,
      'is_favorite': n.isFavorite,
      'is_archived': n.isArchived,
      'tags_count': n.tags.length,
    }).toList();
    
    return jsonEncode(simplified);
  }

  /// Verifica si las notas han cambiado
  bool _hasNotesChanged(List<Note> currentNotes) {
    if (currentNotes.isEmpty) return false;
    
    final currentHash = _calculateNotesHash(currentNotes);
    final hasChanged = currentHash != _lastNotesHash;
    
    if (hasChanged) {
      final notesAdded = currentNotes.length - _lastNotes.length;
      _AutoBackupLogger.info('📝 Cambios detectados: +$notesAdded notas, total: ${currentNotes.length}');
    }
    
    return hasChanged;
  }

  // ============================================
  // MÉTODOS PRINCIPALES
  // ============================================

  /// Notificar cambios en las notas (debe llamarse desde NotesProvider)
  void notifyNotesChanged(List<Note> currentNotes) {
    if (!_state.isEnabled) {
      _AutoBackupLogger.info('⏸️ Auto-Backup deshabilitado, ignorando cambios');
      return;
    }

    if (currentNotes.length < _config.minNotesToBackup) {
      _AutoBackupLogger.info('⏸️ Auto-Backup omitido: solo ${currentNotes.length} notas (mínimo ${_config.minNotesToBackup})');
      return;
    }

    final hasChanged = _hasNotesChanged(currentNotes);
    
    if (hasChanged) {
      _scheduleBackup(currentNotes);
    }
  }

  /// Programa un backup después del debounce
  void _scheduleBackup(List<Note> notes) {
    // Cancelar timer anterior
    _debounceTimer?.cancel();
    
    // Actualizar estado
    _updateState(_state.copyWith(
      status: AutoBackupStatus.pending,
      pendingChangesCount: notes.length - _lastNotes.length,
    ));
    
    _AutoBackupLogger.info('⏳ Programando backup en ${_config.debounceDelayMs ~/ 1000} segundos...');
    
    // Programar nuevo timer
    _debounceTimer = Timer(Duration(milliseconds: _config.debounceDelayMs), () {
      _performBackup(notes);
    });
  }

  /// Ejecuta el backup
  Future<void> _performBackup(List<Note> notes, {bool isManual = false}) async {
    if (!_state.isEnabled && !isManual) {
      _AutoBackupLogger.info('⏸️ Auto-Backup deshabilitado');
      return;
    }

    if (_state.isBackingUp) {
      _AutoBackupLogger.info('⏸️ Backup ya en progreso');
      return;
    }

    _updateState(_state.copyWith(
      status: AutoBackupStatus.backingUp,
      lastError: null,
    ));
    
    _AutoBackupLogger.info('🔄 Iniciando backup automático...');

    try {
      // Crear backup (syncToCloud = _config.syncToCloud)
      final result = await _backupService.createBackup(notes, syncToCloud: _config.syncToCloud);
      
      if (result != null) {
        final now = DateTime.now();
        _lastNotesHash = _calculateNotesHash(notes);
        _lastNotes = List.from(notes);
        
        await _saveLastBackupTime(now);
        
        _updateState(_state.copyWith(
          status: AutoBackupStatus.success,
          lastBackupTime: now,
          pendingChangesCount: 0,
        ));
        
        _AutoBackupLogger.success('✅ Backup automático completado: ${result['note_count']} notas');
        
        // Resetear estado después de 3 segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (_state.status == AutoBackupStatus.success) {
            _updateState(_state.copyWith(status: AutoBackupStatus.idle));
          }
        });
      } else {
        throw Exception('Error al crear backup');
      }
    } catch (e) {
      _AutoBackupLogger.error('❌ Error en backup automático: $e');
      _updateState(_state.copyWith(
        status: AutoBackupStatus.error,
        lastError: e.toString(),
      ));
      
      // Resetear después de 5 segundos
      Future.delayed(const Duration(seconds: 5), () {
        if (_state.status == AutoBackupStatus.error) {
          _updateState(_state.copyWith(status: AutoBackupStatus.idle));
        }
      });
    }
  }

  /// Forzar backup manualmente
  Future<bool> forceBackup(List<Note> notes) async {
    if (notes.isEmpty) {
      _AutoBackupLogger.warn('No hay notas para respaldar');
      return false;
    }

    _AutoBackupLogger.info('🔧 Forzando backup manual...');
    await _performBackup(notes, isManual: true);
    return _state.status == AutoBackupStatus.success;
  }

  /// Habilitar/Deshabilitar auto-backup
  Future<void> setEnabled(bool enabled) async {
    _AutoBackupLogger.info('🔘 Auto-Backup ${enabled ? 'activado' : 'desactivado'}');
    
    _updateState(_state.copyWith(isEnabled: enabled));
    await _saveEnabledState(enabled);
    
    if (!enabled) {
      // Cancelar cualquier backup pendiente
      _debounceTimer?.cancel();
      _updateState(_state.copyWith(
        status: AutoBackupStatus.idle,
        pendingChangesCount: 0,
      ));
    }
  }

  /// Actualizar configuración inicial de notas
  void setInitialNotes(List<Note> notes) {
    if (notes.isNotEmpty) {
      _lastNotesHash = _calculateNotesHash(notes);
      _lastNotes = List.from(notes);
      _AutoBackupLogger.info('📋 Notas iniciales cargadas: ${notes.length} notas');
    }
  }

  /// Actualizar estado y notificar listeners
  void _updateState(AutoBackupState newState) {
    _state = newState;
    _notifyListeners();
  }

  // ============================================
  // LISTENERS
  // ============================================

  void addListener(void Function(AutoBackupState) listener) {
    _listeners.add(listener);
    // Notificar estado actual inmediatamente
    listener(_state);
  }

  void removeListener(void Function(AutoBackupState) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_state);
    }
  }

  // ============================================
  // LIMPIEZA
  // ============================================

  void dispose() {
    _debounceTimer?.cancel();
    _listeners.clear();
    _AutoBackupLogger.info('Auto-Backup service disposed');
  }
}