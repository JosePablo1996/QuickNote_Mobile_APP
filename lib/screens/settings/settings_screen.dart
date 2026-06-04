// lib/screens/settings/settings_screen.dart
// CORREGIDO - Navegación segura con PopScope y go('/notes')
// ✅ CORREGIDO: Al presionar "Atrás" desde Settings siempre va a notas
// ✅ CORREGIDO: Gesto de retroceso no causa pantalla negra
// ✅ CORREGIDO: Error de navegación eliminado
// ✅ SECCIÓN SEGURIDAD REORGANIZADA: Cerrar sesión movido al final
// ✅ NUEVO: LogoutModal como componente independiente
// ✅ BIOMETRÍA: Opción completamente oculta en dispositivos sin huella
// ✅ NUEVO: Entrada para configuración de backups programados
// ✅ REFACTOR: Sección de notificaciones usando NotificationSettingsWidget

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:quicknote/providers/theme_provider.dart';
import 'package:quicknote/screens/settings/developer_screen.dart';
import 'package:quicknote/screens/settings/help_screen.dart';
import 'package:quicknote/screens/settings/changelog_screen.dart';
import 'package:quicknote/screens/backup/backup_screen.dart';
import 'package:quicknote/screens/settings/two_factor_setup_screen.dart';
import 'package:quicknote/screens/auth/forgot_password_screen.dart';
import 'package:quicknote/widgets/toast_message.dart';
import 'package:quicknote/widgets/user_profile_card.dart';
import 'package:quicknote/widgets/logout_modal.dart';
import 'package:quicknote/widgets/notification_settings_widget.dart';
import 'package:quicknote/widgets/app_bottom_nav.dart';
import 'package:quicknote/core/services/two_factor_service.dart';
import 'package:quicknote/core/utils/secure_storage.dart';
import 'package:quicknote/core/utils/token_storage.dart';

class _SettingsLogger {
  static void info(String message) => debugPrint('ℹ️ [Settings] $message');
  static void success(String message) => debugPrint('✅ [Settings] $message');
  static void warning(String message) => debugPrint('⚠️ [Settings] $message');
  static void error(String message) => debugPrint('❌ [Settings] $message');
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  
  get onTabChanged => null;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  bool _autoSaveEnabled = true;
  String _selectedSortOrder = 'Fecha de modificación';
  bool _showPasswordDropdown = false;
  bool _showLogoutModal = false;
  bool _isLoggingOut = false;
  bool _isBiometricEnabled = false;
  bool _isCheckingBiometric = false;
  bool _isTwoFactorEnabled = false;
  bool _isLoadingTwoFactor = true;
  bool _isNavigating = false;

  final List<String> _sortOptions = [
    'Fecha de modificación',
    'Fecha de creación',
    'Título (A-Z)',
    'Título (Z-A)',
  ];

  final SecureStorage _secureStorage = SecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  Future<void> _loadInitialData() async {
    await _loadTwoFactorStatus();
    await _loadBiometricPreference();
  }

  Future<void> _loadTwoFactorStatus() async {
    if (!mounted) return;
    
    setState(() => _isLoadingTwoFactor = true);
    
    try {
      final token = await tokenStorage.getAuthToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _isTwoFactorEnabled = false;
            _isLoadingTwoFactor = false;
          });
        }
        return;
      }
      
      final twoFactorService = TwoFactorService();
      final status = await twoFactorService.getTwoFactorStatus();
      
      if (mounted) {
        setState(() {
          _isTwoFactorEnabled = status['enabled'] == true;
          _isLoadingTwoFactor = false;
        });
        await twoFactorService.saveTwoFactorEnabled(_isTwoFactorEnabled);
        _SettingsLogger.info('Estado 2FA: ${_isTwoFactorEnabled ? "Activado" : "Desactivado"}');
      }
    } catch (e) {
      _SettingsLogger.error('Error 2FA: $e');
      if (mounted) setState(() => _isLoadingTwoFactor = false);
    }
  }

  Future<void> _loadBiometricPreference() async {
    try {
      final isEnabled = await _secureStorage.isBiometricEnabled();
      final authState = ref.read(authProvider);
      final isAvailable = authState.isBiometricAvailable;
      
      _SettingsLogger.info('📱 Cargando preferencia biométrica:');
      _SettingsLogger.info('   Activada en storage: $isEnabled');
      _SettingsLogger.info('   Disponible en dispositivo: $isAvailable');
      
      if (mounted) {
        if (!isAvailable && isEnabled) {
          await _secureStorage.saveBiometricEnabled(false);
          setState(() => _isBiometricEnabled = false);
        } else {
          setState(() => _isBiometricEnabled = isEnabled);
        }
      }
    } catch (e) {
      _SettingsLogger.error('Error biometría: $e');
      if (mounted) setState(() => _isBiometricEnabled = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!mounted || _isCheckingBiometric) return;
    
    setState(() => _isCheckingBiometric = true);
    final authNotifier = ref.read(authProvider.notifier);
    final authState = ref.read(authProvider);
    
    if (!authState.isBiometricAvailable) {
      _SettingsLogger.warning('Biometría no disponible en este dispositivo');
      if (mounted) {
        ToastMessage.warning(context, '🔒 Tu dispositivo no soporta autenticación biométrica.');
        setState(() {
          _isBiometricEnabled = false;
          _isCheckingBiometric = false;
        });
      }
      return;
    }
    
    if (value) {
      await authNotifier.checkBiometricAvailability();
      final currentState = ref.read(authProvider);
      
      if (!currentState.isBiometricAvailable) {
        if (mounted) {
          ToastMessage.warning(context, '🔒 La biometría no está disponible en este dispositivo.');
          setState(() {
            _isBiometricEnabled = false;
            _isCheckingBiometric = false;
          });
        }
        return;
      }
      
      await authNotifier.checkBiometricEnrollment();
      final updatedState = ref.read(authProvider);
      
      if (!updatedState.isBiometricEnrolled) {
        if (mounted) {
          ToastMessage.warning(context, '📱 No hay huellas digitales registradas.\n\nConfigura tu huella en Ajustes del dispositivo antes de activar esta opción.');
          setState(() {
            _isBiometricEnabled = false;
            _isCheckingBiometric = false;
          });
        }
        return;
      }
      
      final authenticated = await authNotifier.authenticateWithBiometric(
        reason: 'Activar autenticación biométrica para QuickNote',
      );
      
      if (!authenticated) {
        if (mounted) {
          ToastMessage.error(context, '🔐 Autenticación fallida. No se pudo activar la biometría.');
          setState(() {
            _isBiometricEnabled = false;
            _isCheckingBiometric = false;
          });
        }
        return;
      }
      
      await _secureStorage.saveBiometricEnabled(true);
      await authNotifier.enableBiometric(true);
      
      if (mounted) {
        ToastMessage.success(context, '✅ Autenticación biométrica activada correctamente');
        setState(() {
          _isBiometricEnabled = true;
          _isCheckingBiometric = false;
        });
      }
    } else {
      await _secureStorage.saveBiometricEnabled(false);
      await authNotifier.enableBiometric(false);
      
      if (mounted) {
        ToastMessage.info(context, '🔓 Autenticación biométrica desactivada');
        setState(() {
          _isBiometricEnabled = false;
          _isCheckingBiometric = false;
        });
      }
    }
  }

  Widget _buildMaterial3Switch(bool value, Future<void> Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 52,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: value ? const Color(0xFF8B5CF6) : Colors.grey.shade400,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: value ? 24 : 4,
              top: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Center(
                  child: Icon(
                    value ? Icons.check : Icons.close,
                    size: 14,
                    color: value ? const Color(0xFF8B5CF6) : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTwoFactor() async {
    if (_isNavigating) return;
    _isNavigating = true;
    
    final token = await tokenStorage.getAuthToken();
    if (token == null || token.isEmpty) {
      _isNavigating = false;
      if (mounted) ToastMessage.error(context, 'No hay sesión activa.');
      return;
    }
    
    if (_isTwoFactorEnabled) {
      _isNavigating = false;
      if (mounted) _showTwoFactorOptions();
    } else {
      final result = await context.push<bool>('/two-factor-setup');
      _isNavigating = false;
      if (result == true && mounted) await _loadTwoFactorStatus();
    }
  }
  
  void _showTwoFactorOptions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Autenticación en Dos Pasos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.blue),
              title: const Text('Ver configuración 2FA'),
              subtitle: const Text('Método TOTP - Google Authenticator'),
              onTap: () {
                Navigator.pop(context);
                context.push('/two-factor-setup').then((_) {
                  if (mounted) _loadTwoFactorStatus();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Desactivar 2FA', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Tu cuenta quedará menos protegida'),
              onTap: () {
                Navigator.pop(context);
                _disableTwoFactor();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
  
  Future<void> _disableTwoFactor() async {
    if (_isNavigating) return;
    _isNavigating = true;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar 2FA'),
        content: const Text('¿Estás seguro de que deseas desactivar la autenticación en dos pasos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desactivar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) {
      _isNavigating = false;
      return;
    }
    
    if (mounted) setState(() => _isLoadingTwoFactor = true);
    
    try {
      final twoFactorService = TwoFactorService();
      final success = await twoFactorService.disableTwoFactor();
      
      if (success && mounted) {
        await _loadTwoFactorStatus();
        ToastMessage.success(context, '2FA desactivado correctamente');
      } else if (mounted) {
        ToastMessage.error(context, 'Error al desactivar 2FA');
        setState(() => _isLoadingTwoFactor = false);
      }
    } catch (e) {
      _SettingsLogger.error('Error desactivando 2FA: $e');
      if (mounted) {
        ToastMessage.error(context, 'Error: ${e.toString()}');
        setState(() => _isLoadingTwoFactor = false);
      }
    }
    _isNavigating = false;
  }

  // ============================================
  // ✅ NAVEGACIÓN CORREGIDA - Siempre usa go('/notes')
  // ============================================
  
  void _goBack() {
    if (_isNavigating) return;
    _isNavigating = true;
    
    _SettingsLogger.info('🔙 Navegando de vuelta a notas');
    
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      try {
        context.go('/notes');
        _SettingsLogger.success('✅ Navegación exitosa a /notes');
      } catch (e) {
        _SettingsLogger.error('Error en navegación: $e');
        try {
          context.go('/notes');
        } catch (e2) {
          _SettingsLogger.error('Error en fallback: $e2');
        }
      } finally {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _isNavigating = false;
        });
      }
    });
  }
  
  void _navigateTo(String route, {Object? extra}) {
    if (_isNavigating) return;
    _isNavigating = true;
    
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      try {
        context.push(route, extra: extra);
        _SettingsLogger.success('✅ Navegación exitosa a $route');
      } catch (e) {
        _SettingsLogger.error('Error navegando a $route: $e');
        if (mounted) ToastMessage.error(context, 'Error de navegación');
      } finally {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _isNavigating = false;
        });
      }
    });
  }

  void _navigateToProfile() => _navigateTo('/profile');
  void _navigateToChangelog() => _navigateTo('/changelog');
  void _navigateToBackup() => _navigateTo('/backup');
  void _navigateToDeveloper() => _navigateTo('/developer');
  void _navigateToHelp() => _navigateTo('/help');
  void _navigateToBackupScheduler() => _navigateTo('/backup-scheduler');

  void _navigateToResetPassword() {
    final user = ref.read(currentUserProvider);
    final email = user?.email ?? '';
    
    if (email.isEmpty) {
      ToastMessage.error(context, 'No se pudo obtener tu correo electrónico');
      return;
    }
    
    _navigateTo('/forgot-password', extra: {'email': email});
  }

  void _logout() async {
    if (_isLoggingOut) return;
    
    setState(() => _isLoggingOut = true);
    await ref.read(authProvider.notifier).logout();
    
    if (mounted) {
      setState(() => _isLoggingOut = false);
      context.go('/login');
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => LogoutModal(
        onConfirm: () {
          Navigator.pop(context);
          _logout();
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final isBiometricAvailable = authState.isBiometricAvailable;
    final user = ref.watch(currentUserProvider);
    final userEmail = user?.email ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack();
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: _buildAppBar(isDarkMode),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              GestureDetector(onTap: _navigateToProfile, child: const UserProfileCard()),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Apariencia', Icons.palette, isDarkMode),
                    const SizedBox(height: 8),
                    _buildCard(isDarkMode, children: [
                      _buildSettingTile(
                        isDarkMode,
                        icon: Icons.dark_mode,
                        iconColor: Colors.blue,
                        title: 'Modo oscuro',
                        subtitle: 'Cambiar entre tema claro y oscuro',
                        trailing: _buildThemeToggle(isDarkMode),
                        showArrow: false,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    
                    // ✅ NUEVA SECCIÓN DE NOTIFICACIONES con NotificationSettingsWidget
                    _buildSectionTitle('Notificaciones', Icons.notifications, isDarkMode),
                    const SizedBox(height: 8),
                    const NotificationSettingsWidget(),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle('Ordenar notas', Icons.sort, isDarkMode),
                    const SizedBox(height: 8),
                    _buildCard(isDarkMode, children: [
                      _buildSettingTile(
                        isDarkMode,
                        icon: Icons.sort_by_alpha,
                        iconColor: Colors.purple,
                        title: 'Ordenar por',
                        subtitle: _selectedSortOrder,
                        trailing: _buildSortDropdown(isDarkMode),
                        showArrow: false,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle('Ajustes generales', Icons.settings, isDarkMode),
                    const SizedBox(height: 8),
                    _buildCard(isDarkMode, children: [
                      _buildSettingTile(
                        isDarkMode,
                        icon: Icons.save,
                        iconColor: Colors.green,
                        title: 'Auto-guardado',
                        subtitle: 'Guardar automáticamente al escribir',
                        trailing: _buildMaterial3Switch(_autoSaveEnabled, (value) async {
                          setState(() => _autoSaveEnabled = value);
                          if (mounted) ToastMessage.info(context, value ? 'Auto-guardado activado' : 'Auto-guardado desactivado');
                        }),
                        showArrow: false,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle('Seguridad', Icons.security, isDarkMode),
                    const SizedBox(height: 8),
                    _buildCard(isDarkMode, children: [
                      _buildSettingTile(
                        isDarkMode,
                        icon: Icons.lock_reset,
                        iconColor: Colors.purple,
                        title: 'Cambiar contraseña',
                        subtitle: 'Recibirás un código OTP a tu correo electrónico',
                        onTap: () => setState(() => _showPasswordDropdown = !_showPasswordDropdown),
                        trailing: Icon(_showPasswordDropdown ? Icons.expand_less : Icons.expand_more, color: isDarkMode ? Colors.white54 : Colors.grey.shade600),
                      ),
                      if (_showPasswordDropdown) _buildPasswordDropdown(isDarkMode, userEmail),
                      
                      _buildSettingTile(
                        isDarkMode,
                        icon: Icons.security,
                        iconColor: Colors.teal,
                        title: 'Autenticación en Dos Pasos (2FA)',
                        subtitle: _isLoadingTwoFactor ? 'Cargando...' : (_isTwoFactorEnabled ? '✅ Activado' : 'Añade capa extra de seguridad'),
                        onTap: _isLoadingTwoFactor ? null : _navigateToTwoFactor,
                        trailing: _isLoadingTwoFactor
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : (_isTwoFactorEnabled
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                    child: const Text('ACTIVADO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                  )
                                : null),
                      ),
                      
                      if (isBiometricAvailable)
                        _buildSettingTile(
                          isDarkMode,
                          icon: Icons.fingerprint,
                          iconColor: Colors.blue,
                          title: 'Autenticación Biométrica',
                          subtitle: _isBiometricEnabled 
                              ? '✅ Activado' 
                              : (_isCheckingBiometric ? 'Verificando...' : 'Usa huella digital o Face ID'),
                          trailing: !_isCheckingBiometric
                              ? _buildMaterial3Switch(_isBiometricEnabled, (value) => _toggleBiometric(value))
                              : const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          showArrow: false,
                        ),
                      
                      _buildDividerLight(isDarkMode),
                      _buildSettingTile(
                        isDarkMode,
                        icon: Icons.backup,
                        iconColor: Colors.orange,
                        title: 'Copias de seguridad',
                        subtitle: 'Crear y restaurar copias de seguridad',
                        onTap: _navigateToBackup,
                      ),
                      
                      // Configuración de backups programados
                      _buildSettingTile(
                        isDarkMode,
                        icon: Icons.schedule,
                        iconColor: Colors.teal,
                        title: 'Backups programados',
                        subtitle: 'Configurar backups automáticos (diario/semanal)',
                        onTap: _navigateToBackupScheduler,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle('Acerca de', Icons.info, isDarkMode),
                    const SizedBox(height: 8),
                    _buildCard(isDarkMode, children: [
                      _buildSettingTile(isDarkMode, icon: Icons.info_outline, iconColor: Colors.blue, title: 'Versión', subtitle: 'QuickNote v2.8.0', showArrow: false),
                      _buildSettingTile(isDarkMode, icon: Icons.history, iconColor: Colors.amber, title: 'Registro de cambios', subtitle: 'Ver todas las novedades', onTap: _navigateToChangelog),
                      _buildSettingTile(isDarkMode, icon: Icons.help_outline, iconColor: Colors.green, title: 'Centro de ayuda', subtitle: 'Preguntas frecuentes y soporte', onTap: _navigateToHelp),
                    ]),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle('Información del desarrollador', Icons.code, isDarkMode, centered: true),
                    const SizedBox(height: 8),
                    _buildDeveloperCard(isDarkMode),
                    
                    const SizedBox(height: 16),
                    
                    // CERRAR SESIÓN - Colocado al final, después del desarrollador
                    _buildSectionTitle('Cuenta', Icons.account_circle, isDarkMode),
                    const SizedBox(height: 8),
                    _buildCard(isDarkMode, children: [
                      _buildSettingTile(
                        isDarkMode,
                        icon: Icons.logout,
                        iconColor: Colors.red,
                        title: 'Cerrar sesión',
                        subtitle: 'Salir de tu cuenta actual',
                        onTap: _showLogoutConfirmation,
                      ),
                    ]),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: 3,
          onTabChanged: (index) {
            _SettingsLogger.info('Tab cambiada a índice: $index');
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    return AppBar(
      title: Text('Configuración', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      centerTitle: true,
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _goBack,
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDarkMode, {bool centered = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Container(width: 3, height: 18, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Icon(icon, size: 16, color: isDarkMode ? Colors.white54 : Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: isDarkMode ? Colors.white54 : Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildCard(bool isDarkMode, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile(
    bool isDarkMode, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade200, width: 0.5))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 22, color: iconColor)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (showArrow && trailing == null) Icon(Icons.chevron_right, color: isDarkMode ? Colors.white54 : Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(bool isDark) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        final newThemeMode = isDark ? ThemeMode.light : ThemeMode.dark;
        ref.read(themeProvider.notifier).setThemeMode(newThemeMode);
        if (mounted) ToastMessage.info(context, isDark ? 'Modo claro activado' : 'Modo oscuro activado');
      },
      child: Container(
        width: 80,
        height: 34,
        decoration: BoxDecoration(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? const Color(0xFF8B5CF6) : const Color(0xFFF59E0B), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)]),
                child: Icon(isDark ? Icons.nightlight_round : Icons.wb_sunny, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortDropdown(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSortOrder,
          icon: Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white70 : Colors.grey.shade700),
          items: _sortOptions.map((option) => DropdownMenuItem(value: option, child: Text(option, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedSortOrder = value);
              if (mounted) ToastMessage.info(context, 'Orden cambiado a $value');
            }
          },
        ),
      ),
    );
  }

  Widget _buildPasswordDropdown(bool isDarkMode, String userEmail) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(child: Text('Recibirás un código de verificación (OTP) a tu correo electrónico', style: GoogleFonts.poppins(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.grey.shade700))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToResetPassword,
              icon: const Icon(Icons.email_outlined, size: 18),
              label: const Text('RESTABLECER CONTRASEÑA CON OTP'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(height: 8),
          Text('Recibirás un código OTP en $userEmail', style: GoogleFonts.poppins(fontSize: 11, color: isDarkMode ? Colors.white54 : Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildDividerLight(bool isDarkMode) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
    );
  }

  Widget _buildDeveloperCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode ? [Colors.purple.shade900.withOpacity(0.4), Colors.pink.shade900.withOpacity(0.4)] : [Colors.purple.shade50, Colors.pink.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? Colors.white24 : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            'Desarrollado con ❤️ por',
            style: GoogleFonts.poppins(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'José Pablo Miranda Quintanilla',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _navigateToDeveloper,
              icon: const Icon(Icons.person, size: 18),
              label: const Text('VER PERFIL DEL DESARROLLADOR'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade400),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}