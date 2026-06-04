// lib/core/services/export_zip_service.dart
// Servicio para exportar notas a formato ZIP

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quicknote/models/note.dart';

class _ExportZipLogger {
  static void info(String message) => debugPrint('ℹ️ [ExportZipService] $message');
  static void success(String message) => debugPrint('✅ [ExportZipService] $message');
  static void warning(String message) => debugPrint('⚠️ [ExportZipService] $message');
  static void error(String message) => debugPrint('❌ [ExportZipService] $message');
}

class ExportProgress {
  final int current;
  final int total;
  final String currentNoteTitle;
  final bool isComplete;
  final String? error;

  ExportProgress({
    required this.current,
    required this.total,
    required this.currentNoteTitle,
    this.isComplete = false,
    this.error,
  });

  double get progress => total > 0 ? current / total : 0;
  int get percentage => (progress * 100).toInt();
}

class ExportZipService {
  static final ExportZipService _instance = ExportZipService._internal();
  factory ExportZipService() => _instance;
  ExportZipService._internal();

  String? _lastGeneratedZipPath;
  Function(ExportProgress)? onProgress;

  // ============================================
  // MÉTODOS PÚBLICOS
  // ============================================

  Future<String?> exportNotesToZip({
    required List<Note> notes,
    required String exportName,
    Function(ExportProgress)? onProgressCallback,
  }) async {
    onProgress = onProgressCallback;
    
    try {
      _ExportZipLogger.info('📦 Iniciando exportación a ZIP de ${notes.length} notas');
      
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final folderName = '${_sanitizeFileName(exportName)}_$timestamp';
      final exportFolder = Directory('${tempDir.path}/$folderName');
      
      if (await exportFolder.exists()) {
        await exportFolder.delete(recursive: true);
      }
      await exportFolder.create(recursive: true);
      
      final notesFolder = Directory('${exportFolder.path}/notes');
      final jsonFolder = Directory('${exportFolder.path}/json');
      await notesFolder.create();
      await jsonFolder.create();
      
      await _generateReadme(exportFolder, notes, exportName);
      
      for (int i = 0; i < notes.length; i++) {
        final note = notes[i];
        
        onProgress?.call(ExportProgress(
          current: i + 1,
          total: notes.length,
          currentNoteTitle: note.title.length > 30 ? '${note.title.substring(0, 30)}...' : note.title,
        ));
        
        await _generateMarkdownFile(notesFolder, note);
        await _generateJsonFile(jsonFolder, note);
        
        _ExportZipLogger.info('📄 Procesada nota ${i + 1}/${notes.length}: ${note.title}');
      }
      
      final zipPath = '${tempDir.path}/$folderName.zip';
      await _createZipFile(exportFolder, zipPath);
      
      await exportFolder.delete(recursive: true);
      
      _lastGeneratedZipPath = zipPath;
      _ExportZipLogger.success('✅ ZIP creado exitosamente: $zipPath');
      
      onProgress?.call(ExportProgress(
        current: notes.length,
        total: notes.length,
        currentNoteTitle: 'Completado',
        isComplete: true,
      ));
      
      return zipPath;
      
    } catch (e) {
      _ExportZipLogger.error('❌ Error en exportación ZIP: $e');
      onProgress?.call(ExportProgress(
        current: 0,
        total: notes.length,
        currentNoteTitle: 'Error',
        isComplete: true,
        error: e.toString(),
      ));
      return null;
    }
  }

  Future<bool> shareZip() async {
    if (_lastGeneratedZipPath == null) {
      return false;
    }
    try {
      await Share.shareXFiles(
        [XFile(_lastGeneratedZipPath!)], 
        text: 'Exportación de notas de QuickNote',
      );
      return true;
    } catch (e) {
      _ExportZipLogger.error('Error al compartir: $e');
      return false;
    }
  }

  Future<String?> saveZipToDownloads() async {
    if (_lastGeneratedZipPath == null) return null;
    
    try {
      final zipFile = File(_lastGeneratedZipPath!);
      if (!await zipFile.exists()) return null;
      
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) return null;
      
      final fileName = _lastGeneratedZipPath!.split('/').last;
      final destination = File('${downloadsDir.path}/$fileName');
      
      await zipFile.copy(destination.path);
      _ExportZipLogger.success('✅ ZIP guardado en: ${destination.path}');
      
      return destination.path;
      
    } catch (e) {
      _ExportZipLogger.error('❌ Error al guardar ZIP: $e');
      return null;
    }
  }

  Future<void> cleanup() async {
    if (_lastGeneratedZipPath != null) {
      try {
        final zipFile = File(_lastGeneratedZipPath!);
        if (await zipFile.exists()) {
          await zipFile.delete();
        }
      } catch (e) {
        // Ignorar errores al limpiar
      } finally {
        _lastGeneratedZipPath = null;
      }
    }
  }

  // ============================================
  // MÉTODOS PRIVADOS
  // ============================================

  String _sanitizeFileName(String name) {
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    String sanitized = name.replaceAll(invalidChars, '_');
    if (sanitized.length > 50) {
      sanitized = sanitized.substring(0, 50);
    }
    return sanitized.isEmpty ? 'nota_sin_titulo' : sanitized;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Crear archivo ZIP usando la API correcta de archive
  Future<void> _createZipFile(Directory folder, String outputPath) async {
    final archive = Archive();
    
    await for (final entity in folder.list(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.path.replaceFirst('${folder.path}/', '');
        final fileBytes = await entity.readAsBytes();
        final archiveFile = ArchiveFile(relativePath, fileBytes.length, fileBytes);
        archive.addFile(archiveFile);
        _ExportZipLogger.info('  📄 Añadido: $relativePath');
      }
    }
    
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes != null) {
      final zipFile = File(outputPath);
      await zipFile.writeAsBytes(zipBytes);
      _ExportZipLogger.success('✅ ZIP comprimido: ${zipBytes.length} bytes');
    } else {
      throw Exception('Error al comprimir el archivo ZIP');
    }
  }

  Future<void> _generateReadme(Directory folder, List<Note> notes, String exportName) async {
    final readmeFile = File('${folder.path}/README.md');
    final date = DateTime.now();
    
    final StringBuffer notesList = StringBuffer();
    for (int i = 0; i < notes.length; i++) {
      final n = notes[i];
      final titleEscaped = n.title.replaceAll('|', '\\|');
      notesList.writeln('| ${i + 1} | $titleEscaped | ${n.isFavorite ? "✅" : "❌"} | ${n.isArchived ? "✅" : "❌"} | ${n.tags.join(", ")} |');
    }
    
    final content = '''
# Exportación de QuickNote

## Información general
- **Nombre de exportación:** $exportName
- **Fecha de exportación:** ${date.day}/${date.month}/${date.year}
- **Total de notas exportadas:** ${notes.length}

## Lista de notas exportadas
| # | Título | Favorita | Archivada | Etiquetas |
|---|--------|----------|-----------|-----------|
$notesList

---
*Exportado desde QuickNote*
''';
    
    await readmeFile.writeAsString(content);
  }

  Future<void> _generateMarkdownFile(Directory folder, Note note) async {
    final fileName = '${_sanitizeFileName(note.title)}.md';
    final file = File('${folder.path}/$fileName');
    
    final content = '''
# ${note.title}

${note.content.isNotEmpty ? note.content : '*Sin contenido*'}

---
- **Creada:** ${_formatDate(note.createdAt)}
- **Actualizada:** ${_formatDate(note.updatedAt)}
- **Etiquetas:** ${note.tags.isNotEmpty ? note.tags.join(", ") : "Sin etiquetas"}
''';
    
    await file.writeAsString(content);
  }

  Future<void> _generateJsonFile(Directory folder, Note note) async {
    final fileName = '${_sanitizeFileName(note.title)}.json';
    final file = File('${folder.path}/$fileName');
    
    final jsonData = {
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'color': note.color,
      'is_favorite': note.isFavorite,
      'is_archived': note.isArchived,
      'tags': note.tags,
      'created_at': note.createdAt.toIso8601String(),
      'updated_at': note.updatedAt.toIso8601String(),
      'exported_at': DateTime.now().toIso8601String(),
    };
    
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonData));
  }
}

final exportZipService = ExportZipService();