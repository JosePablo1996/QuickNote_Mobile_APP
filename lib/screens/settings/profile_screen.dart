// lib/screens/settings/profile_screen.dart
// Pantalla de perfil de usuario - VERSIÓN CON ROL DE ADMINISTRADOR
// ✅ NAVEGACIÓN CORREGIDA: Siempre usa go('/notes') para regresar a Home
// ✅ Gesto hacia atrás funciona correctamente (vuelve a HomeScreen)
// ✅ Banner se muestra correctamente desde el backend
// ✅ Mejor manejo de carga de imágenes
// ✅ Refresco automático del perfil
// ✅ Soporte completo para banner de usuario
// ✅ BANNER RESPONSIVO: Se adapta a pantallas más grandes (tablets/desktop)
// ✅ ROL DE ADMINISTRADOR: Visualización especial con badge y estilo dorado

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quicknote/models/user.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:quicknote/providers/notes_provider.dart';
import 'package:quicknote/widgets/loading_indicator.dart';
import 'package:quicknote/widgets/toast_message.dart';
import 'package:cached_network_image/cached_network_image.dart';

class _ProfileScreenLogger {
  static void info(String message) => debugPrint('ℹ️ [Profile] $message');
  static void success(String message) => debugPrint('✅ [Profile] $message');
  static void error(String message) => debugPrint('❌ [Profile] $message');
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  
  // Campos editables
  String _editedName = '';
  
  // Imágenes
  File? _avatarFile;
  File? _bannerFile;
  String? _avatarPreview;
  String? _bannerPreview;
  bool _isUploadingBanner = false;
  bool _avatarError = false;
  bool _bannerError = false;
  bool _isNavigating = false;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Refrescar perfil al cargar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserProfile();
    });
  }

  void _loadUserData() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _editedName = user.name ?? '';
      _avatarPreview = user.avatar;
      _bannerPreview = user.banner;
      _ProfileScreenLogger.info('Perfil cargado - Nombre: ${user.name}, Avatar: ${user.avatar != null ? "✅" : "❌"}, Banner: ${user.banner != null ? "✅" : "❌"}, Rol: ${user.role}');
    }
  }

  // ============================================
  // ✅ NAVEGACIÓN CORREGIDA - Siempre usa go('/notes')
  // ============================================
  
  void _goBack() {
    if (_isNavigating) return;
    _isNavigating = true;
    
    _ProfileScreenLogger.info('🔙 Navegando de vuelta a HomeScreen');
    
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      try {
        context.go('/notes');
        _ProfileScreenLogger.success('✅ Navegación exitosa a /notes');
      } catch (e) {
        _ProfileScreenLogger.error('Error en navegación: $e');
        try {
          context.go('/notes');
        } catch (e2) {
          _ProfileScreenLogger.error('Error en fallback: $e2');
        }
      } finally {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _isNavigating = false;
        });
      }
    });
  }

  Future<void> _refreshUserProfile() async {
    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.refreshProfile();
    final updatedUser = ref.read(currentUserProvider);
    if (updatedUser != null && mounted) {
      setState(() {
        _editedName = updatedUser.name ?? '';
        _avatarPreview = updatedUser.avatar;
        _bannerPreview = updatedUser.banner;
        _avatarError = false;
        _bannerError = false;
      });
      _ProfileScreenLogger.success('Perfil refrescado - Avatar: ${updatedUser.avatar != null ? "✅" : "❌"}, Banner: ${updatedUser.banner != null ? "✅" : "❌"}, Rol: ${updatedUser.role}');
    }
  }

  Future<void> _pickImage(ImageSource source, bool isAvatar) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: isAvatar ? 500 : 2000,
        maxHeight: isAvatar ? 500 : 600,
        imageQuality: 85,
      );
      
      if (pickedFile != null && mounted) {
        if (isAvatar) {
          setState(() {
            _avatarFile = File(pickedFile.path);
            _avatarPreview = null;
          });
          await _uploadAvatar();
        } else {
          setState(() {
            _bannerFile = File(pickedFile.path);
            _bannerPreview = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.error(context, 'Error al seleccionar imagen');
      }
    }
  }

  Future<void> _uploadAvatar() async {
    if (_avatarFile == null) return;
    
    if (!mounted) return;
    
    try {
      final authNotifier = ref.read(authProvider.notifier);
      final newAvatarUrl = await authNotifier.uploadAvatar(_avatarFile!, context);
      
      if (mounted && newAvatarUrl != null) {
        setState(() {
          _avatarPreview = newAvatarUrl;
          _avatarFile = null;
        });
        await _refreshUserProfile();
        ref.invalidate(currentUserProvider);
        ToastMessage.success(context, 'Avatar actualizado correctamente');
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.error(context, 'Error al subir avatar: ${e.toString()}');
        setState(() {
          _avatarFile = null;
        });
      }
    }
  }

  void _showImagePickerOptions(bool isAvatar) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Seleccionar imagen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isAvatar);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isAvatar);
              },
            ),
            if ((isAvatar && (_avatarFile != null || _avatarPreview != null)) ||
                (!isAvatar && (_bannerFile != null || _bannerPreview != null)))
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar imagen', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  if (isAvatar) {
                    setState(() {
                      _avatarFile = null;
                      _avatarPreview = null;
                    });
                  } else {
                    setState(() {
                      _bannerFile = null;
                      _bannerPreview = null;
                    });
                  }
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadBanner() async {
    if (_bannerFile == null) return;
    
    if (!mounted) return;
    setState(() => _isUploadingBanner = true);
    
    try {
      final authNotifier = ref.read(authProvider.notifier);
      final newBannerUrl = await authNotifier.uploadBanner(_bannerFile!, context);
      
      if (mounted && newBannerUrl != null) {
        setState(() {
          _bannerPreview = newBannerUrl;
          _bannerFile = null;
        });
        await _refreshUserProfile();
        ref.invalidate(currentUserProvider);
        ToastMessage.success(context, 'Banner actualizado correctamente');
        _ProfileScreenLogger.success('Banner actualizado: $newBannerUrl');
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.error(context, 'Error al subir banner: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingBanner = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_isEditing) return;
    
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final authNotifier = ref.read(authProvider.notifier);
      
      final currentUser = ref.read(currentUserProvider);
      final hasNameChanged = _editedName != (currentUser?.name ?? '');
      
      if (hasNameChanged) {
        final success = await authNotifier.updateProfile(
          fullName: _editedName,
          context: context,
        );
        
        if (!success && mounted) {
          ToastMessage.error(context, 'Error al actualizar el nombre');
        }
      }
      
      await _refreshUserProfile();
      
      if (mounted) {
        setState(() => _isEditing = false);
        ToastMessage.success(context, 'Perfil actualizado correctamente');
        ref.invalidate(currentUserProvider);
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.error(context, 'Error al actualizar perfil: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _cancelEdit() {
    _loadUserData();
    setState(() {
      _isEditing = false;
      _avatarFile = null;
      _bannerFile = null;
    });
  }

  String? _getValidImageUrl(String? url) {
    if (url == null) return null;
    if (url.contains('via.placeholder.com')) return null;
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;
    final isTablet = screenWidth >= 600 && screenWidth < 800;
    final user = ref.watch(currentUserProvider);
    final notesState = ref.watch(notesProvider);
    
    if (user == null) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }
    
    final validAvatarUrl = _getValidImageUrl(_avatarPreview ?? user.avatar);
    final validBannerUrl = _getValidImageUrl(_bannerPreview ?? user.banner);
    
    final initials = user.initials;
    final noteStats = _getNoteStats(notesState);
    final displayName = _editedName.isNotEmpty ? _editedName : user.displayName;
    final bool isAdmin = user.role == 'admin';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack();
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: _buildAppBar(isDarkMode),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildBanner(isDarkMode, validBannerUrl, isDesktop, isTablet),
              _buildAvatar(isDarkMode, initials, validAvatarUrl, isDesktop, isTablet, isAdmin),
              Padding(
                padding: EdgeInsets.all(isDesktop ? 32 : 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: EdgeInsets.all(isDesktop ? 32 : 20),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey.shade900.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNameSection(isDarkMode, user, displayName, isAdmin),
                          const SizedBox(height: 20),
                          _buildPersonalInfoGrid(isDarkMode, user, displayName, isDesktop, isAdmin),
                          const SizedBox(height: 24),
                          _buildStatsSection(isDarkMode, noteStats, isDesktop),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildFooter(isDarkMode),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    return AppBar(
      title: Text(
        'Mi Perfil',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _goBack,
      ),
      actions: [
        if (!_isEditing)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => setState(() => _isEditing = true),
            tooltip: 'Editar perfil',
          )
        else ...[
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelEdit,
            tooltip: 'Cancelar',
          ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveProfile,
            tooltip: 'Guardar',
          ),
        ],
      ],
    );
  }

  Widget _buildBanner(bool isDarkMode, String? bannerUrl, bool isDesktop, bool isTablet) {
    final hasImage = bannerUrl != null && bannerUrl.isNotEmpty && !_bannerError;
    final double bannerHeight = isDesktop ? 220.0 : (isTablet ? 190.0 : 160.0);
    
    return GestureDetector(
      onTap: _isEditing ? () => _showImagePickerOptions(false) : null,
      child: Container(
        height: bannerHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: !hasImage
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? const [Color(0xFF1E3A8A), Color(0xFF4C1D95)]
                      : const [Color(0xFF2563EB), Color(0xFF7C3AED)],
                )
              : null,
          image: hasImage
              ? DecorationImage(
                  image: CachedNetworkImageProvider(bannerUrl),
                  fit: BoxFit.cover,
                  onError: (error, stackTrace) {
                    _ProfileScreenLogger.error('Error cargando banner: $error');
                    setState(() => _bannerError = true);
                  },
                )
              : null,
        ),
        child: _buildBannerOverlay(isDarkMode),
      ),
    );
  }

  Widget _buildBannerOverlay(bool isDarkMode) {
    if (_isEditing && !_isUploadingBanner && _bannerFile == null) {
      return Container(
        height: double.infinity,
        width: double.infinity,
        color: Colors.black54,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, color: Colors.white, size: 32),
              SizedBox(height: 8),
              Text(
                'Cambiar banner',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_isUploadingBanner) {
      return Container(
        height: double.infinity,
        width: double.infinity,
        color: Colors.black54,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'Subiendo...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_bannerFile != null && !_isUploadingBanner) {
      return Container(
        height: double.infinity,
        width: double.infinity,
        color: Colors.black54,
        child: Stack(
          children: [
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Imagen seleccionada',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: _uploadBanner,
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildAvatar(bool isDarkMode, String initials, String? avatarUrl, bool isDesktop, bool isTablet, bool isAdmin) {
    final hasImage = avatarUrl != null && avatarUrl.isNotEmpty && !_avatarError;
    final double avatarSize = isDesktop ? 120.0 : (isTablet ? 100.0 : 85.0);
    final double avatarOffset = isDesktop ? -70.0 : (isTablet ? -60.0 : -50.0);
    
    return Transform.translate(
      offset: Offset(0, avatarOffset),
      child: GestureDetector(
        onTap: _isEditing ? () => _showImagePickerOptions(true) : null,
        child: Stack(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAdmin 
                      ? Colors.amber 
                      : (isDarkMode ? const Color(0xFF1F2937) : Colors.white), 
                  width: isAdmin ? 3 : 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isAdmin 
                        ? Colors.amber.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: hasImage
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(avatarUrl),
                        fit: BoxFit.cover,
                        onError: (error, stackTrace) {
                          _ProfileScreenLogger.error('Error cargando avatar: $error');
                          setState(() => _avatarError = true);
                        },
                      )
                    : null,
              ),
              child: !hasImage
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDarkMode
                              ? [Colors.blue.shade800, Colors.purple.shade800]
                              : [Colors.blue.shade400, Colors.purple.shade400],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.poppins(
                            fontSize: isDesktop ? 40.0 : (isTablet ? 32.0 : 28.0),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            // Badge de administrador
            if (isAdmin)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.star, size: 16, color: Colors.white),
                ),
              ),
            if (_isEditing && _avatarFile == null && !isAdmin)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            if (_avatarFile != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameSection(bool isDarkMode, User user, String displayName, bool isAdmin) {
    return Center(
      child: Column(
        children: [
          if (_isEditing)
            TextField(
              controller: TextEditingController(text: _editedName),
              onChanged: (value) => _editedName = value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'Nombre completo',
                border: InputBorder.none,
              ),
            )
          else
            Text(
              displayName,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Cuenta verificada',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.green),
                    ),
                  ],
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.admin_panel_settings, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'Administrador',
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.amber),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoGrid(bool isDarkMode, User user, String displayName, bool isDesktop, bool isAdmin) {
    final joinDate = _formatDate(user.createdAt);
    
    String roleDisplayName;
    Color roleColor;
    IconData roleIcon;
    
    if (isAdmin) {
      roleDisplayName = 'Administrador';
      roleColor = Colors.amber;
      roleIcon = Icons.admin_panel_settings;
    } else {
      roleDisplayName = 'Usuario';
      roleColor = Colors.green;
      roleIcon = Icons.person;
    }
    
    final List<Map<String, dynamic>> infoItems = [
      {'icon': Icons.person, 'label': 'Nombre completo', 'value': displayName},
      {'icon': Icons.email, 'label': 'Correo electrónico', 'value': user.email},
      {'icon': Icons.calendar_today, 'label': 'Miembro desde', 'value': joinDate},
      {
        'icon': roleIcon, 
        'label': 'Rol', 
        'value': roleDisplayName, 
        'color': roleColor,
        'isAdmin': isAdmin
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: infoItems.map((item) {
        final color = item['color'] as Color? ?? (isDarkMode ? Colors.white70 : Colors.grey.shade700);
        final bool isAdminItem = item['isAdmin'] == true;
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: isAdminItem
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [Colors.amber.shade900.withValues(alpha: 0.3), Colors.orange.shade900.withValues(alpha: 0.2)]
                        : [Colors.amber.shade100.withValues(alpha: 0.5), Colors.orange.shade100.withValues(alpha: 0.3)],
                  )
                : null,
            color: !isAdminItem && isDarkMode 
                ? Colors.grey.shade800.withValues(alpha: 0.5) 
                : (!isAdminItem ? Colors.white.withValues(alpha: 0.5) : null),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAdminItem
                  ? Colors.amber
                  : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
              width: isAdminItem ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item['icon'] as IconData, 
                  size: 20, 
                  color: isAdminItem ? Colors.amber : const Color(0xFF8B5CF6)),
              const SizedBox(height: 8),
              Text(
                item['label'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (isAdminItem) ...[
                    Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      item['value'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsSection(bool isDarkMode, Map<String, dynamic> stats, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart, size: 18, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Text(
                'Estadísticas de actividad',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 4 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(isDarkMode, Icons.note, 'Notas totales', '${stats['total']}', Colors.blue),
              _buildStatCard(isDarkMode, Icons.star, 'Favoritas', '${stats['favorites']}', Colors.amber),
              _buildStatCard(isDarkMode, Icons.archive, 'Archivadas', '${stats['archived']}', Colors.teal),
              _buildStatCard(isDarkMode, Icons.tag, 'Etiquetas', '${stats['tags']}', Colors.purple),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notas este mes',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      Text(
                        '${stats['thisMonth']}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(bool isDarkMode, IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'QuickNote · Desarrollado con ❤️ por José Pablo Miranda Quintanilla',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Map<String, dynamic> _getNoteStats(NotesState notesState) {
    final activeNotes = notesState.activeNotes;
    final favorites = activeNotes.where((n) => n.isFavorite).length;
    final archived = notesState.archivedNotes.length;
    final tags = activeNotes.expand((n) => n.tags).toSet().length;
    final now = DateTime.now();
    final thisMonth = activeNotes.where((n) =>
      n.createdAt.year == now.year && n.createdAt.month == now.month
    ).length;
    
    return {
      'total': activeNotes.length,
      'favorites': favorites,
      'archived': archived,
      'tags': tags,
      'thisMonth': thisMonth,
    };
  }
}