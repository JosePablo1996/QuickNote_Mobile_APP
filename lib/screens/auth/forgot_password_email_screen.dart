// lib/screens/auth/forgot_password_email_screen.dart
// Pantalla de recuperación de contraseña - PASO 2: Ingresar email
// CORREGIDO: Navegación a login

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:quicknote/screens/auth/forgot_password_verify_screen.dart';
import 'package:quicknote/screens/auth/login_screen.dart';
import 'package:quicknote/widgets/toast_message.dart';

class ForgotPasswordEmailScreen extends ConsumerStatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  ConsumerState<ForgotPasswordEmailScreen> createState() => _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends ConsumerState<ForgotPasswordEmailScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _showEmailHelp = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _sendOtp() async {
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
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.forgotPassword(_emailController.text.trim());

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ForgotPasswordVerifyScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
        ToastMessage.success(context, '📧 Código enviado a tu correo');
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goBack() {
    Navigator.pop(context);
  }

  void _goToLogin() {
    // ✅ CORREGIDO: Navegar directamente a LoginScreen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false, // Elimina todas las rutas anteriores
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
                                _buildStepIndicator(1, 4, isDarkMode, active: true),
                                const SizedBox(width: 8),
                                _buildStepIndicator(2, 4, isDarkMode),
                                const SizedBox(width: 8),
                                _buildStepIndicator(3, 4, isDarkMode),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            Text(
                              'Recuperar contraseña',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.grey.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Te enviaremos un código de verificación a tu correo',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            _buildEmailField(isDarkMode),
                            const SizedBox(height: 12),
                            _buildEmailHelpButton(isDarkMode),
                            if (_showEmailHelp) _buildEmailHelpTip(isDarkMode),
                            const SizedBox(height: 16),
                            
                            if (_error != null) _buildErrorWidget(),
                            
                            _buildSendButton(),
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
      child: const Icon(Icons.email_outlined, size: 36, color: Colors.white),
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