// lib/core/services/backup_service.dart
// Servicio de gestión de backups locales - VERSIÓN COMPLETA CORREGIDA
// ✅ CORREGIDO: ID único basado en timestamp + microsegundos
// ✅ CORREGIDO: Recarga de metadatos después de cada operación
// ✅ CORREGIDO: Eliminación correcta de archivos y metadatos
// ✅ CORREGIDO: Logs detallados para depuración

import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:path_provider/path_provider.dart';
import 'package:quicknote/models/backup.dart';
import 'package:quicknote/models/note.dart';

// ============================================
// LOGGER
// ============================================

class _BackupServiceLogger {
  static void info(String message) => log('ℹ️ [BackupService] $message');
  static void success(String message) => log('✅ [BackupService] $message');
  static void error(String message) => log('❌ [BackupService] $message');
  static void warn(String message) => log('⚠️ [BackupService] $message');
}

// ============================================
// BACKUP SERVICE
// ============================================

class BackupService {
  static const String _backupsFolder = 'backups';
  static const String _backupMetadataFile = 'backups_metadata.json';
  
  List<BackupMetadata> _backups = [];
  bool _isInitialized = false;

  // ============================================
  // INICIALIZACIÓN
  // ============================================

  Future<void> init() async {
    if (_isInitialized) {
      // ✅ Forzar recarga de metadatos incluso si ya está inicializado
      await _loadMetadata();
      return;
    }
    
    _BackupServiceLogger.info('Inicializando BackupService...');
    await _loadMetadata();
    _isInitialized = true;
    _BackupServiceLogger.success('BackupService inicializado con ${_backups.length} backups');
  }

  Future<Directory> _getBackupsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupsDir = Directory('${appDir.path}/$_backupsFolder');
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
      _BackupServiceLogger.info('📁 Carpeta de backups creada: ${backupsDir.path}');
    }
    return backupsDir;
  }

  Future<File> _getMetadataFile() async {
    final dir = await _getBackupsDirectory();
    return File('${dir.path}/$_backupMetadataFile');
  }

  // ============================================
  // CARGA Y GUARDADO DE METADATOS
  // ============================================

  Future<void> _loadMetadata() async {
    try {
      final metadataFile = await _getMetadataFile();
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _backups = jsonList.map((json) => BackupMetadata.fromJson(json)).toList();
        _BackupServiceLogger.info('📦 Cargados ${_backups.length} backups desde metadata');
        
        // ✅ Log de cada backup cargado
        for (var backup in _backups) {
          _BackupServiceLogger.info('   - ${backup.fileName} (id: ${backup.id}, source: ${backup.source})');
        }
      } else {
        _backups = [];
        _BackupServiceLogger.info('📦 No hay metadata de backups, empezando desde cero');
      }
    } catch (e) {
      _BackupServiceLogger.error('❌ Error cargando metadata: $e');
      _backups = [];
    }
  }

  Future<void> _saveMetadata() async {
    try {
      final metadataFile = await _getMetadataFile();
      final jsonList = _backups.map((b) => b.toJson()).toList();
      await metadataFile.writeAsString(jsonEncode(jsonList));
      _BackupServiceLogger.success('💾 Metadata guardada (${_backups.length} backups)');
    } catch (e) {
      _BackupServiceLogger.error('❌ Error guardando metadata: $e');
    }
  }

  // ============================================
  // MÉTODOS PRINCIPALES
  // ============================================

  /// Obtener todos los backups (como List<BackupMetadata>)
  Future<List<BackupMetadata>> getBackups() async {
    await init();
    // Ordenar por fecha descendente (más reciente primero)
    _backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _BackupServiceLogger.info('📋 getBackups() retorna ${_backups.length} backups');
    return List.unmodifiable(_backups);
  }

  /// Obtener solo backups locales
  Future<List<BackupMetadata>> getLocalBackups() async {
    await init();
    final locals = _backups.where((b) => b.source == 'local' || b.source == null).toList();
    locals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _BackupServiceLogger.info('📋 getLocalBackups() retorna ${locals.length} backups locales');
    return List.unmodifiable(locals);
  }

  /// Crear un nuevo backup
  Future<Map<String, dynamic>?> createBackup(List<Note> notes, {bool syncToCloud = false}) async {
    await init();
    
    if (notes.isEmpty) {
      _BackupServiceLogger.error('❌ No hay notas para respaldar');
      return null;
    }

    // Verificar límite
    final limitInfo = await getBackupLimitInfo();
    if (limitInfo.isFull) {
      _BackupServiceLogger.error('❌ Límite de backups alcanzado (${limitInfo.current}/${limitInfo.max})');
      return null;
    }

    final timestamp = DateTime.now();
    final fileName = _generateFileName(notes.length, timestamp);
    
    final backupData = {
      'version': '1.0.0',
      'timestamp': timestamp.toIso8601String(),
      'total_notes': notes.length,
      'notes': notes.map((n) => n.toJson()).toList(),
      'metadata': {
        'app_version': '1.0.0',
        'export_date': timestamp.toIso8601String(),
      },
    };

    final jsonContent = jsonEncode(backupData);
    final fileSize = utf8.encode(jsonContent).length;

    // Guardar archivo JSON
    final backupsDir = await _getBackupsDirectory();
    final backupFile = File('${backupsDir.path}/$fileName');
    await backupFile.writeAsString(jsonContent);
    _BackupServiceLogger.success('📄 Archivo guardado: $fileName ($fileSize bytes)');
    
    // ✅ ID ÚNICO basado en timestamp + microsegundos para evitar duplicados
    final backupId = 'backup_${timestamp.millisecondsSinceEpoch}_${timestamp.microsecond}';
    
    // Crear metadata
    final backup = BackupMetadata(
      id: backupId,
      userId: 'local',
      fileName: fileName,
      fileSize: fileSize,
      noteCount: notes.length,
      version: '1.0.0',
      isAccumulative: true,
      createdAt: timestamp,
      isLatest: true,
      source: 'local',
      cloudId: null,
    );

    // Actualizar isLatest de otros backups
    for (var i = 0; i < _backups.length; i++) {
      if (_backups[i].isLatest && _backups[i].source != 'cloud') {
        _backups[i] = _backups[i].copyWith(isLatest: false);
        _BackupServiceLogger.info('🔄 Actualizado isLatest=false para: ${_backups[i].fileName}');
      }
    }
    
    _backups.insert(0, backup);
    await _saveMetadata();
    
    _BackupServiceLogger.success('✅ Backup creado: $fileName (${notes.length} notas)');
    _BackupServiceLogger.info('   ID: $backupId');
    _BackupServiceLogger.info('   Total backups ahora: ${_backups.length}');
    
    return {
      'id': backup.id,
      'file_name': backup.fileName,
      'note_count': backup.noteCount,
      'file_size': backup.fileSize,
      'created_at': backup.createdAt.toIso8601String(),
    };
  }

  /// Restaurar un backup por ID
  Future<List<Note>> restoreBackup(String backupId) async {
    await init();
    
    _BackupServiceLogger.info('🔄 Buscando backup: $backupId');
    
    // Buscar en backups locales
    BackupMetadata? backup;
    for (var b in _backups) {
      if (b.id == backupId) {
        backup = b;
        break;
      }
    }
    
    if (backup == null) {
      _BackupServiceLogger.error('❌ Backup no encontrado: $backupId');
      throw Exception('Backup no encontrado: $backupId');
    }
    
    _BackupServiceLogger.info('📄 Cargando archivo: ${backup.fileName}');
    
    // Cargar archivo
    final backupsDir = await _getBackupsDirectory();
    final backupFile = File('${backupsDir.path}/${backup.fileName}');
    
    if (!await backupFile.exists()) {
      _BackupServiceLogger.error('❌ Archivo no encontrado: ${backup.fileName}');
      throw Exception('Archivo de backup no encontrado: ${backup.fileName}');
    }
    
    final content = await backupFile.readAsString();
    final Map<String, dynamic> data = jsonDecode(content);
    final notesJson = data['notes'] as List<dynamic>;
    
    final notes = notesJson.map((json) => Note.fromJson(json)).toList();
    _BackupServiceLogger.success('✅ Backup restaurado: ${notes.length} notas');
    
    return notes;
  }

  /// Eliminar un backup por ID
  Future<void> deleteBackup(String backupId) async {
    await init();
    
    _BackupServiceLogger.info('🗑️ Buscando backup para eliminar: $backupId');
    
    // Buscar el backup
    BackupMetadata? backupToDelete;
    for (var i = 0; i < _backups.length; i++) {
      if (_backups[i].id == backupId) {
        backupToDelete = _backups[i];
        _backups.removeAt(i);
        break;
      }
    }
    
    if (backupToDelete != null) {
      _BackupServiceLogger.info('📄 Eliminando archivo: ${backupToDelete.fileName}');
      
      // Eliminar archivo
      final backupsDir = await _getBackupsDirectory();
      final backupFile = File('${backupsDir.path}/${backupToDelete.fileName}');
      if (await backupFile.exists()) {
        await backupFile.delete();
        _BackupServiceLogger.success('🗑️ Archivo eliminado: ${backupToDelete.fileName}');
      } else {
        _BackupServiceLogger.warn('⚠️ Archivo no existía: ${backupToDelete.fileName}');
      }
      
      await _saveMetadata();
      _BackupServiceLogger.success('✅ Backup eliminado de metadata. Total restantes: ${_backups.length}');
    } else {
      _BackupServiceLogger.warn('⚠️ Backup no encontrado para eliminar: $backupId');
    }
  }

  /// Descargar backup (copia a descargas)
  Future<void> downloadBackup(String backupId) async {
    await init();
    
    BackupMetadata? backup;
    for (var b in _backups) {
      if (b.id == backupId) {
        backup = b;
        break;
      }
    }
    
    if (backup == null) {
      throw Exception('Backup no encontrado: $backupId');
    }
    
    final backupsDir = await _getBackupsDirectory();
    final backupFile = File('${backupsDir.path}/${backup.fileName}');
    
    if (!await backupFile.exists()) {
      throw Exception('Archivo no encontrado: ${backup.fileName}');
    }
    
    // Copiar a descargas (implementar según plataforma)
    _BackupServiceLogger.info('📥 Descargando backup: ${backup.fileName}');
    // TODO: Implementar share_plus para compartir el archivo
  }

  // ============================================
  // UTILIDADES
  // ============================================

  Future<BackupLimitInfo> getBackupLimitInfo() async {
    await init();
    final localBackups = await getLocalBackups();
    final current = localBackups.length;
    const max = 20;
    final totalSize = localBackups.fold<int>(0, (sum, b) => sum + b.fileSize);
    
    _BackupServiceLogger.info('📊 Límite: $current/$max backups, ${_formatFileSize(totalSize)} usado');
    
    return BackupLimitInfo(
      current: current,
      max: max,
      remaining: max - current,
      isFull: current >= max,
      isLow: current >= max - 2,
      totalSize: totalSize,
    );
  }

  String _generateFileName(int noteCount, DateTime date) {
    return 'quicknote_backup_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}_${date.hour.toString().padLeft(2, '0')}-${date.minute.toString().padLeft(2, '0')}_${noteCount}notas.json';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}