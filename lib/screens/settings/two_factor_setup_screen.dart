// lib/screens/settings/two_factor_setup_screen.dart
// Pantalla de configuración 2FA - Conectada al backend real
// CORREGIDO: Manejo de error "2FA ya esta activado"

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:quicknote/widgets/toast_message.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quicknote/core/services/two_factor_service.dart';

class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen> {
  int _currentStep = 0; // 0: loading, 1: qr, 2: verify, 3: complete
  String _secret = '';
  String _qrCode = '';
  String _manualKey = '';
  String _verificationCode = '';
  List<String> _backupCodes = [];
  bool _isLoading = false;
  bool _isVerifying = false;
  String? _error;
  bool _isCopied = false;
  bool _isAlreadyEnabled = false;
  
  final TwoFactorService _twoFactorService = TwoFactorService();

  @override
  void initState() {
    super.initState();
    _startSetup();
  }

  // ============================================
  // INICIAR CONFIGURACIÓN 2FA (VERIFICAR ESTADO PRIMERO)
  // ============================================
  Future<void> _startSetup() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ✅ PRIMERO VERIFICAR SI 2FA YA ESTÁ ACTIVADO
      final status = await _twoFactorService.getTwoFactorStatus();
      
      if (status['enabled'] == true) {
        // ✅ Si ya está activado, mostrar mensaje y salir
        setState(() {
          _isAlreadyEnabled = true;
          _isLoading = false;
        });
        
        if (mounted) {
          ToastMessage.warning(
            context, 
            'La autenticación en dos pasos ya está activada en tu cuenta.'
          );
        }
        return;
      }
      
      // ✅ Si no está activado, proceder con la configuración
      final response = await _twoFactorService.enableTwoFactor();
      
      if (response['secret'] != null && mounted) {
        setState(() {
          _secret = response['secret'];
          _qrCode = response['qr_code'] ?? '';
          _manualKey = response['manual_key'] ?? _secret;
          _isLoading = false;
          _currentStep = 1;
        });
      } else {
        throw Exception('No se pudo generar el código QR');
      }
    } catch (e) {
      final errorMsg = e.toString();
      
      // ✅ Manejar específicamente el error "2FA ya esta activado"
      if (errorMsg.contains('2FA ya esta activado') || errorMsg.contains('already enabled')) {
        setState(() {
          _isAlreadyEnabled = true;
          _isLoading = false;
        });
        if (mounted) {
          ToastMessage.warning(
            context, 
            'La autenticación en dos pasos ya está activada en tu cuenta.'
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _error = errorMsg;
            _isLoading = false;
          });
          ToastMessage.error(context, 'Error al iniciar 2FA: ${e.toString()}');
        }
      }
    }
  }

  // ============================================
  // VERIFICAR Y ACTIVAR 2FA
  // ============================================
  Future<void> _verifyAndEnable() async {
    if (_verificationCode.length != 6) {
      setState(() => _error = 'Ingresa el código de 6 dígitos');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final response = await _twoFactorService.verifyAndEnableTwoFactor(
        code: _verificationCode,
        secret: _secret,
      );
      
      if (response['success'] == true && mounted) {
        final backupCodes = response['backup_codes'] as List<String>?;
        
        setState(() {
          _backupCodes = backupCodes ?? [];
          _isVerifying = false;
          _currentStep = 3;
        });
        
        ToastMessage.success(context, '2FA activado correctamente');
      } else {
        throw Exception(response['message'] ?? 'Código inválido');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isVerifying = false;
        });
        ToastMessage.error(context, 'Error al verificar: ${e.toString()}');
      }
    }
  }

  // ============================================
  // REINTENTAR GENERAR QR
  // ============================================
  Future<void> _retrySetup() async {
    setState(() {
      _currentStep = 0;
      _error = null;
      _verificationCode = '';
      _isAlreadyEnabled = false;
    });
    await _startSetup();
  }

  // ============================================
  // COPIAR CLAVE MANUAL
  // ============================================
  void _copyManualKey() {
    if (_manualKey.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _manualKey));
      setState(() => _isCopied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isCopied = false);
      });
      ToastMessage.success(context, 'Clave manual copiada');
    }
  }

  // ============================================
  // COPIAR CÓDIGOS DE RESPALDO
  // ============================================
  void _copyBackupCodes() {
    if (_backupCodes.isNotEmpty) {
      final codesText = _backupCodes.join('\n');
      Clipboard.setData(ClipboardData(text: codesText));
      ToastMessage.success(context, 'Códigos de respaldo copiados');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Autenticación en Dos Pasos'),
        centerTitle: true,
        backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: _buildBody(isDarkMode, user),
    );
  }

  Widget _buildBody(bool isDarkMode, dynamic user) {
    // ✅ Si ya está activado, mostrar pantalla informativa
    if (_isAlreadyEnabled) {
      return _buildAlreadyEnabledScreen(isDarkMode);
    }
    
    if (_isLoading && _currentStep == 0) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_currentStep == 1) {
      return _buildQrStep(isDarkMode, user);
    } else if (_currentStep == 2) {
      return _buildVerifyStep(isDarkMode);
    } else if (_currentStep == 3) {
      return _buildCompleteStep(isDarkMode);
    }
    
    return _buildQrStep(isDarkMode, user);
  }

  // ============================================
  // PANTALLA: 2FA YA ACTIVADO
  // ============================================
  Widget _buildAlreadyEnabledScreen(bool isDarkMode) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.shield,
                  size: 50,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '2FA ya está activado',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'La autenticación en dos pasos ya está activada en tu cuenta.\n\n'
                'Si deseas modificar la configuración, ve a Configuración > Seguridad.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'CERRAR',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // PASO 1: MOSTRAR QR
  // ============================================
  Widget _buildQrStep(bool isDarkMode, dynamic user) {
    final displayName = user?.name ?? user?.email?.split('@').first ?? 'Usuario';
    final email = user?.email ?? '';
    final avatarUrl = user?.avatar;
    final hasValidAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final initials = _getInitials(displayName);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Tarjeta de usuario
            Center(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                      isDarkMode ? const Color(0xFF374151) : Colors.white,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: hasValidAvatar
                              ? Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildAvatarFallback(initials),
                                )
                              : _buildAvatarFallback(initials),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Título
            Text(
              'Configurar autenticación en dos pasos',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Protege tu cuenta con una capa adicional de seguridad',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Código QR
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _qrCode.isNotEmpty
                  ? QrImageView(
                      data: _qrCode,
                      version: QrVersions.auto,
                      size: 200,
                      gapless: false,
                    )
                  : Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
            ),
            
            const SizedBox(height: 24),
            
            // Clave manual
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.key, size: 18, color: const Color(0xFF8B5CF6)),
                      const SizedBox(width: 8),
                      Text(
                        'Clave manual',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                            ),
                          ),
                          child: SelectableText(
                            _manualKey,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              letterSpacing: 1,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _copyManualKey,
                        icon: Icon(_isCopied ? Icons.check : Icons.copy, size: 20),
                        color: _isCopied ? Colors.green : Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instrucciones
            _buildInstructionCard(isDarkMode),
            
            const SizedBox(height: 24),
            
            // Botón continuar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _currentStep = 2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'YA ESCANEÉ EL CÓDIGO',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botón cancelar
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(
                  color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // PASO 2: VERIFICAR CÓDIGO
  // ============================================
  Widget _buildVerifyStep(bool isDarkMode) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Icono
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.security, size: 40, color: Colors.white),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Verifica el código',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa el código de 6 dígitos de Google Authenticator',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Campo de código
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) => _verificationCode = value,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 28,
                        letterSpacing: 8,
                        color: isDarkMode ? Colors.white54 : Colors.grey.shade400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _retrySetup,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
                            ),
                          ),
                          child: const Text('Volver'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyAndEnable,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('VERIFICAR Y ACTIVAR'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Ayuda
            _buildHelpSection(isDarkMode),
          ],
        ),
      ),
    );
  }

  // ============================================
  // PASO 3: COMPLETADO
  // ============================================
  Widget _buildCompleteStep(bool isDarkMode) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // Icono de éxito
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check, size: 50, color: Colors.white),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            Text(
              '¡2FA Activado con Éxito!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Tu cuenta ahora está protegida con autenticación en dos pasos',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Códigos de respaldo
            if (_backupCodes.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.amber.shade700, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Guarda estos códigos de respaldo en un lugar seguro',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cada código funciona una sola vez. Úsalos si pierdes acceso a Google Authenticator.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.amber.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: _backupCodes.map((code) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              code,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _copyBackupCodes,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('COPIAR TODOS LOS CÓDIGOS'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Botón finalizar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'ENTENDIDO, CERRAR',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // WIDGETS AUXILIARES
  // ============================================
  
  Widget _buildInstructionCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Text(
                'Instrucciones',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep('1', 'Abre Google Authenticator', isDarkMode),
          _buildInstructionStep('2', 'Toca el botón + y selecciona "Escanear código QR"', isDarkMode),
          _buildInstructionStep('3', 'Escanea el código QR de esta pantalla', isDarkMode),
          _buildInstructionStep('4', 'Ingresa el código de 6 dígitos en el siguiente paso', isDarkMode),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, size: 18, color: const Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Text(
                '¿Problemas para escanear?',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '1. Asegúrate de que la hora de tu dispositivo esté sincronizada\n'
            '2. También puedes agregar la cuenta manualmente usando la clave de abajo\n'
            '3. Si el código no funciona, espera unos segundos y vuelve a intentar',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String initials) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}