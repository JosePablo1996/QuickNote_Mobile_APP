// lib/screens/auth/forgot_password_verify_screen.dart
// Pantalla de recuperación de contraseña - PASO 3: Verificar código OTP
// CORREGIDO: Navegación a login

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:quicknote/screens/auth/forgot_password_reset_screen.dart';
import 'package:quicknote/screens/auth/login_screen.dart';
import 'package:quicknote/widgets/toast_message.dart';

class ForgotPasswordVerifyScreen extends ConsumerStatefulWidget {
  final String email;
  
  const ForgotPasswordVerifyScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<ForgotPasswordVerifyScreen> createState() => _ForgotPasswordVerifyScreenState();
}

class _ForgotPasswordVerifyScreenState extends ConsumerState<ForgotPasswordVerifyScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  
  bool _isLoading = false;
  int _timerSeconds = 60;
  Timer? _timer;
  String? _error;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
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

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && !RegExp(r'^\d+$').hasMatch(value)) {
      _otpControllers[index].clear();
      return;
    }

    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    
    if (_otpCode.length == 6) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      setState(() => _error = 'Ingresa el código de 6 dígitos');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final success = await authNotifier.verifyPasswordResetOtp(
        widget.email,
        _otpCode,
      );

      if (success && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ForgotPasswordResetScreen(
              email: widget.email,
              otpCode: _otpCode,
            ),
          ),
        );
        ToastMessage.success(context, '✅ Código verificado');
      } else if (mounted) {
        setState(() => _error = 'Código inválido o expirado');
        _clearOtpFields();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Código inválido o expirado';
          _isLoading = false;
        });
        _clearOtpFields();
      }
    } finally {
      if (mounted && !_isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

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
      await authNotifier.forgotPassword(widget.email);
      
      if (mounted) {
        setState(() {
          _successMessage = '📧 Nuevo código enviado a ${widget.email}';
          _error = null;
        });
        _startTimer();
        _clearOtpFields();
        ToastMessage.success(context, '📧 Nuevo código enviado');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudo reenviar el código. Intenta nuevamente.');
      }
    } finally {
      if (mounted) {
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

  void _goBack() {
    Navigator.pop(context);
  }

  void _goToLogin() {
    // ✅ CORREGIDO: Navegar directamente a LoginScreen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStepIndicator(0, 4, isDarkMode, completed: true),
                                const SizedBox(width: 8),
                                _buildStepIndicator(1, 4, isDarkMode, completed: true),
                                const SizedBox(width: 8),
                                _buildStepIndicator(2, 4, isDarkMode, active: true),
                                const SizedBox(width: 8),
                                _buildStepIndicator(3, 4, isDarkMode),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            Text(
                              'Verifica tu identidad',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.grey.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ingresa el código de 6 dígitos',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            _buildEmailCard(isDarkMode),
                            const SizedBox(height: 24),
                            
                            _buildOtpFields(isDarkMode),
                            const SizedBox(height: 16),
                            
                            if (_error != null) _buildErrorWidget(),
                            if (_successMessage != null) _buildSuccessWidget(),
                            
                            _buildTimerText(),
                            const SizedBox(height: 8),
                            _buildResendButton(),
                            const SizedBox(height: 16),
                            _buildBackButtons(isDarkMode),
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

  Widget _buildStepIndicator(int step, int total, bool isDarkMode, {bool active = false, bool completed = false}) {
    Color color;
    if (completed) {
      color = const Color(0xFF10B981);
    } else if (active) {
      color = const Color(0xFF10B981);
    } else {
      color = isDarkMode ? Colors.white24 : Colors.grey.shade300;
    }
    
    return Container(
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
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
      child: const Icon(Icons.verified, size: 36, color: Colors.white),
    );
  }

  Widget _buildEmailCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            isDarkMode ? const Color(0xFF374151) : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.email, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
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
                  widget.email,
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
        ],
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

  Widget _buildBackButtons(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
          onPressed: _goBack,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back, size: 16),
              const SizedBox(width: 4),
              Text(
                'Volver',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _goToLogin,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home, size: 16),
              const SizedBox(width: 4),
              Text(
                'Inicio de sesión',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
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