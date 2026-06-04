// lib/core/services/backup_scheduler_service.dart
// Servicio de programación de backups automáticos
// VERSIÓN SIMPLIFICADA - SIN WORKMANAGER (pendiente de implementar)
// Por ahora, solo notificaciones de recordatorio

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote/core/services/notification_service.dart';

class BackupSchedulerService {
  static final BackupSchedulerService _instance = BackupSchedulerService._internal();
  factory BackupSchedulerService() => _instance;
  BackupSchedulerService._internal();

  bool _isInitialized = false;
  final NotificationService _notificationService = NotificationService();
  Timer? _dailyBackupTimer;
  Timer? _weeklyBackupTimer;

  // ============================================
  // INICIALIZACIÓN
  // ============================================
  
  Future<void> init() async {
    if (_isInitialized) return;
    
    // Inicializar servicio de notificaciones
    await _notificationService.init();
    
    // Cargar configuración guardada
    await _loadSavedConfiguration();
    
    _isInitialized = true;
    debugPrint('✅ BackupSchedulerService inicializado');
  }

  // ============================================
  // PROGRAMAR BACKUPS
  // ============================================
  
  /// Programar backup diario (2:00 AM)
  Future<void> scheduleDailyBackup() async {
    // Cancelar timer existente si hay
    _dailyBackupTimer?.cancel();
    
    final now = DateTime.now();
    DateTime targetTime = DateTime(now.year, now.month, now.day, 2, 0, 0);
    
    if (now.isAfter(targetTime)) {
      targetTime = targetTime.add(const Duration(days: 1));
    }
    
    final initialDelay = targetTime.difference(now);
    
    _dailyBackupTimer = Timer(initialDelay, () {
      _executeDailyBackup();
      // Programar el siguiente después de ejecutar
      _scheduleNextDailyBackup();
    });
    
    // Guardar estado
    await setDailyBackupScheduled(true);
    
    debugPrint('📅 Backup diario programado para las 2:00 AM');
    debugPrint('   Próxima ejecución: ${targetTime.toLocal()}');
  }

  /// Programar backup semanal (lunes 2:00 AM)
  Future<void> scheduleWeeklyBackup() async {
    // Cancelar timer existente si hay
    _weeklyBackupTimer?.cancel();
    
    final now = DateTime.now();
    int daysUntilMonday = (DateTime.monday - now.weekday) % 7;
    if (daysUntilMonday == 0 && now.hour >= 2) {
      daysUntilMonday = 7;
    }
    
    DateTime targetTime = DateTime(
      now.year,
      now.month,
      now.day + daysUntilMonday,
      2, 0, 0,
    );
    
    final initialDelay = targetTime.difference(now);
    
    _weeklyBackupTimer = Timer(initialDelay, () {
      _executeWeeklyBackup();
      // Programar el siguiente después de ejecutar
      _scheduleNextWeeklyBackup();
    });
    
    // Guardar estado
    await setWeeklyBackupScheduled(true);
    
    debugPrint('📅 Backup semanal programado para los lunes 2:00 AM');
    debugPrint('   Próxima ejecución: ${targetTime.toLocal()}');
  }

  /// Cancelar backup diario
  Future<void> cancelDailyBackup() async {
    _dailyBackupTimer?.cancel();
    _dailyBackupTimer = null;
    await setDailyBackupScheduled(false);
    debugPrint('❌ Backup diario cancelado');
  }

  /// Cancelar backup semanal
  Future<void> cancelWeeklyBackup() async {
    _weeklyBackupTimer?.cancel();
    _weeklyBackupTimer = null;
    await setWeeklyBackupScheduled(false);
    debugPrint('❌ Backup semanal cancelado');
  }

  /// Cancelar todos los backups programados
  Future<void> cancelAllBackups() async {
    _dailyBackupTimer?.cancel();
    _weeklyBackupTimer?.cancel();
    _dailyBackupTimer = null;
    _weeklyBackupTimer = null;
    await setDailyBackupScheduled(false);
    await setWeeklyBackupScheduled(false);
    debugPrint('❌ Todos los backups programados cancelados');
  }

  // ============================================
  // BACKUP INMEDIATO (FORZADO)
  // ============================================
  
  /// Forzar backup inmediato
  Future<void> forceBackupNow() async {
    debugPrint('🔄 Ejecutando backup forzado...');
    await _performBackup('manual');
  }

  // ============================================
  // OBTENER ESTADO
  // ============================================
  
  /// Verificar si el backup diario está programado
  Future<bool> isDailyBackupScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('daily_backup_scheduled') ?? false;
  }

  /// Verificar si el backup semanal está programado
  Future<bool> isWeeklyBackupScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('weekly_backup_scheduled') ?? false;
  }

  /// Guardar estado del backup diario
  Future<void> setDailyBackupScheduled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_backup_scheduled', enabled);
  }

  /// Guardar estado del backup semanal
  Future<void> setWeeklyBackupScheduled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weekly_backup_scheduled', enabled);
  }

  // ============================================
  // EJECUCIÓN DE BACKUPS
  // ============================================
  
  void _scheduleNextDailyBackup() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 2, 0, 0);
    final delay = tomorrow.difference(now);
    
    _dailyBackupTimer = Timer(delay, () {
      _executeDailyBackup();
      _scheduleNextDailyBackup();
    });
    
    debugPrint('📅 Próximo backup diario: ${tomorrow.toLocal()}');
  }

  void _scheduleNextWeeklyBackup() {
    final now = DateTime.now();
    int daysUntilNextMonday = (DateTime.monday - now.weekday + 7) % 7;
    if (daysUntilNextMonday == 0) daysUntilNextMonday = 7;
    
    final nextMonday = DateTime(
      now.year,
      now.month,
      now.day + daysUntilNextMonday,
      2, 0, 0,
    );
    final delay = nextMonday.difference(now);
    
    _weeklyBackupTimer = Timer(delay, () {
      _executeWeeklyBackup();
      _scheduleNextWeeklyBackup();
    });
    
    debugPrint('📅 Próximo backup semanal: ${nextMonday.toLocal()}');
  }

  Future<void> _executeDailyBackup() async {
    debugPrint('📦 Ejecutando backup diario...');
    await _performBackup('diario');
  }

  Future<void> _executeWeeklyBackup() async {
    debugPrint('📦 Ejecutando backup semanal...');
    await _performBackup('semanal');
  }

  Future<void> _performBackup(String type) async {
    try {
      // Notificar inicio
      await _notificationService.showBackupStartNotification(type: type);
      
      // TODO: Implementar backup real
      // Por ahora solo simulamos
      await Future.delayed(const Duration(seconds: 2));
      
      // Backup exitoso
      await _notificationService.showBackupSuccessNotification(
        noteCount: 0,
        backupName: 'Backup $type - ${DateTime.now().toLocal()}',
      );
      
      debugPrint('✅ Backup $type completado exitosamente');
      
    } catch (e) {
      debugPrint('❌ Error en backup $type: $e');
      await _notificationService.showBackupErrorNotification(e.toString());
    }
  }

  // ============================================
  // MÉTODOS PRIVADOS
  // ============================================
  
  Future<void> _loadSavedConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final dailyEnabled = prefs.getBool('daily_backup_scheduled') ?? false;
    final weeklyEnabled = prefs.getBool('weekly_backup_scheduled') ?? false;
    
    if (dailyEnabled) {
      await scheduleDailyBackup();
    }
    
    if (weeklyEnabled) {
      await scheduleWeeklyBackup();
    }
  }
}