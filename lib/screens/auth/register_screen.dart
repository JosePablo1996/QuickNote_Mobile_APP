// lib/screens/auth/register_screen.dart
// Pantalla de registro de usuario - Diseño Glassmorphism con efecto cristal

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:quicknote/widgets/toast_message.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      setState(() => _error = 'Por favor ingresa tu nombre completo');
      return;
    }

    if (_emailController.text.isEmpty) {
      setState(() => _error = 'Por favor ingresa tu correo electrónico');
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      setState(() => _error = 'Ingresa un correo electrónico válido');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fullName = '${_firstNameController.text} ${_lastNameController.text}';
      final authNotifier = ref.read(authProvider.notifier);
      final success = await authNotifier.register(
        _emailController.text.trim(),
        _passwordController.text,
        fullName,
      );

      if (success && mounted) {
        ToastMessage.success(context, '✅ ¡Registro exitoso! Por favor inicia sesión');
        if (mounted) {
          context.go('/login');
        }
      } else if (mounted) {
        setState(() => _error = 'Error al registrarse. El correo podría estar en uso.');
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

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  int _getPasswordStrength() {
    final password = _passwordController.text;
    int strength = 0;
    if (password.length >= 8) strength += 25;
    if (password.contains(RegExp(r'[a-z]'))) strength += 25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 25;
    if (password.contains(RegExp(r'[^a-zA-Z0-9]'))) strength += 25;
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final passwordStrength = _getPasswordStrength();
    final strengthText = _getStrengthText(passwordStrength);
    final strengthColor = _getStrengthColor(passwordStrength);
    final passwordsMatch = _passwordController.text == _confirmPasswordController.text;
    final showPasswordMatchError = _confirmPasswordController.text.isNotEmpty && !passwordsMatch;

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
                  // Logo de QuickNote
                  _buildLogo(),
                  const SizedBox(height: 20),
                  
                  // Título
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
                              'Crear cuenta',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.grey.shade900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Únete a QuickNote',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Logo informativo
                            _buildInfoSection(isDarkMode),
                            const SizedBox(height: 20),
                            
                            // Nombre y Apellido
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    _firstNameController,
                                    'Nombre',
                                    Icons.person_outline,
                                    isDarkMode,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    _lastNameController,
                                    'Apellido',
                                    Icons.person_outline,
                                    isDarkMode,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Email
                            _buildTextField(
                              _emailController,
                              'Correo electrónico',
                              Icons.email_outlined,
                              isDarkMode,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            
                            // Contraseña
                            _buildPasswordField(isDarkMode),
                            
                            // Indicador de fortaleza
                            if (_passwordController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: _buildStrengthIndicator(
                                  passwordStrength,
                                  strengthText,
                                  strengthColor,
                                  isDarkMode,
                                ),
                              ),
                            const SizedBox(height: 12),
                            
                            // Confirmar Contraseña
                            _buildConfirmPasswordField(isDarkMode, showPasswordMatchError),
                            
                            // Error de contraseñas no coinciden
                            if (showPasswordMatchError)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, size: 14, color: Colors.red.shade400),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Las contraseñas no coinciden',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.red.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Error general
                            if (_error != null) _buildErrorWidget(),
                            
                            const SizedBox(height: 24),
                            
                            // Botón Registrar
                            _buildRegisterButton(),
                            const SizedBox(height: 16),
                            
                            // Link a Login
                            _buildLoginLink(isDarkMode),
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
          'Crear cuenta',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Únete a QuickNote',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.1)
            : const Color(0xFF8B5CF6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFF8B5CF6).withValues(alpha: 0.3),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_note, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Puedes personalizar tu perfil después',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Avatar, banner y más ajustes',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
    bool isDarkMode, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
          ),
          prefixIcon: Icon(
            icon,
            size: 18,
            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPasswordField(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_showPassword,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Contraseña',
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            size: 18,
            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            ),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField(bool isDarkMode, bool hasError) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? Colors.red.shade400
              : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
        ),
      ),
      child: TextField(
        controller: _confirmPasswordController,
        obscureText: !_showConfirmPassword,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Confirmar contraseña',
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            size: 18,
            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            ),
            onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
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
            Text(
              'SEGURIDAD',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
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
            color: color,
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
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
                  const Icon(Icons.person_add, size: 18),
                  const SizedBox(width: 8),
                  Text('REGISTRARSE', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  Widget _buildLoginLink(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes una cuenta?',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Inicia sesión',
            style: GoogleFonts.poppins(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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