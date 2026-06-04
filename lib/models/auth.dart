// lib/models/auth.dart
// Modelos para autenticación

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class LoginResponse {
  final bool success;
  final bool requires2FA;
  final String? tempToken;
  final String? message;
  final String? accessToken;
  final String? refreshToken;
  final UserData? user;

  LoginResponse({
    required this.success,
    this.requires2FA = false,
    this.tempToken,
    this.message,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      requires2FA: json['requires_2fa'] ?? json['requires2FA'] ?? false,
      tempToken: json['temp_token'] ?? json['tempToken'],
      message: json['message'],
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
    );
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String name;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'full_name': name,
  };
}

class RegisterResponse {
  final bool success;
  final String? message;
  final UserData? user;

  RegisterResponse({
    required this.success,
    this.message,
    this.user,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['success'] ?? false,
      message: json['message'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
    );
  }
}

class UserData {
  final String id;
  final String email;
  final String? username;
  final String? fullName;
  final String? avatar;

  UserData({
    required this.id,
    required this.email,
    this.username,
    this.fullName,
    this.avatar,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      username: json['username'],
      fullName: json['full_name'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'full_name': fullName,
    'avatar': avatar,
  };
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'current_password': currentPassword,
    'new_password': newPassword,
  };
}

class ChangePasswordResponse {
  final bool success;
  final String message;
  final bool requiresRelogin;

  ChangePasswordResponse({
    required this.success,
    required this.message,
    required this.requiresRelogin,
  });

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      requiresRelogin: json['requires_relogin'] ?? false,
    );
  }
}

class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class ForgotPasswordResponse {
  final bool success;
  final String message;
  final bool emailSent;
  final int? expiresIn;

  ForgotPasswordResponse({
    required this.success,
    required this.message,
    required this.emailSent,
    this.expiresIn,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      emailSent: json['email_sent'] ?? false,
      expiresIn: json['expires_in'],
    );
  }
}

class VerifyOtpRequest {
  final String email;
  final String code;

  VerifyOtpRequest({
    required this.email,
    required this.code,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'code': code,
  };
}

class VerifyOtpResponse {
  final bool success;
  final String? tempToken;
  final String? message;

  VerifyOtpResponse({
    required this.success,
    this.tempToken,
    this.message,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      success: json['success'] ?? false,
      tempToken: json['temp_token'],
      message: json['message'],
    );
  }
}

class ResetPasswordRequest {
  final String email;
  final String code;
  final String newPassword;

  ResetPasswordRequest({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'code': code,
    'new_password': newPassword,
  };
}

class ApiError {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiError({
    required this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['detail'] ?? json['message'] ?? 'Error desconocido',
      statusCode: json['status_code'],
      errors: json['errors'],
    );
  }
}