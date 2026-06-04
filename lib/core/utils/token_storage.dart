// lib/core/utils/token_storage.dart
// Almacenamiento centralizado de tokens - FUENTE ÚNICA DE VERDAD
// ACTUALIZADO v2: Incluye clearAuthTokens() para preservar datos 2FA
// ACTUALIZADO v3: Incluye métodos para invalidación de sesiones
// ACTUALIZADO v4: Incluye métodos para rol de usuario (admin/user)

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class _TokenLogger {
  static void info(String message) {
    if (kDebugMode) debugPrint('ℹ️ [TokenStorage] $message');
  }
  static void success(String message) {
    if (kDebugMode) debugPrint('✅ [TokenStorage] $message');
  }
  static void warning(String message) {
    if (kDebugMode) debugPrint('⚠️ [TokenStorage] $message');
  }
  static void error(String message) {
    if (kDebugMode) debugPrint('❌ [TokenStorage] $message');
  }
}

class TokenStorage {
  static final TokenStorage _instance = TokenStorage._internal();
  factory TokenStorage() => _instance;
  TokenStorage._internal();

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
  // CLAVES DE ALMACENAMIENTO
  // ============================================
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserAvatar = 'user_avatar';
  static const String _keyUserBanner = 'user_banner';
  static const String _keyUserRole = 'user_role'; // ✅ NUEVA CLAVE PARA ROL
  static const String _keyTwoFactorVerified = 'two_factor_verified';
  static const String _keyTempToken = 'temp_token';
  static const String _keyTokenIssuedAt = 'token_issued_at';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyRememberMe = 'remember_me';
  
  // ✅ NUEVAS CLAVES PARA INVALIDACIÓN DE SESIONES
  static const String _keySessionVersion = 'session_version';
  static const String _keyLastPasswordChange = 'last_password_change';

  // ============================================
  // CACHÉ EN MEMORIA
  // ============================================
  String? _cachedToken;
  DateTime? _cachedTokenExpiry;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // ============================================
  // TOKENS
  // ============================================
  
  Future<void> saveAuthToken(String token) async {
    try {
      await _storage.write(key: _keyAuthToken, value: token);
      _cachedToken = token;
      _cachedTokenExpiry = DateTime.now().add(_cacheDuration);
      _TokenLogger.success('Token guardado');
      _TokenLogger.info('Preview: ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
    } catch (e) {
      _TokenLogger.error('Error guardando token: $e');
      rethrow;
    }
  }

  Future<String?> getAuthToken() async {
    try {
      if (_cachedToken != null && 
          _cachedTokenExpiry != null && 
          DateTime.now().isBefore(_cachedTokenExpiry!)) {
        _TokenLogger.info('Token desde caché');
        return _cachedToken;
      }
      
      final token = await _storage.read(key: _keyAuthToken);
      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
        _cachedTokenExpiry = DateTime.now().add(_cacheDuration);
        _TokenLogger.success('Token recuperado desde almacenamiento');
      } else {
        _TokenLogger.warning('No hay token almacenado');
      }
      return token;
    } catch (e) {
      _TokenLogger.error('Error obteniendo token: $e');
      return null;
    }
  }

  String? getSyncToken() => _cachedToken;

  Future<bool> hasToken() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  void invalidateCache() {
    _cachedToken = null;
    _cachedTokenExpiry = null;
    _TokenLogger.info('Caché invalidada');
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
    _TokenLogger.success('Refresh token guardado');
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  // ============================================
  // DATOS DE USUARIO
  // ============================================
  
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
    _TokenLogger.success('UserId guardado: $userId');
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _keyUserEmail, value: email);
    _TokenLogger.success('Email guardado: $email');
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  Future<void> saveUserName(String name) async {
    await _storage.write(key: _keyUserName, value: name);
    _TokenLogger.success('Nombre guardado: $name');
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: _keyUserName);
  }

  Future<void> saveUserAvatar(String url) async {
    await _storage.write(key: _keyUserAvatar, value: url);
    _TokenLogger.success('Avatar guardado');
  }

  Future<String?> getUserAvatar() async {
    return await _storage.read(key: _keyUserAvatar);
  }

  Future<void> saveUserBanner(String url) async {
    await _storage.write(key: _keyUserBanner, value: url);
    _TokenLogger.success('Banner guardado');
  }

  Future<String?> getUserBanner() async {
    return await _storage.read(key: _keyUserBanner);
  }

  // ============================================
  // ROL DE USUARIO (NUEVO)
  // ============================================
  
  /// Guardar el rol del usuario ('user' o 'admin')
  Future<void> saveUserRole(String role) async {
    await _storage.write(key: _keyUserRole, value: role);
    _TokenLogger.success('Rol guardado: $role');
  }
  
  /// Obtener el rol del usuario (por defecto 'user')
  Future<String> getUserRole() async {
    final role = await _storage.read(key: _keyUserRole);
    return role ?? 'user';
  }
  
  /// Eliminar el rol del usuario
  Future<void> clearUserRole() async {
    await _storage.delete(key: _keyUserRole);
    _TokenLogger.info('Rol eliminado');
  }

  // ============================================
  // 2FA
  // ============================================
  
  Future<void> saveTempToken(String token) async {
    await _storage.write(key: _keyTempToken, value: token);
    _TokenLogger.success('Temp token 2FA guardado');
  }

  Future<String?> getTempToken() async {
    return await _storage.read(key: _keyTempToken);
  }

  Future<void> clearTempToken() async {
    await _storage.delete(key: _keyTempToken);
    _TokenLogger.info('Temp token 2FA eliminado');
  }

  Future<void> saveTwoFactorVerified(bool verified) async {
    await _storage.write(key: _keyTwoFactorVerified, value: verified.toString());
    _TokenLogger.success('2FA verificado guardado: $verified');
  }

  Future<bool> isTwoFactorVerified() async {
    final value = await _storage.read(key: _keyTwoFactorVerified);
    return value == 'true';
  }

  // ============================================
  // VERSIÓN DE SESIÓN (para invalidación)
  // ============================================
  
  Future<void> saveSessionVersion(int version) async {
    await _storage.write(key: _keySessionVersion, value: version.toString());
    _TokenLogger.success('Versión de sesión guardada: $version');
  }
  
  Future<int?> getSessionVersion() async {
    final value = await _storage.read(key: _keySessionVersion);
    if (value == null) return null;
    return int.tryParse(value);
  }
  
  Future<void> clearSessionVersion() async {
    await _storage.delete(key: _keySessionVersion);
    _TokenLogger.info('Versión de sesión eliminada');
  }

  // ============================================
  // FECHA DE ÚLTIMO CAMBIO DE CONTRASEÑA
  // ============================================
  
  Future<void> saveLastPasswordChange(DateTime date) async {
    await _storage.write(key: _keyLastPasswordChange, value: date.toIso8601String());
    _TokenLogger.success('Fecha último cambio guardada: ${date.toIso8601String()}');
  }
  
  Future<DateTime?> getLastPasswordChange() async {
    final value = await _storage.read(key: _keyLastPasswordChange);
    if (value == null) return null;
    return DateTime.parse(value);
  }
  
  Future<void> clearLastPasswordChange() async {
    await _storage.delete(key: _keyLastPasswordChange);
    _TokenLogger.info('Fecha último cambio eliminada');
  }

  // ============================================
  // BIOMETRÍA Y PREFERENCIAS
  // ============================================
  
  Future<void> saveBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
    _TokenLogger.success('Biometría guardada: $enabled');
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  Future<void> saveRememberMe(bool value) async {
    await _storage.write(key: _keyRememberMe, value: value.toString());
    _TokenLogger.info('Recordarme guardado: $value');
  }

  Future<bool> getRememberMe() async {
    final value = await _storage.read(key: _keyRememberMe);
    return value == 'true';
  }

  // ============================================
  // LIMPIEZA - MÉTODOS MEJORADOS
  // ============================================
  
  /// Limpiar solo tokens de autenticación (preservar datos 2FA temporal)
  Future<void> clearAuthTokens() async {
    try {
      await _storage.delete(key: _keyAuthToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyTokenIssuedAt);
      
      invalidateCache();
      _TokenLogger.success('Tokens de autenticación eliminados (datos 2FA preservados)');
    } catch (e) {
      _TokenLogger.error('Error al limpiar auth tokens: $e');
      rethrow;
    }
  }

  /// Limpiar tokens incluyendo datos 2FA (pero preservar datos de usuario)
  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _keyAuthToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyTwoFactorVerified);
      await _storage.delete(key: _keyTempToken);
      await _storage.delete(key: _keyTokenIssuedAt);
      
      invalidateCache();
      _TokenLogger.success('Tokens eliminados (incluye 2FA)');
    } catch (e) {
      _TokenLogger.error('Error al limpiar tokens: $e');
      rethrow;
    }
  }

  /// Limpiar toda la sesión (tokens, datos 2FA, datos usuario)
  Future<void> clearSession() async {
    try {
      await _storage.delete(key: _keyAuthToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyTwoFactorVerified);
      await _storage.delete(key: _keyTempToken);
      await _storage.delete(key: _keyTokenIssuedAt);
      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyUserEmail);
      await _storage.delete(key: _keyUserName);
      await _storage.delete(key: _keyUserAvatar);
      await _storage.delete(key: _keyUserBanner);
      await _storage.delete(key: _keyUserRole); // ✅ NUEVO: Limpiar rol
      
      invalidateCache();
      _TokenLogger.success('Sesión completamente limpiada');
    } catch (e) {
      _TokenLogger.error('Error al limpiar sesión: $e');
      rethrow;
    }
  }

  /// Limpiar absolutamente todos los datos almacenados
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      invalidateCache();
      _TokenLogger.success('Todos los datos eliminados');
    } catch (e) {
      _TokenLogger.error('Error al limpiar todo: $e');
      rethrow;
    }
  }

  /// Limpiar datos de sesión (para invalidación)
  Future<void> clearSessionData() async {
    try {
      await _storage.delete(key: _keySessionVersion);
      await _storage.delete(key: _keyLastPasswordChange);
      _TokenLogger.success('Datos de sesión eliminados');
    } catch (e) {
      _TokenLogger.error('Error al limpiar datos de sesión: $e');
      rethrow;
    }
  }

  // ============================================
  // UTILIDADES
  // ============================================

  Future<Map<String, dynamic>> getUserInfo() async {
    return {
      'userId': await getUserId(),
      'email': await getUserEmail(),
      'userName': await getUserName(),
      'userRole': await getUserRole(), // ✅ NUEVO: Incluir rol
      'hasToken': await hasToken(),
      'hasTempToken': (await getTempToken()) != null,
      'twoFactorVerified': await isTwoFactorVerified(),
      'biometricEnabled': await isBiometricEnabled(),
      'rememberMe': await getRememberMe(),
      'sessionVersion': await getSessionVersion(),
      'lastPasswordChange': await getLastPasswordChange(),
    };
  }
}

final tokenStorage = TokenStorage();