// lib/widgets/greeting_widget.dart
// Widget de saludo personalizado con hora del día - Todo centrado
// CORREGIDO: Ahora muestra correctamente el avatar del usuario

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GreetingWidget extends StatefulWidget {
  final String? userName;
  final String? userAvatar;
  final String? avatarUrl;

  const GreetingWidget({
    super.key,
    this.userName,
    this.userAvatar,
    this.avatarUrl,
  });

  @override
  State<GreetingWidget> createState() => _GreetingWidgetState();
}

class _GreetingWidgetState extends State<GreetingWidget> {
  late DateTime _currentTime;
  late Timer _timer;
  bool _avatarError = false;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = _currentTime.hour;
    if (hour >= 5 && hour < 12) return 'Buenos días';
    if (hour >= 12 && hour < 18) return 'Buenas tardes';
    if (hour >= 18 && hour < 22) return 'Buenas noches';
    return 'Buenas noches';
  }

  String _getTimeOfDay() {
    final hour = _currentTime.hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 18) return 'afternoon';
    if (hour >= 18 && hour < 22) return 'evening';
    return 'night';
  }

  List<Color> _getGradientColors() {
    final timeOfDay = _getTimeOfDay();
    switch (timeOfDay) {
      case 'morning':
        return [const Color(0xFFF59E0B), const Color(0xFFEA580C)];
      case 'afternoon':
        return [const Color(0xFF0EA5E9), const Color(0xFF3B82F6)];
      case 'evening':
        return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
      default:
        return [const Color(0xFF7C3AED), const Color(0xFFDB2777)];
    }
  }

  String _getSunMoonIcon() {
    final timeOfDay = _getTimeOfDay();
    return (timeOfDay == 'morning' || timeOfDay == 'afternoon') ? '☀️' : '🌙';
  }

  String _formatTime() {
    int hour = _currentTime.hour;
    final minute = _currentTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute $period';
  }

  String _formatDate() {
    final weekdays = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    final months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    
    return '${weekdays[_currentTime.weekday % 7]}, ${_currentTime.day} de ${months[_currentTime.month - 1]}';
  }

  String _getDisplayName() {
    if (widget.userName != null && widget.userName!.isNotEmpty) {
      if (widget.userName!.length > 25) {
        return '${widget.userName!.substring(0, 25)}...';
      }
      return widget.userName!;
    }
    return 'Usuario';
  }

  String _getInitial() {
    if (widget.userName != null && widget.userName!.isNotEmpty) {
      return widget.userName![0].toUpperCase();
    }
    return 'U';
  }

  // ✅ CORREGIDO: Priorizar userAvatar, luego avatarUrl
  String? get _avatar {
    // Primero userAvatar (de AuthProvider.currentUser.avatar)
    if (widget.userAvatar != null && widget.userAvatar!.isNotEmpty && !_avatarError) {
      return widget.userAvatar;
    }
    // Segundo avatarUrl (fallback)
    if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty && !_avatarError) {
      return widget.avatarUrl;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();
    final greeting = _getGreeting();
    final sunMoonIcon = _getSunMoonIcon();
    final displayName = _getDisplayName();
    final initial = _getInitial();
    final avatar = _avatar;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Icono decorativo esquina superior izquierda (Sol/Luna)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  sunMoonIcon,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            
            // Avatar esquina superior derecha
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: avatar != null
                      ? Image.network(
                          avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            if (!_avatarError) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() => _avatarError = true);
                              });
                            }
                            return _buildAvatarFallback(initial);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildAvatarFallback(initial, isLoading: true);
                          },
                        )
                      : _buildAvatarFallback(initial),
                ),
              ),
            ),
            
            // TODO EL CONTENIDO CENTRADO
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Hora centrada
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        _formatTime(),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Fecha centrada
                  Center(
                    child: Text(
                      _formatDate(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Línea decorativa centrada
                  Center(
                    child: Container(
                      width: 50,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withValues(alpha: 0.4), Colors.white.withValues(alpha: 0.1)],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Saludo centrado
                  Center(
                    child: Text(
                      greeting,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Nombre del usuario centrado
                  Center(
                    child: Text(
                      displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String initial, {bool isLoading = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
        ),
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                initial,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}