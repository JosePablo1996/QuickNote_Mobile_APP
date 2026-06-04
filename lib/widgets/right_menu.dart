// lib/widgets/right_menu.dart
// Menú lateral derecho (opciones) - Diseño moderno y espaciado
// ✅ Banner decorativo con diseño idéntico a LeftMenu (gradiente, sombras, círculos)
// ✅ Muestra "Opciones rápidas" como título principal
// ✅ Badge "Personaliza tu experiencia" debajo del título
// ✅ Totalmente responsivo y con degrade dinámico según rol de usuario

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RightMenu extends ConsumerStatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final VoidCallback? onSync;
  final VoidCallback? onExport;
  final VoidCallback? onImport;

  const RightMenu({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.onSync,
    this.onExport,
    this.onImport,
  });

  @override
  ConsumerState<RightMenu> createState() => _RightMenuState();
}

class _RightMenuState extends ConsumerState<RightMenu> with SingleTickerProviderStateMixin {
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
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
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
  void didUpdateWidget(RightMenu oldWidget) {
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
    final isAdmin = user?.role == 'admin';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 640;
    final menuWidth = isMobile ? screenWidth * 0.85 : 320.0;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Overlay para cerrar con fade
            GestureDetector(
              onTap: widget.onClose,
              child: Container(
                color: Colors.black.withValues(alpha: 0.4 * _fadeAnimation.value),
              ),
            ),
            // Menú lateral derecho con animación de slide
            Transform.translate(
              offset: Offset(_slideAnimation.value * screenWidth, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: menuWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF111827) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      bottomLeft: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(-4, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ✅ Banner decorativo con diseño exacto de LeftMenu
                      _buildBannerHeader(
                        isDarkMode: isDarkMode,
                        isMobile: isMobile,
                        menuWidth: menuWidth,
                        isAdmin: isAdmin,
                      ),
                      // Lista de opciones
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: ListView(
                            padding: const EdgeInsets.only(top: 24, bottom: 16),
                            children: [
                              // Sección Principal
                              _buildSectionHeader(context, 'PRINCIPAL', Icons.home),
                              _buildOption(
                                icon: Icons.sync,
                                label: 'Sincronizar',
                                subtitle: 'Sincronizar notas con la nube',
                                onTap: () {
                                  widget.onClose();
                                  widget.onSync?.call();
                                },
                                isDarkMode: isDarkMode,
                              ),
                              _buildOption(
                                icon: Icons.download,
                                label: 'Exportar notas',
                                subtitle: 'Guardar copia local',
                                onTap: () {
                                  widget.onClose();
                                  widget.onExport?.call();
                                },
                                isDarkMode: isDarkMode,
                              ),
                              _buildOption(
                                icon: Icons.upload,
                                label: 'Importar notas',
                                subtitle: 'Restaurar desde copia',
                                onTap: () {
                                  widget.onClose();
                                  widget.onImport?.call();
                                },
                                isDarkMode: isDarkMode,
                              ),
                              
                              const Divider(height: 32, thickness: 1),
                              
                              // Sección Configuración
                              _buildSectionHeader(context, 'CONFIGURACIÓN', Icons.settings),
                              _buildOption(
                                icon: Icons.person_outline,
                                label: 'Mi Perfil',
                                subtitle: 'Editar información personal',
                                onTap: () {
                                  widget.onClose();
                                  context.push('/profile');
                                },
                                isDarkMode: isDarkMode,
                              ),
                              _buildOption(
                                icon: Icons.backup,
                                label: 'Copias de seguridad',
                                subtitle: 'Gestionar backups',
                                onTap: () {
                                  widget.onClose();
                                  context.push('/backup');
                                },
                                isDarkMode: isDarkMode,
                              ),
                              _buildOption(
                                icon: Icons.security_outlined,
                                label: '2FA / Seguridad',
                                subtitle: 'Configurar autenticación de dos factores',
                                onTap: () {
                                  widget.onClose();
                                  context.push('/two-factor-setup');
                                },
                                isDarkMode: isDarkMode,
                              ),
                              
                              const Divider(height: 32, thickness: 1),
                              
                              // Sección Soporte
                              _buildSectionHeader(context, 'SOPORTE', Icons.help_outline),
                              _buildOption(
                                icon: Icons.help_outline,
                                label: 'Ayuda',
                                subtitle: 'Preguntas frecuentes',
                                onTap: () {
                                  widget.onClose();
                                  context.push('/help');
                                },
                                isDarkMode: isDarkMode,
                              ),
                              _buildOption(
                                icon: Icons.code_outlined,
                                label: 'Desarrollador',
                                subtitle: 'Información técnica',
                                onTap: () {
                                  widget.onClose();
                                  context.push('/developer');
                                },
                                isDarkMode: isDarkMode,
                              ),
                              _buildOption(
                                icon: Icons.info_outline,
                                label: 'Acerca de',
                                subtitle: 'Versión 2.8.0',
                                onTap: () {
                                  widget.onClose();
                                  context.push('/changelog');
                                },
                                isDarkMode: isDarkMode,
                              ),
                              
                              const Divider(height: 32, thickness: 1),
                              
                              // Footer
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
            ),
          ],
        );
      },
    );
  }

  // ✅ BANNER DECORATIVO - Diseño idéntico al de LeftMenu, sin avatar
  Widget _buildBannerHeader({
    required bool isDarkMode,
    required bool isMobile,
    required double menuWidth,
    required bool isAdmin,
  }) {
    final headerHeight = isMobile ? (menuWidth > 400 ? 200.0 : 180.0) : 220.0;
    final decorSize1 = menuWidth * 0.35;
    final decorSize2 = menuWidth * 0.3;
    final decorSize3 = menuWidth * 0.18;
    final fontSizeTitle = isMobile ? (menuWidth > 400 ? 22.0 : 20.0) : 24.0;
    final fontSizeBadge = isMobile ? (menuWidth > 400 ? 11.0 : 10.0) : 12.0;

    // ✅ Degradado idéntico al de LeftMenu y UserProfileCard
    final gradientColors = isAdmin
        ? (isDarkMode
            ? const [Color(0xFF78350F), Color(0xFF991B1B), Color(0xFF7C2D12), Color(0xFF451A03)]
            : const [Color(0xFFF59E0B), Color(0xFFDC2626), Color(0xFFEA580C), Color(0xFFFCD34D)])
        : (isDarkMode
            ? const [Color(0xFF1E1B4B), Color(0xFF4C1D95), Color(0xFF831843), Color(0xFF064E3B)]
            : const [Color(0xFF4F46E5), Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF10B981)]);

    return Container(
      height: headerHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
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
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Stack(
            children: [
              // Efectos decorativos (círculos translúcidos)
              Positioned(
                top: -40,
                left: -40,
                child: Container(
                  width: decorSize1,
                  height: decorSize1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(20),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                right: -30,
                child: Container(
                  width: decorSize2,
                  height: decorSize2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(13),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  width: decorSize3,
                  height: decorSize3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(8),
                  ),
                ),
              ),
              // Botón cerrar (izquierda porque es menú derecho)
              Positioned(
                top: isMobile ? 12 : 16,
                left: isMobile ? 12 : 16,
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
              // Contenido centrado
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Título "Opciones rápidas"
                    Text(
                      'Opciones rápidas',
                      style: GoogleFonts.poppins(
                        fontSize: fontSizeTitle,
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
                    const SizedBox(height: 12),
                    // Badge "Personaliza tu experiencia"
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? (menuWidth > 400 ? 16 : 12) : 20,
                        vertical: isMobile ? (menuWidth > 400 ? 8 : 6) : 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(64),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withAlpha(102),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withAlpha(26),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: fontSizeBadge + 2,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Personaliza tu experiencia',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 3, height: 14,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.all(Radius.circular(2)),
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

  Widget _buildOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : const Color(0xFF3B82F6);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
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
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}