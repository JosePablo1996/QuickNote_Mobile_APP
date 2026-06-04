// lib/screens/settings/change_password_screen.dart
// Pantalla de cambio de contraseña - Diseño Glassmorphism con efecto cristal
// ✅ ACTUALIZADO: Incluye invalidación de sesiones y redirección a login

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:quicknote/screens/auth/login_screen.dart';
import 'package:quicknote/widgets/toast_message.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  String? _error;
  bool _isNavigating = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _getPasswordStrength() {
    final String password = _newPasswordController.text;
    int strength = 0;
    if (password.length >= 8) strength += 20;
    if (password.contains(RegExp(r'[a-z]'))) strength += 20;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 20;
    if (password.contains(RegExp(r'[0-9]'))) strength += 20;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) strength += 20;
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
    return _newPasswordController.text == _confirmPasswordController.text;
  }

  void _navigateToLogin() {
    if (_isNavigating) return;
    _isNavigating = true;
    
    // Limpiar el stack y navegar a login
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty) {
      setState(() => _error = 'Ingresa tu contraseña actual');
      return;
    }

    if (_newPasswordController.text.length < 8) {
      setState(() => _error = 'La nueva contraseña debe tener al menos 8 caracteres');
      return;
    }

    if (!_passwordsMatch()) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }

    if (_newPasswordController.text == _currentPasswordController.text) {
      setState(() => _error = 'La nueva contraseña debe ser diferente a la actual');
      return;
    }

    final int strength = _getPasswordStrength();
    if (strength < 40) {
      setState(() => _error = 'La contraseña es demasiado débil');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final bool success = await authNotifier.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (success && mounted) {
        ToastMessage.success(context, '✅ Contraseña actualizada correctamente');
        
        // Verificar si el usuario sigue autenticado
        final authState = ref.read(authProvider);
        
        if (!authState.isAuthenticated) {
          // Si la sesión fue invalidada, redirigir a login
          ToastMessage.info(context, 'Por favor, inicia sesión nuevamente');
          _navigateToLogin();
        } else {
          // Si sigue autenticado, volver a settings
          context.go('/settings');
        }
      } else if (mounted) {
        setState(() => _error = 'Error al cambiar la contraseña');
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final int passwordStrength = _getPasswordStrength();
    final String strengthText = _getStrengthText(passwordStrength);
    final Color strengthColor = _getStrengthColor(passwordStrength);
    final bool passwordsMatch = _passwordsMatch();
    final bool isFormValid = _newPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        passwordsMatch &&
        _getPasswordStrength() >= 40;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Cambiar contraseña',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeader(isDarkMode),
            const SizedBox(height: 24),
            _buildFormContainer(isDarkMode, passwordStrength, strengthText, strengthColor, passwordsMatch, isFormValid),
            const SizedBox(height: 24),
            _buildSecurityInfo(isDarkMode),
            const SizedBox(height: 24),
            _buildFooter(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Center(
      child: Column(
        children: <Widget>[
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.lock_reset, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Cambiar contraseña',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mantén tu cuenta segura con una contraseña fuerte',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContainer(bool isDarkMode, int passwordStrength, String strengthText, Color strengthColor, bool passwordsMatch, bool isFormValid) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
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
            children: <Widget>[
              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'Contraseña actual',
                hint: '••••••••',
                showPassword: _showCurrentPassword,
                onToggle: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'Nueva contraseña',
                hint: '••••••••',
                showPassword: _showNewPassword,
                onToggle: () => setState(() => _showNewPassword = !_showNewPassword),
                isDarkMode: isDarkMode,
                showStrength: true,
                strength: passwordStrength,
                strengthText: strengthText,
                strengthColor: strengthColor,
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirmar contraseña',
                hint: '••••••••',
                showPassword: _showConfirmPassword,
                onToggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                isDarkMode: isDarkMode,
                error: !passwordsMatch && _confirmPasswordController.text.isNotEmpty
                    ? 'Las contraseñas no coinciden'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _buildErrorWidget(),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFormValid ? const Color(0xFF3B82F6) : Colors.grey,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool showPassword,
    required VoidCallback onToggle,
    required bool isDarkMode,
    bool showStrength = false,
    int strength = 0,
    String strengthText = '',
    Color strengthColor = Colors.grey,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: error != null
                  ? Colors.red
                  : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: !showPassword,
            style: GoogleFonts.poppins(color: isDarkMode ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: isDarkMode ? Colors.white54 : Colors.grey.shade500),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                  color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
                ),
                onPressed: onToggle,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error, style: const TextStyle(fontSize: 12, color: Colors.red)),
        ],
        if (showStrength && controller.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Icon(Icons.shield, size: 14, color: strengthColor),
              const SizedBox(width: 4),
              Text(
                'SEGURIDAD',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              Text(
                strengthText,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: strengthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength / 100,
              backgroundColor: isDarkMode ? Colors.white24 : Colors.grey.shade300,
              color: strengthColor,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              _buildRequirementIcon('8+ caracteres', controller.text.length >= 8, isDarkMode),
              _buildRequirementIcon('Mayúsculas', controller.text.contains(RegExp(r'[A-Z]')), isDarkMode),
              _buildRequirementIcon('Minúsculas', controller.text.contains(RegExp(r'[a-z]')), isDarkMode),
              _buildRequirementIcon('Números', controller.text.contains(RegExp(r'[0-9]')), isDarkMode),
              _buildRequirementIcon('Símbolos', controller.text.contains(RegExp(r'[!@#\$%^&*]')), isDarkMode),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRequirementIcon(String text, bool isValid, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
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

  Widget _buildErrorWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
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

  Widget _buildSecurityInfo(bool isDarkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.grey.shade900.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.security, size: 18, color: Color(0xFF8B5CF6)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Requisitos de seguridad',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.check_circle, 'Mínimo 8 caracteres', true, isDarkMode),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.check_circle, 'Al menos una letra mayúscula', true, isDarkMode),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.check_circle, 'Al menos una letra minúscula', true, isDarkMode),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.check_circle, 'Al menos un número', true, isDarkMode),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.check_circle, 'Al menos un símbolo (!@#\$%^&*)', true, isDarkMode),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Al cambiar tu contraseña, se cerrarán todas las sesiones activas en otros dispositivos. Deberás iniciar sesión nuevamente.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isActive, bool isDarkMode) {
    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: 16,
          color: isActive ? Colors.green : (isDarkMode ? Colors.white54 : Colors.grey.shade500),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isActive
                ? (isDarkMode ? Colors.white70 : Colors.grey.shade700)
                : (isDarkMode ? Colors.white54 : Colors.grey.shade500),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDarkMode) {
    return Center(
      child: Text(
        'QuickNote · Protege tu cuenta con una contraseña segura',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
        ),
      ),
    );
  }
}