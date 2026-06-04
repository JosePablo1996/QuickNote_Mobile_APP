// lib/screens/backup/backup_local_screen.dart
// Pantalla de gestión de backups locales - VERSIÓN CORREGIDA
// ✅ CORREGIDO: Restauración de backups funciona correctamente
// ✅ CORREGIDO: Usa replaceAllNotes en lugar de loadNotes
// ✅ CORREGIDO: Overflow en estadísticas
// ✅ CORREGIDO: Filtro de backups locales (source == 'local' o source == null)
// ✅ CORREGIDO: Diseño responsivo sin desbordamientos
// ✅ CORREGIDO: Recarga automática después de crear/eliminar/restaurar

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/providers/backup_provider.dart';
import 'package:quicknote/providers/notes_provider.dart';
import 'package:quicknote/widgets/loading_indicator.dart';
import 'package:quicknote/widgets/toast_message.dart';
import 'package:quicknote/core/services/backup_service.dart';
import 'package:quicknote/models/note.dart';
import 'dart:async';

class _BackupLocalScreenLogger {
  static void info(String message) => debugPrint('ℹ️ [BackupLocalScreen] $message');
  static void success(String message) => debugPrint('✅ [BackupLocalScreen] $message');
  static void error(String message) => debugPrint('❌ [BackupLocalScreen] $message');
}

// ============================================
// TARJETA DE BACKUP LOCAL - RESPONSIVA
// ============================================

class LocalBackupCard extends StatelessWidget {
  final Map<String, dynamic> backup;
  final bool isSelected;
  final bool isLatest;
  final VoidCallback onTap;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final VoidCallback onDownload;
  final VoidCallback? onSelect;

  const LocalBackupCard({
    super.key,
    required this.backup,
    required this.isSelected,
    required this.isLatest,
    required this.onTap,
    required this.onRestore,
    required this.onDelete,
    required this.onDownload,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final fileName = backup['file_name'] as String;
    final noteCount = backup['note_count'] as int;
    final fileSize = backup['file_size'] as int;
    final createdAt = DateTime.parse(backup['created_at'] as String);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B5CF6)
                : (isDarkMode ? Colors.white24 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (onSelect != null)
              Checkbox(
                value: isSelected,
                onChanged: (_) => onSelect!(),
                activeColor: const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(
                color: isLatest
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isLatest ? Icons.cloud_done : Icons.file_present,
                size: isSmallScreen ? 18 : 20,
                color: isLatest ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fileName,
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLatest)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'ÚLTIMO',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _buildInfoChip(Icons.note, '$noteCount notas', isDarkMode, isSmallScreen),
                      _buildInfoChip(Icons.storage, _formatFileSize(fileSize), isDarkMode, isSmallScreen),
                      _buildInfoChip(Icons.calendar_today, _formatDate(createdAt), isDarkMode, isSmallScreen),
                    ],
                  ),
                ],
              ),
            ),
            if (onSelect == null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    icon: Icons.restore,
                    color: Colors.green,
                    onTap: onRestore,
                    tooltip: 'Restaurar',
                    isSmallScreen: isSmallScreen,
                  ),
                  _buildActionButton(
                    icon: Icons.download,
                    color: Colors.blue,
                    onTap: onDownload,
                    tooltip: 'Descargar',
                    isSmallScreen: isSmallScreen,
                  ),
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    onTap: onDelete,
                    tooltip: 'Eliminar',
                    isSmallScreen: isSmallScreen,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, bool isDarkMode, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 9 : 10, color: isDarkMode ? Colors.white54 : Colors.grey.shade600),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 8 : 10,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
    required bool isSmallScreen,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      child: IconButton(
        icon: Icon(icon, size: isSmallScreen ? 16 : 18, color: color),
        onPressed: onTap,
        tooltip: tooltip,
        constraints: const BoxConstraints(),
        padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ============================================
// MODAL DE PROGRESO - RESPONSIVO
// ============================================

class ProgressModal extends StatelessWidget {
  final double progress;
  final String message;

  const ProgressModal({
    super.key,
    required this.progress,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: isSmallScreen ? screenWidth * 0.85 : 300,
        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: isSmallScreen ? 32 : 40,
              height: isSmallScreen ? 32 : 40,
              child: const CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                color: const Color(0xFF8B5CF6),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.toInt()}%',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 10 : 12,
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// PANTALLA PRINCIPAL - VERSIÓN CORREGIDA
// ============================================

class BackupLocalScreen extends ConsumerStatefulWidget {
  const BackupLocalScreen({super.key});

  @override
  ConsumerState<BackupLocalScreen> createState() => _BackupLocalScreenState();
}

class _BackupLocalScreenState extends ConsumerState<BackupLocalScreen> {
  final Set<String> _selectedBackupIds = {};
  bool _isSelectionMode = false;
  bool _isDeletingSelected = false;
  double _progress = 0;
  String _progressMessage = '';
  bool _showProgress = false;
  bool _isNavigating = false;
  bool _isCreating = false;

  void _goBack() {
    if (_isNavigating) return;
    _isNavigating = true;
    
    _BackupLocalScreenLogger.info('🔙 Navegando de vuelta a notas');
    
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      try {
        context.go('/notes');
        _BackupLocalScreenLogger.success('✅ Navegación exitosa');
      } catch (e) {
        _BackupLocalScreenLogger.error('Error: $e');
      } finally {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _isNavigating = false;
        });
      }
    });
  }

  Future<void> _refreshBackups() async {
    _BackupLocalScreenLogger.info('🔄 Recargando backups locales...');
    await ref.read(backupProvider.notifier).loadBackups();
    _BackupLocalScreenLogger.success('✅ Backups recargados');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backupState = ref.watch(backupProvider);
    final notesState = ref.watch(notesProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    final allBackups = backupState.backups;
    final localBackups = allBackups
        .where((b) => b.source == 'local' || b.source == null)
        .toList();
    
    _BackupLocalScreenLogger.info('📦 Total backups: ${allBackups.length}');
    _BackupLocalScreenLogger.info('📦 Backups locales filtrados: ${localBackups.length}');

    final totalSize = localBackups.fold<int>(0, (sum, b) => sum + b.fileSize);
    final limitInfo = backupState.limitInfo;
    final current = localBackups.length;
    final max = limitInfo?.max ?? 20;
    final remaining = max - current;

    if (backupState.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: LoadingIndicator(message: 'Cargando backups locales...')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack();
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.transparent,
            body: RefreshIndicator(
              onRefresh: _refreshBackups,
              child: CustomScrollView(
                slivers: [
                  // Header de estadísticas - CORREGIDO
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: _buildStatsHeader(
                        isDarkMode: isDarkMode,
                        current: current,
                        max: max,
                        remaining: remaining,
                        totalSize: totalSize,
                        totalNotes: notesState.notes.length,
                        hasBackups: localBackups.isNotEmpty,
                        onSelectMode: () => setState(() => _isSelectionMode = true),
                        isSelectionMode: _isSelectionMode,
                        onCreateBackup: _createBackup,
                        isCreating: _isCreating,
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                  ),
                  
                  // Barra de selección múltiple
                  if (_isSelectionMode)
                    SliverToBoxAdapter(
                      child: _buildSelectionBar(
                        isDarkMode: isDarkMode,
                        totalBackups: localBackups.length,
                        selectedCount: _selectedBackupIds.length,
                        isAllSelected: _selectedBackupIds.length == localBackups.length && localBackups.isNotEmpty,
                        onSelectAll: () {
                          setState(() {
                            if (_selectedBackupIds.length == localBackups.length) {
                              _selectedBackupIds.clear();
                            } else {
                              _selectedBackupIds.addAll(localBackups.map((b) => b.id));
                            }
                          });
                        },
                        onCancel: () => setState(() {
                          _selectedBackupIds.clear();
                          _isSelectionMode = false;
                        }),
                        onDeleteSelected: _deleteSelectedBackups,
                        isDeletingSelected: _isDeletingSelected,
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                  
                  // Barra de acciones
                  if (!_isSelectionMode && localBackups.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildActionsBar(
                        isDarkMode: isDarkMode,
                        onImport: _importBackup,
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                  
                  // Lista de backups
                  if (localBackups.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(
                        isDarkMode,
                        onCreateBackup: _createBackup,
                        isCreating: _isCreating,
                        isSmallScreen: isSmallScreen,
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final backup = localBackups[index];
                          final isSelected = _selectedBackupIds.contains(backup.id);
                          final isLatest = index == 0;
                          
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 12 : 16,
                              vertical: 4,
                            ),
                            child: LocalBackupCard(
                              backup: {
                                'id': backup.id,
                                'file_name': backup.fileName,
                                'note_count': backup.noteCount,
                                'file_size': backup.fileSize,
                                'created_at': backup.createdAt.toIso8601String(),
                              },
                              isSelected: isSelected,
                              isLatest: isLatest,
                              onTap: _isSelectionMode
                                  ? () => _toggleSelection(backup.id)
                                  : () {},
                              onRestore: () => _restoreBackup(backup.id),
                              onDelete: () => _deleteBackup(backup.id),
                              onDownload: () => _downloadBackup(backup),
                              onSelect: _isSelectionMode ? () => _toggleSelection(backup.id) : null,
                            ),
                          );
                        },
                        childCount: localBackups.length,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Modal de progreso
          if (_showProgress)
            Center(
              child: ProgressModal(
                progress: _progress,
                message: _progressMessage,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader({
    required bool isDarkMode,
    required int current,
    required int max,
    required int remaining,
    required int totalSize,
    required int totalNotes,
    required bool hasBackups,
    required VoidCallback onSelectMode,
    required bool isSelectionMode,
    required VoidCallback onCreateBackup,
    required bool isCreating,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF1F2937), const Color(0xFF374151)]
              : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Estadísticas en fila horizontal (sin GridView para evitar overflow)
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Backups',
                  '$current',
                  isDarkMode,
                  icon: Icons.backup,
                  color: Colors.blue,
                  isSmallScreen: isSmallScreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Notas',
                  '$totalNotes',
                  isDarkMode,
                  icon: Icons.note,
                  color: Colors.green,
                  isSmallScreen: isSmallScreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Espacio',
                  _formatFileSize(totalSize),
                  isDarkMode,
                  icon: Icons.storage,
                  color: Colors.orange,
                  isSmallScreen: isSmallScreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: current / max,
              backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              color: remaining <= 2 ? Colors.orange : Colors.green,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$current / $max backups',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 9 : 10,
                  color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              if (remaining <= 2 && remaining > 0)
                Text(
                  '⚠️ Quedan $remaining',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 9 : 10,
                    color: Colors.orange,
                  ),
                ),
              if (remaining <= 0)
                Text(
                  '🔴 Límite',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 9 : 10,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (remaining <= 0 || isCreating) ? null : onCreateBackup,
                  icon: isCreating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(Icons.backup, size: isSmallScreen ? 16 : 18),
                  label: Text(
                    isSmallScreen ? 'NUEVO' : 'NUEVO BACKUP',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 11 : 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (!isSelectionMode && hasBackups)
                Padding(
                  padding: EdgeInsets.only(left: isSmallScreen ? 8 : 12),
                  child: OutlinedButton.icon(
                    onPressed: onSelectMode,
                    icon: Icon(Icons.checklist, size: isSmallScreen ? 16 : 18),
                    label: Text(
                      isSmallScreen ? 'SELEC' : 'SELECCIONAR',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 11 : 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade400),
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 10 : 12,
                        horizontal: isSmallScreen ? 12 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDarkMode, {
    required IconData icon,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 10, horizontal: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: isSmallScreen ? 14 : 16, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 9 : 10,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar({
    required bool isDarkMode,
    required int totalBackups,
    required int selectedCount,
    required bool isAllSelected,
    required VoidCallback onSelectAll,
    required VoidCallback onCancel,
    required VoidCallback onDeleteSelected,
    required bool isDeletingSelected,
    required bool isSmallScreen,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onSelectAll,
            icon: Icon(
              isAllSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: Colors.white,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),
          Text(
            isSmallScreen ? '$selectedCount' : '$selectedCount seleccionado${selectedCount != 1 ? 's' : ''}',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 11 : 13,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: Text(
              isSmallScreen ? 'X' : 'CANCELAR',
              style: TextStyle(color: Colors.white70, fontSize: isSmallScreen ? 11 : 12),
            ),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: onDeleteSelected,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
            ),
            child: isDeletingSelected
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(isSmallScreen ? 'DEL' : 'ELIMINAR', style: TextStyle(fontSize: isSmallScreen ? 10 : 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsBar({
    required bool isDarkMode,
    required VoidCallback onImport,
    required bool isSmallScreen,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
      child: OutlinedButton.icon(
        onPressed: onImport,
        icon: const Icon(Icons.upload_file, size: 16),
        label: const Text('IMPORTAR BACKUP'),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade400),
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode, {required VoidCallback onCreateBackup, required bool isCreating, required bool isSmallScreen}) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isSmallScreen ? 80 : 100,
              height: isSmallScreen ? 80 : 100,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
                ),
              ),
              child: Icon(Icons.backup, size: isSmallScreen ? 40 : 50, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(
              'No hay backups locales',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer backup para proteger tus notas',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 11 : 13,
                color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isCreating ? null : onCreateBackup,
              icon: isCreating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.backup, size: 16),
              label: Text(isSmallScreen ? 'CREAR BACKUP' : 'CREAR PRIMER BACKUP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ACCIONES - CORREGIDAS CON replaceAllNotes
  // ============================================

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedBackupIds.contains(id)) {
        _selectedBackupIds.remove(id);
        if (_selectedBackupIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedBackupIds.add(id);
      }
    });
  }

  Future<void> _createBackup() async {
    final notes = ref.read(notesProvider).notes;
    if (notes.isEmpty) {
      ToastMessage.warning('No hay notas para respaldar');
      return;
    }

    setState(() {
      _isCreating = true;
      _showProgress = true;
      _progress = 0;
      _progressMessage = 'Preparando backup...';
    });

    final timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_progress < 90 && mounted) {
        setState(() {
          _progress += 5;
          if (_progress < 30) {
            _progressMessage = 'Preparando notas...';
          } else if (_progress < 60) {
            _progressMessage = 'Comprimiendo datos...';
          } else if (_progress < 90) {
            _progressMessage = 'Generando archivo...';
          }
        });
      }
    });

    try {
      final backupService = BackupService();
      await backupService.init();
      final result = await backupService.createBackup(notes);

      timer.cancel();
      if (mounted) {
        setState(() {
          _progress = 100;
          _progressMessage = '¡Completado!';
        });
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _showProgress = false;
          _isCreating = false;
        });
        
        if (result != null) {
          ToastMessage.success('✅ Backup creado correctamente');
          await _refreshBackups();
        } else {
          ToastMessage.error('Error al crear backup');
        }
      }
    } catch (e) {
      timer.cancel();
      if (mounted) {
        setState(() {
          _showProgress = false;
          _isCreating = false;
        });
        ToastMessage.error('Error al crear backup: ${e.toString()}');
      }
    }
  }

  // ✅ CORREGIDO: Restauración de backup LOCAL usando replaceAllNotes
  Future<void> _restoreBackup(String id) async {
    final confirmed = await _showConfirmDialog(
      'Restaurar backup',
      '¿Restaurar este backup? Se reemplazarán TODAS las notas actuales por las del backup. Esta acción NO se puede deshacer.',
    );
    if (!confirmed) return;

    if (!mounted) return;

    setState(() {
      _showProgress = true;
      _progress = 0;
      _progressMessage = 'Restaurando backup...';
    });

    final timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_progress < 90 && mounted) {
        setState(() => _progress += 10);
      }
    });

    try {
      final backupService = BackupService();
      await backupService.init();
      
      // 1. Obtener las notas del backup
      final restoredNotes = await backupService.restoreBackup(id);
      
      timer.cancel();
      
      if (mounted) {
        setState(() {
          _progress = 100;
          _progressMessage = '¡Restauración completada!';
        });
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && restoredNotes.isNotEmpty) {
        // 2. ✅ CORREGIDO: Usar replaceAllNotes en lugar de loadNotes
        final notesNotifier = ref.read(notesProvider.notifier);
        await notesNotifier.replaceAllNotes(restoredNotes);
        
        // 3. Mostrar mensaje de éxito
        ToastMessage.success('✅ ${restoredNotes.length} notas restauradas correctamente');
        _BackupLocalScreenLogger.success('✅ Backup restaurado: ${restoredNotes.length} notas');
        
        // 4. Recargar la lista de backups
        await _refreshBackups();
        
        // 5. Volver a la pantalla de notas después de un momento
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _goBack();
          }
        });
      } else if (mounted) {
        ToastMessage.warning('No se encontraron notas en el backup');
      }
    } catch (e) {
      timer.cancel();
      if (mounted) {
        setState(() => _showProgress = false);
        ToastMessage.error('Error al restaurar backup: ${e.toString()}');
        _BackupLocalScreenLogger.error('❌ Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _showProgress = false);
      }
    }
  }

  Future<void> _deleteBackup(String id) async {
    final confirmed = await _showConfirmDialog(
      'Eliminar backup',
      '¿Eliminar este backup permanentemente?',
    );
    if (!confirmed) return;

    if (!mounted) return;

    await ref.read(backupProvider.notifier).deleteBackup(id);
    ToastMessage.success('✅ Backup eliminado correctamente');
    await _refreshBackups();
  }

  Future<void> _deleteSelectedBackups() async {
    final confirmed = await _showConfirmDialog(
      'Eliminar seleccionados',
      '¿Eliminar ${_selectedBackupIds.length} backup${_selectedBackupIds.length != 1 ? 's' : ''} permanentemente?',
    );
    if (!confirmed) return;

    if (!mounted) return;

    setState(() => _isDeletingSelected = true);

    for (final id in _selectedBackupIds) {
      await ref.read(backupProvider.notifier).deleteBackup(id);
    }

    if (mounted) {
      setState(() {
        _selectedBackupIds.clear();
        _isSelectionMode = false;
        _isDeletingSelected = false;
      });
      
      ToastMessage.success('✅ Backups eliminados correctamente');
      await _refreshBackups();
    }
  }

  void _downloadBackup(dynamic backup) {
    ToastMessage.info('Descargando ${backup.fileName}...');
  }

  void _importBackup() async {
    ToastMessage.info('Importación de backup - Próximamente');
  }

  // ============================================
  // UTILIDADES
  // ============================================

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Aceptar', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    ) ?? false;
  }
}