// lib/core/api/api_client.dart
// Cliente HTTP principal para comunicación con el backend
// ✅ CORREGIDO: Usa interceptores separados (AuthInterceptor, LoggingInterceptor, RedirectInterceptor, RetryInterceptor)
// ✅ CORREGIDO: followRedirects = true
// ✅ CORREGIDO: validateStatus = status < 500
// ✅ AGREGADO: RedirectInterceptor para manejar 307

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:quicknote/core/api/endpoints.dart';
import 'package:quicknote/core/api/interceptors.dart';
import 'package:quicknote/core/utils/token_storage.dart';

// Logger simple para evitar warnings de print
class _ApiLogger {
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ [ApiClient] $message');
    }
  }
  
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ [ApiClient] $message');
    }
  }
  
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ [ApiClient] $message');
    }
  }
  
  static void error(String message) {
    if (kDebugMode) {
      debugPrint('❌ [ApiClient] $message');
    }
  }
}

// ✅ GlobalKey para navegación desde el interceptor
final GlobalKey<NavigatorState> apiNavigatorKey = GlobalKey<NavigatorState>();

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  bool _isInitialized = false;
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Inicializar el cliente HTTP
  Future<void> init() async {
    if (_isInitialized) return;

    _dio = Dio(BaseOptions(
      baseUrl: Endpoints.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      // ✅ Seguir redirecciones automáticamente
      followRedirects: true,
      // ✅ Permitir redirecciones temporales (307)
      validateStatus: (status) => status != null && status < 500,
    ));

    // ✅ Agregar interceptores (ahora desde interceptors.dart)
    _dio.interceptors.addAll([
      AuthInterceptor(),      // Manejo de autenticación
      LoggingInterceptor(),   // Logging de peticiones
      RedirectInterceptor(),  // ✅ NUEVO: Manejo de redirecciones 307
      RetryInterceptor(),     // Reintentos para errores de red
    ]);

    _isInitialized = true;
    _ApiLogger.success('ApiClient inicializado correctamente');
    _ApiLogger.info('Base URL: ${Endpoints.baseUrl}');
    _ApiLogger.info('✅ followRedirects: true, validateStatus: status < 500');
    _ApiLogger.info('✅ Interceptores: Auth, Logging, Redirect, Retry');
  }

  /// Forzar reinicialización completa del cliente
  Future<void> refreshToken() async {
    _ApiLogger.info('Reinicializando cliente para actualizar token...');
    
    _dio = Dio(BaseOptions(
      baseUrl: Endpoints.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      followRedirects: true,
      validateStatus: (status) => status != null && status < 500,
    ));

    // Limpiar y reagregar interceptores
    _dio.interceptors.clear();
    _dio.interceptors.addAll([
      AuthInterceptor(),
      LoggingInterceptor(),
      RedirectInterceptor(),  // ✅ NUEVO
      RetryInterceptor(),
    ]);

    _isInitialized = true;
    _ApiLogger.success('Cliente reinicializado correctamente');
    _ApiLogger.info('Base URL: ${Endpoints.baseUrl}');
  }

  /// Verificar si el token está disponible
  Future<bool> isTokenAvailable() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      final isAvailable = token != null && token.isNotEmpty;
      _ApiLogger.info('Token disponible: $isAvailable');
      return isAvailable;
    } catch (e) {
      _ApiLogger.error('Error verificando token: $e');
      return false;
    }
  }

  /// Obtener instancia del Dio
  Future<Dio> get dio async {
    if (!_isInitialized) {
      await init();
    }
    return _dio;
  }

  /// Obtener Dio de forma síncrona
  Dio get dioSync {
    if (!_isInitialized) {
      throw Exception('ApiClient no inicializado. Llama a init() primero.');
    }
    return _dio;
  }

  // ============================================
  // MÉTODOS DE AUTENTICACIÓN
  // ============================================

  Future<Response> login(String email, String password) async {
    final dioClient = await dio;
    return dioClient.post(
      Endpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  Future<Response> changePassword(String currentPassword, String newPassword) async {
    final dioClient = await dio;
    return dioClient.post(
      Endpoints.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  Future<Response> forgotPasswordSendOtp(String email) async {
    final dioClient = await dio;
    return dioClient.post(
      Endpoints.forgotPasswordSendOtp,
      data: {'email': email},
    );
  }

  Future<Response> forgotPasswordVerifyOtp(String email, String code) async {
    final dioClient = await dio;
    return dioClient.post(
      Endpoints.forgotPasswordVerifyOtp,
      data: {'email': email, 'code': code},
    );
  }

  Future<Response> forgotPasswordReset(String email, String code, String newPassword) async {
    final dioClient = await dio;
    return dioClient.post(
      Endpoints.forgotPasswordReset,
      data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      },
    );
  }

  Future<Response> sendOtp(String email) async {
    final dioClient = await dio;
    return dioClient.post(
      Endpoints.sendOtp,
      data: {'email': email},
    );
  }

  Future<Response> verifyOtp(String email, String code) async {
    final dioClient = await dio;
    return dioClient.post(
      Endpoints.verifyOtp,
      data: {'email': email, 'code': code},
    );
  }

  // ============================================
  // MÉTODOS 2FA
  // ============================================

  Future<Response> enableTwoFactor() async {
    final dioClient = await dio;
    return dioClient.post(Endpoints.twoFactorEnable);
  }

  Future<Response> verifyEnableTwoFactor(String code, String secret) async {
    final dioClient = await dio;
    return dioClient.post(
      Endpoints.twoFactorVerifyEnable,
      data: {'code': code, 'secret': secret},
    );
  }

  Future<Response> verifyTwoFactorLogin(String code, String tempToken) async {
    final dioClient = await dio;
    return dioClient.post(
      Endpoints.twoFactorVerifyLogin,
      data: {'code': code, 'temp_token': tempToken},
    );
  }

  Future<Response> getTwoFactorStatus() async {
    final dioClient = await dio;
    return dioClient.get(Endpoints.twoFactorStatus);
  }

  Future<Response> disableTwoFactor() async {
    final dioClient = await dio;
    return dioClient.post(Endpoints.twoFactorDisable);
  }

  Future<Response> verifyBackupCode(String code, String tempToken) async {
    final dioClient = await dio;
    return dioClient.post(
      Endpoints.twoFactorVerifyBackup,
      data: {'code': code, 'temp_token': tempToken},
    );
  }

  // ============================================
  // MÉTODOS DE NOTAS (CRUD) - CON SLASH FINAL
  // ============================================

  Future<Response> getNotes({bool deleted = false}) async {
    final dioClient = await dio;
    return dioClient.get(
      '/notes/',
      queryParameters: {'deleted': deleted},
    );
  }

  Future<Response> getNoteById(String id) async {
    final dioClient = await dio;
    return dioClient.get('/notes/$id/');
  }

  Future<Response> createNote(Map<String, dynamic> note) async {
    final dioClient = await dio;
    return dioClient.post('/notes/', data: note);
  }

  Future<Response> updateNote(String id, Map<String, dynamic> note) async {
    final dioClient = await dio;
    return dioClient.put('/notes/$id/', data: note);
  }

  Future<Response> deleteNote(String id) async {
    final dioClient = await dio;
    return dioClient.delete('/notes/$id/');
  }

  Future<Response> syncNotes(List<Map<String, dynamic>> notes) async {
    final dioClient = await dio;
    return dioClient.post(Endpoints.notesSync, data: notes);
  }

  // ============================================
  // MÉTODOS DE BACKUP EN LA NUBE
  // ============================================

  Future<Response> getCloudBackups() async {
    final dioClient = await dio;
    return dioClient.get(Endpoints.backupCloud);
  }

  Future<Response> saveCloudBackup(Map<String, dynamic> backupData) async {
    final dioClient = await dio;
    return dioClient.post(Endpoints.backupCloud, data: backupData);
  }

  Future<Response> getCloudBackup(String backupId) async {
    final dioClient = await dio;
    return dioClient.get(Endpoints.backupCloudById(backupId));
  }

  Future<Response> deleteCloudBackup(String backupId) async {
    final dioClient = await dio;
    return dioClient.delete(Endpoints.backupCloudById(backupId));
  }

  Future<Response> syncCloudBackups(List<Map<String, dynamic>> localBackups) async {
    final dioClient = await dio;
    return dioClient.post(
      Endpoints.backupCloudSync,
      data: {'local_backups': localBackups},
    );
  }

  Future<Response> getBackupLimitInfo() async {
    final dioClient = await dio;
    return dioClient.get(Endpoints.backupCloudLimitInfo);
  }

  // ============================================
  // HEALTH CHECK
  // ============================================

  Future<Response> healthCheck() async {
    final dioClient = await dio;
    return dioClient.get(Endpoints.health);
  }
}

// Instancia global del cliente API
final apiClient = ApiClient();