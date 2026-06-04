// lib/core/services/session_service.dart
// Servicio para manejar sesiones de usuario e invalidación

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote/core/utils/token_storage.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  final TokenStorage _tokenStorage = TokenStorage();
  
  // Clave para almacenar la versión de la sesión
  static const String _keySessionVersion = 'session_version';
  static const String _keyLastPasswordChange = 'last_password_change';

  // ============================================
  // VERSIÓN DE SESIÓN
  // ============================================
  
  /// Obtener la versión actual de la sesión del usuario
  Future<int> getCurrentSessionVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySessionVersion) ?? 1;
  }
  
  /// Incrementar la versión de la sesión (invalida todas las sesiones anteriores)
  Future<int> incrementSessionVersion() async {
    final prefs = await SharedPreferences.getInstance();
    final currentVersion = await getCurrentSessionVersion();
    final newVersion = currentVersion + 1;
    await prefs.setInt(_keySessionVersion, newVersion);
    debugPrint('✅ Versión de sesión incrementada a: $newVersion');
    return newVersion;
  }
  
  /// Guardar la versión de la sesión en el token storage
  Future<void> saveSessionVersionToToken(int version) async {
    await _tokenStorage.saveSessionVersion(version);
  }
  
  /// Obtener la versión de sesión guardada en el token
  Future<int?> getSessionVersionFromToken() async {
    return await _tokenStorage.getSessionVersion();
  }
  
  /// Verificar si la sesión actual es válida
  Future<bool> isSessionValid() async {
    final tokenVersion = await getSessionVersionFromToken();
    final currentVersion = await getCurrentSessionVersion();
    
    if (tokenVersion == null) return true;
    
    final isValid = tokenVersion >= currentVersion;
    if (!isValid) {
      debugPrint('⚠️ Sesión inválida: tokenVersion=$tokenVersion, currentVersion=$currentVersion');
    }
    return isValid;
  }

  // ============================================
  // FECHA DE ÚLTIMO CAMBIO DE CONTRASEÑA
  // ============================================
  
  /// Guardar la fecha del último cambio de contraseña
  Future<void> saveLastPasswordChange(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastPasswordChange, date.toIso8601String());
    debugPrint('✅ Fecha de último cambio guardada: ${date.toIso8601String()}');
  }
  
  /// Obtener la fecha del último cambio de contraseña
  Future<DateTime?> getLastPasswordChange() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_keyLastPasswordChange);
    if (dateStr == null) return null;
    return DateTime.parse(dateStr);
  }
  
  /// Verificar si la contraseña ha expirado (90 días)
  Future<bool> isPasswordExpired() async {
    final lastChange = await getLastPasswordChange();
    if (lastChange == null) return false;
    
    const expirationDays = 90;
    final expirationDate = lastChange.add(Duration(days: expirationDays));
    final isExpired = DateTime.now().isAfter(expirationDate);
    
    if (isExpired) {
      debugPrint('⚠️ La contraseña expiró el: ${expirationDate.toIso8601String()}');
    }
    
    return isExpired;
  }
  
  /// Obtener días restantes para expiración
  Future<int> getDaysUntilPasswordExpiration() async {
    final lastChange = await getLastPasswordChange();
    if (lastChange == null) return 90;
    
    const expirationDays = 90;
    final expirationDate = lastChange.add(Duration(days: expirationDays));
    final daysLeft = expirationDate.difference(DateTime.now()).inDays;
    
    return daysLeft > 0 ? daysLeft : 0;
  }

  // ============================================
  // LIMPIEZA DE SESIÓN
  // ============================================
  
  /// Invalidar la sesión actual (cerrar sesión)
  Future<void> invalidateCurrentSession() async {
    await _tokenStorage.clearSession();
    await incrementSessionVersion();
    debugPrint('✅ Sesión actual invalidada');
  }
  
  /// Limpiar todos los datos de sesión
  Future<void> clearAllSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionVersion);
    await prefs.remove(_keyLastPasswordChange);
    await _tokenStorage.clearAll();
    debugPrint('✅ Todos los datos de sesión eliminados');
  }

  /// ✅ NUEVO: Limpiar solo los datos de sesión (versión y fecha)
  Future<void> clearSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionVersion);
    await prefs.remove(_keyLastPasswordChange);
    debugPrint('✅ Datos de sesión eliminados (versión y fecha)');
  }

  // ============================================
  // VERIFICACIÓN EN CADA PETICIÓN
  // ============================================
  
  /// Verificar si la sesión es válida antes de cada petición
  /// Debe ser llamado en el interceptor de la API
  Future<bool> validateSessionBeforeRequest() async {
    final isValid = await isSessionValid();
    if (!isValid) {
      debugPrint('❌ Sesión inválida - se requiere relogin');
      await invalidateCurrentSession();
    }
    return isValid;
  }
}