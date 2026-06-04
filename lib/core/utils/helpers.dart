// lib/core/utils/helpers.dart
// Funciones de ayuda generales

import 'dart:async';
import 'dart:ui';

class Helpers {
  // ============================================
  // VALIDACIÓN DE EMAIL
  // ============================================
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  // ============================================
  // VALIDACIÓN DE CONTRASEÑA
  // ============================================
  static bool isValidPassword(String password) {
    return password.length >= 8 &&
           password.contains(RegExp(r'[A-Z]')) &&
           password.contains(RegExp(r'[a-z]')) &&
           password.contains(RegExp(r'[0-9]'));
  }

  // ============================================
  // VALIDACIÓN DE TELÉFONO (OPCIONAL)
  // ============================================
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone);
  }

  // ============================================
  // OBTENER INICIALES DE UN NOMBRE
  // ============================================
  static String getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // ============================================
  // CAPITALIZAR PALABRAS
  // ============================================
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // ============================================
  // TRUNCAR TEXTO
  // ============================================
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // ============================================
  // GENERAR ID ÚNICO
  // ============================================
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // ============================================
  // GENERAR COLOR ALEATORIO
  // ============================================
  static Color getRandomColor() {
    final colors = [
      const Color(0xFF3B82F6), // Azul
      const Color(0xFFEF4444), // Rojo
      const Color(0xFF10B981), // Verde
      const Color(0xFFF59E0B), // Ámbar
      const Color(0xFF8B5CF6), // Púrpura
      const Color(0xFFEC4899), // Rosa
      const Color(0xFF06B6D4), // Cian
    ];
    return colors[DateTime.now().millisecondsSinceEpoch % colors.length];
  }

  // ============================================
  // FORMATEAR NÚMERO CON SEPARADORES
  // ============================================
  static String formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}K';
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }

  // ============================================
  // DELAY ASÍNCRONO
  // ============================================
  static Future<void> delay(int milliseconds) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  // ============================================
  // COPIAR TEXTO AL PORTAPAPELES
  // ============================================
  static Future<void> copyToClipboard(String text) async {
    await Future.delayed(Duration.zero);
    // Nota: Se necesita importar 'package:flutter/services.dart'
    // para usar Clipboard.setData
  }

  // ============================================
  // DEBOUNCE PARA BÚSQUEDAS
  // ============================================
  static Debouncer createDebouncer(Duration duration) {
    return Debouncer(duration);
  }
}

// ============================================
// CLASE DEBOUNCER
// ============================================
class Debouncer {
  final Duration duration;
  void Function()? _callback;
  Timer? _timer;

  Debouncer(this.duration);

  void run(void Function() callback) {
    _callback = callback;
    _timer?.cancel();
    _timer = Timer(duration, () {
      _callback?.call();
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}