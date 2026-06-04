// lib/widgets/notification_settings_widget.dart
// Widget de configuración de notificaciones
// ✅ Muestra estado de permisos
// ✅ Solicitar permisos de notificación
// ✅ Activar/desactivar notificaciones
// ✅ Personalización de canales

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/core/services/notification_service.dart';
import 'package:quicknote/widgets/toast_message.dart';

class NotificationSettingsWidget extends ConsumerStatefulWidget {
  const NotificationSettingsWidget({super.key});

  @override
  ConsumerState<NotificationSettingsWidget> createState() => _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState extends ConsumerState<NotificationSettingsWidget> {
  bool _notificationsEnabled = true;
  bool _isLoading = false;
  bool _permissionGranted = false;
  bool _isCheckingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isCheckingPermissions = true);
    
    try {
      final granted = await notificationService.arePermissionsGranted();
      setState(() {
        _permissionGranted = granted;
        _notificationsEnabled = granted;
        _isCheckingPermissions = false;
      });
    } catch (e) {
      setState(() => _isCheckingPermissions = false);
    }
  }

  Future<void> _requestPermissions() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final granted = await notificationService.requestPermissions();
      
      setState(() {
        _permissionGranted = granted;
        _notificationsEnabled = granted;
      });
      
      if (granted && mounted) {
        ToastMessage.success(context, 'Permisos de notificación activados');
      } else if (mounted) {
        ToastMessage.warning(context, 'Permisos de notificación denegados');
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.error(context, 'Error al solicitar permisos: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (_isLoading) return;
    
    setState(() {
      _notificationsEnabled = value;
      _isLoading = true;
    });
    
    try {
      if (value && !_permissionGranted) {
        await _requestPermissions();
      } else if (!value) {
        await notificationService.cancelAllNotifications();
        ToastMessage.info(context, 'Notificaciones desactivadas');
      } else {
        ToastMessage.success(context, 'Notificaciones activadas');
      }
      
      setState(() => _permissionGranted = value);
    } catch (e) {
      ToastMessage.error(context, 'Error: ${e.toString()}');
      setState(() => _notificationsEnabled = !value);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Título de la sección
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.notifications_active, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Notificaciones',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Toggle de notificaciones
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permitir notificaciones',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Recibir alertas de backups y recordatorios',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isCheckingPermissions)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: _notificationsEnabled,
                    onChanged: _isLoading ? null : _toggleNotifications,
                    activeColor: const Color(0xFF8B5CF6),
                  ),
              ],
            ),
          ),
          
          // Estado de permisos
          if (!_permissionGranted && !_isCheckingPermissions && !_notificationsEnabled)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, size: 18, color: Colors.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Permisos de notificación no activados. Actívalos para recibir alertas.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDarkMode ? Colors.amber.shade300 : Colors.amber.shade800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _requestPermissions,
                    child: const Text(
                      'ACTIVAR',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          
          // Información adicional
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Las notificaciones te informarán cuando los backups se completen o si hay errores.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}