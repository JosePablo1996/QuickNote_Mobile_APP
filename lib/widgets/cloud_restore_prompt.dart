// lib/widgets/cloud_restore_prompt.dart
// Prompt flotante que aparece cuando hay backup más reciente en la nube
// ✅ Verificar al iniciar la app
// ✅ Comparar fechas entre backup y notas locales
// ✅ Mostrar solo una vez por sesión
// ✅ Opciones: "Restaurar ahora" / "Recordar después" / "No mostrar más"
// ✅ Diseño responsivo y animado

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote/core/api/api_client.dart';
import 'package:quicknote/models/note.dart';
import 'package:quicknote/widgets/toast_message.dart';

class _CloudRestoreLogger {
  static void info(String message) => debugPrint('ℹ️ [CloudRestore] $message');
  static void success(String message) => debugPrint('✅ [CloudRestore] $message');
  static void warning(String message) => debugPrint('⚠️ [CloudRestore] $message');
  static void error(String message) => debugPrint('❌ [CloudRestore] $message');
}

class CloudRestorePrompt extends ConsumerStatefulWidget {
  final List<Note> localNotes;
  final VoidCallback onRestoreComplete;
  final VoidCallback? onDismiss;

  const CloudRestorePrompt({
    super.key,
    required this.localNotes,
    required this.onRestoreComplete,
    this.onDismiss,
  });

  @override
  ConsumerState<CloudRestorePrompt> createState() => _CloudRestorePromptState();
}

class _CloudRestorePromptState extends ConsumerState<CloudRestorePrompt> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = false;
  bool _isExpanded = false;
  Map<String, dynamic>? _latestCloudBackup;
  DateTime? _latestCloudBackupDate;
  DateTime? _latestLocalNoteDate;
  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _checkForNewerCloudBackup();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkForNewerCloudBackup() async {
    try {
      _CloudRestoreLogger.info('🔍 Verificando backups en la nube...');
      
      // Verificar si el usuario ha seleccionado "No mostrar más"
      final prefs = await SharedPreferences.getInstance();
      final neverShowAgain = prefs.getBool('cloud_restore_never_show') ?? false;
      
      if (neverShowAgain) {
        _CloudRestoreLogger.info('🚫 Usuario seleccionó "No mostrar más"');
        _shouldShow = false;
        if (mounted) setState(() {});
        return;
      }
      
      // Verificar si ya se mostró en esta sesión
      final shownInSession = prefs.getBool('cloud_restore_shown_session') ?? false;
      if (shownInSession) {
        _CloudRestoreLogger.info('🔄 Ya se mostró en esta sesión');
        _shouldShow = false;
        if (mounted) setState(() {});
        return;
      }
      
      // Obtener backups de la nube
      final response = await apiClient.getCloudBackups();
      
      if (response.statusCode != 200) {
        _CloudRestoreLogger.warning('⚠️ Error obteniendo backups: ${response.statusCode}');
        _shouldShow = false;
        if (mounted) setState(() {});
        return;
      }
      
      final List<dynamic> backups = response.data;
      
      if (backups.isEmpty) {
        _CloudRestoreLogger.info('📭 No hay backups en la nube');
        _shouldShow = false;
        if (mounted) setState(() {});
        return;
      }
      
      // Encontrar el backup más reciente
      _latestCloudBackup = backups.first;
      final cloudDateStr = _latestCloudBackup!['created_at'];
      _latestCloudBackupDate = DateTime.tryParse(cloudDateStr);
      
      // Encontrar la nota local más reciente
      if (widget.localNotes.isNotEmpty) {
        _latestLocalNoteDate = widget.localNotes.map((n) => n.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b);
      } else {
        _latestLocalNoteDate = DateTime(2020, 1, 1);
      }
      
      _CloudRestoreLogger.info('📅 Último backup cloud: $_latestCloudBackupDate');
      _CloudRestoreLogger.info('📅 Última nota local: $_latestLocalNoteDate');
      
      // Comparar fechas
      if (_latestCloudBackupDate != null && 
          _latestCloudBackupDate!.isAfter(_latestLocalNoteDate!)) {
        _shouldShow = true;
        _CloudRestoreLogger.success('✅ Hay un backup más reciente en la nube');
        
        // Marcar que ya se mostró en esta sesión
        await prefs.setBool('cloud_restore_shown_session', true);
        
        // Animar entrada
        _animationController.forward();
      } else {
        _shouldShow = false;
        _CloudRestoreLogger.info('✅ Las notas locales están actualizadas');
      }
      
      if (mounted) setState(() {});
      
    } catch (e) {
      _CloudRestoreLogger.error('❌ Error verificando backups: $e');
      _shouldShow = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _restoreFromCloud() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _isExpanded = true;
    });
    
    try {
      final backupId = _latestCloudBackup?['id'];
      
      if (backupId == null) {
        throw Exception('No se pudo identificar el backup');
      }
      
      _CloudRestoreLogger.info('🔄 Restaurando desde backup: $backupId');
      
      // Obtener detalles del backup
      final response = await apiClient.getCloudBackup(backupId);
      
      if (response.statusCode != 200) {
        throw Exception('Error al obtener el backup');
      }
      
      final backupData = response.data;
      final notesData = backupData['notes_data'];
      
      if (notesData == null) {
        throw Exception('El backup no contiene datos de notas');
      }
      
      final List<dynamic> notes = notesData is List ? notesData : [];
      
      _CloudRestoreLogger.info('📝 Restaurando ${notes.length} notas...');
      
      // Sincronizar notas (esto debería reemplazar las locales)
      final syncResponse = await apiClient.syncNotes(notes.map((n) => n as Map<String, dynamic>).toList());
      
      if (syncResponse.statusCode == 200) {
        _CloudRestoreLogger.success('✅ Restauración completada');
        
        if (mounted) {
          ToastMessage.success(context, '${notes.length} notas restauradas correctamente');
          widget.onRestoreComplete();
        }
        
        // Cerrar el prompt después de restaurar
        _animationController.reverse().then((_) {
          if (mounted) widget.onDismiss?.call();
        });
      } else {
        throw Exception('Error al sincronizar notas');
      }
      
    } catch (e) {
      _CloudRestoreLogger.error('❌ Error en restauración: $e');
      if (mounted) {
        ToastMessage.error(context, 'Error al restaurar: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isExpanded = false;
        });
      }
    }
  }

  Future<void> _dismissAndRemember() async {
    _CloudRestoreLogger.info('🔔 Usuario seleccionó "Recordar después"');
    _animationController.reverse().then((_) {
      if (mounted) widget.onDismiss?.call();
    });
  }

  Future<void> _neverShowAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cloud_restore_never_show', true);
    _CloudRestoreLogger.info('🚫 Usuario seleccionó "No mostrar más"');
    _animationController.reverse().then((_) {
      if (mounted) widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final noteCount = _latestCloudBackup?['note_count'] ?? 0;
    final backupDate = _latestCloudBackupDate;
    final formattedDate = backupDate != null 
        ? '${backupDate.day}/${backupDate.month}/${backupDate.year} ${backupDate.hour.toString().padLeft(2, '0')}:${backupDate.minute.toString().padLeft(2, '0')}'
        : 'fecha desconocida';
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          bottom: 80,
          left: 16,
          right: 16,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value * 100),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(20),
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [const Color(0xFF1E3A8A), const Color(0xFF4C1D95), const Color(0xFF831843)]
                          : [const Color(0xFF2563EB), const Color(0xFF7C3AED), const Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.cloud_upload,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Backup disponible en la nube',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$noteCount notas • $formattedDate',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: _dismissAndRemember,
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ),
                      
                      // Mensaje informativo
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Hay un backup más reciente en la nube que tus notas actuales. ¿Deseas restaurarlo?',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Botones de acción
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _restoreFromCloud,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF7C3AED),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF7C3AED),
                                        ),
                                      )
                                    : const Text(
                                        'RESTAURAR AHORA',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: _dismissAndRemember,
                                    child: Text(
                                      'Recordar después',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextButton(
                                    onPressed: _neverShowAgain,
                                    child: Text(
                                      'No mostrar más',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}