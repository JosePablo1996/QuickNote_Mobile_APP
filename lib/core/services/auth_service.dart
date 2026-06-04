// lib/core/services/auth_service.dart
// Servicio de autenticación - VERSIÓN CON ROL Y URLs DIRECTAS

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:quicknote/core/api/api_client.dart';
import 'package:quicknote/core/constants/endpoints.dart';
import 'package:quicknote/core/utils/token_storage.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();

  AuthService._internal();

  // ============================================
  // LOGIN CON EMAIL Y PASSWORD
  // ============================================
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final dio = await _apiClient.dio;
      final response = await dio.post(
        Endpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      
      if (data['access_token'] != null) {
        await _tokenStorage.saveAuthToken(data['access_token']);
        
        if (data['refresh_token'] != null) {
          await _tokenStorage.saveRefreshToken(data['refresh_token']);
        }
      }
      
      if (data['user'] != null) {
        final user = data['user'] as Map<String, dynamic>;
        await _saveUserData(user, email);
      }
      
      if (data['requires_2fa'] == true && data['temp_token'] != null) {
        await _tokenStorage.saveTempToken(data['temp_token']);
        await _tokenStorage.saveUserId(data['user_id'] ?? '');
      }

      return data;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // VERIFICAR 2FA DURANTE LOGIN
  // ============================================
  Future<Map<String, dynamic>> verifyTwoFactorLogin(String code, String tempToken) async {
    try {
      final dio = await _apiClient.dio;
      final response = await dio.post(
        Endpoints.twoFactorVerifyLogin,
        data: {
          'code': code,
          'temp_token': tempToken,
        },
      );

      final data = response.data as Map<String, dynamic>;
      
      if (data['access_token'] != null) {
        await _tokenStorage.saveAuthToken(data['access_token']);
        
        if (data['refresh_token'] != null) {
          await _tokenStorage.saveRefreshToken(data['refresh_token']);
        }
        
        if (data['user'] != null) {
          final user = data['user'] as Map<String, dynamic>;
          await _saveUserData(user, user['email'] ?? '');
        }
        
        await _tokenStorage.clearTempToken();
        await _tokenStorage.saveTwoFactorVerified(true);
      }
      
      return data;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // VERIFICAR CÓDIGO DE RESPALDO 2FA
  // ============================================
  Future<Map<String, dynamic>> verifyBackupCode(String code, String tempToken) async {
    try {
      final dio = await _apiClient.dio;
      final response = await dio.post(
        Endpoints.twoFactorVerifyBackup,
        data: {
          'code': code,
          'temp_token': tempToken,
        },
      );

      final data = response.data as Map<String, dynamic>;
      
      if (data['access_token'] != null) {
        await _tokenStorage.saveAuthToken(data['access_token']);
        
        if (data['user'] != null) {
          final user = data['user'] as Map<String, dynamic>;
          await _saveUserData(user, user['email'] ?? '');
        }
        
        await _tokenStorage.clearTempToken();
        await _tokenStorage.saveTwoFactorVerified(true);
      }
      
      return data;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // LOGIN CON OTP
  // ============================================
  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final dio = await _apiClient.dio;
      final response = await dio.post(
        Endpoints.sendOtp,
        data: {'email': email},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String code) async {
    try {
      final dio = await _apiClient.dio;
      final response = await dio.post(
        Endpoints.verifyOtp,
        data: {'email': email, 'code': code},
      );
      
      final data = response.data as Map<String, dynamic>;
      
      if (data['access_token'] != null) {
        await _tokenStorage.saveAuthToken(data['access_token']);
        
        if (data['user'] != null) {
          final user = data['user'] as Map<String, dynamic>;
          await _saveUserData(user, email);
        }
      }
      
      return data;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // OBTENER PERFIL
  // ============================================
  Future<Map<String, dynamic>> getProfile() async {
    return await getCurrentUser();
  }

  // ============================================
  // ACTUALIZAR PERFIL
  // ============================================
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? username,
    String? bio,
  }) async {
    if (fullName != null && fullName.isNotEmpty) {
      await _tokenStorage.saveUserName(fullName);
    }
    
    return {
      'success': true,
      'message': 'Perfil actualizado localmente',
    };
  }

  // ============================================
  // SUBIR AVATAR - CON URL DIRECTA
  // ============================================
  Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    try {
      final dio = await _apiClient.dio;
      
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });
      
      final String url = '${Endpoints.baseUrl}/upload/avatar';
      
      final response = await dio.post(
        url,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      
      final data = response.data as Map<String, dynamic>;
      
      if (data['avatar_url'] != null && data['avatar_url'].toString().isNotEmpty) {
        await _tokenStorage.saveUserAvatar(data['avatar_url']);
      }
      
      return data;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // SUBIR BANNER - CON URL DIRECTA
  // ============================================
  Future<Map<String, dynamic>> uploadBanner(File imageFile) async {
    try {
      final dio = await _apiClient.dio;
      
      final fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });
      
      final String url = '${Endpoints.baseUrl}/upload/banner';
      
      final response = await dio.post(
        url,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      
      final data = response.data as Map<String, dynamic>;
      
      if (data['banner_url'] != null && data['banner_url'].toString().isNotEmpty) {
        await _tokenStorage.saveUserBanner(data['banner_url']);
      }
      
      return data;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // ELIMINAR AVATAR - CON URL DIRECTA
  // ============================================
  Future<Map<String, dynamic>> deleteAvatar() async {
    try {
      final dio = await _apiClient.dio;
      final String url = '${Endpoints.baseUrl}/upload/avatar';
      final response = await dio.delete(url);
      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        await _tokenStorage.saveUserAvatar('');
      }
      
      return data;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // ELIMINAR BANNER - CON URL DIRECTA
  // ============================================
  Future<Map<String, dynamic>> deleteBanner() async {
    try {
      final dio = await _apiClient.dio;
      final String url = '${Endpoints.baseUrl}/upload/banner';
      final response = await dio.delete(url);
      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        await _tokenStorage.saveUserBanner('');
      }
      
      return data;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // CAMBIAR CONTRASEÑA
  // ============================================
  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final dio = await _apiClient.dio;
      final response = await dio.post(
        Endpoints.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // RECUPERACIÓN DE CONTRASEÑA CON OTP
  // ============================================
  Future<Map<String, dynamic>> forgotPasswordSendOtp(String email) async {
    try {
      final dio = await _apiClient.dio;
      final response = await dio.post(
        Endpoints.forgotPasswordSendOtp,
        data: {'email': email},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> forgotPasswordVerifyOtp(String email, String code) async {
    try {
      final dio = await _apiClient.dio;
      final response = await dio.post(
        Endpoints.forgotPasswordVerifyOtp,
        data: {'email': email, 'code': code},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> forgotPasswordReset(String email, String code, String newPassword) async {
    try {
      final dio = await _apiClient.dio;
      final response = await dio.post(
        Endpoints.forgotPasswordReset,
        data: {
          'email': email,
          'code': code,
          'new_password': newPassword,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // CIERRE DE SESIÓN
  // ============================================
  Future<void> logout() async {
    await _tokenStorage.clearSession();
  }

  // ============================================
  // VERIFICAR SESIÓN
  // ============================================
  Future<bool> isAuthenticated() async {
    return await _tokenStorage.hasToken();
  }

  // ============================================
  // OBTENER USUARIO ACTUAL - ✅ CORREGIDO CON ROL
  // ============================================
  Future<Map<String, dynamic>> getCurrentUser() async {
    final userId = await _tokenStorage.getUserId();
    final email = await _tokenStorage.getUserEmail();
    final fullName = await _tokenStorage.getUserName();
    final avatar = await _tokenStorage.getUserAvatar();
    final banner = await _tokenStorage.getUserBanner();
    final role = await _tokenStorage.getUserRole(); // ✅ NUEVO: Obtener rol
    
    return {
      'id': userId,
      'email': email,
      'full_name': fullName,
      'username': email?.split('@')[0],
      'avatar': avatar,
      'banner': banner,
      'role': role, // ✅ NUEVO: Incluir rol en la respuesta
    };
  }

  // ============================================
  // REFRESCAR TOKEN
  // ============================================
  Future<String?> refreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return null;
    
    try {
      final dio = await _apiClient.dio;
      final response = await dio.post(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      
      final data = response.data as Map<String, dynamic>;
      if (data['access_token'] != null) {
        await _tokenStorage.saveAuthToken(data['access_token']);
        return data['access_token'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // BIOMETRÍA
  // ============================================
  Future<void> saveBiometricEnabled(bool enabled) async {
    await _tokenStorage.saveBiometricEnabled(enabled);
  }

  Future<bool> isBiometricEnabled() async {
    return await _tokenStorage.isBiometricEnabled();
  }

  Future<void> saveRememberMe(bool value) async {
    await _tokenStorage.saveRememberMe(value);
  }

  Future<bool> getRememberMe() async {
    return await _tokenStorage.getRememberMe();
  }

  // ============================================
  // MÉTODOS PRIVADOS - ✅ CORREGIDO CON ROL
  // ============================================
  
  Future<void> _saveUserData(Map<String, dynamic> user, String fallbackEmail) async {
    final id = user['id']?.toString();
    final email = user['email'] ?? fallbackEmail;
    final fullName = user['full_name'] ?? user['name'] ?? '';
    final avatar = user['avatar'];
    final banner = user['banner'];
    final role = user['role'] ?? 'user'; // ✅ NUEVO: Obtener rol del backend
    
    if (id != null && id.isNotEmpty) {
      await _tokenStorage.saveUserId(id);
    }
    if (email.isNotEmpty) {
      await _tokenStorage.saveUserEmail(email);
    }
    if (fullName.isNotEmpty) {
      await _tokenStorage.saveUserName(fullName);
    }
    if (avatar != null && avatar.toString().isNotEmpty) {
      await _tokenStorage.saveUserAvatar(avatar.toString());
    }
    if (banner != null && banner.toString().isNotEmpty) {
      await _tokenStorage.saveUserBanner(banner.toString());
    }
    // ✅ NUEVO: Guardar rol
    await _tokenStorage.saveUserRole(role);
  }
}