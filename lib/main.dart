// lib/main.dart
// Punto de entrada principal de la aplicación QuickNote
// ⚠️ IMPORTANTE: Para que la biometría funcione correctamente en Android,
// la MainActivity debe extender de FlutterFragmentActivity (ver MainActivity.kt)
// ✅ ACTUALIZADO: Incluye validación de sesión al iniciar
// ✅ NUEVO: Inicialización del servicio de notificaciones
// ✅ NUEVO: Inicialización del servicio de backups programados (Timer)
// ✅ WorkManager eliminado temporalmente por problemas de compatibilidad

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicknote/app.dart';
import 'package:quicknote/core/api/api_client.dart';
import 'package:quicknote/core/services/notification_service.dart';
import 'package:quicknote/core/services/backup_scheduler_service.dart';
// import 'package:quicknote/core/services/scheduled_backup_service.dart'; // COMENTADO - WorkManager desactivado
import 'package:quicknote/core/services/session_service.dart';
import 'package:quicknote/core/utils/secure_storage.dart';
import 'package:quicknote/core/utils/token_storage.dart';

// Logger simple para evitar warnings de print
class _MainLogger {
  static void info(String message) {
    debugPrint('ℹ️ [Main] $message');
  }
  
  static void success(String message) {
    debugPrint('✅ [Main] $message');
  }
  
  static void warning(String message) {
    debugPrint('⚠️ [Main] $message');
  }
  
  static void error(String message) {
    debugPrint('❌ [Main] $message');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  _MainLogger.info('Inicializando servicios...');
  
  // 1. Inicializar SecureStorage
  final secureStorage = SecureStorage();
  
  // 2. Inicializar biometría (crea el valor si no existe)
  await secureStorage.initBiometricIfNeeded();
  
  // 3. Verificar estado de biometría
  final biometricEnabled = await secureStorage.isBiometricEnabled();
  _MainLogger.info('Estado biometría persistido: $biometricEnabled');
  
  // 4. Inicializar ApiClient
  await apiClient.init();
  _MainLogger.success('ApiClient inicializado');
  
  // 5. ✅ INICIALIZAR SERVICIO DE NOTIFICACIONES
  try {
    await notificationService.init();
    _MainLogger.success('Servicio de notificaciones inicializado');
  } catch (e) {
    _MainLogger.error('Error inicializando notificaciones: $e');
  }
  
  // 6. ✅ INICIALIZAR SERVICIO DE BACKUPS PROGRAMADOS (Timer - app abierta)
  try {
    final backupScheduler = BackupSchedulerService();
    await backupScheduler.init();
    _MainLogger.success('Servicio de backups programados (Timer) inicializado');
  } catch (e) {
    _MainLogger.error('Error inicializando backups programados (Timer): $e');
  }
  
  // 7. ❌ WORKMANAGER DESACTIVADO - Problemas de compatibilidad
  // try {
  //   await scheduledBackupService.init();
  //   _MainLogger.success('Servicio de backups con WorkManager inicializado');
  // } catch (e) {
  //   _MainLogger.error('Error inicializando backups con WorkManager: $e');
  // }
  
  // 8. ✅ INICIALIZAR SERVICIO DE SESIÓN Y VALIDAR
  final sessionService = SessionService();
  final isSessionValid = await sessionService.isSessionValid();
  
  if (!isSessionValid) {
    _MainLogger.warning('⚠️ Sesión inválida detectada, limpiando tokens...');
    await tokenStorage.clearSession();
    await sessionService.clearSessionData();
    _MainLogger.success('✅ Tokens y datos de sesión eliminados');
  } else {
    // Verificar si la contraseña ha expirado
    final isPasswordExpired = await sessionService.isPasswordExpired();
    if (isPasswordExpired) {
      _MainLogger.warning('⚠️ La contraseña ha expirado. Se requerirá cambio.');
    }
    
    final daysRemaining = await sessionService.getDaysUntilPasswordExpiration();
    if (daysRemaining > 0 && daysRemaining <= 7) {
      _MainLogger.info('ℹ️ La contraseña expirará en $daysRemaining días');
    }
  }
  
  // 9. Debug: Verificar todas las claves de biometría
  final debugInfo = await secureStorage.getBiometricDebugInfo();
  _MainLogger.info('Debug biometría: $debugInfo');
  
  _MainLogger.success('Todos los servicios inicializados correctamente');
  
  // Ejecutar la aplicación con ProviderScope para Riverpod
  runApp(
    const ProviderScope(
      child: QuickNoteApp(),
    ),
  );
}