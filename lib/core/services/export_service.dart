// lib/core/services/export_service.dart
// Servicio de exportación - PDF, Markdown, ZIP, JSON
// Para Android exclusivamente

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quicknote/models/note.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  // ============================================
  // EXPORTAR A PDF (Nota individual)
  // ============================================
  
  Future<File?> exportNoteToPdf(Note note) async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            _buildPdfHeader(note),
            pw.SizedBox(height: 20),
            _buildPdfContent(note),
            pw.SizedBox(height: 30),
            _buildPdfFooter(note),
          ],
        ),
      );
      
      final output = await getTemporaryDirectory();
      final filePath = '${output.path}/quicknote_${note.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      return file;
    } catch (e) {
      debugPrint('Error exportando a PDF: $e');
      return null;
    }
  }

  pw.Widget _buildPdfHeader(Note note) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Row(
            children: [
              pw.Icon(pw.IconData(0xe3c9), size: 40, color: PdfColors.blue),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'QuickNote',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                      ),
                    ),
                    pw.Text(
                      'Nota Exportada',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          note.title,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Creada: ${_formatDate(note.createdAt)} | Actualizada: ${_formatDate(note.updatedAt)}',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildPdfContent(Note note) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Contenido',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          note.content.isEmpty ? 'Sin contenido' : note.content,
          style: pw.TextStyle(fontSize: 12, height: 1.5),
        ),
      ],
    );
  }

  pw.Widget _buildPdfFooter(Note note) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        if (note.tags.isNotEmpty) ...[
          pw.Text(
            'Etiquetas:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Wrap(
            spacing: 5,
            children: note.tags.map((tag) {
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text('#$tag', style: pw.TextStyle(fontSize: 10)),
              );
            }).toList(),
          ),
          pw.SizedBox(height: 10),
        ],
        pw.Text(
          'Generado por QuickNote v2.6.0',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // ============================================
  // EXPORTAR A PDF (Múltiples notas)
  // ============================================
  
  Future<File?> exportMultipleNotesToPdf(List<Note> notes) async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => _buildMultiPageHeader(),
          build: (context) => [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: notes.map((note) => _buildMultiPageNote(note)).toList(),
            ),
          ],
          footer: (context) => _buildMultiPageFooter(context),
        ),
      );
      
      final output = await getTemporaryDirectory();
      final filePath = '${output.path}/quicknote_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      return file;
    } catch (e) {
      debugPrint('Error exportando múltiples notas a PDF: $e');
      return null;
    }
  }

  pw.Widget _buildMultiPageHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        'QuickNote - Exportación de Notas',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildMultiPageNote(Note note) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                note.title,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                note.content.isEmpty ? 'Sin contenido' : note.content,
                style: pw.TextStyle(fontSize: 11),
              ),
              if (note.tags.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Wrap(
                  spacing: 4,
                  children: note.tags.map((tag) {
                    return pw.Text('#$tag', style: pw.TextStyle(fontSize: 9, color: PdfColors.blue));
                  }).toList(),
                ),
              ],
              pw.SizedBox(height: 4),
              pw.Text(
                _formatDate(note.createdAt),
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildMultiPageFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Text(
        'Página ${context.pageNumber}',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
      ),
    );
  }

  // ============================================
  // EXPORTAR A MARKDOWN
  // ============================================
  
  String exportToMarkdown(Note note) {
    final buffer = StringBuffer();
    
    buffer.writeln('# ${note.title}');
    buffer.writeln();
    buffer.writeln('> Creada: ${_formatDate(note.createdAt)}');
    buffer.writeln('> Actualizada: ${_formatDate(note.updatedAt)}');
    buffer.writeln();
    
    if (note.tags.isNotEmpty) {
      buffer.writeln('**Etiquetas:** ${note.tags.map((t) => '#$t').join(' ')}');
      buffer.writeln();
    }
    
    buffer.writeln('## Contenido');
    buffer.writeln();
    buffer.writeln(note.content.isEmpty ? '*Sin contenido*' : note.content);
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('*Generado por QuickNote v2.6.0*');
    
    return buffer.toString();
  }
  
  Future<File?> exportToMarkdownFile(Note note) async {
    try {
      final content = exportToMarkdown(note);
      final output = await getTemporaryDirectory();
      final filePath = '${output.path}/quicknote_${note.id}_${DateTime.now().millisecondsSinceEpoch}.md';
      final file = File(filePath);
      await file.writeAsString(content);
      return file;
    } catch (e) {
      debugPrint('Error exportando a Markdown: $e');
      return null;
    }
  }

  // ============================================
  // EXPORTAR A ZIP (Múltiples formatos)
  // ============================================
  
  Future<File?> exportToZip({
    required List<Note> notes,
    bool includePdf = true,
    bool includeMarkdown = true,
    bool includeJson = true,
  }) async {
    try {
      final archive = Archive();
      final output = await getTemporaryDirectory();
      
      for (final note in notes) {
        if (includePdf) {
          final pdfFile = await exportNoteToPdf(note);
          if (pdfFile != null) {
            final pdfBytes = await pdfFile.readAsBytes();
            archive.addFile(ArchiveFile(
              '${_sanitizeFilename(note.title)}.pdf',
              pdfBytes.length,
              pdfBytes,
            ));
          }
        }
        
        if (includeMarkdown) {
          final mdContent = exportToMarkdown(note);
          archive.addFile(ArchiveFile(
            '${_sanitizeFilename(note.title)}.md',
            mdContent.length,
            mdContent.codeUnits,
          ));
        }
        
        if (includeJson) {
          final jsonContent = jsonEncode(note.toJson());
          archive.addFile(ArchiveFile(
            '${_sanitizeFilename(note.title)}.json',
            jsonContent.length,
            jsonContent.codeUnits,
          ));
        }
      }
      
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) throw Exception('Error comprimiendo archivos');
      
      final zipPath = '${output.path}/quicknote_export_${DateTime.now().millisecondsSinceEpoch}.zip';
      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipData);
      
      return zipFile;
    } catch (e) {
      debugPrint('Error exportando a ZIP: $e');
      return null;
    }
  }

  // ============================================
  // EXPORTAR A JSON (Backup)
  // ============================================
  
  Future<File?> exportToJson(List<Note> notes) async {
    try {
      final exportData = {
        'version': '2.6.0',
        'exportDate': DateTime.now().toIso8601String(),
        'totalNotes': notes.length,
        'notes': notes.map((n) => n.toJson()).toList(),
      };
      
      final jsonString = jsonEncode(exportData);
      final output = await getTemporaryDirectory();
      final filePath = '${output.path}/quicknote_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      return file;
    } catch (e) {
      debugPrint('Error exportando a JSON: $e');
      return null;
    }
  }

  // ============================================
  // EXPORTAR TEXTO PLANO (Simple)
  // ============================================
  
  String exportToPlainText(Note note) {
    final buffer = StringBuffer();
    buffer.writeln(note.title);
    buffer.writeln('=' * note.title.length);
    buffer.writeln();
    buffer.writeln(note.content.isEmpty ? 'Sin contenido' : note.content);
    buffer.writeln();
    if (note.tags.isNotEmpty) {
      buffer.writeln('Etiquetas: ${note.tags.join(', ')}');
    }
    return buffer.toString();
  }

  // ============================================
  // UTILIDADES
  // ============================================
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  String _sanitizeFilename(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(' ', '_')
        .substring(0, name.length > 50 ? 50 : name.length);
  }
}