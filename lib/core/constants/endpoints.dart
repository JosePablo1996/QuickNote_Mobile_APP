// lib/core/constants/endpoints.dart
// URLs de la API - QuickNote Backend en Render

class Endpoints {
  // ============================================
  // URL BASE
  // ============================================
  static const String baseUrl = 'https://quicknote-api-app-react.onrender.com/api/v1';
  
  // Para desarrollo local (descomentar si es necesario)
  // static const String baseUrl = 'http://localhost:8000/api/v1';
  
  // ============================================
  // AUTENTICACIÓN
  // ============================================
  static const String login = '/auth/login';
  static const String changePassword = '/auth/change-password';
  static const String forgotPasswordSendOtp = '/auth/forgot-password/send-otp';
  static const String forgotPasswordVerifyOtp = '/auth/forgot-password/verify-otp';
  static const String forgotPasswordReset = '/auth/forgot-password/reset';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  
  // ============================================
  // 2FA (Autenticación de Dos Factores)
  // ============================================
  static const String twoFactorEnable = '/auth/2fa/enable';
  static const String twoFactorVerifyEnable = '/auth/2fa/verify-enable';
  static const String twoFactorVerifyLogin = '/auth/2fa/verify-login';
  static const String twoFactorStatus = '/auth/2fa/status';
  static const String twoFactorDisable = '/auth/2fa/disable';
  static const String twoFactorVerifyBackup = '/auth/2fa/verify-backup';
  
  // ============================================
  // NOTAS (CRUD)
  // ============================================
  static const String notes = '/notes';
  static String noteById(String id) => '/notes/$id';
  static const String notesSync = '/notes/sync';
  
  // ============================================
  // BACKUPS EN LA NUBE
  // ============================================
  static const String backupCloud = '/backup/cloud';
  static String backupCloudById(String id) => '/backup/cloud/$id';
  static const String backupCloudSync = '/backup/cloud/sync';
  static const String backupCloudLimitInfo = '/backup/cloud/limit/info';
  
  // ============================================
  // PASSKEYS (WebAuthn) - Para compatibilidad
  // ============================================
  static const String passkeyRegisterStart = '/passkeys/register/start';
  static const String passkeyRegisterComplete = '/passkeys/register/complete';
  static const String passkeyLoginStart = '/passkeys/login/start';
  static const String passkeyLoginComplete = '/passkeys/login/complete';
  static String passkeyList(String userId) => '/passkeys/list/$userId';
  static String passkeyDelete(String credentialId, String userId) => 
      '/passkeys/$credentialId?user_id=$userId';
  
  // ============================================
  // HEALTH CHECK
  // ============================================
  static const String health = '/health';
}

// Headers comunes
class ApiHeaders {
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}

// Parámetros de consulta comunes
class ApiQueryParams {
  static Map<String, dynamic> pagination(int page, int limit) => {
    'page': page,
    'limit': limit,
  };
  
  static Map<String, dynamic> search(String query) => {
    'search': query,
  };
  
  static Map<String, dynamic> filters({
    bool? deleted,
    bool? archived,
    bool? favorite,
    String? tag,
  }) => {
    if (deleted != null) 'deleted': deleted,
    if (archived != null) 'archived': archived,
    if (favorite != null) 'favorite': favorite,
    if (tag != null) 'tag': tag,
  };
}