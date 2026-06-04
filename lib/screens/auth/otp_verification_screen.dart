// lib/screens/auth/otp_verification_screen.dart
// Pantalla de verificación OTP - Diseño Glassmorphism con efecto cristal
// CORREGIDO v3:
// - Mejor manejo de errores cuando el email no llega
// - Guardado de email para biometría (login con huella después de OTP)
// - Mensajes más claros sobre el estado del envío
// - Verificación de email válido antes de enviar
// - ✅ REFRESCA EL PERFIL DEL USUARIO DESPUÉS DEL LOGIN (carga avatar, banner, etc.)
// - ✅ INVALIDA EL PROVIDER PARA ACTUALIZAR LA UI

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:quicknote/widgets/toast_message.dart';
import 'package:quicknote/core/utils/secure_storage.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  
  bool _isLoading = false;
  bool _codeSent = false;
  int _timerSeconds = 60;
  Timer? _timer;
  String? _error;
  String? _successMessage;
  bool _showEmailHelp = false;

  final SecureStorage _secureStorage = SecureStorage();

  @override
  void dispose() {
    _emailController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timerSeconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        if (mounted) {
          setState(() => _timerSeconds--);
        }
      }
    });
  }

  // ============================================
  // ✅ VALIDAR EMAIL
  // ============================================
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // ============================================
  // ✅ ENVIAR OTP - CORREGIDO
  // Mejor manejo de errores y mensajes claros
  // ============================================
  Future<void> _sendOtp() async {
    // Validar email
    if (_emailController.text.isEmpty) {
      setState(() => _error = 'Ingresa tu correo electrónico');
      return;
    }
    
    if (!_isValidEmail(_emailController.text)) {
      setState(() => _error = 'Ingresa un correo electrónico válido (ejemplo@correo.com)');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final success = await authNotifier.sendOtp(_emailController.text.trim());

      if (success && mounted) {
        setState(() {
          _codeSent = true;
          _error = null;
          _successMessage = '📧 Código enviado a ${_emailController.text}\nRevisa tu bandeja de entrada o carpeta de spam.';
        });
        _startTimer();
        
        // Enfocar el primer campo OTP
        Future.delayed(const Duration(milliseconds: 100), () {
          _otpFocusNodes[0].requestFocus();
        });
        
        ToastMessage.success(context, '📧 Código enviado a tu correo');
      } else if (mounted) {
        setState(() {
          _error = '❌ No se pudo enviar el código. Verifica que el correo existe y está registrado.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('timeout') || errorMessage.contains('Network')) {
          errorMessage = '⏰ Error de conexión. Verifica tu internet e intenta nuevamente.';
        } else if (errorMessage.contains('400') || errorMessage.contains('not found')) {
          errorMessage = '📧 El correo no está registrado. Verifica tu email.';
        } else if (errorMessage.contains('500')) {
          errorMessage = '⚠️ Error en el servidor. Intenta más tarde.';
        }
        setState(() => _error = errorMessage);
      }
    } finally {
      if (mounted && !_codeSent) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================
  // ✅ VERIFICAR OTP - CORREGIDO CON REFRESH DE PERFIL
  // Guarda email para biometría después de login exitoso
  // Y REFRESCA EL PERFIL PARA CARGAR AVATAR, BANNER, ETC.
  // ============================================
  Future<void> _verifyOtp() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 6) {
      setState(() => _error = 'Ingresa el código de 6 dígitos');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final success = await authNotifier.verifyOtp(_emailController.text.trim(), code);

      if (success && mounted) {
        // ✅ Guardar email para login biométrico (la contraseña no está disponible en OTP)
        final rememberMe = await _secureStorage.getRememberMe();
        if (rememberMe) {
          await _secureStorage.saveSavedEmail(_emailController.text.trim());
          debugPrint('✅ [OTP] Email guardado para login biométrico');
          ToastMessage.info(context, '🔐 Email guardado para acceso rápido con huella');
        }
        
        // ✅ REFRESCAR PERFIL DEL USUARIO - Carga avatar, banner, nombre completo, etc.
        debugPrint('🔄 [OTP] Refrescando perfil del usuario...');
        await authNotifier.refreshProfile();
        
        // ✅ Invalidar el provider para que la UI se actualice con los nuevos datos
        ref.invalidate(currentUserProvider);
        
        debugPrint('✅ [OTP] Perfil refrescado exitosamente');
        ToastMessage.success(context, '✅ Inicio de sesión exitoso');
        context.go('/notes');
      } else if (mounted) {
        final authState = ref.read(authProvider);
        setState(() {
          _error = authState.error ?? '❌ Código inválido o expirado. Solicita uno nuevo.';
          _isLoading = false;
          _clearOtpFields();
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('timeout') || errorMessage.contains('Network')) {
          errorMessage = '⏰ Error de conexión. Verifica tu internet.';
        } else if (errorMessage.contains('invalid') || errorMessage.contains('expired')) {
          errorMessage = '🔢 Código inválido o expirado. Solicita uno nuevo.';
        }
        setState(() => _error = errorMessage);
      }
    } finally {
      if (mounted && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearOtpFields() {
    for (var c in _otpControllers) {
      c.clear();
    }
    _otpFocusNodes[0].requestFocus();
  }

  void _onOtpChanged(String value, int index) {
    // Solo permitir dígitos
    if (value.isNotEmpty && !RegExp(r'^\d+$').hasMatch(value)) {
      _otpControllers[index].clear();
      return;
    }

    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length == 6) {
      _verifyOtp();
    }
  }

  // ============================================
  // ✅ REENVIAR OTP
  // ============================================
  Future<void> _resendOtp() async {
    if (_timerSeconds > 0) {
      setState(() => _error = 'Espera ${_timerSeconds} segundos para reenviar el código');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final authNotifier = ref.read(authProvider.notifier);
      final success = await authNotifier.sendOtp(_emailController.text.trim());
      
      if (success && mounted) {
        setState(() {
          _successMessage = '📧 Nuevo código enviado a ${_emailController.text}';
          _error = null;
        });
        _startTimer();
        _clearOtpFields();
        ToastMessage.success(context, '📧 Nuevo código enviado');
      } else if (mounted) {
        setState(() => _error = 'No se pudo reenviar el código. Intenta nuevamente.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  
                  // ✅ Formulario con efecto Glassmorphism
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
                              _codeSent ? 'Verificar código' : 'Inicio con OTP',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.grey.shade900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _codeSent 
                                  ? 'Ingresa el código de 6 dígitos' 
                                  : 'Recibirás un código por email',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            if (!_codeSent) ...[
                              _buildEmailField(isDarkMode),
                              const SizedBox(height: 12),
                              _buildEmailHelpButton(isDarkMode),
                              if (_showEmailHelp) _buildEmailHelpTip(isDarkMode),
                              const SizedBox(height: 16),
                              if (_error != null) _buildErrorWidget(),
                              _buildSendButton(),
                            ] else ...[
                              // ✅ Mostrar email del usuario
                              _buildUserEmailCard(isDarkMode),
                              const SizedBox(height: 20),
                              _buildOtpFields(isDarkMode),
                              const SizedBox(height: 16),
                              if (_error != null) _buildErrorWidget(),
                              if (_successMessage != null) _buildSuccessWidget(),
                              _buildTimerText(),
                              const SizedBox(height: 12),
                              _buildResendButton(),
                            ],
                            
                            const SizedBox(height: 16),
                            _buildBackButton(isDarkMode),
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

  Widget _buildLogo() {
    return Container(
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
      child: const Icon(Icons.edit_note, size: 36, color: Colors.white),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Verificación OTP',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'QuickNote protege tu cuenta',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailHelpButton(bool isDarkMode) {
    return GestureDetector(
      onTap: () => setState(() => _showEmailHelp = !_showEmailHelp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline,
            size: 14,
            color: isDarkMode ? Colors.white60 : Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            '¿No recibes el código?',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isDarkMode ? Colors.white60 : Colors.white70,
            ),
          ),
          Icon(
            _showEmailHelp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 16,
            color: isDarkMode ? Colors.white60 : Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailHelpTip(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.amber.withValues(alpha: 0.1)
            : Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.email, size: 14, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Text(
                'Consejos para recibir el código:',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Revisa tu carpeta de SPAM o Correo no deseado\n'
            '• Verifica que el correo esté escrito correctamente\n'
            '• Espera unos segundos y solicita un nuevo código\n'
            '• Si el problema persiste, contacta a soporte',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserEmailCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            isDarkMode ? const Color(0xFF374151) : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.email, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Código enviado a:',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _emailController.text,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.email_outlined, size: 18, color: const Color(0xFF8B5CF6)),
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
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: 'correo@ejemplo.com',
          hintStyle: GoogleFonts.poppins(
            color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
          ),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildOtpFields(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        final isFocused = _otpFocusNodes[index].hasFocus;
        final hasValue = _otpControllers[index].text.isNotEmpty;
        
        return Container(
          width: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: isFocused ? [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ] : [],
          ),
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
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
                      ? const Color(0xFF8B5CF6) 
                      : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
                  width: isFocused ? 2 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) => _onOtpChanged(value, index),
          ),
        );
      }),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendOtp,
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
            : Text('ENVIAR CÓDIGO', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTimerText() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (_timerSeconds > 0) {
      return Text(
        'Reenviar en ${_timerSeconds ~/ 60}:${(_timerSeconds % 60).toString().padLeft(2, '0')}',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildResendButton() {
    return TextButton(
      onPressed: _timerSeconds == 0 && !_isLoading ? _resendOtp : null,
      child: Text(
        'Reenviar código',
        style: GoogleFonts.poppins(color: Colors.blue, fontSize: 13),
      ),
    );
  }

  Widget _buildBackButton(bool isDarkMode) {
    return TextButton(
      onPressed: () => context.go('/login'),
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
    );
  }

  Widget _buildErrorWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
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

  Widget _buildSuccessWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _successMessage!,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.green),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _successMessage = null),
            child: const Icon(Icons.close, color: Colors.green, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDarkMode) {
    return Text(
      'QuickNote · Desarrollado con ❤️ por José Pablo Miranda Quintanilla',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 10,
        color: isDarkMode ? Colors.white54 : Colors.white70,
      ),
    );
  }
}