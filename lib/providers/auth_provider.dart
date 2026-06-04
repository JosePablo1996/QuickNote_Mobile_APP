// lib/providers/auth_provider.dart
// Proveedor de autenticación con Riverpod - VERSIÓN CON ROL CORREGIDA
// ✅ CORREGIDO: La biometría persiste después de cerrar sesión
// ✅ CORREGIDO: No se eliminan credenciales biométricas al hacer logout
// ✅ CORREGIDO: Solo se limpian tokens de sesión, no datos de usuario biométricos
// ✅ NUEVO: Soporte completo para rol de usuario (admin/user)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicknote/core/services/auth_service.dart';
import 'package:quicknote/core/services/biometric_service.dart';
import 'package:quicknote/core/services/session_service.dart';
import 'package:quicknote/core/services/storage_service.dart';
import 'package:quicknote/core/services/two_factor_service.dart';
import 'package:quicknote/core/utils/secure_storage.dart';
import 'package:quicknote/core/utils/token_storage.dart';
import 'package:quicknote/models/user.dart';
import 'package:quicknote/widgets/toast_message.dart';

// Logger para evitar warnings de print
class _AuthLogger {
  static void info(String message) {
    debugPrint('ℹ️ [AuthProvider] $message');
  }
  
  static void success(String message) {
    debugPrint('✅ [AuthProvider] $message');
  }
  
  static void warning(String message) {
    debugPrint('⚠️ [AuthProvider] $message');
  }
  
  static void error(String message) {
    debugPrint('❌ [AuthProvider] $message');
  }
}

// ============================================
// STATE
// ============================================

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool requiresTwoFactor;
  final String? twoFactorTempToken;
  final bool isBiometricAvailable;
  final bool isBiometricEnabled;
  final bool isBiometricEnrolled;
  final String? biometricType;
  
  // Datos temporales para 2FA
  final String? pendingTwoFactorEmail;
  final String? pendingTwoFactorFullName;
  final String? pendingTwoFactorAvatar;
  final String? pendingTwoFactorBanner;
  final String? pendingTwoFactorTempToken;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.requiresTwoFactor = false,
    this.twoFactorTempToken,
    this.isBiometricAvailable = false,
    this.isBiometricEnabled = false,
    this.isBiometricEnrolled = false,
    this.biometricType,
    this.pendingTwoFactorEmail,
    this.pendingTwoFactorFullName,
    this.pendingTwoFactorAvatar,
    this.pendingTwoFactorBanner,
    this.pendingTwoFactorTempToken,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? requiresTwoFactor,
    String? twoFactorTempToken,
    bool? isBiometricAvailable,
    bool? isBiometricEnabled,
    bool? isBiometricEnrolled,
    String? biometricType,
    String? pendingTwoFactorEmail,
    String? pendingTwoFactorFullName,
    String? pendingTwoFactorAvatar,
    String? pendingTwoFactorBanner,
    String? pendingTwoFactorTempToken,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      requiresTwoFactor: requiresTwoFactor ?? this.requiresTwoFactor,
      twoFactorTempToken: twoFactorTempToken ?? this.twoFactorTempToken,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricEnrolled: isBiometricEnrolled ?? this.isBiometricEnrolled,
      biometricType: biometricType ?? this.biometricType,
      pendingTwoFactorEmail: pendingTwoFactorEmail ?? this.pendingTwoFactorEmail,
      pendingTwoFactorFullName: pendingTwoFactorFullName ?? this.pendingTwoFactorFullName,
      pendingTwoFactorAvatar: pendingTwoFactorAvatar ?? this.pendingTwoFactorAvatar,
      pendingTwoFactorBanner: pendingTwoFactorBanner ?? this.pendingTwoFactorBanner,
      pendingTwoFactorTempToken: pendingTwoFactorTempToken ?? this.pendingTwoFactorTempToken,
    );
  }
}

// ============================================
// NOTIFIER
// ============================================

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final AuthService _authService = AuthService();
  final TwoFactorService _twoFactorService = TwoFactorService();
  final BiometricService _biometricService = BiometricService();
  final SecureStorage _secureStorage = SecureStorage();
  final StorageService _storageService = StorageService();
  final SessionService _sessionService = SessionService();

  Future<void> _init() async {
    await checkAuthStatus();
    await checkBiometricAvailability();
    await checkBiometricEnrollment();
    await refreshProfile();
  }

  // ============================================
  // VERIFICAR ESTADO DE AUTENTICACIÓN
  // ============================================
  
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // ✅ VERIFICAR VALIDEZ DE SESIÓN
      final isSessionValid = await _sessionService.isSessionValid();
      
      if (!isSessionValid) {
        _AuthLogger.warning('Sesión inválida, limpiando tokens...');
        await tokenStorage.clearSession();
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
        );
        return;
      }
      
      final token = await tokenStorage.getAuthToken();
      final userId = await tokenStorage.getUserId();
      
      if (token != null && userId != null) {
        final email = await tokenStorage.getUserEmail();
        final name = await _secureStorage.getUserName();
        final avatar = await _secureStorage.getUserAvatar();
        final banner = await _secureStorage.getUserBanner();
        final role = await tokenStorage.getUserRole(); // ✅ NUEVO: Leer rol
        
        final user = User(
          id: userId,
          email: email ?? '',
          name: name,
          avatar: avatar,
          banner: banner,
          role: role, // ✅ Asignar rol
          createdAt: DateTime.now(),
          isActive: true,
        );
        
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        _AuthLogger.success('Usuario autenticado: ${user.email}, Rol: ${user.role}');
        _AuthLogger.info('   Banner: ${banner != null ? "✅" : "❌"}');
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
        );
        _AuthLogger.warning('No hay sesión activa');
      }
    } catch (e) {
      _AuthLogger.error('Error en checkAuthStatus: $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // ============================================
  // VERIFICAR DISPONIBILIDAD DE BIOMETRÍA
  // ============================================
  
  Future<void> checkBiometricAvailability() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final isEnabled = await _secureStorage.isBiometricEnabled();
    final biometricName = await _biometricService.getBiometricName();
    
    _AuthLogger.info('Estado biometría - Disponible: $isAvailable, Activada: $isEnabled, Tipo: $biometricName');
    
    state = state.copyWith(
      isBiometricAvailable: isAvailable,
      isBiometricEnabled: isEnabled,
      biometricType: biometricName,
    );
  }

  Future<void> checkBiometricEnrollment() async {
    final isEnrolled = await _biometricService.isBiometricEnrolled();
    _AuthLogger.info('Biometría registrada en dispositivo: $isEnrolled');
    state = state.copyWith(isBiometricEnrolled: isEnrolled);
  }

  Future<bool> registerBiometric() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final registered = await _biometricService.registerBiometric();
      
      if (registered) {
        await checkBiometricEnrollment();
        await checkBiometricAvailability();
        
        if (state.isBiometricEnrolled) {
          await enableBiometric(true);
        }
        
        state = state.copyWith(isLoading: false);
        _AuthLogger.success('Biometría registrada exitosamente');
        return true;
      }
      
      state = state.copyWith(
        error: 'No se pudo registrar la biometría',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<void> enableBiometric(bool enable) async {
    await _secureStorage.saveBiometricEnabled(enable);
    _AuthLogger.info('Biometría ${enable ? "activada" : "desactivada"} en SecureStorage');
    
    state = state.copyWith(isBiometricEnabled: enable);
    
    final verifyEnabled = await _secureStorage.isBiometricEnabled();
    _AuthLogger.info('Verificación - Biometría activada: $verifyEnabled');
  }

  Future<bool> authenticateWithBiometric({required String reason}) async {
    try {
      _AuthLogger.info('Iniciando autenticación biométrica...');
      
      final isAvailable = await _biometricService.isBiometricAvailable();
      if (!isAvailable) {
        _AuthLogger.warning('Biometría no disponible en el dispositivo');
        return false;
      }
      
      final isEnrolled = await _biometricService.isBiometricEnrolled();
      if (!isEnrolled) {
        _AuthLogger.warning('No hay biometría registrada en el dispositivo');
        return false;
      }
      
      _AuthLogger.info('Mostrando diálogo de autenticación biométrica...');
      
      final authenticated = await _biometricService.authenticate(
        reason: reason,
      );
      
      if (authenticated) {
        _AuthLogger.success('Autenticación biométrica exitosa');
        return true;
      } else {
        _AuthLogger.warning('Autenticación biométrica fallida - usuario no autenticado');
        return false;
      }
    } catch (e) {
      _AuthLogger.error('Error en autenticación biométrica: $e');
      return false;
    }
  }

  // ============================================
  // GUARDAR CREDENCIALES BIOMÉTRICAS
  // ============================================
  
  Future<void> _saveBiometricCredentialsIfNeeded(String email, String password) async {
    final rememberMe = await _secureStorage.getRememberMe();
    if (rememberMe && email.isNotEmpty && password.isNotEmpty) {
      await _secureStorage.saveCredentialsForBiometric(email, password);
      _AuthLogger.success('✅ Credenciales guardadas para login biométrico');
    } else {
      _AuthLogger.info('No se guardaron credenciales (rememberMe=$rememberMe)');
    }
  }

  // ============================================
  // BUSCAR IMÁGENES DEL USUARIO (BANNER Y AVATAR)
  // ============================================
  
  Future<Map<String, String?>> fetchUserImagesFromStorage(String userId) async {
    return await _storageService.fetchUserImages(userId);
  }

  // ✅ NUEVO: Refrescar perfil incluyendo el rol
  Future<void> refreshProfile() async {
    try {
      final userId = await tokenStorage.getUserId();
      if (userId == null) {
        _AuthLogger.warning('No hay userId para refrescar perfil');
        return;
      }
      
      // ✅ OBTENER DATOS FRESCOS DEL BACKEND
      final userData = await _authService.getCurrentUser();
      
      final String fullName = userData['full_name'] ?? await _secureStorage.getUserName() ?? '';
      final String? avatar = userData['avatar'] ?? await _secureStorage.getUserAvatar();
      final String? banner = userData['banner'] ?? await _secureStorage.getUserBanner();
      final String role = userData['role'] ?? 'user'; // ✅ Obtener rol del backend
      
      _AuthLogger.info('📥 Estado actual antes de refresh:');
      _AuthLogger.info('   Nombre: $fullName');
      _AuthLogger.info('   Avatar: ${avatar != null ? "✅" : "❌"}');
      _AuthLogger.info('   Banner: ${banner != null ? "✅" : "❌"}');
      _AuthLogger.info('   Rol: $role');
      
      // ✅ GUARDAR ROL EN TOKENSTORAGE
      await tokenStorage.saveUserRole(role);
      _AuthLogger.success('✅ Rol guardado: $role');
      
      // ✅ GUARDAR NOMBRE
      if (fullName.isNotEmpty) {
        await _secureStorage.saveUserName(fullName);
      }
      
      // ✅ BUSCAR IMÁGENES EN STORAGE DE SUPABASE
      final storageImages = await fetchUserImagesFromStorage(userId);
      
      String? finalAvatar = avatar;
      String? finalBanner = banner;
      
      if (storageImages['avatar'] != null && storageImages['avatar']!.isNotEmpty) {
        finalAvatar = storageImages['avatar'];
        await _secureStorage.saveUserAvatar(finalAvatar!);
        _AuthLogger.success('✅ Avatar actualizado desde storage');
      }
      
      if (storageImages['banner'] != null && storageImages['banner']!.isNotEmpty) {
        finalBanner = storageImages['banner'];
        await _secureStorage.saveUserBanner(finalBanner!);
        _AuthLogger.success('✅ Banner actualizado desde storage: $finalBanner');
      }
      
      final email = await tokenStorage.getUserEmail();
      final user = User(
        id: userId,
        email: email ?? '',
        name: fullName,
        avatar: finalAvatar,
        banner: finalBanner,
        role: role,
        createdAt: state.user?.createdAt ?? DateTime.now(),
        isActive: true,
      );
      
      state = state.copyWith(user: user);
      _AuthLogger.success('✅ Perfil actualizado - Banner: ${finalBanner != null ? "Sí" : "No"}, Rol: $role');
      
    } catch (e) {
      _AuthLogger.error('Error refrescando perfil: $e');
    }
  }

  // ============================================
  // LOGIN CON EMAIL Y PASSWORD (CON RESPUESTA COMPLETA)
  // ============================================
  
  Future<Map<String, dynamic>> loginWithResponse(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _authService.login(email, password);
      
      if (response['requires_2fa'] == true) {
        final tempToken = response['temp_token'] ?? response['user_id'];
        final userData = response['user'] as Map<String, dynamic>?;
        final fullName = userData?['full_name'] ?? userData?['name'];
        final avatar = userData?['avatar'];
        final banner = userData?['banner'];
        
        state = state.copyWith(
          requiresTwoFactor: true,
          twoFactorTempToken: tempToken,
          pendingTwoFactorEmail: email,
          pendingTwoFactorFullName: fullName,
          pendingTwoFactorAvatar: avatar,
          pendingTwoFactorBanner: banner,
          pendingTwoFactorTempToken: tempToken,
          isLoading: false,
        );
        return response;
      }
      
      if (response['access_token'] != null) {
        await _saveUserDataFromResponse(response, email);
        await _loadUserFromToken();
        await _saveBiometricCredentialsIfNeeded(email, password);
        await refreshProfile();
        
        state = state.copyWith(
          requiresTwoFactor: false,
          twoFactorTempToken: null,
          pendingTwoFactorEmail: null,
          pendingTwoFactorFullName: null,
          pendingTwoFactorAvatar: null,
          pendingTwoFactorBanner: null,
          pendingTwoFactorTempToken: null,
          isLoading: false,
          isAuthenticated: true,
        );
        return response;
      }
      
      state = state.copyWith(
        error: response['message'] ?? 'Error de autenticación',
        isLoading: false,
      );
      return response;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // LOGIN CON EMAIL Y PASSWORD (SIMPLE)
  // ============================================
  
  Future<bool> login(String email, String password, [BuildContext? context]) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _authService.login(email, password);
      
      if (response['requires_2fa'] == true) {
        final tempToken = response['temp_token'] ?? response['user_id'];
        final userData = response['user'] as Map<String, dynamic>?;
        final fullName = userData?['full_name'] ?? userData?['name'];
        final avatar = userData?['avatar'];
        final banner = userData?['banner'];
        
        state = state.copyWith(
          requiresTwoFactor: true,
          twoFactorTempToken: tempToken,
          pendingTwoFactorEmail: email,
          pendingTwoFactorFullName: fullName,
          pendingTwoFactorAvatar: avatar,
          pendingTwoFactorBanner: banner,
          pendingTwoFactorTempToken: tempToken,
          isLoading: false,
        );
        return false;
      }
      
      if (response['access_token'] != null) {
        await _saveUserDataFromResponse(response, email);
        await _loadUserFromToken();
        await _saveBiometricCredentialsIfNeeded(email, password);
        await refreshProfile();
        
        state = state.copyWith(
          requiresTwoFactor: false,
          twoFactorTempToken: null,
          pendingTwoFactorEmail: null,
          pendingTwoFactorFullName: null,
          pendingTwoFactorAvatar: null,
          pendingTwoFactorBanner: null,
          pendingTwoFactorTempToken: null,
          isLoading: false,
          isAuthenticated: true,
        );
        return true;
      }
      
      state = state.copyWith(
        error: response['message'] ?? 'Error de autenticación',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  // ============================================
  // VERIFICAR 2FA
  // ============================================
  
  Future<bool> verifyTwoFactor(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final tempToken = state.twoFactorTempToken ?? state.pendingTwoFactorTempToken;
      if (tempToken == null) {
        throw Exception('No hay token temporal');
      }
      
      _AuthLogger.info('Verificando 2FA con tempToken: $tempToken');
      
      final response = await _twoFactorService.verifyTwoFactorLogin(code, tempToken);
      
      if (response['access_token'] != null) {
        final token = response['access_token'];
        
        await tokenStorage.saveAuthToken(token);
        
        final verifyToken = await tokenStorage.getAuthToken();
        _AuthLogger.success('Verificación token guardado: ${verifyToken != null}');
        
        if (response['refresh_token'] != null) {
          await tokenStorage.saveRefreshToken(response['refresh_token']);
        }
        
        final email = state.pendingTwoFactorEmail;
        if (email != null && email.isNotEmpty) {
          await tokenStorage.saveUserEmail(email);
          
          final savedPassword = await _secureStorage.getSavedPassword();
          if (savedPassword != null && savedPassword.isNotEmpty) {
            await _saveBiometricCredentialsIfNeeded(email, savedPassword);
          } else {
            _AuthLogger.warning('No hay contraseña guardada para credenciales biométricas');
          }
        }
        
        if (state.pendingTwoFactorAvatar != null && state.pendingTwoFactorAvatar!.isNotEmpty) {
          await _secureStorage.saveUserAvatar(state.pendingTwoFactorAvatar!);
        }
        
        if (state.pendingTwoFactorFullName != null && state.pendingTwoFactorFullName!.isNotEmpty) {
          await _secureStorage.saveUserName(state.pendingTwoFactorFullName!);
          _AuthLogger.success('✅ Nombre guardado: ${state.pendingTwoFactorFullName}');
        }
        
        final userData = response['user'] as Map<String, dynamic>?;
        if (userData != null) {
          if (userData['avatar'] != null && userData['avatar'].toString().isNotEmpty) {
            await _secureStorage.saveUserAvatar(userData['avatar']);
          }
          if (userData['banner'] != null && userData['banner'].toString().isNotEmpty) {
            await _secureStorage.saveUserBanner(userData['banner']);
          }
          if (userData['id'] != null) {
            await tokenStorage.saveUserId(userData['id'].toString());
          }
          if (userData['full_name'] != null && userData['full_name'].toString().isNotEmpty) {
            await _secureStorage.saveUserName(userData['full_name']);
          }
          // ✅ NUEVO: Guardar rol si viene en la respuesta
          if (userData['role'] != null && userData['role'].toString().isNotEmpty) {
            await tokenStorage.saveUserRole(userData['role']);
            _AuthLogger.success('✅ Rol guardado desde 2FA: ${userData['role']}');
          }
        }
        
        final userId = await tokenStorage.getUserId();
        if (userId != null) {
          final storageImages = await fetchUserImagesFromStorage(userId);
          if (storageImages['banner'] != null && storageImages['banner']!.isNotEmpty) {
            await _secureStorage.saveUserBanner(storageImages['banner']!);
            _AuthLogger.success('✅ Banner cargado desde storage');
          }
        }
        
        await tokenStorage.saveTwoFactorVerified(true);
        await _loadUserFromToken();
        await refreshProfile();
        
        state = state.copyWith(
          requiresTwoFactor: false,
          twoFactorTempToken: null,
          pendingTwoFactorEmail: null,
          pendingTwoFactorFullName: null,
          pendingTwoFactorAvatar: null,
          pendingTwoFactorBanner: null,
          pendingTwoFactorTempToken: null,
          isLoading: false,
          isAuthenticated: true,
        );
        
        _AuthLogger.success('Verificación 2FA completada exitosamente');
        return true;
      }
      
      state = state.copyWith(
        error: response['message'] ?? 'Código 2FA inválido',
        isLoading: false,
      );
      return false;
    } catch (e) {
      _AuthLogger.error('Error en verificación 2FA: $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  // ============================================
  // LOGIN CON OTP
  // ============================================
  
  Future<bool> sendOtp(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _authService.sendOtp(email);
      state = state.copyWith(isLoading: false);
      return response['success'] == true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _authService.verifyOtp(email, code);
      
      if (response['access_token'] != null) {
        final token = response['access_token'];
        
        await tokenStorage.saveAuthToken(token);
        
        final verifyToken = await tokenStorage.getAuthToken();
        _AuthLogger.success('OTP - Verificación token guardado: ${verifyToken != null}');
        
        final userData = response['user'] as Map<String, dynamic>?;
        if (userData != null) {
          await tokenStorage.saveUserId(userData['id']?.toString() ?? '');
          await tokenStorage.saveUserEmail(userData['email'] ?? email);
          if (userData['full_name'] != null && userData['full_name'].toString().isNotEmpty) {
            await _secureStorage.saveUserName(userData['full_name']);
          }
          if (userData['avatar'] != null && userData['avatar'].toString().isNotEmpty) {
            await _secureStorage.saveUserAvatar(userData['avatar']);
          }
          if (userData['banner'] != null && userData['banner'].toString().isNotEmpty) {
            await _secureStorage.saveUserBanner(userData['banner']);
            _AuthLogger.success('✅ Banner guardado desde respuesta OTP: ${userData['banner']}');
          }
          // ✅ NUEVO: Guardar rol si viene en la respuesta
          if (userData['role'] != null && userData['role'].toString().isNotEmpty) {
            await tokenStorage.saveUserRole(userData['role']);
            _AuthLogger.success('✅ Rol guardado desde OTP: ${userData['role']}');
          }
        }
        
        final rememberMe = await _secureStorage.getRememberMe();
        if (rememberMe) {
          await _secureStorage.saveSavedEmail(email);
          _AuthLogger.success('Email guardado para login biométrico (contraseña pendiente)');
        }
        
        final userId = await tokenStorage.getUserId();
        if (userId != null) {
          final storageImages = await fetchUserImagesFromStorage(userId);
          if (storageImages['banner'] != null && storageImages['banner']!.isNotEmpty) {
            await _secureStorage.saveUserBanner(storageImages['banner']!);
            _AuthLogger.success('✅ Banner cargado desde storage después de OTP');
          }
        }
        
        await _loadUserFromToken();
        await refreshProfile();
        
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
        );
        return true;
      }
      
      state = state.copyWith(
        error: response['message'] ?? 'Código OTP inválido',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  // ============================================
  // LOGIN CON BIOMETRÍA
  // ============================================
  
  Future<bool> loginWithBiometric() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      _AuthLogger.info('Iniciando login biométrico...');
      
      final isAvailable = await _biometricService.isBiometricAvailable();
      if (!isAvailable) {
        _AuthLogger.warning('Biometría no disponible en este dispositivo');
        state = state.copyWith(
          error: 'La biometría no está disponible en este dispositivo',
          isLoading: false,
        );
        return false;
      }
      
      final authenticated = await authenticateWithBiometric(
        reason: 'Verifica tu identidad para acceder a QuickNote',
      );
      
      if (!authenticated) {
        _AuthLogger.warning('Autenticación biométrica fallida');
        state = state.copyWith(
          error: 'Autenticación biométrica fallida',
          isLoading: false,
        );
        return false;
      }
      
      final savedEmail = await _secureStorage.getSavedEmail();
      final savedPassword = await _secureStorage.getSavedPassword();
      
      if (savedEmail == null || savedEmail.isEmpty || savedPassword == null || savedPassword.isEmpty) {
        _AuthLogger.warning('No hay credenciales guardadas para login biométrico');
        state = state.copyWith(
          error: 'No hay credenciales guardadas. Inicia sesión manualmente primero y activa "Recordarme".',
          isLoading: false,
        );
        return false;
      }
      
      _AuthLogger.info('Credenciales encontradas, realizando login...');
      
      final response = await _authService.login(savedEmail, savedPassword);
      
      if (response['requires_2fa'] == true) {
        _AuthLogger.info('Usuario requiere 2FA, redirigiendo a verificación...');
        
        final tempToken = response['temp_token'] ?? response['user_id'];
        final userData = response['user'] as Map<String, dynamic>?;
        final fullName = userData?['full_name'] ?? userData?['name'];
        final avatar = userData?['avatar'];
        final banner = userData?['banner'];
        
        state = state.copyWith(
          requiresTwoFactor: true,
          twoFactorTempToken: tempToken,
          pendingTwoFactorEmail: savedEmail,
          pendingTwoFactorFullName: fullName,
          pendingTwoFactorAvatar: avatar,
          pendingTwoFactorBanner: banner,
          pendingTwoFactorTempToken: tempToken,
          isLoading: false,
        );
        
        return false;
      }
      
      if (response['access_token'] != null) {
        await tokenStorage.saveAuthToken(response['access_token']);
        await tokenStorage.saveUserEmail(savedEmail);
        
        if (response['refresh_token'] != null) {
          await tokenStorage.saveRefreshToken(response['refresh_token']);
        }
        
        final userData = response['user'] as Map<String, dynamic>?;
        if (userData != null) {
          if (userData['id'] != null) {
            await tokenStorage.saveUserId(userData['id'].toString());
          }
          if (userData['full_name'] != null && userData['full_name'].toString().isNotEmpty) {
            await _secureStorage.saveUserName(userData['full_name']);
            _AuthLogger.success('✅ Nombre guardado: ${userData['full_name']}');
          }
          if (userData['avatar'] != null && userData['avatar'].toString().isNotEmpty) {
            await _secureStorage.saveUserAvatar(userData['avatar']);
          }
          if (userData['banner'] != null && userData['banner'].toString().isNotEmpty) {
            await _secureStorage.saveUserBanner(userData['banner']);
            _AuthLogger.success('✅ Banner guardado desde login biométrico');
          }
          // ✅ NUEVO: Guardar rol
          if (userData['role'] != null && userData['role'].toString().isNotEmpty) {
            await tokenStorage.saveUserRole(userData['role']);
            _AuthLogger.success('✅ Rol guardado desde login biométrico: ${userData['role']}');
          }
        }
        
        final userId = await tokenStorage.getUserId();
        if (userId != null) {
          final storageImages = await fetchUserImagesFromStorage(userId);
          if (storageImages['banner'] != null && storageImages['banner']!.isNotEmpty) {
            await _secureStorage.saveUserBanner(storageImages['banner']!);
            _AuthLogger.success('✅ Banner cargado desde storage después de login biométrico');
          }
        }
        
        await _loadUserFromToken();
        await refreshProfile();
        
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
        );
        
        _AuthLogger.success('Login biométrico exitoso');
        return true;
      }
      
      _AuthLogger.warning('Login biométrico fallido - respuesta sin token');
      state = state.copyWith(
        error: response['message'] ?? 'Error en login biométrico',
        isLoading: false,
      );
      return false;
      
    } catch (e) {
      _AuthLogger.error('Error en login biométrico: $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  // ============================================
  // REGISTRO
  // ============================================
  
  Future<bool> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _authService.login(email, password);
      
      if (response['access_token'] != null) {
        await _saveUserDataFromResponse(response, email, name);
        await _loadUserFromToken();
        await refreshProfile();
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
        );
        return true;
      }
      
      state = state.copyWith(
        error: response['message'] ?? 'Error en el registro',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  // ============================================
  // CAMBIAR CONTRASEÑA - CON INVALIDACIÓN DE SESIONES
  // ============================================
  
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _authService.changePassword(currentPassword, newPassword);
      
      if (response['success'] == true) {
        await _sessionService.incrementSessionVersion();
        await _sessionService.saveLastPasswordChange(DateTime.now());
        
        final newVersion = await _sessionService.getCurrentSessionVersion();
        await tokenStorage.saveSessionVersion(newVersion);
        
        if (response['requires_relogin'] == true) {
          await logout();
          ToastMessage.success('Contraseña actualizada. Por favor, inicia sesión nuevamente.');
        } else {
          ToastMessage.success('Contraseña actualizada correctamente');
        }
        
        state = state.copyWith(isLoading: false);
        return true;
      }
      
      state = state.copyWith(
        error: response['message'] ?? 'Error al cambiar contraseña',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  // ============================================
  // VERIFICAR EXPIRACIÓN DE CONTRASEÑA
  // ============================================
  
  Future<bool> isPasswordExpired() async {
    return await _sessionService.isPasswordExpired();
  }
  
  Future<int> getPasswordDaysRemaining() async {
    return await _sessionService.getDaysUntilPasswordExpiration();
  }
  
  Future<bool> validateSession() async {
    final isValid = await _sessionService.isSessionValid();
    
    if (!isValid) {
      await logout();
      return false;
    }
    return true;
  }

  // ============================================
  // RECUPERAR CONTRASEÑA
  // ============================================
  
  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authService.forgotPasswordSendOtp(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  Future<bool> verifyPasswordResetOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _authService.forgotPasswordVerifyOtp(email, otp);
      
      if (response['success'] == true) {
        state = state.copyWith(isLoading: false);
        return true;
      }
      
      state = state.copyWith(
        error: response['message'] ?? 'Código inválido',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> resetPassword(String email, String code, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _authService.forgotPasswordReset(email, code, newPassword);
      
      if (response['success'] == true) {
        state = state.copyWith(isLoading: false);
        return true;
      }
      
      state = state.copyWith(
        error: response['message'] ?? 'Error al resetear contraseña',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  // ============================================
  // SUBIR AVATAR Y BANNER
  // ============================================
  
  Future<String?> uploadAvatar(File imageFile, BuildContext context) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _authService.uploadAvatar(imageFile);
      
      if (response['avatar_url'] != null) {
        final newAvatarUrl = response['avatar_url'];
        await _secureStorage.saveUserAvatar(newAvatarUrl);
        
        if (state.user != null) {
          final updatedUser = state.user!.copyWith(avatar: newAvatarUrl);
          state = state.copyWith(user: updatedUser, isLoading: false);
        } else {
          state = state.copyWith(isLoading: false);
        }
        
        if (context.mounted) {
          ToastMessage.success(context, 'Avatar actualizado correctamente');
        }
        return newAvatarUrl;
      } else {
        throw Exception(response['message'] ?? 'Error al subir avatar');
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      if (context.mounted) {
        ToastMessage.error(context, 'Error al subir avatar: ${e.toString()}');
      }
      return null;
    }
  }

  Future<String?> uploadBanner(File imageFile, BuildContext context) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _authService.uploadBanner(imageFile);
      
      if (response['banner_url'] != null) {
        final newBannerUrl = response['banner_url'];
        await _secureStorage.saveUserBanner(newBannerUrl);
        _AuthLogger.success('✅ Banner guardado: $newBannerUrl');
        
        if (state.user != null) {
          final updatedUser = state.user!.copyWith(banner: newBannerUrl);
          state = state.copyWith(user: updatedUser, isLoading: false);
        } else {
          state = state.copyWith(isLoading: false);
        }
        
        if (context.mounted) {
          ToastMessage.success(context, 'Banner actualizado correctamente');
        }
        return newBannerUrl;
      } else {
        throw Exception(response['message'] ?? 'Error al subir banner');
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      if (context.mounted) {
        ToastMessage.error(context, 'Error al subir banner: ${e.toString()}');
      }
      return null;
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    required BuildContext context,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _authService.updateProfile(
        fullName: fullName,
        username: username,
        bio: bio,
      );
      
      if (response['success'] == true) {
        if (fullName != null && fullName.isNotEmpty) {
          await _secureStorage.saveUserName(fullName);
          _AuthLogger.success('✅ Nombre actualizado: $fullName');
        }
        
        if (state.user != null) {
          final updatedUser = state.user!.copyWith(
            name: fullName ?? state.user!.name,
          );
          state = state.copyWith(user: updatedUser, isLoading: false);
        } else {
          state = state.copyWith(isLoading: false);
        }
        
        if (context.mounted) {
          ToastMessage.success(context, 'Perfil actualizado correctamente');
        }
        return true;
      } else {
        throw Exception(response['message'] ?? 'Error al actualizar perfil');
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      if (context.mounted) {
        ToastMessage.error(context, 'Error al actualizar perfil: ${e.toString()}');
      }
      return false;
    }
  }

  // ============================================
  // PREFERENCIAS
  // ============================================
  
  Future<void> saveRememberMe(bool value) async {
    await _secureStorage.saveRememberMe(value);
  }
  
  Future<bool> getRememberMe() async {
    return await _secureStorage.getRememberMe();
  }

  void setTwoFactorTempToken(String token) {
    state = state.copyWith(
      requiresTwoFactor: true,
      twoFactorTempToken: token,
      pendingTwoFactorTempToken: token,
    );
  }

  Map<String, String?> getPendingTwoFactorData() {
    return {
      'email': state.pendingTwoFactorEmail,
      'fullName': state.pendingTwoFactorFullName,
      'avatar': state.pendingTwoFactorAvatar,
      'banner': state.pendingTwoFactorBanner,
      'tempToken': state.pendingTwoFactorTempToken ?? state.twoFactorTempToken,
    };
  }

  // ============================================
  // GUARDAR DATOS AUXILIARES
  // ============================================
  
  Future<void> saveAuthToken(String token) async {
    await tokenStorage.saveAuthToken(token);
    _AuthLogger.success('Token guardado manualmente');
  }

  Future<void> saveRefreshToken(String token) async {
    await tokenStorage.saveRefreshToken(token);
  }

  Future<void> saveUserName(String name) async {
    await _secureStorage.saveUserName(name);
  }

  Future<void> saveUserAvatar(String avatar) async {
    await _secureStorage.saveUserAvatar(avatar);
  }

  Future<void> saveUserBanner(String banner) async {
    await _secureStorage.saveUserBanner(banner);
  }

  Future<void> saveUserEmail(String email) async {
    await tokenStorage.saveUserEmail(email);
  }

  Future<void> saveUserId(String userId) async {
    await tokenStorage.saveUserId(userId);
  }

  // ✅ NUEVO: Guardar rol manualmente
  Future<void> saveUserRole(String role) async {
    await tokenStorage.saveUserRole(role);
    _AuthLogger.success('✅ Rol guardado manualmente: $role');
    
    // Actualizar el usuario actual
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(role: role);
      state = state.copyWith(user: updatedUser);
    }
  }

  // ============================================
  // CIERRE DE SESIÓN - CORREGIDO v8
  // ============================================
  
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    
    _AuthLogger.info('🚪 Iniciando cierre de sesión...');
    
    // ✅ 1. Limpiar tokens de autenticación
    await tokenStorage.clearSession();
    _AuthLogger.info('✅ Tokens de autenticación eliminados');
    
    _AuthLogger.info('ℹ️ Biometría NO se desactiva - persiste entre sesiones');
    _AuthLogger.info('ℹ️ Credenciales biométricas NO se eliminan - persisten entre sesiones');
    
    // ✅ 2. Limpiar datos de sesión
    await _sessionService.clearSessionData();
    _AuthLogger.info('✅ Datos de sesión eliminados');
    
    // ✅ 3. Limpiar datos de usuario (excepto credenciales biométricas)
    await _secureStorage.saveUserName('');
    await _secureStorage.saveUserAvatar('');
    await _secureStorage.saveUserBanner('');
    _AuthLogger.info('✅ Datos de usuario eliminados');
    
    // ✅ 4. Actualizar estado
    state = state.copyWith(
      user: null,
      isAuthenticated: false,
      requiresTwoFactor: false,
      twoFactorTempToken: null,
      pendingTwoFactorEmail: null,
      pendingTwoFactorFullName: null,
      pendingTwoFactorAvatar: null,
      pendingTwoFactorBanner: null,
      pendingTwoFactorTempToken: null,
      isLoading: false,
      error: null,
    );
    
    // ✅ 5. Verificar credenciales biométricas
    final hasCredentials = await _secureStorage.hasSavedCredentials();
    final isBiometricEnabled = await _secureStorage.isBiometricEnabled();
    _AuthLogger.info('🔍 Estado después de logout:');
    _AuthLogger.info('   Credenciales biométricas: ${hasCredentials ? "✅ PRESERVADAS" : "❌ No hay"}');
    _AuthLogger.info('   Biometría activada: ${isBiometricEnabled ? "✅ PRESERVADA" : "❌ No"}');
    
    _AuthLogger.success('✅ Sesión cerrada - Biometría y credenciales preservadas');
  }

  Future<void> logoutKeepBiometricCredentials() async {
    state = state.copyWith(isLoading: true);
    
    _AuthLogger.info('🚪 Iniciando cierre de sesión (preservando credenciales biométricas)...');
    
    await tokenStorage.clearSession();
    await _sessionService.clearSessionData();
    
    state = state.copyWith(
      user: null,
      isAuthenticated: false,
      requiresTwoFactor: false,
      twoFactorTempToken: null,
      pendingTwoFactorEmail: null,
      pendingTwoFactorFullName: null,
      pendingTwoFactorAvatar: null,
      pendingTwoFactorBanner: null,
      pendingTwoFactorTempToken: null,
      isLoading: false,
      error: null,
    );
    
    _AuthLogger.success('✅ Sesión cerrada (credenciales biométricas preservadas)');
  }

  Future<bool> hasBiometricCredentials() async {
    return await _secureStorage.hasSavedCredentials();
  }

  // ============================================
  // MÉTODOS PRIVADOS
  // ============================================
  
  Future<void> _saveUserDataFromResponse(Map<String, dynamic> response, String email, [String? providedName]) async {
    final userData = response['user'] as Map<String, dynamic>?;
    
    if (userData != null) {
      await tokenStorage.saveUserId(userData['id']?.toString() ?? '');
      await tokenStorage.saveUserEmail(userData['email'] ?? email);
      
      final fullName = userData['full_name'] ?? userData['name'] ?? providedName ?? '';
      if (fullName.isNotEmpty) {
        await _secureStorage.saveUserName(fullName);
        _AuthLogger.success('✅ Nombre guardado en _saveUserDataFromResponse: $fullName');
      }
      
      if (userData['avatar'] != null && userData['avatar'].toString().isNotEmpty) {
        await _secureStorage.saveUserAvatar(userData['avatar']);
        _AuthLogger.success('✅ Avatar guardado');
      }
      
      if (userData['banner'] != null && userData['banner'].toString().isNotEmpty) {
        await _secureStorage.saveUserBanner(userData['banner']);
        _AuthLogger.success('✅ Banner guardado');
      }
      
      // ✅ NUEVO: Guardar rol
      final role = userData['role'] ?? 'user';
      await tokenStorage.saveUserRole(role);
      _AuthLogger.success('✅ Rol guardado en _saveUserDataFromResponse: $role');
    } else {
      await tokenStorage.saveUserEmail(email);
      if (providedName != null && providedName.isNotEmpty) {
        await _secureStorage.saveUserName(providedName);
      }
      // Rol por defecto
      await tokenStorage.saveUserRole('user');
    }
  }

  Future<void> _loadUserFromToken() async {
    final userId = await tokenStorage.getUserId();
    final email = await tokenStorage.getUserEmail();
    final name = await _secureStorage.getUserName();
    final avatar = await _secureStorage.getUserAvatar();
    final banner = await _secureStorage.getUserBanner();
    final role = await tokenStorage.getUserRole();
    
    _AuthLogger.info('📥 Cargando usuario desde almacenamiento:');
    _AuthLogger.info('   Nombre: $name');
    _AuthLogger.info('   Avatar: ${avatar != null ? "✅" : "❌"}');
    _AuthLogger.info('   Banner: ${banner != null ? "✅" : "❌"}');
    _AuthLogger.info('   Rol: $role');
    
    if (userId != null) {
      final user = User(
        id: userId,
        email: email ?? '',
        name: name,
        avatar: avatar,
        banner: banner,
        role: role,
        createdAt: DateTime.now(),
        isActive: true,
      );
      state = state.copyWith(user: user);
      _AuthLogger.success('Usuario cargado: ${user.email}, Rol: ${user.role}');
    }
  }
}

// ============================================
// PROVIDERS
// ============================================

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final isBiometricAvailableProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isBiometricAvailable;
});

final isBiometricEnabledProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isBiometricEnabled;
});

final isBiometricEnrolledProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isBiometricEnrolled;
});

final biometricTypeProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).biometricType;
});

final pendingTwoFactorDataProvider = Provider<Map<String, String?>>((ref) {
  return ref.watch(authProvider).pendingTwoFactorTempToken != null
      ? {
          'email': ref.watch(authProvider).pendingTwoFactorEmail,
          'fullName': ref.watch(authProvider).pendingTwoFactorFullName,
          'avatar': ref.watch(authProvider).pendingTwoFactorAvatar,
          'banner': ref.watch(authProvider).pendingTwoFactorBanner,
          'tempToken': ref.watch(authProvider).pendingTwoFactorTempToken,
        }
      : {};
});

final hasBiometricCredentialsProvider = FutureProvider<bool>((ref) async {
  final authNotifier = ref.read(authProvider.notifier);
  return await authNotifier.hasBiometricCredentials();
});

final passwordDaysRemainingProvider = FutureProvider<int>((ref) async {
  final authNotifier = ref.read(authProvider.notifier);
  return await authNotifier.getPasswordDaysRemaining();
});

final isPasswordExpiredProvider = FutureProvider<bool>((ref) async {
  final authNotifier = ref.read(authProvider.notifier);
  return await authNotifier.isPasswordExpired();
});