// lib/widgets/restore_options_modal.dart
// Modal para seleccionar modo de restauración

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/core/utils/restore_utils.dart';
import 'package:quicknote/models/note.dart';

class RestoreOptionsModal extends StatelessWidget {
  final List<Note> currentNotes;
  final List<Note> backupNotes;
  final Function(RestoreMode) onConfirm;

  const RestoreOptionsModal({
    super.key,
    required this.currentNotes,
    required this.backupNotes,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
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
                  'Selecciona el modo de restauración',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
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
          ),
          const SizedBox(height: 16),
          
          // Descripción
          Text(
            'Elige cómo quieres restaurar las notas del backup',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          
          // Opciones de restauración
          ...RestoreMode.values.map((mode) {
            final stats = RestoreUtils.getRestoreStats(
              currentNotes: currentNotes,
              backupNotes: backupNotes,
              mode: mode,
            );
            final warning = RestoreUtils.getWarningMessage(mode, stats);
            
            return _buildRestoreOption(
              isDarkMode,
              mode: mode,
              stats: stats,
              warning: warning,
              onTap: () {
                Navigator.pop(context);
                onConfirm(mode);
              },
            );
          }).toList(),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRestoreOption(
    bool isDarkMode, {
    required RestoreMode mode,
    required RestoreStats stats,
    required String? warning,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: mode.color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: mode.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(mode.icon, size: 24, color: mode.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mode.description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildStatChip(
                        '➕ ${stats.notesToAdd} agregar',
                        Colors.green,
                        isDarkMode,
                      ),
                      if (stats.notesToUpdate > 0)
                        _buildStatChip(
                          '🔄 ${stats.notesToUpdate} actualizar',
                          Colors.blue,
                          isDarkMode,
                        ),
                      if (stats.notesToRemove > 0)
                        _buildStatChip(
                          '🗑️ ${stats.notesToRemove} eliminar',
                          Colors.red,
                          isDarkMode,
                        ),
                      _buildStatChip(
                        '📊 Total: ${stats.totalAfterRestore}',
                        Colors.purple,
                        isDarkMode,
                      ),
                    ],
                  ),
                  if (warning != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        warning,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: mode == RestoreMode.replace ? Colors.red : Colors.amber,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: mode.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }
}