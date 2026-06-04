// lib/screens/auth/login_screen.dart
// Pantalla de inicio de sesión - Diseño Glassmorphism con efecto cristal
// CORREGIDO v16: 
// - ELIMINADOS badges "2FA disponible" y "OTP"
// - CORREGIDO: Activación automática de biometría después de login exitoso
// - CORREGIDO: Guardado correcto de RememberMe en el storage
// - CORREGIDO: Credenciales biométricas persisten entre sesiones
// - Conexión correcta con el flujo de recuperación de contraseña
// - Manejo correcto de 2FA después de login biométrico
// - Redirección a pantalla de verificación 2FA cuando es necesario
// - Mejor manejo de errores y estados de carga
// - NUEVO: Pasar el rol del usuario a la pantalla de 2FA

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:quicknote/screens/auth/two_factor_screen.dart';
import 'package:quicknote/screens/auth/forgot_password_screen.dart';
import 'package:quicknote/core/utils/secure_storage.dart';
import 'package:quicknote/widgets/toast_message.dart';

// Logger interno
class _LoginScreenLogger {
  static void info(String message) {
    debugPrint('ℹ️ [LoginScreen] $message');
  }
  static void success(String message) {
    debugPrint('✅ [LoginScreen] $message');
  }
  static void warning(String message) {
    debugPrint('⚠️ [LoginScreen] $message');
  }
  static void error(String message) {
    debugPrint('❌ [LoginScreen] $message');
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final SecureStorage _secureStorage = SecureStorage();
  bool _showPassword = false;
  bool _rememberMe = false;
  bool _showAlternativeMethods = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRememberMePreference();
    
    // ✅ AUTO-LOGIN BIOMÉTRICO - Verificar al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoBiometricLogin();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================
  // CARGAR PREFERENCIA DE RECORDARME
  // ============================================
  Future<void> _loadRememberMePreference() async {
    try {
      final rememberMeValue = await _secureStorage.getRememberMe();
      if (mounted) {
        setState(() {
          _rememberMe = rememberMeValue;
        });
        _LoginScreenLogger.info('📝 RememberMe cargado: $_rememberMe');
      }
    } catch (e) {
      _LoginScreenLogger.error('❌ Error cargando RememberMe: $e');
    }
  }

  // ============================================
  // AUTO-LOGIN BIOMÉTRICO
  // ============================================
  Future<void> _checkAutoBiometricLogin() async {
    try {
      if (!mounted) return;
      final authState = ref.read(authProvider);
      
      if (authState.isAuthenticated) {
        _LoginScreenLogger.info('🔐 Usuario ya autenticado, omitiendo auto-login');
        return;
      }
      
      final isBiometricEnabled = await _secureStorage.isBiometricEnabled();
      final hasCredentials = await _secureStorage.hasSavedCredentials();
      final isBiometricAvailable = authState.isBiometricAvailable;
      
      _LoginScreenLogger.info('🔍 Verificando auto-login biométrico:');
      _LoginScreenLogger.info('   Biometría activada en settings (storage): $isBiometricEnabled');
      _LoginScreenLogger.info('   Credenciales guardadas: $hasCredentials');
      _LoginScreenLogger.info('   Biometría disponible en dispositivo: $isBiometricAvailable');
      
      if (isBiometricEnabled && hasCredentials && isBiometricAvailable && mounted) {
        _LoginScreenLogger.info('🔄 Iniciando auto-login biométrico...');
        
        if (!mounted) return;
        
        if (mounted) {
          ToastMessage.info(context, '🔐 Verificando identidad...');
        }
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          await _handleBiometricLogin(auto: true);
        }
      }
    } catch (e) {
      _LoginScreenLogger.error('❌ Error en auto-login biométrico: $e');
    }
  }

  // ============================================
  // NAVEGAR A RECUPERACIÓN DE CONTRASEÑA
  // ============================================
  void _navigateToForgotPassword() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  // ============================================
  // GUARDAR CREDENCIALES BIOMÉTRICAS Y ACTIVAR BIOMETRÍA
  // ============================================
  Future<void> _saveBiometricCredentialsAndEnable(String email, String password) async {
    if (_rememberMe && email.isNotEmpty && password.isNotEmpty) {
      await _secureStorage.saveCredentialsForBiometric(email, password);
      await _secureStorage.saveBiometricEnabled(true);
      await _secureStorage.saveRememberMe(true);
      _LoginScreenLogger.success('✅ Credenciales guardadas y biometría ACTIVADA');
      _LoginScreenLogger.info('   Email guardado: $email');
    } else {
      _LoginScreenLogger.info('No se guardaron credenciales (rememberMe=$_rememberMe)');
    }
  }

  // ============================================
  // LOGIN CON EMAIL Y CONTRASEÑA (CORREGIDO v16)
  // ============================================
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty) {
      setState(() => _error = 'Por favor ingresa tu correo electrónico');
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Por favor ingresa tu contraseña');
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      
      // Guardar rememberMe ANTES del login
      await _secureStorage.saveRememberMe(_rememberMe);
      _LoginScreenLogger.info('📝 RememberMe guardado: $_rememberMe');
      
      final response = await authNotifier.loginWithResponse(email, password);
      _LoginScreenLogger.info('📡 Respuesta login recibida');

      if (!mounted) return;

      final requiresTwoFactor = response['requires_2fa'] == true;
      
      if (requiresTwoFactor) {
        final tempToken = response['temp_token'] ?? response['user_id'];
        final userData = response['user'] as Map<String, dynamic>?;
        final userFullName = userData?['full_name'] ?? userData?['name'];
        final userAvatar = userData?['avatar'];
        final userBanner = userData?['banner'];
        final userRole = userData?['role'] ?? 'user'; // ✅ NUEVO: Obtener rol
        
        _LoginScreenLogger.info('🔐 Redirigiendo a 2FA - Rol: $userRole');
        
        // Guardar credenciales y ACTIVAR biometría ANTES de ir a 2FA
        if (_rememberMe && email.isNotEmpty && password.isNotEmpty) {
          await _secureStorage.saveCredentialsForBiometric(email, password);
          await _secureStorage.saveBiometricEnabled(true);
          await _secureStorage.saveRememberMe(true);
          _LoginScreenLogger.success('✅ Credenciales guardadas y biometría ACTIVADA');
        }
        
        if (tempToken != null && tempToken.isNotEmpty && mounted) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TwoFactorScreen(
                  tempToken: tempToken,
                  email: email,
                  password: password,
                  userFullName: userFullName,
                  userAvatar: userAvatar,
                  userBanner: userBanner,
                  userRole: userRole, // ✅ NUEVO: Pasar rol
                  onTwoFactorComplete: () async {
                    await _secureStorage.saveRememberMe(_rememberMe);
                    if (_rememberMe) {
                      await _secureStorage.saveCredentialsForBiometric(email, password);
                      await _secureStorage.saveBiometricEnabled(true);
                      _LoginScreenLogger.success('✅ Credenciales re-verificadas después de 2FA');
                    }
                  },
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            setState(() {
              _error = 'Error: No se recibió token temporal para 2FA';
              _isLoading = false;
            });
          }
        }
        return;
      }
      
      if (response['access_token'] != null) {
        // Guardar credenciales y ACTIVAR biometría después de login exitoso
        if (_rememberMe && email.isNotEmpty && password.isNotEmpty) {
          await _secureStorage.saveCredentialsForBiometric(email, password);
          await _secureStorage.saveBiometricEnabled(true);
          await _secureStorage.saveRememberMe(true);
          _LoginScreenLogger.success('✅ Credenciales guardadas y biometría ACTIVADA');
          _LoginScreenLogger.info('   Email guardado: $email');
        }
        
        if (mounted) {
          ToastMessage.success(context, '✅ ¡Bienvenido!');
          context.go('/notes');
        }
      } else {
        final errorMsg = response['message'] ?? 'Email o contraseña incorrectos';
        if (mounted) {
          setState(() {
            _error = errorMsg;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      _LoginScreenLogger.error('❌ Error en login: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================
  // LOGIN BIOMÉTRICO (CORREGIDO v16)
  // ============================================
  Future<void> _handleBiometricLogin({bool auto = false}) async {
    if (!mounted) return;
    
    if (!auto) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final authState = ref.read(authProvider);
      
      _LoginScreenLogger.info('🔐 Iniciando login biométrico...');
      
      final isBiometricEnabledFromStorage = await _secureStorage.isBiometricEnabled();
      final isBiometricAvailable = authState.isBiometricAvailable;
      
      _LoginScreenLogger.info('🔍 Verificando estado biometría:');
      _LoginScreenLogger.info('   Desde storage: $isBiometricEnabledFromStorage');
      _LoginScreenLogger.info('   Disponible en dispositivo: $isBiometricAvailable');
      
      if (!isBiometricAvailable) {
        final errorMsg = '🔒 La biometría no está disponible en este dispositivo.';
        if (!auto && mounted) {
          setState(() {
            _error = errorMsg;
            _isLoading = false;
          });
        }
        return;
      }
      
      if (!isBiometricEnabledFromStorage) {
        final errorMsg = '🔓 La autenticación biométrica no está activada.\nActívala en Configuración > Seguridad.';
        if (!auto && mounted) {
          setState(() {
            _error = errorMsg;
            _isLoading = false;
          });
        } else {
          _LoginScreenLogger.info('Biometría no activada en configuración');
        }
        return;
      }
      
      final hasCredentials = await _secureStorage.hasSavedCredentials();
      if (!hasCredentials) {
        final errorMsg = '📝 No hay credenciales guardadas para acceso biométrico.\nInicia sesión manualmente primero y activa "Recordarme".';
        if (!auto && mounted) {
          setState(() {
            _error = errorMsg;
            _isLoading = false;
          });
        } else {
          _LoginScreenLogger.warning('No hay credenciales guardadas');
        }
        return;
      }
      
      _LoginScreenLogger.info('🔄 Solicitando autenticación biométrica...');
      
      final authenticated = await authNotifier.authenticateWithBiometric(
        reason: 'Verifica tu identidad para acceder a QuickNote',
      );
      
      if (!authenticated) {
        _LoginScreenLogger.warning('❌ Autenticación biométrica fallida');
        if (!auto && mounted) {
          setState(() {
            _error = '🔐 Autenticación biométrica fallida.';
            _isLoading = false;
          });
        }
        return;
      }
      
      _LoginScreenLogger.success('✅ Autenticación biométrica exitosa');
      
      final savedEmail = await _secureStorage.getSavedEmail();
      final savedPassword = await _secureStorage.getSavedPassword();
      
      if (savedEmail == null || savedEmail.isEmpty || savedPassword == null || savedPassword.isEmpty) {
        _LoginScreenLogger.error('❌ Credenciales guardadas no encontradas');
        if (!auto && mounted) {
          setState(() {
            _error = 'Error: No se encontraron las credenciales guardadas.';
            _isLoading = false;
          });
        }
        return;
      }
      
      _LoginScreenLogger.info('📧 Credenciales encontradas para: $savedEmail');
      
      final response = await authNotifier.loginWithResponse(savedEmail, savedPassword);
      
      if (!mounted) return;
      
      final requiresTwoFactor = response['requires_2fa'] == true;
      
      if (requiresTwoFactor) {
        final tempToken = response['temp_token'] ?? response['user_id'];
        final userData = response['user'] as Map<String, dynamic>?;
        final userFullName = userData?['full_name'] ?? userData?['name'];
        final userAvatar = userData?['avatar'];
        final userBanner = userData?['banner'];
        final userRole = userData?['role'] ?? 'user'; // ✅ NUEVO: Obtener rol
        
        _LoginScreenLogger.info('🔐 Login biométrico requiere 2FA - Rol: $userRole');
        
        if (tempToken != null && tempToken.isNotEmpty && mounted) {
          if (!auto && mounted) {
            setState(() => _isLoading = false);
          }
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TwoFactorScreen(
                  tempToken: tempToken,
                  email: savedEmail,
                  password: savedPassword,
                  userFullName: userFullName,
                  userAvatar: userAvatar,
                  userBanner: userBanner,
                  userRole: userRole, // ✅ NUEVO: Pasar rol
                ),
              ),
            );
          }
        } else {
          if (!auto && mounted) {
            setState(() {
              _error = 'Error: No se recibió token temporal para 2FA';
              _isLoading = false;
            });
          }
        }
        return;
      }
      
      if (response['access_token'] != null) {
        _LoginScreenLogger.success('🎉 Login biométrico exitoso');
        if (mounted) {
          ToastMessage.success(context, '✅ Bienvenido de vuelta');
          context.go('/notes');
        }
      } else if (!auto && mounted) {
        setState(() {
          _error = response['message'] ?? 'Error en login biométrico';
          _isLoading = false;
        });
      }
    } catch (e) {
      _LoginScreenLogger.error('❌ Error en login biométrico: $e');
      if (!auto && mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    } finally {
      if (!auto && mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================
  // LOGIN CON OTP
  // ============================================
  void _handleOtpLogin() {
    if (!mounted) return;
    context.push('/otp-login');
  }

  // ============================================
  // UI - INDICADOR DE SEGURIDAD
  // ============================================
  int _getPasswordStrength() {
    final password = _passwordController.text;
    int strength = 0;
    if (password.length >= 8) strength += 20;
    if (password.contains(RegExp(r'[a-z]'))) strength += 20;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 20;
    if (password.contains(RegExp(r'[0-9]'))) strength += 20;
    if (password.contains(RegExp(r'[^a-zA-Z0-9]'))) strength += 20;
    return strength.clamp(0, 100);
  }

  String _getStrengthText(int strength) {
    if (strength == 0) return '';
    if (strength < 40) return 'Débil';
    if (strength < 70) return 'Media';
    return 'Fuerte';
  }

  Color _getStrengthColor(int strength) {
    if (strength < 40) return Colors.red;
    if (strength < 70) return Colors.orange;
    return Colors.green;
  }

  // ============================================
  // BUILD PRINCIPAL
  // ============================================
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final passwordStrength = _getPasswordStrength();
    final strengthText = _getStrengthText(passwordStrength);
    final strengthColor = _getStrengthColor(passwordStrength);
    final authState = ref.watch(authProvider);
    
    final showBiometric = authState.isBiometricAvailable && !_isLoading;

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
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey.shade900.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Bienvenido de vuelta',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.grey.shade900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ingresa tus credenciales para acceder',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            if (_error != null) _buildErrorWidget(),
                            
                            _buildEmailField(isDarkMode),
                            const SizedBox(height: 16),
                            _buildPasswordField(isDarkMode),
                            
                            if (_passwordController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _buildStrengthIndicator(
                                  passwordStrength,
                                  strengthText,
                                  strengthColor,
                                  isDarkMode,
                                ),
                              ),
                            
                            _buildOptionsRow(isDarkMode),
                            const SizedBox(height: 24),
                            _buildLoginButton(),
                            const SizedBox(height: 16),
                            _buildAlternativeMethodsButton(isDarkMode, showBiometric),
                            _buildDivider(isDarkMode),
                            _buildRegisterLink(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  _buildFooter(isDarkMode),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // WIDGETS DE UI
  // ============================================

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.edit_note, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Quick',
                style: GoogleFonts.poppins(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Note',
                style: GoogleFonts.poppins(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFFA78BFA), Color(0xFFF472B6)],
                    ).createShader(const Rect.fromLTWH(0, 0, 150, 50)),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _error = null),
            child: const Icon(Icons.close, color: Colors.red, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
      ),
      child: TextField(
        controller: _emailController,
        style: GoogleFonts.poppins(color: isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'correo@ejemplo.com',
          hintStyle: GoogleFonts.poppins(color: isDarkMode ? Colors.white54 : Colors.grey.shade500),
          prefixIcon: Icon(Icons.email_outlined,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
      ),
    );
  }

  Widget _buildPasswordField(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_showPassword,
        style: GoogleFonts.poppins(color: isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: '••••••••',
          hintStyle: GoogleFonts.poppins(color: isDarkMode ? Colors.white54 : Colors.grey.shade500),
          prefixIcon: Icon(Icons.lock_outline,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600),
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            ),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        autofillHints: const [AutofillHints.password],
      ),
    );
  }

  Widget _buildStrengthIndicator(
    int strength,
    String text,
    Color color,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.shield, size: 14, color: color),
            const SizedBox(width: 6),
            Text('SEGURIDAD',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600)),
            const Spacer(),
            Text(text, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strength / 100,
            backgroundColor: isDarkMode ? Colors.white24 : Colors.grey.shade300,
            color: color,
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsRow(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) => setState(() => _rememberMe = value ?? false),
                activeColor: Colors.blue,
                side: BorderSide(color: isDarkMode ? Colors.white54 : Colors.grey.shade400),
              ),
              Text('Recordarme',
                  style: GoogleFonts.poppins(color: isDarkMode ? Colors.white70 : Colors.grey.shade700)),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: _navigateToForgotPassword,
            child: Text('¿Olvidaste tu contraseña?',
                style: GoogleFonts.poppins(color: Colors.blue, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login, size: 18),
                  const SizedBox(width: 8),
                  Text('INICIAR SESIÓN', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  Widget _buildAlternativeMethodsButton(bool isDarkMode, bool showBiometric) {
    return Column(
      children: [
        OutlinedButton(
          onPressed: () => setState(() => _showAlternativeMethods = !_showAlternativeMethods),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade400),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, size: 18),
              const SizedBox(width: 8),
              Text('Inicia sesión de otras formas',
                  style: GoogleFonts.poppins(color: isDarkMode ? Colors.white70 : Colors.grey.shade700)),
              Icon(_showAlternativeMethods ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18),
            ],
          ),
        ),
        if (_showAlternativeMethods) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey.shade800.withValues(alpha: 0.5)
                  : Colors.grey.shade100.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Text('Métodos alternativos de inicio de sesión',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Elige tu método preferido para acceder',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 16),
                if (showBiometric)
                  _buildAlternativeOption(
                    icon: Icons.fingerprint,
                    label: 'Acceso Biométrico',
                    subtitle: 'Usa huella digital o Face ID para acceder',
                    color: Colors.purple,
                    onTap: () => _handleBiometricLogin(auto: false),
                  ),
                if (showBiometric) const SizedBox(height: 12),
                _buildAlternativeOption(
                  icon: Icons.smartphone,
                  label: 'Código OTP',
                  subtitle: 'Recibe un código por email',
                  color: Colors.green,
                  onTap: _handleOtpLogin,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.purple.withValues(alpha: 0.1)
                        : Colors.purple.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield, size: 16, color: Colors.purple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Si tienes 2FA activado, se te pedirá el código después de iniciar sesión',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: isDarkMode ? Colors.white70 : Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAlternativeOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.grey.shade800.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: onTap == null ? Colors.grey : color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: onTap == null 
                              ? Colors.grey 
                              : (isDarkMode ? Colors.white70 : Colors.grey.shade600))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: onTap == null ? Colors.grey : color),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(child: Divider(color: isDarkMode ? Colors.white24 : Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('¿Nuevo en QuickNote?',
                style: GoogleFonts.poppins(
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600, fontSize: 12)),
          ),
          Expanded(child: Divider(color: isDarkMode ? Colors.white24 : Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: TextButton(
        onPressed: () {
          if (mounted) context.push('/register');
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✨', style: TextStyle(fontSize: 14)),
            SizedBox(width: 8),
            Text('Crear una cuenta nueva', style: TextStyle(color: Colors.blue)),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward, size: 14, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDarkMode) {
    return Text(
      'QuickNote · Desarrollado con ❤️ por José Pablo Miranda Quintanilla',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(fontSize: 10, color: isDarkMode ? Colors.white54 : Colors.white70),
    );
  }
}