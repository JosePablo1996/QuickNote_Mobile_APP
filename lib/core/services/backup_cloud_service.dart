// lib/core/services/backup_cloud_service.dart
// Servicio de comunicación con API para backups en la nube
// ✅ CORREGIDO: Importación correcta de token_storage
// ✅ CORREGIDO: Importación de Note
// ✅ CORREGIDO: Uso de debugPrint en lugar de print
// ✅ CORREGIDO: Manejo de IDs con/sin prefijo

import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:quicknote/core/utils/token_storage.dart';
import 'package:quicknote/models/note.dart';

// ============================================
// LOGGER
// ============================================

class _BackupCloudServiceLogger {
  static void info(String message) => log('ℹ️ [BackupCloudService] $message');
  static void success(String message) => log('✅ [BackupCloudService] $message');
  static void error(String message) => log('❌ [BackupCloudService] $message');
  static void warn(String message) => log('⚠️ [BackupCloudService] $message');
}

// ============================================
// BACKUP CLOUD SERVICE
// ============================================

class BackupCloudService {
  final TokenStorage _tokenStorage = TokenStorage();

  // ============================================
  // MÉTODOS PRIVADOS
  // ============================================

  /// Obtener token de autenticación
  Future<String?> _getAuthToken() async {
    return await _tokenStorage.getAuthToken();
  }

  /// Construir URL correctamente
  String _buildUrl(String path) {
    // Usar variable de entorno o URL por defecto
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://quicknote-api-app-react.onrender.com',
    );
    
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$baseUrl$normalizedPath';
    
    _BackupCloudServiceLogger.info('📡 URL: $fullUrl');
    return fullUrl;
  }

  /// Extraer ID limpio (sin prefijo 'cloud_')
  String _cleanId(String id) {
    if (id.startsWith('cloud_')) {
      final clean = id.substring(6);
      _BackupCloudServiceLogger.info('🧹 ID limpio: $id -> $clean');
      return clean;
    }
    return id;
  }

  // ============================================
  // GUARDAR BACKUP EN LA NUBE
  // ============================================

  /// Guardar un backup en la nube
  Future<Map<String, dynamic>?> saveCloudBackup({
    required String fileName,
    required int fileSize,
    required int noteCount,
    required Map<String, dynamic> notesData,
  }) async {
    _BackupCloudServiceLogger.info('☁️ Guardando backup en la nube...');
    _BackupCloudServiceLogger.info('   - fileName: $fileName');
    _BackupCloudServiceLogger.info('   - noteCount: $noteCount');
    _BackupCloudServiceLogger.info('   - fileSize: $fileSize bytes');

    final token = await _getAuthToken();
    if (token == null) {
      _BackupCloudServiceLogger.error('❌ No hay token de autenticación');
      return null;
    }

    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://quicknote-api-app-react.onrender.com',
    );
    final url = '$baseUrl/api/v1/backup/cloud';
    
    final body = {
      'file_name': fileName,
      'file_size': fileSize,
      'note_count': noteCount,
      'notes_data': notesData,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      _BackupCloudServiceLogger.info('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _BackupCloudServiceLogger.success('✅ Backup guardado: ${data['id']}');
        return data;
      } else {
        _BackupCloudServiceLogger.error('❌ Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      _BackupCloudServiceLogger.error('❌ Excepción: $e');
      return null;
    }
  }

  // ============================================
  // OBTENER BACKUPS DE LA NUBE
  // ============================================

  /// Obtener lista de backups de la nube
  Future<List<Map<String, dynamic>>> getCloudBackups() async {
    _BackupCloudServiceLogger.info('☁️ Obteniendo backups de la nube...');

    final token = await _getAuthToken();
    if (token == null) {
      _BackupCloudServiceLogger.error('❌ No hay token de autenticación');
      return [];
    }

    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://quicknote-api-app-react.onrender.com',
    );
    final url = '$baseUrl/api/v1/backup/cloud';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _BackupCloudServiceLogger.info('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _BackupCloudServiceLogger.success('✅ ${data.length} backups encontrados');
        
        // Log de cada backup para depuración
        for (var backup in data) {
          _BackupCloudServiceLogger.info('   - ${backup['file_name']} (id: ${backup['id']})');
        }
        
        return data.map((backup) => Map<String, dynamic>.from(backup)).toList();
      } else if (response.statusCode == 404) {
        _BackupCloudServiceLogger.warn('⚠️ No hay backups (404)');
        return [];
      } else {
        _BackupCloudServiceLogger.error('❌ Error ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _BackupCloudServiceLogger.error('❌ Excepción: $e');
      return [];
    }
  }

  // ============================================
  // OBTENER UN BACKUP ESPECÍFICO
  // ============================================

  /// Obtener un backup específico de la nube (incluye datos)
  Future<Map<String, dynamic>?> getCloudBackup(String backupId) async {
    final cleanId = _cleanId(backupId);
    _BackupCloudServiceLogger.info('🔍 Obteniendo backup: $cleanId');

    final token = await _getAuthToken();
    if (token == null) {
      _BackupCloudServiceLogger.error('❌ No hay token de autenticación');
      return null;
    }

    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://quicknote-api-app-react.onrender.com',
    );
    final url = '$baseUrl/api/v1/backup/cloud/$cleanId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _BackupCloudServiceLogger.info('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _BackupCloudServiceLogger.success('✅ Backup obtenido: ${data['file_name']}');
        return data;
      } else if (response.statusCode == 404) {
        _BackupCloudServiceLogger.warn('⚠️ Backup no encontrado: $cleanId');
        return null;
      } else {
        _BackupCloudServiceLogger.error('❌ Error ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _BackupCloudServiceLogger.error('❌ Excepción: $e');
      return null;
    }
  }

  // ============================================
  // RESTAURAR BACKUP
  // ============================================

  /// Restaurar un backup de la nube (retorna las notas)
  Future<List<Note>> restoreCloudBackup(String backupId) async {
    final cleanId = _cleanId(backupId);
    _BackupCloudServiceLogger.info('🔄 Restaurando backup: $cleanId');

    final backupData = await getCloudBackup(cleanId);
    
    if (backupData == null) {
      throw Exception('Backup no encontrado: $cleanId');
    }
    
    // Extraer notas del backup
    List<Note> notes = [];
    
    if (backupData['notes_data'] != null) {
      final notesData = backupData['notes_data'];
      
      if (notesData is Map && notesData.containsKey('notes')) {
        final notesJson = notesData['notes'] as List?;
        if (notesJson != null) {
          notes = notesJson.map((json) => Note.fromJson(json)).toList();
        }
      } else if (notesData is List) {
        notes = notesData.map((json) => Note.fromJson(json)).toList();
      }
    }
    
    _BackupCloudServiceLogger.success('✅ Backup restaurado: ${notes.length} notas');
    return notes;
  }

  // ============================================
  // ELIMINAR BACKUP - CORREGIDO
  // ============================================

  /// Eliminar un backup de la nube
  Future<bool> deleteCloudBackup(String backupId) async {
    final cleanId = _cleanId(backupId);
    _BackupCloudServiceLogger.info('🗑️ Eliminando backup: $cleanId');

    final token = await _getAuthToken();
    if (token == null) {
      _BackupCloudServiceLogger.error('❌ No hay token de autenticación');
      return false;
    }

    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://quicknote-api-app-react.onrender.com',
    );
    final url = '$baseUrl/api/v1/backup/cloud/$cleanId';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _BackupCloudServiceLogger.info('📥 Response status: ${response.statusCode}');

      // ✅ Aceptamos 200, 204 (éxito) y 404 (ya no existe)
      if (response.statusCode == 200 || response.statusCode == 204) {
        _BackupCloudServiceLogger.success('✅ Backup eliminado: $cleanId');
        return true;
      } else if (response.statusCode == 404) {
        _BackupCloudServiceLogger.warn('⚠️ Backup no existía: $cleanId (ya fue eliminado)');
        return true; // Consideramos éxito si ya no existe
      } else {
        _BackupCloudServiceLogger.error('❌ Error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      _BackupCloudServiceLogger.error('❌ Excepción: $e');
      return false;
    }
  }

  // ============================================
  // SINCRONIZAR BACKUPS LOCALES CON NUBE
  // ============================================

  /// Sincronizar backups locales con la nube
  Future<Map<String, dynamic>> syncCloudBackups(List<Map<String, dynamic>> localBackups) async {
    _BackupCloudServiceLogger.info('🔄 Sincronizando ${localBackups.length} backups locales con la nube...');

    final token = await _getAuthToken();
    if (token == null) {
      _BackupCloudServiceLogger.error('❌ No hay token de autenticación');
      return {
        'synced_count': 0,
        'failed_count': 0,
        'cloud_backups_to_download': [],
        'message': 'No autenticado',
      };
    }

    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://quicknote-api-app-react.onrender.com',
    );
    final url = '$baseUrl/api/v1/backup/cloud/sync';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'local_backups': localBackups}),
      );

      _BackupCloudServiceLogger.info('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _BackupCloudServiceLogger.success('✅ Sincronización completada');
        _BackupCloudServiceLogger.info('   - Sincronizados: ${data['synced_count']}');
        _BackupCloudServiceLogger.info('   - Fallidos: ${data['failed_count']}');
        _BackupCloudServiceLogger.info('   - Para descargar: ${data['cloud_backups_to_download']?.length ?? 0}');
        
        return {
          'synced_count': data['synced_count'] ?? 0,
          'failed_count': data['failed_count'] ?? 0,
          'cloud_backups_to_download': data['cloud_backups_to_download'] ?? [],
          'message': data['message'] ?? 'Sincronización completada',
        };
      } else {
        _BackupCloudServiceLogger.error('❌ Error ${response.statusCode}: ${response.body}');
        return {
          'synced_count': 0,
          'failed_count': 0,
          'cloud_backups_to_download': [],
          'message': 'Error ${response.statusCode}',
        };
      }
    } catch (e) {
      _BackupCloudServiceLogger.error('❌ Excepción: $e');
      return {
        'synced_count': 0,
        'failed_count': 0,
        'cloud_backups_to_download': [],
        'message': e.toString(),
      };
    }
  }

  // ============================================
  // OBTENER INFORMACIÓN DE LÍMITE
  // ============================================

  /// Obtener información del límite de backups
  Future<Map<String, dynamic>?> getBackupLimitInfo() async {
    _BackupCloudServiceLogger.info('📊 Obteniendo información de límite...');

    final token = await _getAuthToken();
    if (token == null) {
      _BackupCloudServiceLogger.error('❌ No hay token de autenticación');
      return null;
    }

    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://quicknote-api-app-react.onrender.com',
    );
    final url = '$baseUrl/api/v1/backup/cloud/limit/info';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _BackupCloudServiceLogger.info('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _BackupCloudServiceLogger.success('✅ Límite: ${data['current']}/${data['max']}');
        return data;
      } else {
        _BackupCloudServiceLogger.error('❌ Error ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _BackupCloudServiceLogger.error('❌ Excepción: $e');
      return null;
    }
  }
}