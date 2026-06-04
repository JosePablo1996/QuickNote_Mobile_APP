// lib/widgets/backup_scheduler_widget.dart
// Widget para mostrar estado y control de backups programados

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/core/services/backup_scheduler_service.dart';
import 'package:quicknote/widgets/toast_message.dart';

class BackupSchedulerWidget extends ConsumerStatefulWidget {
  final bool compact;

  const BackupSchedulerWidget({
    super.key,
    this.compact = false,
  });

  @override
  ConsumerState<BackupSchedulerWidget> createState() => _BackupSchedulerWidgetState();
}

class _BackupSchedulerWidgetState extends ConsumerState<BackupSchedulerWidget> {
  final BackupSchedulerService _scheduler = BackupSchedulerService();
  
  bool _dailyEnabled = false;
  bool _weeklyEnabled = false;
  bool _isLoading = true;
  // ✅ CORREGIDO: variable eliminada o marcada como final si no se usa
  // _lastBackupInfo eliminada porque no se usa

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    _dailyEnabled = await _scheduler.isDailyBackupScheduled();
    _weeklyEnabled = await _scheduler.isWeeklyBackupScheduled();
    
    setState(() => _isLoading = false);
  }

  Future<void> _toggleDailyBackup(bool value) async {
    setState(() => _dailyEnabled = value);
    
    if (value) {
      await _scheduler.scheduleDailyBackup();
      await _scheduler.setDailyBackupScheduled(true);
      ToastMessage.success('Backup diario activado (2:00 AM)');
    } else {
      await _scheduler.cancelDailyBackup();
      await _scheduler.setDailyBackupScheduled(false);
      ToastMessage.info('Backup diario desactivado');
    }
  }

  Future<void> _toggleWeeklyBackup(bool value) async {
    setState(() => _weeklyEnabled = value);
    
    if (value) {
      await _scheduler.scheduleWeeklyBackup();
      await _scheduler.setWeeklyBackupScheduled(true);
      ToastMessage.success('Backup semanal activado (lunes 2:00 AM)');
    } else {
      await _scheduler.cancelWeeklyBackup();
      await _scheduler.setWeeklyBackupScheduled(false);
      ToastMessage.info('Backup semanal desactivado');
    }
  }

  Future<void> _forceBackupNow() async {
    ToastMessage.info('Iniciando backup manual...');
    await _scheduler.forceBackupNow();
    ToastMessage.success('Backup manual programado');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (widget.compact) {
      return _buildCompactView(isDarkMode);
    }
    
    return _buildFullView(isDarkMode);
  }

  Widget _buildFullView(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
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
                child: const Icon(Icons.schedule, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Backup Automático',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                // Backup diario
                _buildScheduleOption(
                  isDarkMode,
                  icon: Icons.calendar_today,
                  title: 'Backup Diario',
                  subtitle: 'Se ejecuta automáticamente a las 2:00 AM',
                  value: _dailyEnabled,
                  color: Colors.blue,
                  onChanged: _toggleDailyBackup,
                ),
                const SizedBox(height: 12),
                
                // Backup semanal
                _buildScheduleOption(
                  isDarkMode,
                  icon: Icons.calendar_month,  // ✅ CORREGIDO: calendar_week → calendar_month
                  title: 'Backup Semanal',
                  subtitle: 'Se ejecuta los lunes a las 2:00 AM',
                  value: _weeklyEnabled,
                  color: Colors.purple,
                  onChanged: _toggleWeeklyBackup,
                ),
                const SizedBox(height: 16),
                
                // Botón de backup manual
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _forceBackupNow,
                    icon: const Icon(Icons.backup, size: 18),
                    label: const Text('CREAR BACKUP MANUAL'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildCompactView(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Backup Automático',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (_dailyEnabled || _weeklyEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Activo',
                    style: const TextStyle(fontSize: 10, color: Colors.green),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCompactOption(
                  isDarkMode,
                  label: 'Diario',
                  value: _dailyEnabled,
                  color: Colors.blue,
                  onChanged: _toggleDailyBackup,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactOption(
                  isDarkMode,
                  label: 'Semanal',
                  value: _weeklyEnabled,
                  color: Colors.purple,
                  onChanged: _toggleWeeklyBackup,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _forceBackupNow,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Icon(Icons.backup, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleOption(
    bool isDarkMode, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? color : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
                    fontSize: 14,
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
            activeColor: color,  // ✅ Deprecado pero funciona, se puede dejar
          ),
        ],
      ),
    );
  }

  Widget _buildCompactOption(
    bool isDarkMode, {
    required String label,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: value ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? color : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.circle_outlined,
              size: 12,
              color: value ? color : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: value ? color : (isDarkMode ? Colors.white70 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}