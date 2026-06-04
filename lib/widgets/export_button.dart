// lib/widgets/export_button.dart
// Botón de exportación con menú desplegable
// ✅ Integración con ExportZipService para exportación a ZIP

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicknote/models/note.dart';
import 'package:quicknote/providers/notes_provider.dart';
import 'package:quicknote/core/services/export_service.dart';
import 'package:quicknote/core/services/export_zip_service.dart';
import 'package:quicknote/core/services/share_service.dart';
import 'package:quicknote/core/services/clipboard_service.dart';
import 'package:quicknote/screens/notes/export_modal.dart';
import 'package:quicknote/widgets/toast_message.dart';

class ExportButton extends ConsumerStatefulWidget {
  final Note? note;
  final List<Note>? notes;
  final bool showLabel;
  final Color? iconColor;
  final double iconSize;

  const ExportButton({
    super.key,
    this.note,
    this.notes,
    this.showLabel = false,
    this.iconColor,
    this.iconSize = 20,
  });

  @override
  ConsumerState<ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends ConsumerState<ExportButton> {
  bool _isExporting = false;
  
  late final ExportService _exportService;
  late final ShareService _shareService;
  late final ClipboardService _clipboardService;

  @override
  void initState() {
    super.initState();
    _exportService = ExportService();
    _shareService = ShareService();
    _clipboardService = ClipboardService();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final notes = _getNotes();

    if (notes.isEmpty) {
      return Tooltip(
        message: 'No hay notas para exportar',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.download_outlined,
                size: widget.iconSize,
                color: Colors.grey,
              ),
              if (widget.showLabel) ...[
                const SizedBox(width: 6),
                const Text(
                  'Exportar',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Exportar notas',
      offset: const Offset(0, 40),
      color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.purple.shade800, Colors.purple.shade900]
                : [Colors.purple.shade400, Colors.purple.shade600],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isExporting)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                Icons.download_outlined,
                size: widget.iconSize,
                color: widget.iconColor ?? Colors.white,
              ),
            if (widget.showLabel) ...[
              const SizedBox(width: 6),
              Text(
                'Exportar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.iconColor ?? Colors.white,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
            ],
          ],
        ),
      ),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'pdf_single',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, size: 18, color: Colors.red),
              SizedBox(width: 12),
              Expanded(child: Text('Exportar a PDF')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pdf_all',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, size: 18, color: Colors.red),
              SizedBox(width: 12),
              Expanded(child: Text('Exportar todas a PDF')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'markdown',
          child: Row(
            children: [
              Icon(Icons.text_fields, size: 18, color: Colors.blue),
              SizedBox(width: 12),
              Expanded(child: Text('Exportar a Markdown')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'json',
          child: Row(
            children: [
              Icon(Icons.code, size: 18, color: Colors.green),
              SizedBox(width: 12),
              Expanded(child: Text('Exportar a JSON (Backup)')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'zip',
          child: Row(
            children: [
              Icon(Icons.folder_zip, size: 18, color: Colors.orange),
              SizedBox(width: 12),
              Expanded(child: Text('Exportar a ZIP (MD+JSON)')),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 18, color: Colors.teal),
              SizedBox(width: 12),
              Expanded(child: Text('Compartir nota')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy, size: 18, color: Colors.purple),
              SizedBox(width: 12),
              Expanded(child: Text('Copiar al portapapeles')),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'advanced',
          child: Row(
            children: [
              Icon(Icons.settings, size: 18, color: Colors.grey),
              SizedBox(width: 12),
              Expanded(child: Text('Opciones avanzadas...')),
            ],
          ),
        ),
      ],
      onSelected: (value) => _handleExport(value),
    );
  }

  List<Note> _getNotes() {
    if (widget.notes != null && widget.notes!.isNotEmpty) {
      return widget.notes!;
    }
    if (widget.note != null) {
      return [widget.note!];
    }
    
    final notesState = ref.read(notesProvider);
    return notesState.activeNotes;
  }

  Future<void> _handleExport(String value) async {
    if (_isExporting) return;
    
    final notes = _getNotes();
    if (notes.isEmpty) {
      if (mounted) ToastMessage.warning('No hay notas para exportar');
      return;
    }

    switch (value) {
      case 'pdf_single':
        await _exportPdfSingle(notes.first);
        break;
      case 'pdf_all':
        await _exportPdfAll(notes);
        break;
      case 'markdown':
        await _exportMarkdown(notes.first);
        break;
      case 'json':
        await _exportJson(notes);
        break;
      case 'zip':
        await _exportZip(notes);
        break;
      case 'share':
        await _shareNote(notes.first);
        break;
      case 'copy':
        await _copyNote(notes.first);
        break;
      case 'advanced':
        await _showAdvancedModal(notes);
        break;
    }
  }

  Future<void> _exportPdfSingle(Note note) async {
    setState(() => _isExporting = true);
    
    try {
      final pdfFile = await _exportService.exportNoteToPdf(note);
      
      if (pdfFile != null && mounted) {
        ToastMessage.success('PDF exportado correctamente');
        _showShareOptions(pdfFile, '${note.title}.pdf');
      } else if (mounted) {
        ToastMessage.error('Error al exportar PDF');
      }
    } catch (e) {
      if (mounted) ToastMessage.error('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPdfAll(List<Note> notes) async {
    setState(() => _isExporting = true);
    
    try {
      final pdfFile = await _exportService.exportMultipleNotesToPdf(notes);
      
      if (pdfFile != null && mounted) {
        ToastMessage.success('${notes.length} notas exportadas a PDF');
        _showShareOptions(pdfFile, 'quicknote_export.pdf');
      } else if (mounted) {
        ToastMessage.error('Error al exportar PDF');
      }
    } catch (e) {
      if (mounted) ToastMessage.error('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportMarkdown(Note note) async {
    setState(() => _isExporting = true);
    
    try {
      final mdFile = await _exportService.exportToMarkdownFile(note);
      
      if (mdFile != null && mounted) {
        ToastMessage.success('Markdown exportado correctamente');
        _showShareOptions(mdFile, '${note.title}.md');
      } else if (mounted) {
        ToastMessage.error('Error al exportar Markdown');
      }
    } catch (e) {
      if (mounted) ToastMessage.error('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportJson(List<Note> notes) async {
    setState(() => _isExporting = true);
    
    try {
      final jsonFile = await _exportService.exportToJson(notes);
      
      if (jsonFile != null && mounted) {
        ToastMessage.success('JSON exportado correctamente');
        _showShareOptions(jsonFile, 'quicknote_backup.json');
      } else if (mounted) {
        ToastMessage.error('Error al exportar JSON');
      }
    } catch (e) {
      if (mounted) ToastMessage.error('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportZip(List<Note> notes) async {
    setState(() => _isExporting = true);
    
    try {
      final zipPath = await exportZipService.exportNotesToZip(
        notes: notes,
        exportName: 'quicknote_export',
        onProgressCallback: (progress) {
          if (mounted) {
            debugPrint('Progreso ZIP: ${progress.percentage}% - ${progress.currentNoteTitle}');
          }
        },
      );
      
      if (zipPath != null && mounted) {
        ToastMessage.success('ZIP exportado correctamente');
        _showZipOptions(File(zipPath), 'quicknote_export.zip');
      } else if (mounted) {
        ToastMessage.error('Error al exportar ZIP');
      }
    } catch (e) {
      if (mounted) ToastMessage.error('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showZipOptions(File zipFile, String fileName) {
    if (!mounted) return;
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ZIP generado correctamente',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              fileName,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildShareOption(
                    icon: Icons.share,
                    label: 'Compartir',
                    color: Colors.teal,
                    onTap: () async {
                      Navigator.pop(context);
                      await exportZipService.shareZip();
                    },
                  ),
                ),
                Expanded(
                  child: _buildShareOption(
                    icon: Icons.save_alt,
                    label: 'Guardar',
                    color: Colors.blue,
                    onTap: () async {
                      Navigator.pop(context);
                      final savedPath = await exportZipService.saveZipToDownloads();
                      if (savedPath != null && mounted) {
                        ToastMessage.success('ZIP guardado en Descargas');
                      } else if (mounted) {
                        ToastMessage.error('Error al guardar ZIP');
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _shareNote(Note note) async {
    setState(() => _isExporting = true);
    
    try {
      await _shareService.shareNoteAsText(note);
    } catch (e) {
      if (mounted) ToastMessage.error('Error al compartir: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _copyNote(Note note) async {
    setState(() => _isExporting = true);
    
    try {
      final success = await _clipboardService.copyNote(note);
      
      if (success && mounted) {
        ToastMessage.success('Nota copiada al portapapeles');
      } else if (mounted) {
        ToastMessage.error('Error al copiar la nota');
      }
    } catch (e) {
      if (mounted) ToastMessage.error('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _showAdvancedModal(List<Note> notes) async {
    if (!mounted) return;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ExportModal(
        notes: notes,
        onExportComplete: () {
          if (mounted) ToastMessage.success('Exportación completada');
        },
      ),
    );
  }

  void _showShareOptions(File file, String fileName) {
    if (!mounted) return;
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Archivo generado correctamente',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              fileName,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildShareOption(
                    icon: Icons.share,
                    label: 'Compartir',
                    color: Colors.teal,
                    onTap: () async {
                      Navigator.pop(context);
                      final mimeType = fileName.endsWith('.pdf')
                          ? 'application/pdf'
                          : fileName.endsWith('.md')
                              ? 'text/markdown'
                              : 'application/json';
                      await _shareService.shareNoteAsFile(file, fileName, mimeType);
                    },
                  ),
                ),
                Expanded(
                  child: _buildShareOption(
                    icon: Icons.save_alt,
                    label: 'Guardar',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      ToastMessage.success('Archivo guardado en: ${file.path}');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}