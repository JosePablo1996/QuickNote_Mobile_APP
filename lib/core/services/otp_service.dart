// lib/core/services/otp_service.dart
// Servicio de OTP (One-Time Password)

import 'package:dio/dio.dart';
import 'package:quicknote/core/api/api_client.dart';
import 'package:quicknote/core/constants/endpoints.dart';

class OtpService {
  static final OtpService _instance = OtpService._internal();
  factory OtpService() => _instance;
  OtpService._internal();

  final ApiClient _apiClient = ApiClient();

  // ============================================
  // ENVIAR OTP DE RECUPERACIÓN
  // ============================================
  Future<Map<String, dynamic>> sendPasswordResetOtp(String email) async {
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

  // ============================================
  // VERIFICAR OTP DE RECUPERACIÓN
  // ============================================
  Future<Map<String, dynamic>> verifyPasswordResetOtp(String email, String code) async {
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

  // ============================================
  // RESETEAR CONTRASEÑA CON OTP
  // ============================================
  Future<Map<String, dynamic>> resetPasswordWithOtp(
    String email,
    String code,
    String newPassword,
  ) async {
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
  // ENVIAR OTP DE LOGIN
  // ============================================
  Future<Map<String, dynamic>> sendLoginOtp(String email) async {
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

  // ============================================
  // VERIFICAR OTP DE LOGIN
  // ============================================
  Future<Map<String, dynamic>> verifyLoginOtp(String email, String code) async {
    try {
      final dio = await _apiClient.dio;
      final response = await dio.post(
        Endpoints.verifyOtp,
        data: {'email': email, 'code': code},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // VALIDAR CÓDIGO OTP (6 DÍGITOS)
  // ============================================
  static bool isValidOtpCode(String code) {
    return code.length == 6 && RegExp(r'^\d+$').hasMatch(code);
  }
}