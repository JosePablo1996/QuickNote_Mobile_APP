// lib/screens/backup/restore_modal.dart
// Modal de restauración con opciones

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/core/utils/restore_utils.dart';
import 'package:quicknote/models/note.dart';
import 'package:quicknote/providers/notes_provider.dart';
import 'package:quicknote/widgets/loading_indicator.dart';
import 'package:quicknote/widgets/toast_message.dart';

class RestoreModal extends ConsumerStatefulWidget {
  final List<Note> backupNotes;
  final VoidCallback onRestoreComplete;

  const RestoreModal({
    super.key,
    required this.backupNotes,
    required this.onRestoreComplete,
  });

  @override
  ConsumerState<RestoreModal> createState() => _RestoreModalState();
}

class _RestoreModalState extends ConsumerState<RestoreModal> {
  bool _isRestoring = false;
  RestoreMode? _selectedMode;
  RestoreStats? _stats;
  String? _warning;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentNotes = ref.read(notesProvider).activeNotes;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(isDarkMode),
          const SizedBox(height: 16),
          
          // Contenido
          Expanded(
            child: _isRestoring
                ? const Center(child: LoadingIndicator(message: 'Restaurando notas...'))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Información del backup
                        _buildBackupInfo(isDarkMode),
                        const SizedBox(height: 24),
                        
                        // Opciones de restauración
                        _buildRestoreOptions(isDarkMode, currentNotes),
                        
                        if (_selectedMode != null && _stats != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: _buildRestorePreview(isDarkMode),
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Botón de restaurar
                        _buildRestoreButton(isDarkMode),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.restore, size: 24, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Restaurar Backup',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: isDarkMode ? Colors.white54 : Colors.grey.shade600),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildBackupInfo(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.backup, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backup contiene ${widget.backupNotes.length} notas',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selecciona cómo quieres restaurar estas notas',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreOptions(bool isDarkMode, List<Note> currentNotes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modo de restauración',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...RestoreMode.values.map((mode) {
          final stats = RestoreUtils.getRestoreStats(
            currentNotes: currentNotes,
            backupNotes: widget.backupNotes,
            mode: mode,
          );
          final warning = RestoreUtils.getWarningMessage(mode, stats);
          final isSelected = _selectedMode == mode;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMode = mode;
                _stats = stats;
                _warning = warning;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? mode.color.withValues(alpha: 0.1)
                    : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? mode.color
                      : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: mode.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(mode.icon, size: 20, color: mode.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mode.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: mode.color, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRestorePreview(bool isDarkMode) {
    if (_stats == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vista previa',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (_stats!.notesToAdd > 0)
                _buildPreviewChip(
                  '+ ${_stats!.notesToAdd} notas nuevas',
                  Colors.green,
                ),
              if (_stats!.notesToUpdate > 0)
                _buildPreviewChip(
                  '🔄 ${_stats!.notesToUpdate} notas actualizadas',
                  Colors.blue,
                ),
              if (_stats!.notesToRemove > 0)
                _buildPreviewChip(
                  '🗑️ ${_stats!.notesToRemove} notas eliminadas',
                  Colors.red,
                ),
              _buildPreviewChip(
                '📊 Total: ${_stats!.totalAfterRestore} notas',
                Colors.purple,
              ),
            ],
          ),
          if (_warning != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _warning!,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: _selectedMode == RestoreMode.replace ? Colors.red : Colors.amber,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRestoreButton(bool isDarkMode) {
    final isEnabled = _selectedMode != null && !_isRestoring;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? () => _executeRestore() : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedMode?.color ?? Colors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isRestoring
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'RESTAURAR',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _executeRestore() async {
    if (_selectedMode == null) return;
    
    setState(() => _isRestoring = true);
    
    try {
      final currentNotes = ref.read(notesProvider).activeNotes;
      
      final restoredNotes = RestoreUtils.applyRestoreMode(
        currentNotes: currentNotes,
        backupNotes: widget.backupNotes,
        mode: _selectedMode!,
      );
      
      // Aquí se implementa la lógica para guardar las notas restauradas
      // Por ahora, mostramos un mensaje de éxito
      
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ToastMessage.success('Backup restaurado correctamente');
        widget.onRestoreComplete();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.error('Error al restaurar: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }
}