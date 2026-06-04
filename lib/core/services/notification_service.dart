// lib/core/services/notification_service.dart
// Servicio de notificaciones locales para QuickNote
// ✅ Canal específico para backups
// ✅ Notificaciones de éxito, error y progreso
// ✅ Soporte para Android

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class _NotificationLogger {
  static void info(String message) => debugPrint('ℹ️ [NotificationService] $message');
  static void success(String message) => debugPrint('✅ [NotificationService] $message');
  static void error(String message) => debugPrint('❌ [NotificationService] $message');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // IDs de notificaciones
  static const int idBackupStart = 1001;
  static const int idBackupSuccess = 1002;
  static const int idBackupError = 1003;
  static const int idBackupProgress = 1004;
  static const int idRestoreSuccess = 2001;
  static const int idRestoreError = 2002;

  // ============================================
  // INICIALIZACIÓN
  // ============================================
  
  Future<void> init() async {
    if (_isInitialized) return;
    
    _NotificationLogger.info('🔔 Inicializando servicio de notificaciones...');
    
    // Configuración para Android
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configuración para iOS
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _plugin.initialize(initializationSettings, onDidReceiveNotificationResponse: _onNotificationTap);
    
    // Crear canales de notificación para Android
    await _createNotificationChannels();
    
    _isInitialized = true;
    _NotificationLogger.success('✅ Servicio de notificaciones inicializado');
  }

  /// Crear canales de notificación para Android (API 26+)
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel backupChannel = AndroidNotificationChannel(
      'quicknote_backups',
      'Copias de seguridad',
      description: 'Notificaciones sobre copias de seguridad',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'quicknote_general',
      'Notificaciones generales',
      description: 'Notificaciones generales de la aplicación',
      importance: Importance.defaultImportance,
    );

    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(backupChannel);
    
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);

    _NotificationLogger.info('📢 Canales de notificación creados');
  }

  /// Manejar cuando el usuario toca una notificación
  void _onNotificationTap(NotificationResponse response) {
    _NotificationLogger.info('🔔 Notificación tocada: ${response.payload}');
  }

  // ============================================
  // NOTIFICACIONES DE BACKUP
  // ============================================
  
  /// Mostrar notificación de inicio de backup
  Future<void> showBackupStartNotification({String type = 'manual'}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'quicknote_backups',
      'Copias de seguridad',
      channelDescription: 'Notificaciones sobre copias de seguridad',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      idBackupStart,
      'Iniciando copia de seguridad',
      'Creando respaldo de tus notas...',
      notificationDetails,
    );

    _NotificationLogger.info('📤 Notificación de inicio de backup mostrada');
  }

  /// Mostrar notificación de backup exitoso
  Future<void> showBackupSuccessNotification({int? noteCount, String? backupName}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'quicknote_backups',
      'Copias de seguridad',
      channelDescription: 'Notificaciones sobre copias de seguridad',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    String body = 'Copia de seguridad completada exitosamente';
    if (noteCount != null) {
      body = '$noteCount notas respaldadas correctamente';
    }
    if (backupName != null) {
      body = '$body\n$backupName';
    }

    await _plugin.show(
      idBackupSuccess,
      '✅ Backup completado',
      body,
      notificationDetails,
    );

    _NotificationLogger.success('✅ Notificación de backup exitoso mostrada');
  }

  /// Mostrar notificación de error en backup
  Future<void> showBackupErrorNotification(String errorMessage) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'quicknote_backups',
      'Copias de seguridad',
      channelDescription: 'Notificaciones sobre copias de seguridad',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    final String displayMessage = errorMessage.length > 100 
        ? '${errorMessage.substring(0, 100)}...' 
        : errorMessage;

    await _plugin.show(
      idBackupError,
      '❌ Error en copia de seguridad',
      displayMessage,
      notificationDetails,
    );

    _NotificationLogger.error('❌ Notificación de error mostrada: $errorMessage');
  }

  /// Mostrar notificación de progreso
  Future<void> showBackupProgressNotification(int current, int total) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'quicknote_backups',
      'Copias de seguridad',
      channelDescription: 'Notificaciones sobre copias de seguridad',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      idBackupProgress,
      'QuickNote',
      'Procesando nota $current de $total...',
      notificationDetails,
    );

    _NotificationLogger.info('📊 Progreso de backup: $current/$total');
  }

  /// Cancelar notificación de progreso
  Future<void> cancelBackupProgressNotification() async {
    await _plugin.cancel(idBackupProgress);
  }

  // ============================================
  // NOTIFICACIONES DE RESTAURACIÓN
  // ============================================
  
  /// Mostrar notificación de restauración exitosa
  Future<void> showRestoreSuccessNotification(int noteCount) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'quicknote_backups',
      'Copias de seguridad',
      channelDescription: 'Notificaciones sobre copias de seguridad',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      idRestoreSuccess,
      '🔄 Restauración completada',
      '$noteCount notas restauradas correctamente',
      notificationDetails,
    );

    _NotificationLogger.success('✅ Notificación de restauración exitosa mostrada');
  }

  /// Mostrar notificación de error en restauración
  Future<void> showRestoreErrorNotification(String errorMessage) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'quicknote_backups',
      'Copias de seguridad',
      channelDescription: 'Notificaciones sobre copias de seguridad',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    final String displayMessage = errorMessage.length > 100 
        ? '${errorMessage.substring(0, 100)}...' 
        : errorMessage;

    await _plugin.show(
      idRestoreError,
      '❌ Error en restauración',
      displayMessage,
      notificationDetails,
    );

    _NotificationLogger.error('❌ Notificación de error en restauración mostrada');
  }

  // ============================================
  // NOTIFICACIONES GENERALES
  // ============================================
  
  /// Mostrar notificación de recordatorio
  Future<void> showReminderNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'quicknote_general',
      'Notificaciones generales',
      channelDescription: 'Notificaciones generales de la aplicación',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      notificationDetails,
    );

    _NotificationLogger.info('🔔 Notificación de recordatorio mostrada: $title');
  }

  // ============================================
  // PERMISOS Y UTILIDADES
  // ============================================
  
  /// Solicitar permisos de notificación
  Future<bool> requestPermissions() async {
    _NotificationLogger.info('🔔 Solicitando permisos de notificación...');

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    final bool? result = await androidPlugin?.requestNotificationsPermission();

    _NotificationLogger.info('Permisos de notificación: $result');
    return result ?? false;
  }

  /// Verificar si los permisos están concedidos
  Future<bool> arePermissionsGranted() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    final bool? result = await androidPlugin?.areNotificationsEnabled();

    return result ?? false;
  }

  /// Cancelar una notificación específica
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
    _NotificationLogger.info('🗑️ Notificación cancelada: $id');
  }
  
  /// Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    _NotificationLogger.info('🗑️ Todas las notificaciones canceladas');
  }
}

// Instancia global
final notificationService = NotificationService();