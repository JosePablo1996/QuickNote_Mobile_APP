// lib/core/services/share_service.dart
// Servicio para compartir notas (Web Share API en Android)

import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:quicknote/models/note.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  // ============================================
  // COMPARTIR NOTA COMO TEXTO
  // ============================================
  
  Future<void> shareNoteAsText(Note note) async {
    final subject = 'QuickNote: ${note.title}';
    final body = _buildShareText(note);
    
    await Share.share(body, subject: subject);
  }
  
  String _buildShareText(Note note) {
    final buffer = StringBuffer();
    buffer.writeln('📝 ${note.title}');
    buffer.writeln();
    buffer.writeln(note.content.isEmpty ? 'Sin contenido' : note.content);
    buffer.writeln();
    
    if (note.tags.isNotEmpty) {
      buffer.writeln('🏷️ Etiquetas: ${note.tags.map((t) => '#$t').join(' ')}');
      buffer.writeln();
    }
    
    buffer.writeln('---');
    buffer.writeln('Compartido desde QuickNote');
    
    return buffer.toString();
  }

  // ============================================
  // COMPARTIR NOTA COMO ARCHIVO (PDF/Markdown)
  // ============================================
  
  Future<void> shareNoteAsFile(File file, String fileName, String mimeType) async {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: 'QuickNote - $fileName',
    );
  }
  
  Future<void> shareNoteAsPdf(File pdfFile, String noteTitle) async {
    await shareNoteAsFile(pdfFile, '$noteTitle.pdf', 'application/pdf');
  }
  
  Future<void> shareNoteAsMarkdown(File mdFile, String noteTitle) async {
    await shareNoteAsFile(mdFile, '$noteTitle.md', 'text/markdown');
  }

  // ============================================
  // COMPARTIR MÚLTIPLES NOTAS
  // ============================================
  
  Future<void> shareMultipleNotesAsText(List<Note> notes) async {
    final buffer = StringBuffer();
    buffer.writeln('📚 QuickNote - ${notes.length} notas compartidas');
    buffer.writeln();
    
    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      buffer.writeln('${i + 1}. ${note.title}');
      buffer.writeln('   ${_truncate(note.content, 100)}');
      buffer.writeln();
    }
    
    buffer.writeln('---');
    buffer.writeln('Compartido desde QuickNote');
    
    await Share.share(buffer.toString());
  }
  
  Future<void> shareZipFile(File zipFile, int noteCount) async {
    await shareNoteAsFile(zipFile, '${noteCount}_notas.zip', 'application/zip');
  }

  // ============================================
  // COMPARTIR TEXTO PERSONALIZADO
  // ============================================
  
  Future<void> shareCustomText(String text, {String? subject}) async {
    await Share.share(text, subject: subject);
  }
  
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}