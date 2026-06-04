// lib/screens/notes/export_modal.dart
// Modal de exportación avanzada - Similar a la versión web

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/models/note.dart';
import 'package:quicknote/core/services/export_service.dart';
import 'package:quicknote/core/services/share_service.dart';
import 'package:quicknote/widgets/toast_message.dart';

class ExportModal extends ConsumerStatefulWidget {
  final List<Note> notes;
  final VoidCallback? onExportComplete;

  const ExportModal({
    super.key,
    required this.notes,
    this.onExportComplete,
  });

  @override
  ConsumerState<ExportModal> createState() => _ExportModalState();
}

class _ExportModalState extends ConsumerState<ExportModal> {
  // Opciones de exportación
  bool _includePdf = true;
  bool _includeMarkdown = true;
  bool _includeJson = true;
  bool _includeMetadata = true;
  bool _includeTags = true;
  bool _includeDates = true;
  
  // Estado de exportación
  bool _isExporting = false;
  double _exportProgress = 0;
  String _exportStatus = '';
  File? _generatedFile;

  late final ExportService _exportService;
  late final ShareService _shareService;

  @override
  void initState() {
    super.initState();
    _exportService = ExportService();
    _shareService = ShareService();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final totalNotes = widget.notes.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(isDarkMode, totalNotes),
          
          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información de notas
                  _buildNotesInfo(isDarkMode, totalNotes),
                  const SizedBox(height: 24),
                  
                  // Opciones de formato
                  _buildFormatSection(isDarkMode),
                  const SizedBox(height: 24),
                  
                  // Opciones de contenido
                  _buildContentSection(isDarkMode),
                  const SizedBox(height: 24),
                  
                  // Progreso de exportación
                  if (_isExporting) _buildProgressSection(isDarkMode),
                  
                  // Archivo generado
                  if (_generatedFile != null && !_isExporting)
                    _buildFileResult(isDarkMode),
                ],
              ),
            ),
          ),
          
          // Botones de acción
          _buildActionButtons(isDarkMode),
        ],
      ),
    );
  }

  // ============================================
  // HEADER
  // ============================================
  
  Widget _buildHeader(bool isDarkMode, int totalNotes) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF374151) : Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: const Icon(Icons.download, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exportar Notas',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalNotes nota${totalNotes != 1 ? 's' : ''} seleccionada${totalNotes != 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 20, color: isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // INFORMACIÓN DE NOTAS
  // ============================================
  
  Widget _buildNotesInfo(bool isDarkMode, int totalNotes) {
    final totalSize = widget.notes.fold<int>(
      0,
      (sum, note) => sum + note.title.length + note.content.length,
    );
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline, color: Colors.purple, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalNotes notas serán exportadas',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tamaño estimado: ${_formatBytes(totalSize)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // SECCIÓN DE FORMATO
  // ============================================
  
  Widget _buildFormatSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Formato de exportación',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          isDarkMode,
          icon: Icons.picture_as_pdf,
          title: 'PDF',
          subtitle: 'Documento profesional, listo para imprimir',
          color: Colors.red,
          value: _includePdf,
          onChanged: (bool value) => setState(() => _includePdf = value),
        ),
        const SizedBox(height: 8),
        _buildOptionCard(
          isDarkMode,
          icon: Icons.text_fields,
          title: 'Markdown',
          subtitle: 'Formato de texto plano con estilo',
          color: Colors.blue,
          value: _includeMarkdown,
          onChanged: (bool value) => setState(() => _includeMarkdown = value),
        ),
        const SizedBox(height: 8),
        _buildOptionCard(
          isDarkMode,
          icon: Icons.code,
          title: 'JSON',
          subtitle: 'Datos estructurados para desarrollo',
          color: Colors.green,
          value: _includeJson,
          onChanged: (bool value) => setState(() => _includeJson = value),
        ),
      ],
    );
  }

  // ============================================
  // SECCIÓN DE CONTENIDO
  // ============================================
  
  Widget _buildContentSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Opciones de contenido',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildContentOption(
          isDarkMode,
          title: 'Incluir metadatos',
          subtitle: 'Fecha de creación, actualización, etc.',
          value: _includeMetadata,
          onChanged: (bool? value) => setState(() => _includeMetadata = value ?? false),
        ),
        _buildContentOption(
          isDarkMode,
          title: 'Incluir etiquetas',
          subtitle: 'Todas las etiquetas de las notas',
          value: _includeTags,
          onChanged: (bool? value) => setState(() => _includeTags = value ?? false),
        ),
        _buildContentOption(
          isDarkMode,
          title: 'Incluir fechas',
          subtitle: 'Fechas de creación y modificación',
          value: _includeDates,
          onChanged: (bool? value) => setState(() => _includeDates = value ?? false),
        ),
      ],
    );
  }

  // ============================================
  // PROGRESO DE EXPORTACIÓN
  // ============================================
  
  Widget _buildProgressSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF374151) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_empty, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _exportStatus,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ),
              Text(
                '${_exportProgress.toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _exportProgress / 100,
              backgroundColor: isDarkMode ? Colors.white24 : Colors.grey.shade300,
              color: Colors.purple,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // RESULTADO DE EXPORTACIÓN
  // ============================================
  
  Widget _buildFileResult(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exportación completada',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _generatedFile!.path.split('/').last,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _shareFile(_generatedFile!),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.share, color: Colors.teal, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BOTONES DE ACCIÓN
  // ============================================
  
  Widget _buildActionButtons(bool isDarkMode) {
    final hasFormats = _includePdf || _includeMarkdown || _includeJson;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isExporting ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
                ),
              ),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isExporting || !hasFormats ? null : _startExport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'EXPORTAR',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // EXPORTACIÓN PRINCIPAL
  // ============================================
  
  Future<void> _startExport() async {
    if (!mounted) return;
    
    setState(() {
      _isExporting = true;
      _exportProgress = 0;
      _exportStatus = 'Preparando archivos...';
      _generatedFile = null;
    });

    // Simular progreso para mejor UX
    _simulateProgress();

    try {
      final result = await _exportService.exportToZip(
        notes: widget.notes,
        includePdf: _includePdf,
        includeMarkdown: _includeMarkdown,
        includeJson: _includeJson,
      );

      if (mounted && result != null) {
        setState(() {
          _generatedFile = result;
          _exportProgress = 100;
          _exportStatus = '¡Exportación completada!';
          _isExporting = false;
        });
        
        widget.onExportComplete?.call();
      } else if (mounted) {
        throw Exception('Error al generar el archivo');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        ToastMessage.error('Error: ${e.toString()}');
      }
    }
  }

  void _simulateProgress() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isExporting) {
        setState(() {
          _exportProgress = 30;
          _exportStatus = 'Generando archivos...';
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _isExporting) {
        setState(() {
          _exportProgress = 60;
          _exportStatus = 'Comprimiendo...';
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _isExporting) {
        setState(() {
          _exportProgress = 80;
          _exportStatus = 'Finalizando...';
        });
      }
    });
  }

  Future<void> _shareFile(File file) async {
    final fileName = file.path.split('/').last;
    final mimeType = fileName.endsWith('.zip') 
        ? 'application/zip'
        : fileName.endsWith('.pdf')
            ? 'application/pdf'
            : 'application/octet-stream';
    
    await _shareService.shareNoteAsFile(file, fileName, mimeType);
    if (mounted) {
      ToastMessage.success('Compartiendo archivo...');
    }
  }

  // ============================================
  // WIDGETS AUXILIARES
  // ============================================
  
  Widget _buildOptionCard(
    bool isDarkMode, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF374151) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? color.withValues(alpha: 0.5) : (isDarkMode ? Colors.white24 : Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildContentOption(
    bool isDarkMode, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
        ),
      ),
      activeColor: Colors.purple,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}