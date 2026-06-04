// lib/screens/auth/biometric_login_screen.dart
// Pantalla de autenticación biométrica - Diseño Glassmorphism con efecto cristal

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/core/services/biometric_service.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:quicknote/widgets/toast_message.dart';

class BiometricLoginScreen extends ConsumerStatefulWidget {
  const BiometricLoginScreen({super.key});

  @override
  ConsumerState<BiometricLoginScreen> createState() => _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends ConsumerState<BiometricLoginScreen>
    with SingleTickerProviderStateMixin {
  final BiometricService _biometricService = BiometricService();
  bool _isLoading = false;
  bool _isAuthenticating = false;
  String _biometricType = 'Biometría';
  IconData _biometricIcon = Icons.fingerprint;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadBiometricInfo();
    // Pequeña pausa antes de iniciar autenticación
    Future.delayed(const Duration(milliseconds: 500), () {
      _authenticate();
    });
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _loadBiometricInfo() async {
    final type = await _biometricService.getBiometricName();
    final icon = await _biometricService.getBiometricIcon();
    if (mounted) {
      setState(() {
        _biometricType = type;
        _biometricIcon = icon;
      });
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
      _isLoading = true;
      _error = null;
    });

    try {
      final authenticated = await _biometricService.authenticate(
        reason: await _biometricService.getAuthenticationReason(),
      );

      if (!mounted) return;

      if (authenticated) {
        // Verificar si hay sesión guardada
        final authState = ref.read(authProvider);
        
        if (authState.isAuthenticated) {
          ToastMessage.success(context, '✅ $_biometricType verificada correctamente');
          if (mounted) {
            context.go('/notes');
          }
        } else {
          // Intentar login biométrico si hay token guardado
          final authNotifier = ref.read(authProvider.notifier);
          final success = await authNotifier.loginWithBiometric();
          
          if (success && mounted) {
            ToastMessage.success(context, '✅ Bienvenido de vuelta');
            if (mounted) {
              context.go('/notes');
            }
          } else if (mounted) {
            setState(() {
              _error = 'No hay sesión guardada. Inicia sesión primero.';
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Autenticación biométrica fallida. Intenta de nuevo.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    } finally {
      if (mounted && !_isLoading) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
                  // Logo
                  _buildLogo(),
                  const SizedBox(height: 24),
                  
                  // Título
                  _buildHeader(),
                  const SizedBox(height: 32),
                  
                  // ✅ Formulario con efecto Glassmorphism
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
                            // Ícono biométrico animado
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _biometricIcon,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            Text(
                              'Acceso Biométrico',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Usa $_biometricType para acceder',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Error
                            if (_error != null) _buildErrorWidget(),
                            
                            // Indicador de carga
                            if (_isLoading)
                              const Column(
                                children: [
                                  CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Verificando...',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            
                            // Botón manual
                            if (!_isLoading)
                              Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _authenticate,
                                      icon: Icon(_biometricIcon, size: 20),
                                      label: Text(
                                        'Usar $_biometricType',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF8B5CF6),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextButton(
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
                                  ),
                                ],
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
          'Acceso Biométrico',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
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