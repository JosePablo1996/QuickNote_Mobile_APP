// lib/core/services/clipboard_service.dart
// Servicio para copiar al portapapeles

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quicknote/models/note.dart';

class ClipboardService {
  static final ClipboardService _instance = ClipboardService._internal();
  factory ClipboardService() => _instance;
  ClipboardService._internal();

  // ============================================
  // COPIAR TEXTO SIMPLE
  // ============================================
  
  Future<bool> copyText(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (e) {
      debugPrint('Error copiando texto: $e');
      return false;
    }
  }

  // ============================================
  // COPIAR NOTA COMPLETA
  // ============================================
  
  Future<bool> copyNote(Note note) async {
    final content = _buildNoteContent(note);
    return await copyText(content);
  }
  
  String _buildNoteContent(Note note) {
    final buffer = StringBuffer();
    buffer.writeln('📝 ${note.title}');
    buffer.writeln();
    buffer.writeln(note.content.isEmpty ? 'Sin contenido' : note.content);
    buffer.writeln();
    
    if (note.tags.isNotEmpty) {
      buffer.writeln('🏷️ Etiquetas: ${note.tags.map((t) => '#$t').join(' ')}');
    }
    
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('📅 Creada: ${_formatDate(note.createdAt)}');
    buffer.writeln('🔄 Actualizada: ${_formatDate(note.updatedAt)}');
    
    return buffer.toString();
  }

  // ============================================
  // COPIAR SOLO TÍTULO
  // ============================================
  
  Future<bool> copyTitle(Note note) async {
    return await copyText(note.title);
  }

  // ============================================
  // COPIAR SOLO CONTENIDO
  // ============================================
  
  Future<bool> copyContent(Note note) async {
    return await copyText(note.content.isEmpty ? 'Sin contenido' : note.content);
  }

  // ============================================
  // COPIAR MÚLTIPLES NOTAS
  // ============================================
  
  Future<bool> copyMultipleNotes(List<Note> notes) async {
    final buffer = StringBuffer();
    buffer.writeln('📚 QuickNote - ${notes.length} notas');
    buffer.writeln();
    
    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      buffer.writeln('${i + 1}. ${note.title}');
      buffer.writeln('   ${_truncate(note.content, 150)}');
      buffer.writeln();
    }
    
    return await copyText(buffer.toString());
  }

  // ============================================
  // COPIAR TAGS
  // ============================================
  
  Future<bool> copyTags(Note note) async {
    if (note.tags.isEmpty) {
      return await copyText('Sin etiquetas');
    }
    final tagsText = note.tags.map((t) => '#$t').join(' ');
    return await copyText(tagsText);
  }

  // ============================================
  // COPIAR ENLACE DE NOTA (para futuro)
  // ============================================
  
  Future<bool> copyNoteLink(String noteId) async {
    final link = 'quicknote://note/$noteId';
    return await copyText(link);
  }

  // ============================================
  // UTILIDADES
  // ============================================
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}