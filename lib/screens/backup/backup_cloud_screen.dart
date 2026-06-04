// lib/screens/backup/backup_cloud_screen.dart
// Pantalla de gestión de backups en la nube - VERSIÓN CORREGIDA
// ✅ CORREGIDO: Restauración de backups desde la nube funciona correctamente
// ✅ CORREGIDO: Usa restoreFromBackup en lugar de replaceAllNotes
// ✅ CORREGIDO: Null safety en los métodos
// ✅ CORREGIDO: Uso correcto de mounted en async gaps
// ✅ CORREGIDO: Const constructors
// ✅ CORREGIDO: Eliminación de backups (extrae ID sin prefijo 'cloud_')

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/providers/backup_provider.dart';
import 'package:quicknote/providers/notes_provider.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:quicknote/widgets/loading_indicator.dart';
import 'package:quicknote/widgets/toast_message.dart';
import 'package:quicknote/core/services/backup_cloud_service.dart';
import 'package:quicknote/models/note.dart';
import 'dart:async';

// ============================================
// LOGGER
// ============================================

class _BackupCloudScreenLogger {
  static void info(String message) => debugPrint('ℹ️ [BackupCloudScreen] $message');
  static void success(String message) => debugPrint('✅ [BackupCloudScreen] $message');
  static void error(String message) => debugPrint('❌ [BackupCloudScreen] $message');
}

// ============================================
// TARJETA DE BACKUP EN LA NUBE
// ============================================

class CloudBackupCard extends StatelessWidget {
  final Map<String, dynamic> backup;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final VoidCallback onDownload;
  final VoidCallback? onSelect;

  const CloudBackupCard({
    super.key,
    required this.backup,
    required this.isSelected,
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
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: const Icon(
                Icons.cloud,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                    icon: Icons.cloud_download,
                    color: Colors.green,
                    onTap: onRestore,
                    tooltip: 'Restaurar',
                  ),
                  _buildActionButton(
                    icon: Icons.download,
                    color: Colors.blue,
                    onTap: onDownload,
                    tooltip: 'Descargar',
                  ),
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    onTap: onDelete,
                    tooltip: 'Eliminar',
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
          Icon(icon, size: 10, color: isDarkMode ? Colors.white54 : Colors.grey.shade600),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 9 : 10,
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
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onTap,
        tooltip: tooltip,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(6),
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
// MODAL DE PROGRESO
// ============================================

class CloudProgressModal extends StatelessWidget {
  final double progress;
  final String message;

  const CloudProgressModal({
    super.key,
    required this.progress,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
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
                fontSize: 12,
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
// MODAL DE SELECCIÓN DE BACKUP SELECTIVO
// ============================================

class SelectiveBackupModal extends StatefulWidget {
  final List<Note> notes;
  final Function(List<String>) onConfirm;

  const SelectiveBackupModal({
    super.key,
    required this.notes,
    required this.onConfirm,
  });

  @override
  State<SelectiveBackupModal> createState() => _SelectiveBackupModalState();
}

class _SelectiveBackupModalState extends State<SelectiveBackupModal> {
  final Set<String> _selectedNoteIds = {};
  String _searchQuery = '';

  List<Note> get _filteredNotes {
    if (_searchQuery.isEmpty) return widget.notes;
    return widget.notes.where((note) =>
      note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      note.content.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: screenWidth * 0.9,
        height: screenHeight * 0.8,
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Icon(Icons.cloud_upload, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Backup Selectivo',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Selecciona las notas que quieres respaldar',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 9 : 11,
                          color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Barra de búsqueda
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar notas...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Acciones rápidas
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  label: isSmallScreen ? 'Todas' : 'Seleccionar todas',
                  icon: Icons.check_box,
                  onTap: () => setState(() {
                    _selectedNoteIds.clear();
                    _selectedNoteIds.addAll(_filteredNotes.map((n) => n.id));
                  }),
                  isDarkMode: isDarkMode,
                  isSmallScreen: isSmallScreen,
                ),
                _buildActionChip(
                  label: isSmallScreen ? 'Limpiar' : 'Limpiar selección',
                  icon: Icons.cleaning_services,
                  onTap: () => setState(() => _selectedNoteIds.clear()),
                  isDarkMode: isDarkMode,
                  isSmallScreen: isSmallScreen,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Lista de notas
            Expanded(
              child: ListView.builder(
                itemCount: _filteredNotes.length,
                itemBuilder: (context, index) {
                  final note = _filteredNotes[index];
                  final isSelected = _selectedNoteIds.contains(note.id);
                  
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedNoteIds.add(note.id);
                        } else {
                          _selectedNoteIds.remove(note.id);
                        }
                      });
                    },
                    title: Text(
                      note.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      note.content.length > 80
                          ? '${note.content.substring(0, 80)}...'
                          : note.content,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondary: note.isFavorite
                        ? const Icon(Icons.star, color: Colors.amber, size: 16)
                        : null,
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    activeColor: const Color(0xFF8B5CF6),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                },
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Cancelar', style: GoogleFonts.poppins(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedNoteIds.isEmpty
                        ? null
                        : () {
                            widget.onConfirm(_selectedNoteIds.toList());
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Guardar (${_selectedNoteIds.length})',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkMode,
    required bool isSmallScreen,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12, vertical: 5),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isSmallScreen ? 12 : 14, color: const Color(0xFF8B5CF6)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 10 : 11,
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

class BackupCloudScreen extends ConsumerStatefulWidget {
  const BackupCloudScreen({super.key});

  @override
  ConsumerState<BackupCloudScreen> createState() => _BackupCloudScreenState();
}

class _BackupCloudScreenState extends ConsumerState<BackupCloudScreen> {
  final Set<String> _selectedBackupIds = {};
  bool _isSelectionMode = false;
  bool _isSyncing = false;
  bool _isSaving = false;
  bool _isDeletingSelected = false;
  double _progress = 0;
  String _progressMessage = '';
  bool _showProgress = false;
  bool _isNavigating = false;
  
  late final BackupCloudService _cloudService;

  @override
  void initState() {
    super.initState();
    _cloudService = BackupCloudService();
  }

  void _goBack() {
    if (_isNavigating) return;
    _isNavigating = true;
    
    _BackupCloudScreenLogger.info('🔙 Navegando de vuelta a notas');
    
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      try {
        context.go('/notes');
        _BackupCloudScreenLogger.success('✅ Navegación exitosa');
      } catch (e) {
        _BackupCloudScreenLogger.error('Error: $e');
      } finally {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _isNavigating = false;
        });
      }
    });
  }

  Future<void> _refreshBackups() async {
    _BackupCloudScreenLogger.info('🔄 Recargando backups...');
    await ref.read(backupProvider.notifier).loadBackups();
    _BackupCloudScreenLogger.success('✅ Backups recargados');
  }

  String _extractRealId(String id) {
    if (id.startsWith('cloud_')) {
      return id.substring(6);
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backupState = ref.watch(backupProvider);
    final notesState = ref.watch(notesProvider);
    final user = ref.watch(currentUserProvider);
    
    final cloudBackups = backupState.backups
        .where((b) => b.source == 'cloud')
        .toList();
    
    final limitInfo = backupState.limitInfo;
    final current = cloudBackups.length;
    final max = limitInfo?.max ?? 20;
    final remaining = max - current;

    if (backupState.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: LoadingIndicator(message: 'Cargando backups en la nube...')),
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
              child: Column(
                children: [
                  // Header con estadísticas
                  _buildStatsHeader(
                    isDarkMode,
                    current,
                    max,
                    remaining,
                    notesState.notes.length,
                    user,
                    cloudBackups.isNotEmpty,
                  ),
                  
                  // Barra de selección múltiple
                  if (_isSelectionMode)
                    _buildSelectionBar(isDarkMode, cloudBackups.length),
                  
                  // Lista de backups
                  Expanded(
                    child: cloudBackups.isEmpty
                        ? _buildEmptyState(isDarkMode)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: cloudBackups.length,
                            itemBuilder: (context, index) {
                              final backup = cloudBackups[index];
                              final isSelected = _selectedBackupIds.contains(backup.id);
                              
                              return CloudBackupCard(
                                backup: {
                                  'id': backup.id,
                                  'file_name': backup.fileName,
                                  'note_count': backup.noteCount,
                                  'file_size': backup.fileSize,
                                  'created_at': backup.createdAt.toIso8601String(),
                                },
                                isSelected: isSelected,
                                onTap: _isSelectionMode
                                    ? () => _toggleSelection(backup.id)
                                    : () {},
                                onRestore: () => _restoreCloudBackup(backup.id),
                                onDelete: () => _deleteCloudBackup(backup.id),
                                onDownload: () => _downloadCloudBackup(backup),
                                onSelect: _isSelectionMode ? () => _toggleSelection(backup.id) : null,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          // Modal de progreso
          if (_showProgress)
            Center(
              child: CloudProgressModal(
                progress: _progress,
                message: _progressMessage,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(
    bool isDarkMode,
    int current,
    int max,
    int remaining,
    int totalNotes,
    dynamic user,
    bool hasBackups,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      margin: const EdgeInsets.all(16),
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
          // Estadísticas en fila
          Row(
            children: [
              _buildStatItem(
                'Backups',
                '$current',
                isDarkMode,
                icon: Icons.cloud,
                color: Colors.purple,
                isSmallScreen: isSmallScreen,
              ),
              Container(
                width: 1,
                height: 40,
                color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
              ),
              _buildStatItem(
                'Notas actuales',
                '$totalNotes',
                isDarkMode,
                icon: Icons.note,
                color: Colors.green,
                isSmallScreen: isSmallScreen,
              ),
              Container(
                width: 1,
                height: 40,
                color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
              ),
              _buildStatItem(
                'Límite',
                '$max',
                isDarkMode,
                icon: Icons.cloud_queue,
                color: Colors.orange,
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
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
          
          // Texto de límite
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$current / $max backups',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              if (remaining <= 2 && remaining > 0)
                Text(
                  '⚠️ Quedan $remaining espacios',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.orange,
                  ),
                ),
              if (remaining <= 0)
                Text(
                  '🔴 Límite alcanzado',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Botones en fila
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              // Botón GUARDAR EN NUBE
              SizedBox(
                width: isSmallScreen ? 100 : 120,
                height: 44,
                child: ElevatedButton(
                  onPressed: (remaining <= 0 || _isSaving) ? null : _saveToCloud,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload, size: isSmallScreen ? 16 : 18),
                            const SizedBox(width: 6),
                            Text(
                              isSmallScreen ? 'SUBIR' : 'GUARDAR',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 11 : 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              // Botón SELECTIVO
              SizedBox(
                width: isSmallScreen ? 100 : 120,
                height: 44,
                child: OutlinedButton(
                  onPressed: _openSelectiveBackup,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFF8B5CF6), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_list, size: isSmallScreen ? 16 : 18, color: const Color(0xFF8B5CF6)),
                      const SizedBox(width: 6),
                      Text(
                        isSmallScreen ? 'SELECT' : 'SELECTIVO',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 11 : 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Botón SINCRONIZAR
              if (user != null)
                SizedBox(
                  width: isSmallScreen ? 100 : 120,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _syncWithCloud,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: _isSyncing
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sync, size: isSmallScreen ? 16 : 18),
                              const SizedBox(width: 6),
                              Text(
                                isSmallScreen ? 'SINCR' : 'SINCRONIZAR',
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 11 : 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),
          
          // Botón SELECCIONAR MÚLTIPLES
          if (!_isSelectionMode && hasBackups) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => setState(() => _isSelectionMode = true),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade400),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist, size: isSmallScreen ? 16 : 18),
                  const SizedBox(width: 6),
                  Text(
                    'SELECCIONAR MÚLTIPLES',
                    style: GoogleFonts.poppins(fontSize: isSmallScreen ? 11 : 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDarkMode, {
    required IconData icon,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(bool isDarkMode, int totalBackups) {
    final isAllSelected = _selectedBackupIds.length == totalBackups && totalBackups > 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 450;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                if (isAllSelected) {
                  _selectedBackupIds.clear();
                } else {
                  final backups = ref.read(backupProvider).backups
                      .where((b) => b.source == 'cloud');
                  _selectedBackupIds.addAll(backups.map((b) => b.id));
                }
              });
            },
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
            isSmallScreen ? '${_selectedBackupIds.length}' : '${_selectedBackupIds.length} seleccionado${_selectedBackupIds.length != 1 ? 's' : ''}',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 11 : 13,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() {
              _selectedBackupIds.clear();
              _isSelectionMode = false;
            }),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: Text(
              isSmallScreen ? 'X' : 'CANCELAR',
              style: TextStyle(color: Colors.white70, fontSize: isSmallScreen ? 11 : 12),
            ),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: _deleteSelectedBackups,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
            ),
            child: _isDeletingSelected
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(isSmallScreen ? 'DEL' : 'ELIMINAR', style: TextStyle(fontSize: isSmallScreen ? 10 : 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Center(
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
            child: Icon(Icons.cloud_off, size: isSmallScreen ? 40 : 50, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Text(
            'No hay backups en la nube',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Guarda tu primer backup en Supabase',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 11 : 13,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================
  // ACCIONES - CORREGIDAS CON restoreFromBackup
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

  Future<void> _saveToCloud() async {
    final notes = ref.read(notesProvider).notes;
    if (notes.isEmpty) {
      if (mounted) {
        ToastMessage.warning(context, 'No hay notas para respaldar');
      }
      return;
    }

    setState(() {
      _isSaving = true;
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
            _progressMessage = 'Subiendo a la nube...';
          }
        });
      }
    });

    try {
      final fileName = 'quicknote_cloud_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final notesData = {
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'total_notes': notes.length,
        'notes': notes.map((n) => n.toJson()).toList(),
      };

      final result = await _cloudService.saveCloudBackup(
        fileName: fileName,
        fileSize: notesData.toString().length,
        noteCount: notes.length,
        notesData: notesData,
      );

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
          _isSaving = false;
        });
        
        if (result != null) {
          await _refreshBackups();
          ToastMessage.success(context, '✅ Backup guardado en la nube');
        } else {
          ToastMessage.error(context, 'Error al guardar el backup');
        }
      }
    } catch (e) {
      timer.cancel();
      if (mounted) {
        setState(() {
          _showProgress = false;
          _isSaving = false;
        });
        ToastMessage.error(context, 'Error al guardar en la nube: ${e.toString()}');
      }
    }
  }

  // ✅ CORREGIDO: Restauración de backup desde la NUBE usando restoreFromBackup
  Future<void> _restoreCloudBackup(String id) async {
    final realId = _extractRealId(id);
    _BackupCloudScreenLogger.info('🔄 Restaurando backup: $id -> realId: $realId');
    
    final confirmed = await _showConfirmDialog(
      context,
      'Restaurar backup',
      '¿Restaurar este backup desde la nube? Se reemplazarán TODAS las notas actuales por las del backup. Esta acción NO se puede deshacer.',
    );
    if (!confirmed) return;

    if (!mounted) return;

    setState(() {
      _showProgress = true;
      _progress = 0;
      _progressMessage = 'Descargando backup...';
    });

    final timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_progress < 90 && mounted) {
        setState(() => _progress += 10);
      }
    });

    try {
      // 1. Obtener los datos del backup desde la nube
      final backupData = await _cloudService.getCloudBackup(realId);
      
      timer.cancel();
      
      if (mounted) {
        setState(() {
          _progress = 100;
          _progressMessage = '¡Restauración completada!';
        });
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && backupData != null) {
        // 2. Extraer las notas del backup
        List<Note> restoredNotes = [];
        final notesDataValue = backupData['notes_data'];
        if (notesDataValue != null) {
          final notesJson = notesDataValue['notes'] as List?;
          if (notesJson != null) {
            restoredNotes = notesJson.map((json) => Note.fromJson(json)).toList();
          }
        }
        
        if (restoredNotes.isNotEmpty) {
          // 3. ✅ CORREGIDO: Usar restoreFromBackup en lugar de replaceAllNotes
          final notesNotifier = ref.read(notesProvider.notifier);
          await notesNotifier.restoreFromBackup(restoredNotes);
          
          // 4. Mostrar mensaje de éxito
          ToastMessage.success(context, '✅ ${restoredNotes.length} notas restauradas correctamente');
          _BackupCloudScreenLogger.success('✅ Backup restaurado: ${restoredNotes.length} notas');
          
          // 5. Recargar la lista de backups
          await _refreshBackups();
          
          // 6. Volver a la pantalla de notas después de un momento
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              _goBack();
            }
          });
        } else {
          ToastMessage.warning(context, 'No se encontraron notas en el backup');
          if (mounted) setState(() => _showProgress = false);
        }
      } else if (mounted) {
        ToastMessage.error(context, 'No se pudo obtener el backup de la nube');
        if (mounted) setState(() => _showProgress = false);
      }
    } catch (e) {
      timer.cancel();
      if (mounted) {
        setState(() => _showProgress = false);
        ToastMessage.error(context, 'Error al restaurar backup: ${e.toString()}');
        _BackupCloudScreenLogger.error('❌ Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _showProgress = false);
      }
    }
  }

  Future<void> _deleteCloudBackup(String id) async {
    final realId = _extractRealId(id);
    _BackupCloudScreenLogger.info('🗑️ Eliminando backup: $id -> realId: $realId');
    
    final confirmed = await _showConfirmDialog(
      context,
      'Eliminar backup',
      '¿Eliminar este backup de la nube permanentemente?',
    );
    if (!confirmed) return;

    if (!mounted) return;

    final success = await _cloudService.deleteCloudBackup(realId);
    if (success && mounted) {
      await _refreshBackups();
      ToastMessage.success(context, '✅ Backup eliminado de la nube');
    } else if (mounted) {
      ToastMessage.error(context, 'Error al eliminar backup');
    }
  }

  Future<void> _deleteSelectedBackups() async {
    final confirmed = await _showConfirmDialog(
      context,
      'Eliminar seleccionados',
      '¿Eliminar ${_selectedBackupIds.length} backup${_selectedBackupIds.length != 1 ? 's' : ''} de la nube permanentemente?',
    );
    if (!confirmed) return;

    if (!mounted) return;

    setState(() => _isDeletingSelected = true);

    int successCount = 0;
    for (final id in _selectedBackupIds) {
      final realId = _extractRealId(id);
      final success = await _cloudService.deleteCloudBackup(realId);
      if (success) successCount++;
    }

    if (mounted) {
      setState(() {
        _selectedBackupIds.clear();
        _isSelectionMode = false;
        _isDeletingSelected = false;
      });
      
      await _refreshBackups();
      ToastMessage.success(context, '✅ $successCount backup${successCount != 1 ? 's' : ''} eliminado${successCount != 1 ? 's' : ''} de la nube');
    }
  }

  void _downloadCloudBackup(dynamic backup) {
    ToastMessage.info(context, 'Descargando ${backup.fileName}...');
  }

  Future<void> _syncWithCloud() async {
    setState(() => _isSyncing = true);

    try {
      final localBackups = ref.read(backupProvider).backups
          .where((b) => b.source == 'local' || b.source == null)
          .map((b) => ({
            'id': b.id,
            'file_name': b.fileName,
            'file_size': b.fileSize,
            'note_count': b.noteCount,
            'created_at': b.createdAt.toIso8601String(),
            'source': 'local',
          }))
          .toList();

      final result = await _cloudService.syncCloudBackups(localBackups);
      
      if (mounted) {
        await _refreshBackups();
        ToastMessage.success(context, result['message'] ?? 'Sincronización completada');
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.error(context, 'Error al sincronizar: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _openSelectiveBackup() {
    final notes = ref.read(notesProvider).notes;
    if (notes.isEmpty) {
      ToastMessage.warning(context, 'No hay notas para respaldar');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => SelectiveBackupModal(
        notes: notes,
        onConfirm: (selectedNoteIds) async {
          final selectedNotes = notes.where((n) => selectedNoteIds.contains(n.id)).toList();
          
          if (!mounted) return;

          setState(() {
            _isSaving = true;
            _showProgress = true;
            _progress = 0;
            _progressMessage = 'Preparando backup selectivo...';
          });

          final timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
            if (_progress < 90 && mounted) {
              setState(() => _progress += 10);
            }
          });

          try {
            final fileName = 'quicknote_selective_backup_${DateTime.now().millisecondsSinceEpoch}.json';
            final notesData = {
              'version': '1.0.0',
              'timestamp': DateTime.now().toIso8601String(),
              'total_notes': selectedNotes.length,
              'notes': selectedNotes.map((n) => n.toJson()).toList(),
            };

            final result = await _cloudService.saveCloudBackup(
              fileName: fileName,
              fileSize: notesData.toString().length,
              noteCount: selectedNotes.length,
              notesData: notesData,
            );

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
                _isSaving = false;
              });
              
              if (result != null) {
                await _refreshBackups();
                ToastMessage.success(context, '✅ ${selectedNotes.length} notas guardadas en la nube');
              } else {
                ToastMessage.error(context, 'Error al guardar backup selectivo');
              }
            }
          } catch (e) {
            timer.cancel();
            if (mounted) {
              setState(() {
                _showProgress = false;
                _isSaving = false;
              });
              ToastMessage.error(context, 'Error al guardar backup selectivo: ${e.toString()}');
            }
          }
        },
      ),
    );
  }

  // ============================================
  // UTILIDADES
  // ============================================

  Future<bool> _showConfirmDialog(BuildContext context, String title, String message) async {
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