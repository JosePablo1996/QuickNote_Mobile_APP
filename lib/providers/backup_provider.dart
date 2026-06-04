// lib/providers/backup_provider.dart
// Provider para gestión de backups - VERSIÓN CORREGIDA CON FORZADO DE RECARGA

import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicknote/models/backup.dart';
import 'package:quicknote/models/note.dart';
import 'package:quicknote/core/services/backup_service.dart';
import 'package:quicknote/core/services/backup_cloud_service.dart';

// ============================================
// LOGGER
// ============================================

class _BackupProviderLogger {
  static void info(String message) => log('ℹ️ [BackupProvider] $message');
  static void success(String message) => log('✅ [BackupProvider] $message');
  static void error(String message) => log('❌ [BackupProvider] $message');
}

// ============================================
// ESTADO
// ============================================

class BackupState {
  final List<BackupMetadata> backups;
  final BackupLimitInfo? limitInfo;
  final bool isLoading;
  final String? error;

  const BackupState({
    this.backups = const [],
    this.limitInfo,
    this.isLoading = false,
    this.error,
  });

  BackupState copyWith({
    List<BackupMetadata>? backups,
    BackupLimitInfo? limitInfo,
    bool? isLoading,
    String? error,
  }) {
    return BackupState(
      backups: backups ?? this.backups,
      limitInfo: limitInfo ?? this.limitInfo,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ============================================
// PROVIDER
// ============================================

final backupProvider = StateNotifierProvider<BackupNotifier, BackupState>((ref) {
  return BackupNotifier();
});

// ============================================
// NOTIFIER
// ============================================

class BackupNotifier extends StateNotifier<BackupState> {
  late final BackupService _backupService;
  final BackupCloudService _cloudService = BackupCloudService();

  BackupNotifier() : super(const BackupState()) {
    _init();
  }

  Future<void> _init() async {
    _backupService = BackupService();
    await _backupService.init();
    await loadBackups();
  }

  // ============================================
  // CARGA DE BACKUPS - FORZADA
  // ============================================

  Future<void> loadBackups() async {
    _BackupProviderLogger.info('🔄 Cargando backups...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      // ✅ FORZAR RECARGA DEL SERVICIO (reinicializar)
      await _backupService.init();
      
      // 1. Obtener backups locales del servicio
      final localBackupsData = await _backupService.getBackups();
      _BackupProviderLogger.info('📦 Backups locales desde servicio: ${localBackupsData.length}');
      for (var b in localBackupsData) {
        _BackupProviderLogger.info('   - ${b.fileName} (source: ${b.source}, id: ${b.id})');
      }

      // 2. Obtener backups de la nube directamente
      final cloudBackupsRaw = await _cloudService.getCloudBackups();
      _BackupProviderLogger.info('☁️ Cloud backups desde API: ${cloudBackupsRaw.length}');
      
      // 3. Convertir los backups de nube a BackupMetadata
      final List<BackupMetadata> cloudBackupsData = [];
      for (var raw in cloudBackupsRaw) {
        final backup = BackupMetadata.fromCloudJson(raw);
        cloudBackupsData.add(backup);
        _BackupProviderLogger.info('   - ${backup.fileName} (source: ${backup.source}, id: ${backup.id})');
      }

      // 4. Fusionar locales y nube
      final allBackups = <BackupMetadata>[...localBackupsData];
      final existingCloudIds = localBackupsData
          .where((b) => b.cloudId != null)
          .map((b) => b.cloudId)
          .toSet();
      
      for (var cloudBackup in cloudBackupsData) {
        if (cloudBackup.cloudId != null && !existingCloudIds.contains(cloudBackup.cloudId)) {
          allBackups.add(cloudBackup);
        } else if (cloudBackup.cloudId == null) {
          allBackups.add(cloudBackup);
        }
      }

      // 5. Ordenar por fecha (más reciente primero)
      allBackups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 6. Calcular límite
      final totalSize = allBackups.fold<int>(0, (sum, b) => sum + b.fileSize);
      final limitInfo = BackupLimitInfo(
        current: allBackups.length,
        max: 20,
        remaining: 20 - allBackups.length,
        isFull: allBackups.length >= 20,
        isLow: allBackups.length >= 18,
        totalSize: totalSize,
      );

      state = state.copyWith(
        backups: allBackups,
        limitInfo: limitInfo,
        isLoading: false,
        error: null,
      );
      
      _BackupProviderLogger.success('✅ Backups cargados: ${allBackups.length} totales');
      _BackupProviderLogger.info('   - Locales: ${allBackups.where((b) => b.source == 'local' || b.source == null).length}');
      _BackupProviderLogger.info('   - Nube: ${allBackups.where((b) => b.source == 'cloud').length}');
      
    } catch (e, stackTrace) {
      _BackupProviderLogger.error('❌ Error cargando backups: $e');
      _BackupProviderLogger.error('Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ============================================
  // CREAR BACKUP LOCAL - CON FORZADO DE RECARGA
  // ============================================

  Future<bool> createLocalBackup(List<Note> notes) async {
    _BackupProviderLogger.info('📦 Creando backup local de ${notes.length} notas...');
    
    try {
      final result = await _backupService.createBackup(notes);
      
      if (result != null) {
        _BackupProviderLogger.success('✅ Backup creado: ${result['file_name']}');
        
        // ✅ ESPERAR A QUE EL ARCHIVO SE GUARDE COMPLETAMENTE
        await Future.delayed(const Duration(milliseconds: 500));
        
        // ✅ FORZAR RECARGA DEL SERVICIO (reinicializar para leer nuevos datos)
        await _backupService.init();
        
        // ✅ FORZAR RECARGA DEL ESTADO
        await loadBackups();
        
        // ✅ VERIFICACIÓN: volver a cargar para asegurar
        await Future.delayed(const Duration(milliseconds: 100));
        await loadBackups();
        
        return true;
      }
      return false;
    } catch (e) {
      _BackupProviderLogger.error('❌ Excepción: $e');
      return false;
    }
  }

  // ============================================
  // RESTAURAR BACKUP
  // ============================================

  Future<List<Note>?> restoreBackup(String backupId) async {
    _BackupProviderLogger.info('🔄 Restaurando backup: $backupId');
    
    try {
      final notes = await _backupService.restoreBackup(backupId);
      _BackupProviderLogger.success('✅ Restaurado: ${notes.length} notas');
      await loadBackups();
      return notes;
    } catch (e) {
      _BackupProviderLogger.error('❌ Error: $e');
      return null;
    }
  }

  // ============================================
  // ELIMINAR BACKUP - CON FORZADO DE RECARGA
  // ============================================

  Future<bool> deleteBackup(String backupId) async {
    _BackupProviderLogger.info('🗑️ Eliminando backup: $backupId');
    
    try {
      await _backupService.deleteBackup(backupId);
      _BackupProviderLogger.success('✅ Backup eliminado');
      
      // ✅ FORZAR RECARGA DEL SERVICIO
      await _backupService.init();
      await loadBackups();
      
      return true;
    } catch (e) {
      _BackupProviderLogger.error('❌ Error: $e');
      return false;
    }
  }

  // ============================================
  // SINCRONIZAR CON NUBE
  // ============================================

  Future<Map<String, dynamic>> syncWithCloud() async {
    _BackupProviderLogger.info('🔄 Sincronizando con la nube...');
    
    try {
      final localBackupsData = await _backupService.getBackups();
      final localBackupsList = localBackupsData
          .where((b) => b.source == 'local' || b.source == null)
          .map((b) => {
            'id': b.id,
            'file_name': b.fileName,
            'file_size': b.fileSize,
            'note_count': b.noteCount,
            'created_at': b.createdAt.toIso8601String(),
            'source': 'local',
          })
          .toList();

      final result = await _cloudService.syncCloudBackups(localBackupsList);
      _BackupProviderLogger.success('✅ Sincronización completada');
      await loadBackups();
      return {
        'synced': result['synced_count'] ?? 0,
        'failed': result['failed_count'] ?? 0,
        'message': result['message'] ?? '',
      };
    } catch (e) {
      _BackupProviderLogger.error('❌ Error: $e');
      return {'synced': 0, 'failed': 0, 'message': e.toString()};
    }
  }

  // ============================================
  // GETTERS
  // ============================================

  List<BackupMetadata> get localBackups {
    return state.backups
        .where((b) => b.source == 'local' || b.source == null)
        .toList();
  }

  List<BackupMetadata> get cloudBackups {
    return state.backups
        .where((b) => b.source == 'cloud')
        .toList();
  }

  int get localBackupsCount => localBackups.length;
  int get cloudBackupsCount => cloudBackups.length;
}

// ============================================
// PROVIDERS DERIVADOS
// ============================================

final backupListProvider = Provider<List<BackupMetadata>>((ref) {
  return ref.watch(backupProvider).backups;
});

final backupLimitProvider = Provider<BackupLimitInfo?>((ref) {
  return ref.watch(backupProvider).limitInfo;
});

final isLoadingBackupsProvider = Provider<bool>((ref) {
  return ref.watch(backupProvider).isLoading;
});

final localBackupsCountProvider = Provider<int>((ref) {
  return ref.watch(backupProvider.notifier).localBackupsCount;
});

final cloudBackupsCountProvider = Provider<int>((ref) {
  return ref.watch(backupProvider.notifier).cloudBackupsCount;
});

// Estados para auto-backup
final isBackingUpProvider = StateProvider<bool>((ref) => false);
final pendingChangesProvider = StateProvider<bool>((ref) => false);
final lastBackupTimeProvider = StateProvider<DateTime?>((ref) => null);