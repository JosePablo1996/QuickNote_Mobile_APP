// lib/widgets/user_profile_card.dart
// Widget reutilizable para mostrar la tarjeta de perfil de usuario
// Con colores adaptables para modo oscuro y claro
// ✅ NUEVO: Muestra el rol del usuario (Administrador/Usuario)
// ✅ NUEVO: Insignia especial para administrador

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/models/user.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:quicknote/screens/settings/profile_screen.dart';

class UserProfileCard extends ConsumerStatefulWidget {
  const UserProfileCard({super.key});

  @override
  ConsumerState<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends ConsumerState<UserProfileCard> {
  bool _avatarError = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return const SizedBox.shrink();
    }
    
    final fullName = user.name ?? user.email.split('@').first;
    final email = user.email;
    final avatarUrl = user.avatar;
    final initials = _getInitials(fullName);
    final hasValidAvatar = avatarUrl != null && avatarUrl.isNotEmpty && !_avatarError;
    final isAdmin = user.role == 'admin';

    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width - 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              gradient: isAdmin
                  ? (isDarkMode
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF78350F), // Ámbar oscuro
                            Color(0xFF991B1B), // Rojo oscuro
                            Color(0xFF7C2D12), // Naranja oscuro
                            Color(0xFF451A03), // Marrón oscuro
                          ],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFF59E0B), // Ámbar
                            Color(0xFFDC2626), // Rojo
                            Color(0xFFEA580C), // Naranja
                            Color(0xFFFCD34D), // Amarillo
                          ],
                        ))
                  : (isDarkMode
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1E1B4B), // Índigo oscuro
                            Color(0xFF4C1D95), // Púrpura oscuro
                            Color(0xFF831843), // Rosa oscuro
                            Color(0xFF064E3B), // Verde oscuro
                          ],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF4F46E5), // Índigo brillante
                            Color(0xFF8B5CF6), // Púrpura
                            Color(0xFFEC4899), // Rosa
                            Color(0xFF10B981), // Verde esmeralda
                          ],
                        )),
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Avatar
                GestureDetector(
                  onTap: () => _navigateToProfile(),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isAdmin ? Colors.amber : (isDarkMode ? Colors.white70 : Colors.white),
                        width: isAdmin ? 4 : 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isAdmin 
                              ? Colors.amber.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipOval(
                          child: hasValidAvatar
                              ? Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (context, error, stackTrace) {
                                    if (!_avatarError) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (mounted) setState(() => _avatarError = true);
                                      });
                                    }
                                    return _buildAvatarFallback(initials, isDarkMode);
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return _buildAvatarFallback(initials, isDarkMode, isLoading: true);
                                  },
                                )
                              : _buildAvatarFallback(initials, isDarkMode),
                        ),
                        // Insignia de administrador en el avatar
                        if (isAdmin)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.star,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Nombre con insignia de administrador
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fullName,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.star,
                        size: 20,
                        color: Colors.amber,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Email
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDarkMode 
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                // Badge de verificación y rol
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge de cuenta verificada
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.green.shade900.withValues(alpha: 0.6)
                            : Colors.green.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDarkMode 
                              ? Colors.green.shade300.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: isDarkMode ? Colors.green.shade300 : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Cuenta verificada',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isDarkMode ? Colors.green.shade300 : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      // Badge de administrador
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.amber.shade900.withValues(alpha: 0.6)
                              : Colors.amber.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDarkMode 
                                ? Colors.amber.shade300.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              size: 14,
                              color: isDarkMode ? Colors.amber.shade300 : Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Administrador',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isDarkMode ? Colors.amber.shade300 : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String initials, bool isDarkMode, {bool isLoading = false}) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
              )
            : const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                initials,
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    ).then((_) {
      if (mounted) {
        ref.invalidate(currentUserProvider);
      }
    });
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