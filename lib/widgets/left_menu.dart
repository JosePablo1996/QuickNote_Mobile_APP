// lib/widgets/left_menu.dart
// Menú lateral izquierdo - DISEÑO EXACTO COMO TARJETA DE CONFIGURACIÓN
// ✅ Badge "Cuenta verificada" en VERDE
// ✅ Badge "Administrador" en NARANJA
// ✅ Contenido más abajo (mejor espaciado)
// ✅ Sin botón "X" de cerrar (se cierra al tocar fuera)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/models/user.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:quicknote/providers/notes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeftMenu extends ConsumerStatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final Function(String) onNavigate;

  const LeftMenu({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onNavigate,
  });

  @override
  ConsumerState<LeftMenu> createState() => _LeftMenuState();
}

class _LeftMenuState extends ConsumerState<LeftMenu> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    if (widget.isOpen) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(LeftMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _animationController.forward();
    } else if (!widget.isOpen && oldWidget.isOpen) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final notesState = ref.watch(notesProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 640;
    final menuWidth = isMobile ? screenWidth * 0.85 : 320.0;

    final allNotes = notesState.notes.where((n) => n.deletedAt == null).toList();
    final favoritesCount = allNotes.where((n) => n.isFavorite && !n.isArchived).length;
    final archivedCount = allNotes.where((n) => n.isArchived).length;
    final trashCount = notesState.notes.where((n) => n.deletedAt != null).length;

    final initials = _getInitials(user);
    final avatarColors = _getAvatarGradient(user);
    final isAdmin = user?.role == 'admin';
    final isVerified = user?.email != null && user!.email.isNotEmpty;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            GestureDetector(
              onTap: widget.onClose,
              child: Container(
                color: Colors.black.withAlpha((0.4 * _fadeAnimation.value).toInt()),
              ),
            ),
            Transform.translate(
              offset: Offset(_slideAnimation.value * screenWidth, 0),
              child: Container(
                width: menuWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF111827) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 20,
                      offset: const Offset(4, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildProfileHeader(
                      isDarkMode: isDarkMode,
                      isMobile: isMobile,
                      menuWidth: menuWidth,
                      user: user,
                      initials: initials,
                      avatarColors: avatarColors,
                      isAdmin: isAdmin,
                      isVerified: isVerified,
                    ),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          children: [
                            _buildSectionHeader(context, 'PRINCIPAL', Icons.home),
                            _buildMenuItem(
                              icon: Icons.home_outlined,
                              label: 'Inicio',
                              onTap: () {
                                widget.onClose();
                                widget.onNavigate('/notes');
                              },
                              isDarkMode: isDarkMode,
                            ),
                            _buildMenuItem(
                              icon: Icons.star_outline,
                              label: 'Favoritas',
                              badge: favoritesCount,
                              onTap: () {
                                widget.onClose();
                                widget.onNavigate('/notes/favorites');
                              },
                              isDarkMode: isDarkMode,
                            ),
                            _buildMenuItem(
                              icon: Icons.archive_outlined,
                              label: 'Archivadas',
                              badge: archivedCount,
                              onTap: () {
                                widget.onClose();
                                widget.onNavigate('/notes/archived');
                              },
                              isDarkMode: isDarkMode,
                            ),
                            _buildMenuItem(
                              icon: Icons.delete_outline,
                              label: 'Papelera',
                              badge: trashCount,
                              onTap: () {
                                widget.onClose();
                                widget.onNavigate('/trash');
                              },
                              isDarkMode: isDarkMode,
                            ),
                            const Divider(height: 32, thickness: 1),
                            _buildSectionHeader(context, 'ORGANIZACIÓN', Icons.folder),
                            _buildMenuItem(
                              icon: Icons.tag_outlined,
                              label: 'Etiquetas',
                              onTap: () {
                                widget.onClose();
                                widget.onNavigate('/tags');
                              },
                              isDarkMode: isDarkMode,
                            ),
                            _buildMenuItem(
                              icon: Icons.calendar_month_outlined,
                              label: 'Calendario',
                              onTap: () {
                                widget.onClose();
                                widget.onNavigate('/calendar');
                              },
                              isDarkMode: isDarkMode,
                            ),
                            const Divider(height: 32, thickness: 1),
                            _buildSectionHeader(context, 'CONFIGURACIÓN', Icons.settings),
                            _buildMenuItem(
                              icon: Icons.person_outline,
                              label: 'Mi Perfil',
                              onTap: () {
                                widget.onClose();
                                widget.onNavigate('/profile');
                              },
                              isDarkMode: isDarkMode,
                            ),
                            _buildMenuItem(
                              icon: Icons.backup_outlined,
                              label: 'Copias de seguridad',
                              onTap: () {
                                widget.onClose();
                                widget.onNavigate('/backup');
                              },
                              isDarkMode: isDarkMode,
                            ),
                            _buildMenuItem(
                              icon: Icons.settings_outlined,
                              label: 'Configuración',
                              onTap: () {
                                widget.onClose();
                                widget.onNavigate('/settings');
                              },
                              isDarkMode: isDarkMode,
                            ),
                            _buildMenuItem(
                              icon: Icons.security_outlined,
                              label: '2FA / Seguridad',
                              onTap: () {
                                widget.onClose();
                                widget.onNavigate('/two-factor-setup');
                              },
                              isDarkMode: isDarkMode,
                            ),
                            const Divider(height: 32, thickness: 1),
                            _buildSectionHeader(context, 'SOPORTE', Icons.help),
                            _buildMenuItem(
                              icon: Icons.help_outline,
                              label: 'Ayuda',
                              onTap: () {
                                widget.onClose();
                                widget.onNavigate('/help');
                              },
                              isDarkMode: isDarkMode,
                            ),
                            _buildMenuItem(
                              icon: Icons.code_outlined,
                              label: 'Desarrollador',
                              onTap: () {
                                widget.onClose();
                                widget.onNavigate('/developer');
                              },
                              isDarkMode: isDarkMode,
                            ),
                            _buildMenuItem(
                              icon: Icons.info_outline,
                              label: 'Acerca de',
                              onTap: () {
                                widget.onClose();
                                widget.onNavigate('/changelog');
                              },
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: Text(
                                'QuickNote v2.8.0',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ BANNER DE PERFIL - Badges con colores diferenciados y mejor espaciado
  Widget _buildProfileHeader({
    required bool isDarkMode,
    required bool isMobile,
    required double menuWidth,
    required User? user,
    required String initials,
    required List<Color> avatarColors,
    required bool isAdmin,
    required bool isVerified,
  }) {
    final headerHeight = isMobile ? (menuWidth > 400 ? 260.0 : 240.0) : 280.0;
    final avatarSize = isMobile ? (menuWidth > 400 ? 80.0 : 70.0) : 90.0;
    final fontSizeName = isMobile ? (menuWidth > 400 ? 20.0 : 18.0) : 20.0;
    final fontSizeEmail = isMobile ? 12.0 : 13.0;
    final fontSizeBadge = isMobile ? 10.0 : 11.0;

    // ✅ Degradado del banner (mismo estilo que la tarjeta de configuración)
    final gradientColors = isAdmin
        ? (isDarkMode
            ? const [Color(0xFF78350F), Color(0xFF991B1B), Color(0xFF7C2D12)]
            : const [Color(0xFFF59E0B), Color(0xFFDC2626), Color(0xFFEA580C)])
        : (isDarkMode
            ? const [Color(0xFF1E1B4B), Color(0xFF4C1D95), Color(0xFF831843)]
            : const [Color(0xFF4F46E5), Color(0xFF8B5CF6), Color(0xFFEC4899)]);

    return Container(
      height: headerHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(32),
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
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
      child: Stack(
        children: [
          // Círculos decorativos sutiles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: menuWidth * 0.35,
              height: menuWidth * 0.35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(20),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: menuWidth * 0.3,
              height: menuWidth * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(13),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              width: menuWidth * 0.18,
              height: menuWidth * 0.18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(8),
              ),
            ),
          ),
          // Contenido centrado con padding adicional para bajarlo
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: isMobile ? 20 : 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar circular con borde
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          widget.onClose();
                          widget.onNavigate('/profile');
                        },
                        child: Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isAdmin ? Colors.amber : (isDarkMode ? Colors.white70 : Colors.white),
                              width: isAdmin ? 4 : 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isAdmin
                                    ? Colors.amber.withAlpha(102)
                                    : Colors.black.withAlpha(64),
                                blurRadius: isAdmin ? 15 : 12,
                                spreadRadius: isAdmin ? 3 : 2,
                              ),
                            ],
                            gradient: user?.avatar != null && user!.avatar!.isNotEmpty
                                ? null
                                : LinearGradient(colors: avatarColors),
                          ),
                          child: ClipOval(
                            child: user?.avatar != null && user!.avatar!.isNotEmpty
                                ? Image.network(user.avatar!, fit: BoxFit.cover)
                                : Center(
                                    child: Text(
                                      initials,
                                      style: GoogleFonts.poppins(
                                        fontSize: avatarSize * 0.42,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      if (isVerified)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isAdmin
                                  ? const LinearGradient(
                                      colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                                    )
                                  : const LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                                    ),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: isAdmin ? Colors.amber.withAlpha(102) : Colors.green.withAlpha(102),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              isAdmin ? Icons.star : Icons.verified,
                              size: avatarSize * 0.28,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Nombre del usuario
                  Text(
                    user?.name ?? 'Usuario',
                    style: GoogleFonts.poppins(
                      fontSize: fontSizeName,
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
                  const SizedBox(height: 6),
                  // Email
                  Text(
                    user?.email ?? 'usuario@example.com',
                    style: GoogleFonts.poppins(
                      fontSize: fontSizeEmail,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Badges con colores diferenciados
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      // ✅ Badge Cuenta verificada - COLOR VERDE
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700.withAlpha(180),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withAlpha(102),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: fontSizeBadge + 2,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Cuenta verificada',
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeBadge,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isAdmin)
                        // ✅ Badge Administrador - COLOR NARANJA
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600.withAlpha(200),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withAlpha(102),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                size: fontSizeBadge + 2,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Administrador',
                                style: GoogleFonts.poppins(
                                  fontSize: fontSizeBadge,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(User? user) {
    final name = user?.name ?? 'Usuario';
    if (name == 'Usuario') return 'U';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  List<Color> _getAvatarGradient(User? user) {
    final name = user?.name ?? '';
    if (name.isEmpty) return const [Color(0xFF3B82F6), Color(0xFF7C3AED)];
    const gradients = [
      [Color(0xFF3B82F6), Color(0xFF7C3AED)],
      [Color(0xFF10B981), Color(0xFF0D9488)],
      [Color(0xFFF97316), Color(0xFFDC2626)],
      [Color(0xFFEC4899), Color(0xFFE11D48)],
      [Color(0xFF6366F1), Color(0xFF2563EB)],
      [Color(0xFF8B5CF6), Color(0xFFDB2777)],
      [Color(0xFFF59E0B), Color(0xFFEA580C)],
      [Color(0xFF06B6D4), Color(0xFF2563EB)],
    ];
    int sum = 0;
    for (int i = 0; i < name.length; i++) {
      sum += name.codeUnitAt(i);
    }
    return gradients[sum % gradients.length];
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 3, height: 14,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 12, color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    int? badge,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : const Color(0xFF3B82F6);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : (isDarkMode ? Colors.white : Colors.black87),
        ),
      ),
      trailing: badge != null && badge > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withAlpha(38),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            )
          : const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}