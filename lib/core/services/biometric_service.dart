// lib/core/services/biometric_service.dart
// Servicio de autenticación biométrica - CORREGIDO v3
// Con logs detallados y verificación de huellas registradas
// ✅ CORREGIDO: Mejor manejo de dispositivos sin biometría (tablets)
// ✅ CORREGIDO: Detección automática de disponibilidad
// ✅ CORREGIDO: Logs para depuración en tablets

import 'package:local_auth/local_auth.dart';
import 'package:flutter/material.dart';
import 'package:quicknote/core/utils/secure_storage.dart';

// Logger para evitar warnings de print
class _BiometricLogger {
  static void info(String message) {
    debugPrint('ℹ️ [BiometricService] $message');
  }
  
  static void success(String message) {
    debugPrint('✅ [BiometricService] $message');
  }
  
  static void warning(String message) {
    debugPrint('⚠️ [BiometricService] $message');
  }
  
  static void error(String message) {
    debugPrint('❌ [BiometricService] $message');
  }
}

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorage _secureStorage = SecureStorage();

  // ============================================
  // VERIFICAR DISPONIBILIDAD DE BIOMETRÍA
  // ✅ CORREGIDO: Mejor manejo de errores y logs claros
  // ============================================
  
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final result = isAvailable && isDeviceSupported;
      
      _BiometricLogger.info('🔍 Verificando disponibilidad de biometría:');
      _BiometricLogger.info('   canCheckBiometrics: $isAvailable');
      _BiometricLogger.info('   isDeviceSupported: $isDeviceSupported');
      _BiometricLogger.info('   Resultado: $result');
      
      if (!result) {
        _BiometricLogger.info('ℹ️ El dispositivo no soporta biometría (tablet sin huella digital)');
      }
      
      return result;
    } catch (e) {
      _BiometricLogger.error('Error checking biometric availability: $e');
      return false;
    }
  }

  // ============================================
  // OBTENER TIPOS DE BIOMETRÍA DISPONIBLES
  // ============================================
  
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final types = await _localAuth.getAvailableBiometrics();
      _BiometricLogger.info('🔍 Tipos de biometría disponibles: $types');
      return types;
    } catch (e) {
      _BiometricLogger.error('Error getting available biometrics: $e');
      return [];
    }
  }

  // ============================================
  // VERIFICAR SI EL USUARIO TIENE BIOMETRÍA REGISTRADA EN EL DISPOSITIVO
  // ============================================
  
  Future<bool> isBiometricEnrolled() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        _BiometricLogger.info('Biometría no disponible, no hay huellas registradas');
        return false;
      }
      
      final types = await getAvailableBiometrics();
      final result = types.isNotEmpty;
      _BiometricLogger.info('🔍 Biometría registrada en dispositivo: $result');
      
      if (!result) {
        _BiometricLogger.warning('⚠️ El dispositivo soporta biometría pero no hay huellas registradas');
      }
      
      return result;
    } catch (e) {
      _BiometricLogger.error('Error checking biometric enrollment: $e');
      return false;
    }
  }

  // ============================================
  // REGISTRAR BIOMETRÍA (VERIFICAR Y GUARDAR PREFERENCIA)
  // ============================================
  
  Future<bool> registerBiometric() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        _BiometricLogger.warning('Biometría no disponible en este dispositivo');
        return false;
      }
      
      // Verificar si hay biometría registrada en el dispositivo
      final isEnrolled = await isBiometricEnrolled();
      if (!isEnrolled) {
        _BiometricLogger.warning('No hay biometría registrada en el dispositivo');
        return false;
      }
      
      // Autenticar para confirmar
      _BiometricLogger.info('Solicitando autenticación para registro...');
      
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Configura tu huella digital o Face ID para acceder a QuickNote',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      if (authenticated) {
        // Guardar preferencia en secure storage
        await _secureStorage.saveBiometricEnabled(true);
        _BiometricLogger.success('Biometría registrada y guardada correctamente');
        return true;
      }
      
      _BiometricLogger.warning('Autenticación fallida durante el registro');
      return false;
    } catch (e) {
      _BiometricLogger.error('Error registering biometric: $e');
      return false;
    }
  }

  // ============================================
  // AUTENTICACIÓN BIOMÉTRICA - CORREGIDA
  // ============================================
  
  Future<bool> authenticate({
    required String reason,
    String? title,
    String? subtitle,
    bool stickyAuth = true,
  }) async {
    try {
      _BiometricLogger.info('🔐 Iniciando autenticación biométrica...');
      _BiometricLogger.info('   Razón: $reason');
      
      // 1. Verificar disponibilidad
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        _BiometricLogger.warning('❌ Biometría no disponible en este dispositivo');
        return false;
      }
      
      // 2. Verificar si hay biometría registrada (CRÍTICO)
      final isEnrolled = await isBiometricEnrolled();
      if (!isEnrolled) {
        _BiometricLogger.warning('❌ No hay biometría registrada en el dispositivo');
        return false;
      }
      
      _BiometricLogger.info('✅ Dispositivo listo para autenticación biométrica');
      
      // 3. Intentar autenticar
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );
      
      if (authenticated) {
        _BiometricLogger.success('✅ Autenticación biométrica exitosa');
      } else {
        _BiometricLogger.warning('⚠️ Autenticación biométrica fallida - usuario no autenticado');
      }
      
      return authenticated;
    } catch (e) {
      final errorMsg = e.toString();
      _BiometricLogger.error('❌ Error en autenticación biométrica: $errorMsg');
      
      // Si el error es por cancelación del usuario, retornamos false sin drama
      if (errorMsg.contains('canceled') || 
          errorMsg.contains('cancelled') ||
          errorMsg.contains('user canceled')) {
        _BiometricLogger.warning('Autenticación cancelada por el usuario');
        return false;
      }
      
      return false;
    }
  }

  // ============================================
  // AUTENTICACIÓN CON FALLBACK A PIN/PATRÓN
  // ============================================
  
  Future<bool> authenticateWithFallback({
    required String reason,
    String? title,
    String? subtitle,
  }) async {
    try {
      _BiometricLogger.info('🔐 Autenticación con fallback - Razón: $reason');
      
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        _BiometricLogger.info('ℹ️ Biometría no disponible, usando credenciales de dispositivo');
        return await _authenticateWithDeviceCredentials(reason);
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Permite PIN/patrón como fallback
        ),
      );
      
      _BiometricLogger.info('Autenticación con fallback: ${authenticated ? "exitosa" : "fallida"}');
      return authenticated;
    } catch (e) {
      _BiometricLogger.error('Error en autenticación con fallback: $e');
      return false;
    }
  }

  Future<bool> _authenticateWithDeviceCredentials(String reason) async {
    try {
      _BiometricLogger.info('Usando credenciales del dispositivo');
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
        ),
      );
    } catch (e) {
      _BiometricLogger.error('Error en autenticación con credenciales: $e');
      return false;
    }
  }

  // ============================================
  // OBTENER NOMBRE DEL MÉTODO BIOMÉTRICO
  // ============================================
  
  Future<String> getBiometricName() async {
    final types = await getAvailableBiometrics();
    
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Huella digital';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (types.contains(BiometricType.strong)) {
      return 'Biometría';
    }
    
    return 'Biometría';
  }

  // ============================================
  // OBTENER ICONO DEL MÉTODO BIOMÉTRICO
  // ============================================
  
  Future<IconData> getBiometricIcon() async {
    final types = await getAvailableBiometrics();
    
    if (types.contains(BiometricType.face)) {
      return Icons.face;
    } else if (types.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (types.contains(BiometricType.iris)) {
      return Icons.visibility;
    }
    
    return Icons.fingerprint;
  }

  // ============================================
  // OBTENER MENSAJE DE RAZÓN PERSONALIZADO
  // ============================================
  
  Future<String> getAuthenticationReason() async {
    final biometricName = await getBiometricName();
    return 'Usa $biometricName para acceder a QuickNote';
  }

  // ============================================
  // VERIFICAR SI HAY BIOMETRÍA DISPONIBLE PARA AUTENTICACIÓN
  // ✅ CORREGIDO: Ahora retorna false claramente para tablets sin huella
  // ============================================
  
  Future<bool> canAuthenticateWithBiometric() async {
    final isAvailable = await isBiometricAvailable();
    final isEnrolled = await isBiometricEnrolled();
    final isEnabled = await _secureStorage.isBiometricEnabled();
    final result = isAvailable && isEnrolled && isEnabled;
    
    _BiometricLogger.info('🔍 Puede autenticar con biometría: $result');
    _BiometricLogger.info('   - Disponible en dispositivo: $isAvailable');
    _BiometricLogger.info('   - Biometría registrada: $isEnrolled');
    _BiometricLogger.info('   - Activada en app: $isEnabled');
    
    if (!isAvailable) {
      _BiometricLogger.info('ℹ️ El dispositivo no soporta biometría (tablet sin huella)');
    }
    
    return result;
  }

  // ============================================
  // OBTENER ESTADO COMPLETO DE BIOMETRÍA
  // ============================================
  
  Future<Map<String, dynamic>> getBiometricStatus() async {
    final isAvailable = await isBiometricAvailable();
    final isEnrolled = await isBiometricEnrolled();
    final isEnabled = await _secureStorage.isBiometricEnabled();
    final biometricName = await getBiometricName();
    final biometricIcon = await getBiometricIcon();
    
    _BiometricLogger.info('📊 Estado completo de biometría:');
    _BiometricLogger.info('   - Disponible: $isAvailable');
    _BiometricLogger.info('   - Registrada: $isEnrolled');
    _BiometricLogger.info('   - Activada: $isEnabled');
    _BiometricLogger.info('   - Tipo: $biometricName');
    
    return {
      'isAvailable': isAvailable,
      'isEnrolled': isEnrolled,
      'isEnabled': isEnabled,
      'biometricName': biometricName,
      'biometricIcon': biometricIcon,
      'canAuthenticate': isAvailable && isEnrolled && isEnabled,
    };
  }
  
  // ============================================
  // MÉTODO PARA DEPURACIÓN (VERIFICAR ESTADO EN TABLETS)
  // ============================================
  
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    try {
      final isAvailable = await isBiometricAvailable();
      final isEnrolled = await isBiometricEnrolled();
      final types = await getAvailableBiometrics();
      final isEnabled = await _secureStorage.isBiometricEnabled();
      
      return {
        'isAvailable': isAvailable,
        'isEnrolled': isEnrolled,
        'biometricTypes': types.map((t) => t.toString()).toList(),
        'isEnabled': isEnabled,
        'deviceInfo': {
          'platform': 'Android/iOS',
          'hasBiometricHardware': isAvailable,
          'hasEnrolledBiometrics': isEnrolled,
        },
        'suggestions': _getSuggestions(isAvailable, isEnrolled, types),
      };
    } catch (e) {
      _BiometricLogger.error('Error en diagnóstico: $e');
      return {
        'error': e.toString(),
        'isAvailable': false,
        'isEnrolled': false,
        'suggestions': ['Error al obtener diagnóstico'],
      };
    }
  }
  
  String _getSuggestions(bool isAvailable, bool isEnrolled, List<BiometricType> types) {
    if (!isAvailable) {
      return 'El dispositivo no soporta biometría (tablet sin huella digital). La opción de biometría no estará disponible.';
    }
    if (isAvailable && !isEnrolled) {
      return 'El dispositivo soporta biometría pero no hay huellas registradas. Configura huellas en Ajustes del dispositivo.';
    }
    if (isAvailable && isEnrolled && types.isEmpty) {
      return 'Hay un problema con la detección de biometría. Revisa la configuración del dispositivo.';
    }
    return 'Biometría disponible y configurada correctamente.';
  }
}