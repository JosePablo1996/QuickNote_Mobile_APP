// lib/core/constants/endpoints.dart
// URLs de la API - QuickNote Backend en Render
// ✅ CORREGIDO: URLs específicas con slash final para evitar 307
// ✅ ACTUALIZADO: Endpoints de upload de imágenes (avatar y banner)

class Endpoints {
  // Base URL de la API desplegada en Render
  static const String baseUrl = 'https://quicknote-api-app-react.onrender.com/api/v1';
  
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
  // UPLOAD DE IMÁGENES (NUEVOS ENDPOINTS)
  // ============================================
  /// Subir avatar del usuario (multipart/form-data)
  static const String uploadAvatar = '/upload/avatar';
  
  /// Subir banner del usuario (multipart/form-data)
  static const String uploadBanner = '/upload/banner';
  
  /// Eliminar avatar del usuario
  static const String deleteAvatar = '/upload/avatar';
  
  /// Eliminar banner del usuario
  static const String deleteBanner = '/upload/banner';
  
  // ============================================
  // PERFIL DE USUARIO
  // ============================================
  static const String profile = '/users/profile';
  static const String updateProfile = '/users/profile';
  
  // ============================================
  // 2FA
  // ============================================
  static const String twoFactorEnable = '/auth/2fa/enable';
  static const String twoFactorVerifyEnable = '/auth/2fa/verify-enable';
  static const String twoFactorVerifyLogin = '/auth/2fa/verify-login';
  static const String twoFactorStatus = '/auth/2fa/status';
  static const String twoFactorDisable = '/auth/2fa/disable';
  static const String twoFactorVerifyBackup = '/auth/2fa/verify-backup';
  
  // ============================================
  // NOTAS (CRUD) - CON SLASH FINAL PARA EVITAR 307
  // ============================================
  /// GET y POST usan /notes/ (con slash final)
  static const String notes = '/notes/';
  
  /// Endpoint para nota específica (con slash final)
  static String noteById(String id) => '/notes/$id/';
  
  /// Restaurar nota desde papelera
  static String restoreNote(String id) => '/notes/$id/restore';
  
  /// Eliminar nota permanentemente
  static String permanentlyDeleteNote(String id) => '/notes/$id/permanent';
  
  /// Vaciar papelera completa
  static const String emptyTrash = '/notes/trash/empty';
  
  /// Sincronizar notas
  static const String notesSync = '/notes/sync';
  
  /// Eliminar múltiples notas (soft delete)
  static const String batchSoftDelete = '/notes/batch/soft-delete';
  
  /// Eliminar múltiples notas permanentemente
  static const String batchPermanentDelete = '/notes/batch/permanent-delete';
  
  // ============================================
  // BACKUPS EN LA NUBE
  // ============================================
  static const String backupCloud = '/backup/cloud/';
  static String backupCloudById(String id) => '/backup/cloud/$id/';
  static const String backupCloudSync = '/backup/cloud/sync';
  static const String backupCloudLimitInfo = '/backup/cloud/limit/info';
  
  // ============================================
  // PASSKEYS
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