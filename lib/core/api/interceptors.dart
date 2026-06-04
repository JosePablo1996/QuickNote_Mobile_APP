// lib/core/api/interceptors.dart
// Interceptores para el cliente HTTP (Dio)
// ✅ CORREGIDO v4: Manejo de redirecciones 307
// ✅ CORREGIDO: Soporte para DELETE y PUT con slash final
// ✅ CORREGIDO: No limpiar tokens durante flujo 2FA
// ✅ ACTUALIZADO: Manejo seguro de rutas

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:quicknote/core/services/session_service.dart';
import 'package:quicknote/core/utils/token_storage.dart';

// Logger mejorado para evitar warnings de print
class _AppLogger {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('🔍 [Interceptor] $message');
    }
  }
  
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ [Interceptor] $message');
    }
  }
  
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ [Interceptor] $message');
    }
  }
  
  static void error(String message) {
    if (kDebugMode) {
      debugPrint('❌ [Interceptor] $message');
    }
  }
  
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ [Interceptor] $message');
    }
  }
}

/// Interceptor de autenticación
class AuthInterceptor extends Interceptor {
  // Rutas que no requieren autenticación
  static const List<String> _publicRoutes = [
    '/auth/login',
    '/auth/register',
    '/auth/forgot-password',
    '/auth/reset-password',
    '/auth/verify-otp',
    '/auth/refresh-token',
  ];
  
  // Rutas de verificación 2FA que NO deben limpiar tokens al fallar
  static const List<String> _twoFactorRoutes = [
    '/auth/2fa/verify-login',
    '/auth/2fa/verify-setup',
    '/auth/2fa/enable',
    '/auth/2fa/disable',
    '/auth/2fa/status',
  ];
  
  // Verificar si una ruta es pública
  bool _isPublicRoute(String path) {
    for (final route in _publicRoutes) {
      if (path.contains(route)) return true;
    }
    return false;
  }
  
  // Verificar si una ruta es de 2FA (no debe limpiar tokens)
  bool _isTwoFactorRoute(String path) {
    for (final route in _twoFactorRoutes) {
      if (path.contains(route)) return true;
    }
    return false;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      // ✅ VERIFICAR VALIDEZ DE SESIÓN ANTES DE LA PETICIÓN
      if (!_isPublicRoute(options.path)) {
        final sessionService = SessionService();
        final isSessionValid = await sessionService.isSessionValid();
        
        if (!isSessionValid) {
          _AppLogger.warning('⚠️ Sesión inválida para: ${options.method} ${options.path}');
          _AppLogger.warning('⚠️ Limpiando sesión...');
          await tokenStorage.clearSession();
          return handler.reject(DioException(
            requestOptions: options,
            error: 'Sesión inválida. Por favor, inicia sesión nuevamente.',
            type: DioExceptionType.cancel,
          ));
        }
      }
      
      // ✅ No añadir token para rutas públicas
      if (_isPublicRoute(options.path)) {
        _AppLogger.debug('🔓 Ruta pública, omitiendo token: ${options.method} ${options.path}');
        options.headers['Content-Type'] = 'application/json';
        options.headers['Accept'] = 'application/json';
        return handler.next(options);
      }
      
      // ✅ Usar TokenStorage para obtener token
      final token = await tokenStorage.getAuthToken();
      
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        _AppLogger.debug('✅ Token añadido a: ${options.method} ${options.path}');
      } else {
        _AppLogger.debug('⚠️ No hay token para: ${options.method} ${options.path}');
      }
      
      // Agregar headers comunes
      options.headers['Content-Type'] = 'application/json';
      options.headers['Accept'] = 'application/json';
      
      return handler.next(options);
    } catch (e) {
      _AppLogger.error('Error en onRequest: $e');
      return handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final requestPath = err.requestOptions.path;
    
    // ✅ CRÍTICO: No limpiar tokens para errores 401 en rutas de 2FA
    if (statusCode == 401 && _isTwoFactorRoute(requestPath)) {
      _AppLogger.warning('⚠️ Error 401 en ruta 2FA: $requestPath');
      _AppLogger.warning('⚠️ NO limpiando tokens - esto es parte del flujo 2FA normal');
      return handler.next(err);
    }
    
    // ✅ Para otras rutas con 401, limpiar solo si no es pública
    if (statusCode == 401 && !_isPublicRoute(requestPath)) {
      _AppLogger.warning('⚠️ Token inválido o expirado en: $requestPath');
      _AppLogger.warning('⚠️ Limpiando tokens de autenticación...');
      try {
        await tokenStorage.clearAuthTokens();
        final sessionService = SessionService();
        await sessionService.clearSessionData();
        _AppLogger.success('✅ Tokens de autenticación y datos de sesión eliminados');
      } catch (e) {
        _AppLogger.error('Error al limpiar tokens: $e');
      }
    }
    
    return handler.next(err);
  }
}

/// Interceptor de logging para depuración
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final isPublic = _isPublicRoute(options.path);
    final is2FA = _isTwoFactorRoute(options.path);
    
    _AppLogger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _AppLogger.info('📤 REQUEST: ${options.method} ${options.path}');
    if (isPublic) _AppLogger.debug('🔓 Ruta pública');
    if (is2FA) _AppLogger.debug('🔐 Ruta 2FA');
    
    // Mostrar headers de forma segura
    final safeHeaders = Map<String, dynamic>.from(options.headers);
    if (safeHeaders.containsKey('Authorization')) {
      final authValue = safeHeaders['Authorization'] as String;
      if (authValue.length > 50) {
        safeHeaders['Authorization'] = '${authValue.substring(0, 50)}...';
      }
    }
    _AppLogger.debug('📦 Headers: $safeHeaders');
    
    if (options.data != null) {
      String dataStr = options.data.toString();
      if (dataStr.contains('password')) {
        dataStr = dataStr.replaceAll(RegExp(r'"password":"[^"]*"'), '"password":"***"');
      }
      if (dataStr.contains('code')) {
        dataStr = dataStr.replaceAll(RegExp(r'"code":"[^"]*"'), '"code":"***"');
      }
      final preview = dataStr.length > 500 ? '${dataStr.substring(0, 500)}...' : dataStr;
      _AppLogger.debug('📦 Body: $preview');
    }
    _AppLogger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _AppLogger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _AppLogger.info('📥 RESPONSE: ${response.requestOptions.method} ${response.requestOptions.path}');
    _AppLogger.success('✅ Status: ${response.statusCode}');
    if (response.data != null) {
      final dataStr = response.data.toString();
      final preview = dataStr.length > 500 ? '${dataStr.substring(0, 500)}...' : dataStr;
      _AppLogger.debug('📦 Body: $preview');
    }
    _AppLogger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _AppLogger.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _AppLogger.error('❌ ERROR: ${err.requestOptions.method} ${err.requestOptions.path}');
    _AppLogger.error('⚠️ Status: ${err.response?.statusCode}');
    _AppLogger.error('⚠️ Message: ${err.message}');
    if (err.response?.data != null) {
      final responseData = err.response?.data;
      if (responseData is Map && responseData.containsKey('detail')) {
        _AppLogger.error('⚠️ Detail: ${responseData['detail']}');
      } else {
        _AppLogger.error('⚠️ Response: $responseData');
      }
    }
    _AppLogger.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return handler.next(err);
  }
  
  bool _isPublicRoute(String path) {
    const publicRoutes = [
      '/auth/login',
      '/auth/register',
      '/auth/forgot-password',
      '/auth/reset-password',
      '/auth/verify-otp',
      '/auth/refresh-token',
    ];
    for (final route in publicRoutes) {
      if (path.contains(route)) return true;
    }
    return false;
  }
  
  bool _isTwoFactorRoute(String path) {
    const twoFactorRoutes = [
      '/auth/2fa/verify-login',
      '/auth/2fa/verify-setup',
      '/auth/2fa/enable',
      '/auth/2fa/disable',
      '/auth/2fa/status',
    ];
    for (final route in twoFactorRoutes) {
      if (path.contains(route)) return true;
    }
    return false;
  }
}

/// ✅ INTERCEPTOR DE REDIRECCIONES (NUEVO) - Maneja 307
class RedirectInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Si es 307 y tiene Location header, seguimos la redirección
    if (response.statusCode == 307) {
      final location = response.headers.value('location');
      if (location != null) {
        _AppLogger.info('🔄 Redirección 307 detectada a: $location');
        
        // Crear nueva request con la URL de redirección
        final newOptions = response.requestOptions.copyWith(path: location);
        
        // Reenviar la petición
        final dio = Dio();
        dio.fetch(newOptions).then((newResponse) {
          _AppLogger.success('✅ Redirección completada: ${newResponse.statusCode}');
          handler.resolve(newResponse);
        }).catchError((error) {
          _AppLogger.error('❌ Error en redirección: $error');
          handler.reject(error is DioException ? error : DioException(
            requestOptions: newOptions,
            error: error,
          ));
        });
        return;
      }
    }
    handler.next(response);
  }
}

/// Interceptor de reintentos para errores de red
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor({
    this.maxRetries = 2,
    this.retryDelay = const Duration(seconds: 1),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final extra = requestOptions.extra;

    // No reintentar rutas de 2FA con código inválido
    if (requestOptions.path.contains('/auth/2fa/') && 
        err.response?.statusCode == 401) {
      _AppLogger.debug('⏭️ No reintentando 2FA - código inválido');
      return handler.next(err);
    }

    // No reintentar 307 (ya lo maneja RedirectInterceptor)
    if (err.response?.statusCode == 307) {
      _AppLogger.debug('⏭️ 307 manejado por RedirectInterceptor');
      return handler.next(err);
    }

    // Verificar si ya hemos intentado reintentar
    var retryCount = extra['retry_count'] as int? ?? 0;
    
    if (retryCount < maxRetries && _shouldRetry(err)) {
      retryCount++;
      requestOptions.extra['retry_count'] = retryCount;
      
      _AppLogger.debug('🔄 Reintentando ${requestOptions.method} ${requestOptions.path} '
            '(Intento $retryCount de $maxRetries)');
      
      await Future.delayed(retryDelay);
      
      try {
        final response = await Dio().fetch(requestOptions);
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }
    
    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // Reintentar solo para errores de red o timeout
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           err.type == DioExceptionType.connectionError;
  }
}