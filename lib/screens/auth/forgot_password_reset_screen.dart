// lib/screens/auth/forgot_password_reset_screen.dart
// Pantalla de recuperación de contraseña - PASO 4: Nueva contraseña
// CORREGIDO: Navegación a login después del éxito

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:quicknote/screens/auth/login_screen.dart';
import 'package:quicknote/widgets/toast_message.dart';

class ForgotPasswordResetScreen extends ConsumerStatefulWidget {
  final String email;
  final String otpCode;
  
  const ForgotPasswordResetScreen({
    super.key,
    required this.email,
    required this.otpCode,
  });

  @override
  ConsumerState<ForgotPasswordResetScreen> createState() => _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState extends ConsumerState<ForgotPasswordResetScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _getPasswordStrength() {
    final password = _passwordController.text;
    int strength = 0;
    if (password.length >= 8) strength += 25;
    if (password.contains(RegExp(r'[a-z]'))) strength += 25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 25;
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

  bool _passwordsMatch() {
    return _passwordController.text == _confirmPasswordController.text;
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final strength = _getPasswordStrength();

    if (password.isEmpty) {
      setState(() => _error = 'Ingresa tu nueva contraseña');
      return;
    }

    if (password.length < 8) {
      setState(() => _error = 'La contraseña debe tener al menos 8 caracteres');
      return;
    }

    if (strength < 40) {
      setState(() => _error = 'La contraseña es demasiado débil. Usa mayúsculas, minúsculas y números.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final success = await authNotifier.resetPassword(
        widget.email,
        widget.otpCode,
        password,
      );

      if (success && mounted) {
        ToastMessage.success(context, '✅ Contraseña actualizada correctamente');
        // ✅ CORREGIDO: Navegar directamente a LoginScreen y limpiar el stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else if (mounted) {
        setState(() => _error = 'Error al actualizar la contraseña. Intenta nuevamente.');
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('500')) {
          errorMsg = 'Error en el servidor. Por favor, intenta más tarde.';
        } else if (errorMsg.contains('400')) {
          errorMsg = 'Código inválido o expirado. Solicita uno nuevo.';
        }
        setState(() => _error = errorMsg);
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
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final passwordStrength = _getPasswordStrength();
    final strengthText = _getStrengthText(passwordStrength);
    final strengthColor = _getStrengthColor(passwordStrength);
    final passwordsMatch = _passwordsMatch();
    final isFormValid = _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        passwordsMatch &&
        _getPasswordStrength() >= 40;

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
                                _buildStepIndicator(2, 4, isDarkMode, completed: true),
                                const SizedBox(width: 8),
                                _buildStepIndicator(3, 4, isDarkMode, active: true),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            Text(
                              'Nueva contraseña',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.grey.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Crea una contraseña segura para tu cuenta',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            _buildEmailCard(isDarkMode),
                            const SizedBox(height: 24),
                            
                            _buildPasswordField(isDarkMode, passwordStrength, strengthText, strengthColor),
                            const SizedBox(height: 16),
                            _buildConfirmPasswordField(isDarkMode),
                            
                            if (_error != null) _buildErrorWidget(),
                            const SizedBox(height: 24),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _resetPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFormValid ? const Color(0xFF10B981) : Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        'ACTUALIZAR CONTRASEÑA',
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
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
      child: const Icon(Icons.lock_reset, size: 36, color: Colors.white),
    );
  }

  Widget _buildEmailCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.email_outlined, size: 18, color: const Color(0xFF8B5CF6)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.email,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildPasswordField(bool isDarkMode, int strength, String strengthText, Color strengthColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
              hintText: 'Nueva contraseña',
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
          ),
        ),
        if (_passwordController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.shield, size: 14, color: strengthColor),
                    const SizedBox(width: 6),
                    Text('SEGURIDAD',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white70 : Colors.grey.shade600)),
                    const Spacer(),
                    Text(strengthText,
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.bold, color: strengthColor)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength / 100,
                    backgroundColor: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                    color: strengthColor,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildRequirementIcon('8+ caracteres', _passwordController.text.length >= 8, isDarkMode),
                    _buildRequirementIcon('Mayúsculas', _passwordController.text.contains(RegExp(r'[A-Z]')), isDarkMode),
                    _buildRequirementIcon('Minúsculas', _passwordController.text.contains(RegExp(r'[a-z]')), isDarkMode),
                    _buildRequirementIcon('Números', _passwordController.text.contains(RegExp(r'[0-9]')), isDarkMode),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildConfirmPasswordField(bool isDarkMode) {
    final passwordsMatch = _passwordsMatch();
    final hasValue = _confirmPasswordController.text.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasValue && !passwordsMatch
                  ? Colors.red
                  : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
            ),
          ),
          child: TextField(
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
            style: GoogleFonts.poppins(color: isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Confirmar contraseña',
              hintStyle: GoogleFonts.poppins(color: isDarkMode ? Colors.white54 : Colors.grey.shade500),
              prefixIcon: Icon(Icons.lock_outline,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade600),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasValue && passwordsMatch)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                    ),
                  IconButton(
                    icon: Icon(
                      _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                    ),
                    onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                  ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        if (hasValue && !passwordsMatch)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Las contraseñas no coinciden',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildRequirementIcon(String text, bool isValid, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.circle_outlined,
          size: 12,
          color: isValid ? Colors.green : (isDarkMode ? Colors.white54 : Colors.grey.shade500),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: isValid
                ? Colors.green
                : (isDarkMode ? Colors.white54 : Colors.grey.shade500),
          ),
        ),
      ],
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
      margin: const EdgeInsets.only(top: 16),
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
      'QuickNote · Protege tu cuenta con una contraseña segura',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 11,
        color: isDarkMode ? Colors.white54 : Colors.white70,
      ),
    );
  }
}