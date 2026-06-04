// lib/widgets/auto_backup_indicator.dart
// Widget para mostrar el estado del Auto-Backup

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/providers/auto_backup_provider.dart';
import 'package:quicknote/providers/notes_provider.dart';
import 'package:quicknote/widgets/toast_message.dart';

class AutoBackupIndicator extends ConsumerStatefulWidget {
  final bool isInline;
  final double iconSize;
  final Color? color;

  const AutoBackupIndicator({
    super.key,
    this.isInline = false,
    this.iconSize = 20,
    this.color,
  });

  @override
  ConsumerState<AutoBackupIndicator> createState() => _AutoBackupIndicatorState();
}

class _AutoBackupIndicatorState extends ConsumerState<AutoBackupIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backupState = ref.watch(autoBackupStateProvider);
    final isBackingUp = backupState.isBackingUp;
    final hasPending = backupState.hasPendingChanges;
    final pendingCount = backupState.pendingChangesCount;
    final lastBackupTime = backupState.lastBackupTime;
    final isEnabled = backupState.isEnabled;
    final status = backupState.status;

    if (!isEnabled && !hasPending && !isBackingUp) {
      return const SizedBox.shrink();
    }

    final isSuccess = status.toString().contains('success');
    final isError = status.toString().contains('error');
    
    final statusText = _getStatusText(isBackingUp, hasPending, isSuccess, isError);
    final statusColor = _getStatusColor(isBackingUp, hasPending, isSuccess, isError);
    final statusIcon = _getStatusIcon(isBackingUp, hasPending, isSuccess, isError);

    final indicator = FadeTransition(
      opacity: _animationController,
      child: widget.isInline
          ? _buildInlineIndicator(isDarkMode, isBackingUp, hasPending, pendingCount, lastBackupTime, statusText, statusColor, statusIcon)
          : _buildFloatingIndicator(isDarkMode, isBackingUp, hasPending, pendingCount, lastBackupTime, statusText, statusColor, statusIcon),
    );

    if (widget.isInline) {
      return indicator;
    }

    return Positioned(
      bottom: 16,
      right: 16,
      child: indicator,
    );
  }

  Widget _buildFloatingIndicator(
    bool isDarkMode,
    bool isBackingUp,
    bool hasPending,
    int pendingCount,
    DateTime? lastBackupTime,
    String statusText,
    Color statusColor,
    IconData statusIcon,
  ) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAnimatedIcon(isBackingUp, statusColor, statusIcon, isSmallScreen),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    if (hasPending && pendingCount > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+$pendingCount',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                  ],
                ),
                if (lastBackupTime != null && !isBackingUp)
                  Text(
                    _formatRelativeTime(lastBackupTime),
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 8 : 9,
                      color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
            if (hasPending && !isBackingUp) _buildActionButton(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineIndicator(
    bool isDarkMode,
    bool isBackingUp,
    bool hasPending,
    int pendingCount,
    DateTime? lastBackupTime,
    String statusText,
    Color statusColor,
    IconData statusIcon,
  ) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBackingUp)
            SizedBox(
              width: widget.iconSize,
              height: widget.iconSize,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(statusIcon, size: widget.iconSize, color: widget.color ?? statusColor),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 10 : 11,
              fontWeight: FontWeight.w500,
              color: widget.color ?? (isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
          if (hasPending && pendingCount > 0 && !isBackingUp) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+$pendingCount',
                style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _forceBackup,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Guardar', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(bool isBackingUp, Color statusColor, IconData statusIcon, bool isSmallScreen) {
    if (isBackingUp) {
      return SizedBox(
        width: isSmallScreen ? 28 : 32,
        height: isSmallScreen ? 28 : 32,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _animationController.value,
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, size: isSmallScreen ? 16 : 18, color: statusColor),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(bool isDarkMode) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return Container(
      margin: const EdgeInsets.only(left: 12),
      child: GestureDetector(
        onTap: _forceBackup,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12, vertical: isSmallScreen ? 5 : 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('Guardar', style: GoogleFonts.poppins(fontSize: isSmallScreen ? 10 : 11, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    );
  }

  Future<void> _forceBackup() async {
    final notes = ref.read(notesProvider).notes;
    if (notes.isEmpty) {
      ToastMessage.warning('No hay notas para respaldar');
      return;
    }

    final notifier = ref.read(autoBackupStateProvider.notifier);
    final success = await notifier.forceBackup(notes);
    
    if (success && mounted) {
      ToastMessage.success('Backup manual completado');
    } else if (mounted) {
      ToastMessage.error('Error al crear backup');
    }
  }

  String _getStatusText(bool isBackingUp, bool hasPending, bool isSuccess, bool isError) {
    if (isBackingUp) return 'Respaldando...';
    if (hasPending) return 'Cambios pendientes';
    if (isSuccess) return 'Sincronizado';
    if (isError) return 'Error de conexión';
    return 'Auto-backup activo';
  }

  Color _getStatusColor(bool isBackingUp, bool hasPending, bool isSuccess, bool isError) {
    if (isBackingUp) return Colors.orange;
    if (hasPending) return Colors.amber;
    if (isSuccess) return Colors.green;
    if (isError) return Colors.red;
    return Colors.blue;
  }

  IconData _getStatusIcon(bool isBackingUp, bool hasPending, bool isSuccess, bool isError) {
    if (isBackingUp) return Icons.cloud_upload;
    if (hasPending) return Icons.cloud_upload;
    if (isSuccess) return Icons.cloud_done;
    if (isError) return Icons.cloud_off;
    return Icons.cloud_queue;
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inSeconds < 60) return 'hace unos segundos';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} minutos';
    if (diff.inHours < 24) return 'hace ${diff.inHours} horas';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    return '${date.day}/${date.month}/${date.year}';
  }
}