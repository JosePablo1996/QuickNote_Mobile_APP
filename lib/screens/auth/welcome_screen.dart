// lib/screens/auth/welcome_screen.dart
// Pantalla de bienvenida después del login exitoso

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 1) {
        timer.cancel();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/notes');
        }
      } else {
        if (mounted) {
          setState(() => _countdown--);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final userName = user?.name?.split(' ').first ?? 'Usuario';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? const [Color(0xFF1E3A8A), Color(0xFF4C1D95), Color(0xFF831843)]
                : const [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo animado
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.green, Colors.blue]),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2), 
                                blurRadius: 10, 
                                offset: const Offset(0, 5)
                              ),
                            ],
                          ),
                          child: const Icon(Icons.check_circle, size: 50, color: Colors.white),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Título
                  const Text(
                    '¡Sesión Iniciada!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Mensaje de bienvenida
                  const Text(
                    'Bienvenido de vuelta,',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade300,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Características
                  _buildFeatureRow(
                    icon: Icons.edit_note,
                    label: 'Notas ilimitadas',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(
                    icon: Icons.sync,
                    label: 'Sincronización en la nube',
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(
                    icon: Icons.security,
                    label: 'Seguridad avanzada',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 32),
                  
                  // Botón para continuar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/notes');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'CONTINUAR AL DASHBOARD', 
                        style: TextStyle(fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Serás redirigido automáticamente en $_countdown segundos...',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 32),
                  
                  // Footer
                  const Text(
                    'QuickNote · Desarrollado con ❤️ por José Pablo Miranda Quintanilla',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 16, 
              fontWeight: FontWeight.w500
            ),
          ),
        ],
      ),
    );
  }
}