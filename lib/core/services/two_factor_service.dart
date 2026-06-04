// lib/core/services/two_factor_service.dart
// Servicio para manejar autenticación de dos factores (2FA)

import 'package:dio/dio.dart';
import 'package:quicknote/core/api/api_client.dart';
import 'package:quicknote/core/constants/endpoints.dart';
import 'package:quicknote/core/utils/secure_storage.dart';

class TwoFactorService {
  static final TwoFactorService _instance = TwoFactorService._internal();
  factory TwoFactorService() => _instance;
  TwoFactorService._internal();

  final ApiClient _apiClient = ApiClient();
  final SecureStorage _secureStorage = SecureStorage();

  // ============================================
  // OBTENER ESTADO DE 2FA
  // ============================================
  Future<Map<String, dynamic>> getTwoFactorStatus() async {
    try {
      final token = await _secureStorage.getAuthToken();
      if (token == null || token.isEmpty) {
        return {'enabled': false, 'method': null};
      }

      final dio = await _apiClient.dio;
      final response = await dio.get(
        Endpoints.twoFactorStatus,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      }
      return {'enabled': false, 'method': null};
    } catch (e) {
      return {'enabled': false, 'method': null};
    }
  }

  // ============================================
  // INICIAR ACTIVACIÓN DE 2FA (GENERAR QR)
  // ============================================
  Future<Map<String, dynamic>> enableTwoFactor() async {
    try {
      final token = await _secureStorage.getAuthToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final dio = await _apiClient.dio;
      final response = await dio.post(
        Endpoints.twoFactorEnable,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      }
      throw Exception('Error al iniciar 2FA: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // VERIFICAR Y ACTIVAR 2FA
  // ============================================
  Future<Map<String, dynamic>> verifyAndEnableTwoFactor({
    required String code,
    required String secret,
  }) async {
    try {
      final token = await _secureStorage.getAuthToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final dio = await _apiClient.dio;
      final response = await dio.post(
        Endpoints.twoFactorVerifyEnable,
        data: {
          'code': code,
          'secret': secret,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await _secureStorage.saveTwoFactorEnabled(true);
        return data;
      }
      throw Exception('Error al verificar 2FA: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // VERIFICAR 2FA DURANTE LOGIN
  // ============================================
  Future<Map<String, dynamic>> verifyTwoFactorLogin(
    String code,
    String tempToken,
  ) async {
    try {
      final dio = await _apiClient.dio;
      final response = await dio.post(
        Endpoints.twoFactorVerifyLogin,
        data: {
          'code': code,
          'temp_token': tempToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      }
      throw Exception('Error al verificar 2FA: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // VERIFICAR CÓDIGO DE RESPALDO
  // ============================================
  Future<Map<String, dynamic>> verifyBackupCode(
    String code,
    String tempToken,
  ) async {
    try {
      final dio = await _apiClient.dio;
      final response = await dio.post(
        Endpoints.twoFactorVerifyBackup,
        data: {
          'code': code,
          'temp_token': tempToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      }
      throw Exception('Error al verificar código de respaldo');
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // DESACTIVAR 2FA
  // ============================================
  Future<bool> disableTwoFactor() async {
    try {
      final token = await _secureStorage.getAuthToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final dio = await _apiClient.dio;
      final response = await dio.post(
        Endpoints.twoFactorDisable,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        await _secureStorage.saveTwoFactorEnabled(false);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // GUARDAR ESTADO DE 2FA (NUEVO)
  // ============================================
  Future<void> saveTwoFactorEnabled(bool enabled) async {
    await _secureStorage.saveTwoFactorEnabled(enabled);
  }

  // ============================================
  // MÉTODOS PARA BIOMETRÍA (local_auth)
  // ============================================
  Future<bool> isBiometricEnabled() async {
    return await _secureStorage.isBiometricEnabled();
  }

  Future<void> saveBiometricEnabled(bool enabled) async {
    await _secureStorage.saveBiometricEnabled(enabled);
  }
}