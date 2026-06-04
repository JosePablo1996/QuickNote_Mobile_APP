// lib/screens/auth/two_factor_screen.dart
// Pantalla de verificación 2FA - VERSIÓN CON ROL E INSIGNIAS
// ✅ CORREGIDO: Guardado correcto de credenciales biométricas y activación automática de biometría
// ✅ CORREGIDO: Actualización del estado de biometría en el provider
// ✅ CORREGIDO: Persistencia de biometría después de 2FA
// ✅ NUEVO: Muestra el rol del usuario (Administrador/Usuario)
// ✅ NUEVO: Insignia de verificado en el avatar
// ✅ NUEVO: Insignia de verificado junto al nombre

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:quicknote/screens/auth/login_screen.dart';
import 'package:quicknote/screens/notes/home_screen.dart';
import 'package:quicknote/widgets/toast_message.dart';
import 'package:quicknote/core/services/two_factor_service.dart';
import 'package:quicknote/core/utils/secure_storage.dart';
import 'package:quicknote/core/utils/token_storage.dart';

class TwoFactorScreen extends ConsumerStatefulWidget {
  final String tempToken;
  final String email;
  final String? userFullName;
  final String? userAvatar;
  final String? userBanner;
  final String? password;
  final String? userRole; // ✅ NUEVO: Recibir rol del usuario
  final VoidCallback? onTwoFactorComplete;

  const TwoFactorScreen({
    super.key,
    required this.tempToken,
    required this.email,
    this.userFullName,
    this.userAvatar,
    this.userBanner,
    this.password,
    this.userRole,
    this.onTwoFactorComplete,
  });

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  final List<TextEditingController> _codeControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes = List.generate(6, (_) => FocusNode());
  
  bool _isLoading = false;
  bool _isSuccess = false;
  int _attempts = 0;
  String? _error;
  bool _avatarError = false;
  bool _showHelp = false;
  bool _isUsingBackupCode = false;
  String _backupCode = '';

  final TwoFactorService _twoFactorService = TwoFactorService();
  final SecureStorage _secureStorage = SecureStorage();

  @override
  void initState() {
    super.initState();
    debugPrint('=' * 60);
    debugPrint('🔐 [2FA] Pantalla de verificación 2FA iniciada');
    debugPrint('📧 [2FA] Email recibido: ${widget.email}');
    debugPrint('👤 [2FA] Nombre completo recibido: "${widget.userFullName}"');
    debugPrint('👑 [2FA] Rol recibido: "${widget.userRole ?? "user"}"');
    debugPrint('🔑 [2FA] Password presente: ${widget.password != null ? "✅ Sí" : "❌ No"}');
    debugPrint('=' * 60);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authNotifier = ref.read(authProvider.notifier);
        authNotifier.setTwoFactorTempToken(widget.tempToken);
        _codeFocusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (var c in _codeControllers) {
      c.dispose();
    }
    for (var f in _codeFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty && !RegExp(r'^\d+$').hasMatch(value)) {
      _codeControllers[index].clear();
      return;
    }

    if (value.length == 1 && index < 5) {
      _codeFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _codeFocusNodes[index - 1].requestFocus();
    }
    
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length == 6 && !_isUsingBackupCode) {
      _verifyCode();
    }
  }

  void _onBackupCodeChanged(String value) {
    _backupCode = value;
    if (value.length == 14 || value.length == 15) {
      _verifyBackupCode();
    }
  }

  void _goToNotes() {
    debugPrint('🏠 [2FA] goToNotes - navegando a HomeScreen y limpiando stack');
    if (mounted) {
      if (widget.onTwoFactorComplete != null) {
        widget.onTwoFactorComplete!();
      }
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  void _goToLogin() {
    debugPrint('🔐 [2FA] goToLogin - navegando a LoginScreen');
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length != 6) {
      setState(() => _error = 'Ingresa el código de 6 dígitos');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _twoFactorService.verifyTwoFactorLogin(
        code,
        widget.tempToken,
      );

      if (response['access_token'] != null && mounted) {
        await _saveSuccessfulLogin(response);
        
        setState(() => _isSuccess = true);
        
        if (mounted) {
          ToastMessage.success(context, '✅ ¡Verificación exitosa!');
        }
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _goToNotes();
          }
        });
      } else {
        _handleVerificationError(response['message'] ?? 'Código 2FA inválido');
      }
    } catch (e) {
      _handleVerificationError(e.toString());
    } finally {
      if (mounted && !_isSuccess) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyBackupCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _twoFactorService.verifyBackupCode(
        _backupCode,
        widget.tempToken,
      );

      if (response['access_token'] != null && mounted) {
        await _saveSuccessfulLogin(response);
        
        setState(() => _isSuccess = true);
        
        if (mounted) {
          ToastMessage.success(context, '✅ ¡Código de respaldo válido!');
        }
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _goToNotes();
          }
        });
      } else {
        _handleVerificationError(response['message'] ?? 'Código de respaldo inválido');
      }
    } catch (e) {
      _handleVerificationError(e.toString());
    } finally {
      if (mounted && !_isSuccess) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSuccessfulLogin(Map<String, dynamic> response) async {
    debugPrint('💾 [2FA] Guardando datos de login exitoso...');
    
    if (response['access_token'] != null) {
      await tokenStorage.saveAuthToken(response['access_token']);
      debugPrint('✅ [2FA] Token guardado');
    }
    
    if (response['refresh_token'] != null) {
      await tokenStorage.saveRefreshToken(response['refresh_token']);
    }
    
    final userId = response['user_id'] ?? widget.tempToken;
    if (userId.isNotEmpty) {
      await tokenStorage.saveUserId(userId);
      debugPrint('✅ [2FA] UserId guardado: $userId');
    }
    
    if (widget.email.isNotEmpty) {
      await tokenStorage.saveUserEmail(widget.email);
      debugPrint('✅ [2FA] Email guardado: ${widget.email}');
    }
    
    if (widget.userFullName != null && widget.userFullName!.isNotEmpty) {
      await _secureStorage.saveUserName(widget.userFullName!);
      debugPrint('✅ [2FA] Nombre guardado: ${widget.userFullName}');
    }
    
    if (widget.userAvatar != null && widget.userAvatar!.isNotEmpty) {
      await _secureStorage.saveUserAvatar(widget.userAvatar!);
      debugPrint('✅ [2FA] Avatar guardado');
    }
    
    if (widget.userBanner != null && widget.userBanner!.isNotEmpty) {
      await _secureStorage.saveUserBanner(widget.userBanner!);
      debugPrint('✅ [2FA] Banner guardado');
    }
    
    // ✅ Guardar rol
    final userRole = widget.userRole ?? 'user';
    await tokenStorage.saveUserRole(userRole);
    debugPrint('✅ [2FA] Rol guardado: $userRole');
    
    String? passwordToSave = widget.password;
    
    if (passwordToSave == null || passwordToSave.isEmpty) {
      passwordToSave = await _secureStorage.getSavedPassword();
      debugPrint('📝 [2FA] Password obtenido del storage: ${passwordToSave != null ? "✅ Sí" : "❌ No"}');
    }
    
    final rememberMe = await _secureStorage.getRememberMe();
    debugPrint('📝 [2FA] RememberMe actual: $rememberMe');
    
    if (widget.email.isNotEmpty && passwordToSave != null && passwordToSave.isNotEmpty) {
      await _secureStorage.saveCredentialsForBiometric(widget.email, passwordToSave);
      await _secureStorage.saveRememberMe(true);
      debugPrint('✅ [2FA] Credenciales biométricas guardadas/actualizadas');
      debugPrint('   Email: ${widget.email}');
      debugPrint('   Password: ${'*' * (passwordToSave.length > 0 ? passwordToSave.length : 0)}');
      
      await _secureStorage.saveBiometricEnabled(true);
      debugPrint('✅ [2FA] Biometría ACTIVADA automáticamente');
    } else {
      await _secureStorage.saveSavedEmail(widget.email);
      debugPrint('📝 [2FA] Solo email guardado (sin password)');
    }
    
    await tokenStorage.saveTwoFactorVerified(true);
    debugPrint('✅ [2FA] 2FA verificado guardado: true');
    
    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.checkAuthStatus();
    await authNotifier.checkBiometricAvailability();
    
    final hasCredentials = await _secureStorage.hasSavedCredentials();
    final isBiometricEnabled = await _secureStorage.isBiometricEnabled();
    debugPrint('🔍 [2FA] Verificación final:');
    debugPrint('   Credenciales guardadas: $hasCredentials');
    debugPrint('   Biometría activada: $isBiometricEnabled');
    debugPrint('   Rol guardado: $userRole');
    
    debugPrint('✅ [2FA] Autenticación completada correctamente');
  }

  void _handleVerificationError(String message) {
    if (mounted) {
      setState(() {
        _attempts++;
        _error = '$message. Intentos restantes: ${3 - _attempts}';
        _clearCodeFields();
      });
    }
    
    if (_attempts >= 3 && mounted) {
      ToastMessage.error(context, 'Demasiados intentos. Vuelve a iniciar sesión.');
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _goToLogin();
        }
      });
    }
  }

  void _clearCodeFields() {
    for (var c in _codeControllers) {
      c.clear();
    }
    if (mounted) {
      _codeFocusNodes[0].requestFocus();
    }
  }

  void _toggleBackupMode() {
    setState(() {
      _isUsingBackupCode = !_isUsingBackupCode;
      _error = null;
      _backupCode = '';
      _clearCodeFields();
    });
  }

  String _getInitials(String? fullName, String email) {
    if (fullName != null && fullName.isNotEmpty) {
      final parts = fullName.trim().split(' ');
      if (parts.length >= 2) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
      }
      if (parts[0].isNotEmpty) {
        return parts[0][0].toUpperCase();
      }
    }
    final name = email.split('@')[0];
    if (name.isNotEmpty) {
      return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
    }
    return 'U';
  }

  String _getDisplayName(String? fullName, String email) {
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }
    return email.split('@')[0];
  }

  // ✅ NUEVO: Obtener información del rol
  Map<String, dynamic> _getRoleInfo() {
    final role = widget.userRole ?? 'user';
    final isAdmin = role == 'admin';
    
    return {
      'isAdmin': isAdmin,
      'displayName': isAdmin ? 'Administrador' : 'Usuario',
      'color': isAdmin ? Colors.amber : const Color(0xFF8B5CF6),
      'icon': isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final roleInfo = _getRoleInfo();
    final isAdmin = roleInfo['isAdmin'] as bool;
    final roleColor = roleInfo['color'] as Color;
    final roleIcon = roleInfo['icon'] as IconData;
    final roleDisplayName = roleInfo['displayName'] as String;
    
    final initials = _getInitials(widget.userFullName, widget.email);
    final displayName = _getDisplayName(widget.userFullName, widget.email);
    final hasValidAvatar = widget.userAvatar != null && widget.userAvatar!.isNotEmpty && !_avatarError;

    if (_isSuccess) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? const [Color(0xFF1E3A8A), Color(0xFF4C1D95), Color(0xFF831843)]
                  : const [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFEC4899)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_circle, size: 50, color: Colors.white),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  '¡Verificación exitosa!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Redirigiendo al dashboard...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? const [Color(0xFF1E3A8A), Color(0xFF4C1D95), Color(0xFF831843)]
                : const [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFEC4899)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 24),
                  
                  // Tarjeta de usuario
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                            isDarkMode ? const Color(0xFF374151) : Colors.white,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: roleColor.withValues(alpha: 0.3),
                          width: isAdmin ? 1.5 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Avatar con insignia de verificado
                            Center(
                              child: Stack(
                                children: [
                                  Container(
                                    width: 85,
                                    height: 85,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipOval(
                                      child: hasValidAvatar
                                          ? Image.network(
                                              widget.userAvatar!,
                                              fit: BoxFit.cover,
                                              width: 85,
                                              height: 85,
                                              errorBuilder: (context, error, stackTrace) {
                                                if (!_avatarError) {
                                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                                    if (mounted) setState(() => _avatarError = true);
                                                  });
                                                }
                                                return _buildAvatarFallback(initials);
                                              },
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return _buildAvatarFallback(initials, isLoading: true);
                                              },
                                            )
                                          : _buildAvatarFallback(initials),
                                    ),
                                  ),
                                  // ✅ INSIGNIA DE VERIFICADO EN EL AVATAR
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: roleColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: Icon(
                                        isAdmin ? Icons.star : Icons.verified,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Nombre con insignia de verificado
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(width: 6),
                                  // ✅ INSIGNIA DE VERIFICADO JUNTO AL NOMBRE
                                  Icon(
                                    isAdmin ? Icons.star : Icons.verified,
                                    size: 18,
                                    color: roleColor,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Email
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDarkMode 
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade500),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.email,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // ✅ NUEVO: ROL DEL USUARIO
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      roleColor.withValues(alpha: 0.15),
                                      roleColor.withValues(alpha: 0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: roleColor.withValues(alpha: 0.3),
                                    width: isAdmin ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(roleIcon, size: 14, color: roleColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      roleDisplayName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: roleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Estado de verificación 2FA
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.shield, size: 12, color: Color(0xFF8B5CF6)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Verificación requerida',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF8B5CF6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Center(
                    child: Text(
                      _isUsingBackupCode ? 'Ingresa el código de respaldo' : 'Ingresa el código',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _isUsingBackupCode 
                          ? 'Código de respaldo que guardaste al activar 2FA'
                          : 'Código de 6 dígitos de Google Authenticator',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildVerificationForm(isDarkMode, roleColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.edit_note, size: 35, color: Colors.white),
      ),
    );
  }

  Widget _buildAvatarFallback(String initials, {bool isLoading = false}) {
    return Container(
      width: 85,
      height: 85,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                initials,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildVerificationForm(bool isDarkMode, Color roleColor) {
    final code = _codeControllers.map((c) => c.text).join();
    final isCodeComplete = code.length == 6;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade900.withValues(alpha: 0.85)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!_isUsingBackupCode)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                final isFocused = _codeFocusNodes[index].hasFocus;
                final hasValue = _codeControllers[index].text.isNotEmpty;
                
                return Container(
                  width: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isFocused ? [
                      BoxShadow(
                        color: roleColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ] : [],
                  ),
                  child: TextField(
                    controller: _codeControllers[index],
                    focusNode: _codeFocusNodes[index],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: isDarkMode 
                          ? (hasValue ? Colors.grey.shade700 : Colors.grey.shade800)
                          : (hasValue ? Colors.grey.shade100 : Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isFocused 
                              ? roleColor 
                              : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
                          width: isFocused ? 2 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: roleColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) => _onCodeChanged(value, index),
                  ),
                );
              }),
            ),
          
          if (_isUsingBackupCode)
            TextField(
              onChanged: _onBackupCodeChanged,
              style: GoogleFonts.poppins(
                fontSize: 16,
                letterSpacing: 2,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'XXXXX-XXXXX',
                hintStyle: GoogleFonts.poppins(
                  color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: roleColor, width: 2),
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
              ),
            ),
          
          const SizedBox(height: 24),
          
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          if (_attempts > 0 && _attempts < 3 && !_isUsingBackupCode)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Intentos restantes: ${3 - _attempts} de 3',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isLoading || (_isUsingBackupCode ? _backupCode.length < 10 : !isCodeComplete)) ? null : 
                (_isUsingBackupCode ? _verifyBackupCode : _verifyCode),
              style: ElevatedButton.styleFrom(
                backgroundColor: roleColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: (_isUsingBackupCode ? _backupCode.length >= 10 : isCodeComplete) ? 4 : 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _isUsingBackupCode ? 'VERIFICAR CÓDIGO DE RESPALDO' : 'VERIFICAR Y ACCEDER',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Center(
            child: TextButton(
              onPressed: _toggleBackupMode,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isUsingBackupCode ? Icons.arrow_back : Icons.security,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isUsingBackupCode 
                        ? 'Volver al código normal'
                        : 'Usar código de respaldo',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Center(
            child: TextButton(
              onPressed: _goToLogin,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Volver al inicio de sesión',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          _buildHelpSection(isDarkMode, roleColor),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'QuickNote · Desarrollado con ❤️ por José Pablo Miranda Quintanilla',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: isDarkMode ? Colors.white54 : Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(bool isDarkMode, Color roleColor) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showHelp = !_showHelp;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.help_outline, size: 14, color: roleColor),
                const SizedBox(width: 6),
                Text(
                  '¿Cómo obtener el código?',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: roleColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showHelp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: roleColor,
                ),
              ],
            ),
          ),
        ),
        if (_showHelp)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  roleColor.withValues(alpha: 0.1),
                  roleColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: roleColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpStep('1', 'Abre Google Authenticator', 'O cualquier app compatible (Authy, Microsoft Authenticator)', isDarkMode),
                const SizedBox(height: 12),
                _buildHelpStep('2', 'Busca la cuenta de QuickNote', 'Identificada con tu correo electrónico', isDarkMode),
                const SizedBox(height: 12),
                _buildHelpStep('3', 'Ingresa el código de 6 dígitos', 'El código se actualiza cada 30 segundos', isDarkMode),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Si no configuraste 2FA, usa un código de respaldo o contacta a soporte.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHelpStep(String number, String title, String description, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}