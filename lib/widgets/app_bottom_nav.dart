// lib/widgets/app_bottom_nav.dart
// VERSIÓN CORREGIDA - Navegación consistente con go() y sin conflictos
// ✅ Eliminado _isNavigating que causaba problemas
// ✅ Usar pushReplacementNamed como fallback
// ✅ Manejo de errores mejorado

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBottomNav extends StatefulWidget {
  final Function(int index)? onTabChanged;
  final int currentIndex;

  const AppBottomNav({
    super.key,
    this.onTabChanged,
    this.currentIndex = 0,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  // Mapeo de índices a rutas - ✅ RUTAS CORRECTAS
  static final Map<int, String> _routes = {
    0: '/notes',
    1: '/notes/archived',   // ✅ Ruta correcta para ArchivedScreen
    2: '/notes/favorites',  // ✅ Ruta correcta para FavoritesScreen
    3: '/settings',
  };

  void _navigateToRoute(int index) {
    if (widget.currentIndex == index) return;
    if (!mounted) return;

    final String route = _routes[index] ?? '/notes';
    
    _AppBottomNavLogger.info('📱 Navegando a: $route (índice: $index)');

    // ✅ Usar Future.microtask para evitar conflictos con el ciclo de build
    Future.microtask(() {
      if (!mounted) return;
      
      try {
        final goRouter = GoRouter.of(context);
        // ✅ Usar go() para reemplazar la ruta actual
        goRouter.go(route);
        
        // Notificar al padre si es necesario
        widget.onTabChanged?.call(index);
      } catch (e) {
        _AppBottomNavLogger.error('❌ Error en navegación con go(): $e');
        
        // ✅ Fallback: usar pushReplacementNamed
        try {
          Navigator.of(context).pushReplacementNamed(route);
          widget.onTabChanged?.call(index);
        } catch (e2) {
          _AppBottomNavLogger.error('❌ Error en navegación con pushReplacementNamed: $e2');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = widget.currentIndex;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: isDark ? 2 : 0,
          ),
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.15 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(
                index: 0,
                currentIndex: currentIndex,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Inicio',
                isDark: isDark,
              ),
              _buildNavItem(
                index: 1,
                currentIndex: currentIndex,
                icon: Icons.archive_outlined,
                activeIcon: Icons.archive_rounded,
                label: 'Archivadas',
                isDark: isDark,
              ),
              _buildCreateButton(isDark),
              _buildNavItem(
                index: 2,
                currentIndex: currentIndex,
                icon: Icons.star_outline,
                activeIcon: Icons.star_rounded,
                label: 'Favoritas',
                isDark: isDark,
              ),
              _buildNavItem(
                index: 3,
                currentIndex: currentIndex,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'Ajustes',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        _AppBottomNavLogger.info('➕ Creando nueva nota');
        context.push('/notes/new');
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => _navigateToRoute(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey('$index-$isSelected'),
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                size: 22,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8B5CF6),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppBottomNavLogger {
  static void info(String message) {
    debugPrint('ℹ️ [BottomNav] $message');
  }
  static void error(String message) {
    debugPrint('❌ [BottomNav] $message');
  }
}