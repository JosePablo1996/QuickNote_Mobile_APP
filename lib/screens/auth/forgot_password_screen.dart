// lib/screens/auth/forgot_password_screen.dart
// Pantalla de recuperación de contraseña - PASO 1: Pantalla de bienvenida
// Diseño Glassmorphism con efecto cristal - Mismo estilo que LoginScreen
// CORREGIDO: Navegación a login usando Navigator.pushReplacementNamed

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/screens/auth/forgot_password_email_screen.dart';
import 'package:quicknote/screens/auth/login_screen.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {

  void _navigateToNext() {
    // ✅ Navegar al Paso 2 (ingresar email)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordEmailScreen()),
    );
  }

  void _goToLogin() {
    // ✅ CORREGIDO: Usar Navigator.pop hasta volver al login
    // Método 1: Pop hasta la raíz si login es la pantalla anterior
    Navigator.pop(context);
    
    // Método 2 alternativo: Usar go_router si está configurado
    // context.go('/login');
    
    // Método 3 alternativo: Push y reemplazar
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (_) => const LoginScreen()),
    // );
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
                  
                  // Formulario con efecto Glassmorphism
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.all(32),
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
                            // Icono de ayuda
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.lock_reset,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            Text(
                              '¿Olvidaste tu contraseña?',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.grey.shade900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            
                            Text(
                              'No te preocupes, te ayudaremos a recuperar el acceso a tu cuenta en unos pocos pasos.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            
                            // ✅ Indicador de pasos - Paso 1 activo
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStepIndicator(0, 4, isDarkMode, active: true),
                                const SizedBox(width: 8),
                                _buildStepIndicator(1, 4, isDarkMode),
                                const SizedBox(width: 8),
                                _buildStepIndicator(2, 4, isDarkMode),
                                const SizedBox(width: 8),
                                _buildStepIndicator(3, 4, isDarkMode),
                              ],
                            ),
                            const SizedBox(height: 32),
                            
                            // Botón Continuar
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _navigateToNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'CONTINUAR',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Botón Volver - CORREGIDO
                            TextButton(
                              onPressed: _goToLogin,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.arrow_back, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Volver al inicio de sesión',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  Widget _buildStepIndicator(int step, int total, bool isDarkMode, {bool active = false}) {
    return Container(
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF10B981)
            : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
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
      child: const Icon(Icons.edit_note, size: 36, color: Colors.white),
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