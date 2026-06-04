// lib/core/utils/secure_storage.dart
// Almacenamiento seguro de datos sensibles (tokens, credenciales)
// CORREGIDO v4: Persistencia de biometría, credenciales para login biométrico y mejor manejo de errores
// ✅ CORREGIDO: Mejor manejo de credenciales para dispositivos sin huella
// ✅ CORREGIDO: Logs detallados para depuración
// ✅ CORREGIDO: Verificación de credenciales guardadas

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageKeys {
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String userAvatar = 'user_avatar';
  static const String userBanner = 'user_banner';
  static const String twoFactorTempToken = 'temp_2fa_token';
  static const String twoFactorEnabled = 'two_factor_enabled';
  static const String themeMode = 'theme_mode';
  static const String lastSyncTime = 'last_sync_time';
  static const String biometricEnabled = 'biometric_enabled';
  static const String rememberMe = 'remember_me';
  static const String biometricInitialized = 'biometric_initialized';
  // CLAVES PARA LOGIN BIOMÉTRICO
  static const String savedEmail = 'saved_email';
  static const String savedPassword = 'saved_password';
}

// Logger interno para evitar warnings de print
class _SecureStorageLogger {
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ [SecureStorage] $message');
    }
  }
  
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ [SecureStorage] $message');
    }
  }
  
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ [SecureStorage] $message');
    }
  }
  
  static void error(String message) {
    if (kDebugMode) {
      debugPrint('❌ [SecureStorage] $message');
    }
  }
}

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  // Configuración para persistencia entre reinstalaciones
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'quicknote_prefs',
      preferencesKeyPrefix: 'quicknote_',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // ============================================
  // TOKENS
  // ============================================

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: SecureStorageKeys.authToken, value: token);
    _SecureStorageLogger.success('Token guardado');
    
    // Verificar que se guardó correctamente
    final verifyToken = await _storage.read(key: SecureStorageKeys.authToken);
    _SecureStorageLogger.info('Verificación token guardado: ${verifyToken != null && verifyToken.isNotEmpty}');
  }

  Future<String?> getAuthToken() async {
    final token = await _storage.read(key: SecureStorageKeys.authToken);
    _SecureStorageLogger.info('Token recuperado: ${token != null && token.isNotEmpty}');
    if (token != null && token.isNotEmpty) {
      _SecureStorageLogger.info('Token preview: ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
    }
    return token;
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: SecureStorageKeys.refreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: SecureStorageKeys.refreshToken);
  }

  // ============================================
  // DATOS DE USUARIO
  // ============================================

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: SecureStorageKeys.userId, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: SecureStorageKeys.userId);
  }

  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: SecureStorageKeys.userEmail, value: email);
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: SecureStorageKeys.userEmail);
  }

  Future<void> saveUserName(String name) async {
    await _storage.write(key: SecureStorageKeys.userName, value: name);
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: SecureStorageKeys.userName);
  }

  Future<void> saveUserAvatar(String avatarUrl) async {
    await _storage.write(key: SecureStorageKeys.userAvatar, value: avatarUrl);
  }

  Future<String?> getUserAvatar() async {
    return await _storage.read(key: SecureStorageKeys.userAvatar);
  }

  Future<void> saveUserBanner(String bannerUrl) async {
    await _storage.write(key: SecureStorageKeys.userBanner, value: bannerUrl);
  }

  Future<String?> getUserBanner() async {
    return await _storage.read(key: SecureStorageKeys.userBanner);
  }

  // ============================================
  // RECORDARME
  // ============================================
  
  Future<void> saveRememberMe(bool value) async {
    await _storage.write(key: SecureStorageKeys.rememberMe, value: value.toString());
    _SecureStorageLogger.info('Recordarme guardado: $value');
  }

  Future<bool> getRememberMe() async {
    final value = await _storage.read(key: SecureStorageKeys.rememberMe);
    return value == 'true';
  }

  // ============================================
  // 2FA
  // ============================================

  Future<void> saveTwoFactorTempToken(String token) async {
    await _storage.write(key: SecureStorageKeys.twoFactorTempToken, value: token);
  }

  Future<String?> getTwoFactorTempToken() async {
    return await _storage.read(key: SecureStorageKeys.twoFactorTempToken);
  }

  Future<void> saveTwoFactorEnabled(bool enabled) async {
    await _storage.write(key: SecureStorageKeys.twoFactorEnabled, value: enabled.toString());
  }

  Future<bool> isTwoFactorEnabled() async {
    final value = await _storage.read(key: SecureStorageKeys.twoFactorEnabled);
    return value == 'true';
  }

  // ============================================
  // BIOMETRÍA - CORREGIDO CON PERSISTENCIA REAL
  // ============================================

  /// Guardar el estado de la biometría (activado/desactivado)
  Future<void> saveBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(
        key: SecureStorageKeys.biometricEnabled, 
        value: enabled.toString(),
      );
      _SecureStorageLogger.success('Biometría guardada: $enabled');
      
      // Verificar que se guardó correctamente
      final verifyValue = await _storage.read(key: SecureStorageKeys.biometricEnabled);
      _SecureStorageLogger.info('Verificación - Valor guardado: $verifyValue');
    } catch (e) {
      _SecureStorageLogger.error('Error guardando biometría: $e');
    }
  }

  /// Obtener el estado de la biometría
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _storage.read(key: SecureStorageKeys.biometricEnabled);
      // Si es null, retornar false (no activada por defecto)
      final isEnabled = value == 'true';
      _SecureStorageLogger.info('Biometría recuperada: $isEnabled (valor raw: $value)');
      return isEnabled;
    } catch (e) {
      _SecureStorageLogger.error('Error leyendo biometría: $e');
      return false;
    }
  }

  /// Inicializar biometría si es necesario
  Future<void> initBiometricIfNeeded() async {
    try {
      final currentValue = await _storage.read(key: SecureStorageKeys.biometricEnabled);
      final isInitialized = await _storage.read(key: SecureStorageKeys.biometricInitialized);
      
      _SecureStorageLogger.info('initBiometricIfNeeded - Valor actual: $currentValue, Inicializado: $isInitialized');
      
      if (currentValue == null || isInitialized == null) {
        // Si no hay valor, inicializar como false
        await saveBiometricEnabled(false);
        await _storage.write(key: SecureStorageKeys.biometricInitialized, value: 'true');
        _SecureStorageLogger.info('Biometría inicializada como desactivada');
      } else {
        _SecureStorageLogger.info('Biometría ya inicializada, valor actual: $currentValue');
      }
    } catch (e) {
      _SecureStorageLogger.error('Error inicializando biometría: $e');
    }
  }

  /// Obtener información de depuración de biometría
  Future<Map<String, String>> getBiometricDebugInfo() async {
    try {
      final biometricEnabled = await _storage.read(key: SecureStorageKeys.biometricEnabled);
      final biometricInitialized = await _storage.read(key: SecureStorageKeys.biometricInitialized);
      
      _SecureStorageLogger.info('Debug - biometricEnabled: $biometricEnabled');
      _SecureStorageLogger.info('Debug - biometricInitialized: $biometricInitialized');
      
      return {
        'biometricEnabled': biometricEnabled ?? 'null',
        'biometricInitialized': biometricInitialized ?? 'null',
      };
    } catch (e) {
      _SecureStorageLogger.error('Error en debug biometría: $e');
      return {'error': e.toString()};
    }
  }

  /// Verificar si el token está disponible (para debug)
  Future<bool> isTokenAvailable() async {
    try {
      final token = await _storage.read(key: SecureStorageKeys.authToken);
      final isAvailable = token != null && token.isNotEmpty;
      _SecureStorageLogger.info('Token disponible: $isAvailable');
      return isAvailable;
    } catch (e) {
      _SecureStorageLogger.error('Error verificando token: $e');
      return false;
    }
  }

  // ============================================
  // CREDENCIALES PARA LOGIN BIOMÉTRICO (CORREGIDO)
  // ============================================

  /// Guardar email para login biométrico
  Future<void> saveSavedEmail(String email) async {
    try {
      await _storage.write(key: SecureStorageKeys.savedEmail, value: email);
      _SecureStorageLogger.success('Email guardado para login biométrico');
    } catch (e) {
      _SecureStorageLogger.error('Error guardando email biométrico: $e');
    }
  }

  /// Obtener email guardado para login biométrico
  Future<String?> getSavedEmail() async {
    try {
      return await _storage.read(key: SecureStorageKeys.savedEmail);
    } catch (e) {
      _SecureStorageLogger.error('Error obteniendo email biométrico: $e');
      return null;
    }
  }

  /// Guardar contraseña para login biométrico
  Future<void> saveSavedPassword(String password) async {
    try {
      await _storage.write(key: SecureStorageKeys.savedPassword, value: password);
      _SecureStorageLogger.success('Contraseña guardada para login biométrico');
    } catch (e) {
      _SecureStorageLogger.error('Error guardando contraseña biométrica: $e');
    }
  }

  /// Obtener contraseña guardada para login biométrico
  Future<String?> getSavedPassword() async {
    try {
      return await _storage.read(key: SecureStorageKeys.savedPassword);
    } catch (e) {
      _SecureStorageLogger.error('Error obteniendo contraseña biométrica: $e');
      return null;
    }
  }

  /// Guardar credenciales completas para login biométrico
  Future<void> saveCredentialsForBiometric(String email, String password) async {
    await saveSavedEmail(email);
    await saveSavedPassword(password);
    _SecureStorageLogger.success('✅ Credenciales guardadas para login biométrico');
    _SecureStorageLogger.info('   Email guardado: $email');
    _SecureStorageLogger.info('   Contraseña guardada: ${'*' * (password.length > 0 ? password.length : 0)}');
  }

  /// Limpiar credenciales guardadas (al cerrar sesión)
  Future<void> clearSavedCredentials() async {
    try {
      await _storage.delete(key: SecureStorageKeys.savedEmail);
      await _storage.delete(key: SecureStorageKeys.savedPassword);
      _SecureStorageLogger.info('Credenciales biométricas eliminadas');
    } catch (e) {
      _SecureStorageLogger.error('Error limpiando credenciales biométricas: $e');
    }
  }

  /// Verificar si hay credenciales guardadas para login biométrico
  Future<bool> hasSavedCredentials() async {
    final email = await getSavedEmail();
    final password = await getSavedPassword();
    final hasCredentials = email != null && email.isNotEmpty && password != null && password.isNotEmpty;
    
    _SecureStorageLogger.info('Verificando credenciales biométricas:');
    _SecureStorageLogger.info('   Email: ${email != null ? "✅" : "❌"}');
    _SecureStorageLogger.info('   Password: ${password != null ? "✅" : "❌"}');
    _SecureStorageLogger.info('   Resultado: $hasCredentials');
    
    return hasCredentials;
  }

  /// Obtener información de depuración de credenciales
  Future<Map<String, String>> getCredentialsDebugInfo() async {
    try {
      final savedEmail = await _storage.read(key: SecureStorageKeys.savedEmail);
      final savedPassword = await _storage.read(key: SecureStorageKeys.savedPassword);
      final biometricEnabled = await _storage.read(key: SecureStorageKeys.biometricEnabled);
      
      return {
        'savedEmail': savedEmail != null ? '✅ presente' : '❌ ausente',
        'savedPassword': savedPassword != null ? '✅ presente' : '❌ ausente',
        'biometricEnabled': biometricEnabled ?? 'null',
      };
    } catch (e) {
      _SecureStorageLogger.error('Error en debug credenciales: $e');
      return {'error': e.toString()};
    }
  }

  // ============================================
  // PREFERENCIAS
  // ============================================

  Future<void> saveThemeMode(String mode) async {
    await _storage.write(key: SecureStorageKeys.themeMode, value: mode);
  }

  Future<String?> getThemeMode() async {
    return await _storage.read(key: SecureStorageKeys.themeMode);
  }

  Future<void> saveLastSyncTime(String time) async {
    await _storage.write(key: SecureStorageKeys.lastSyncTime, value: time);
  }

  Future<String?> getLastSyncTime() async {
    return await _storage.read(key: SecureStorageKeys.lastSyncTime);
  }

  // ============================================
  // LIMPIEZA
  // ============================================

  Future<void> clearAll() async {
    await _storage.deleteAll();
    _SecureStorageLogger.success('Todos los datos seguros eliminados');
  }

  Future<void> clearSession() async {
    await _storage.delete(key: SecureStorageKeys.authToken);
    await _storage.delete(key: SecureStorageKeys.refreshToken);
    await _storage.delete(key: SecureStorageKeys.userId);
    await _storage.delete(key: SecureStorageKeys.userEmail);
    await _storage.delete(key: SecureStorageKeys.userName);
    await _storage.delete(key: SecureStorageKeys.userAvatar);
    await _storage.delete(key: SecureStorageKeys.userBanner);
    await _storage.delete(key: SecureStorageKeys.twoFactorTempToken);
    await _storage.delete(key: SecureStorageKeys.rememberMe);
    // ⚠️ NO borrar biometricEnabled, savedEmail, savedPassword aquí
    // para que persistan entre sesiones
    _SecureStorageLogger.info('Sesión limpiada (biometría y credenciales preservadas)');
  }

  /// Limpieza completa incluyendo biometría y credenciales guardadas
  Future<void> clearAllIncludingBiometric() async {
    await _storage.deleteAll();
    _SecureStorageLogger.success('Todos los datos eliminados (incluyendo biometría)');
  }

  /// Método para verificar todas las claves (debug)
  Future<Map<String, String>> getAllKeys() async {
    try {
      final allKeys = await _storage.readAll();
      _SecureStorageLogger.info('Todas las claves: ${allKeys.keys}');
      return allKeys;
    } catch (e) {
      _SecureStorageLogger.error('Error leyendo todas las claves: $e');
      return {};
    }
  }
}

// Instancia global
final secureStorage = SecureStorage();