// lib/screens/settings/developer_screen.dart
// Pantalla de información del desarrollador - VERSIÓN CORREGIDA SIN OVERFLOW
// ✅ Footer horizontal
// ✅ Sin overflow en estadísticas
// ✅ Colores actualizados para nombre y rol
// ✅ Descripciones al hacer clic

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/widgets/toast_message.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================
// MODELO DE TECNOLOGÍA
// ============================================

class TechItem {
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final String category;

  const TechItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.category,
  });
}

// ============================================
// DATOS ESTÁTICOS - ACTUALIZADOS CON TODAS LAS TECNOLOGÍAS
// ============================================

const developerName = 'José Pablo Miranda Quintanilla';
const developerRole = 'Desarrollador Full Stack';
const developerBio = 
    'Desarrollador Full Stack apasionado por crear aplicaciones modernas y funcionales. '
    'Especializado en Flutter, React, FastAPI y Supabase. '
    'Creador de QuickNote, una aplicación de notas con sincronización en la nube '
    'y autenticación avanzada.';

// ============================================
// TODAS LAS TECNOLOGÍAS DEL PROYECTO (50+)
// ============================================

final List<TechItem> allTechnologies = [
  // ========== FRONTEND ==========
  TechItem(
    name: 'React 18',
    icon: Icons.code,
    color: Color(0xFF3B82F6),
    description: 'Framework UI con Hooks y Concurrent Features',
    category: 'frontend',
  ),
  TechItem(
    name: 'TypeScript',
    icon: Icons.data_object,
    color: Color(0xFF3B82F6),
    description: 'Tipado estático y seguridad en tiempo de compilación',
    category: 'frontend',
  ),
  TechItem(
    name: 'Tailwind CSS',
    icon: Icons.palette,
    color: Color(0xFF06B6D4),
    description: 'Utilidades CSS para diseño rápido y responsivo',
    category: 'frontend',
  ),
  TechItem(
    name: 'Framer Motion',
    icon: Icons.animation,
    color: Color(0xFFEC4899),
    description: 'Animaciones fluidas y transiciones',
    category: 'frontend',
  ),
  TechItem(
    name: 'Vite',
    icon: Icons.bolt,
    color: Color(0xFFEAB308),
    description: 'Build tool ultrarrápida con HMR',
    category: 'frontend',
  ),
  TechItem(
    name: 'React Router v6',
    icon: Icons.route,
    color: Color(0xFFEF4444),
    description: 'Enrutamiento dinámico y protección de rutas',
    category: 'frontend',
  ),
  TechItem(
    name: 'Lucide React',
    icon: Icons.favorite,
    color: Color(0xFFEF4444),
    description: 'Iconos modernos y consistentes',
    category: 'frontend',
  ),
  TechItem(
    name: 'Flutter',
    icon: Icons.phone_android,
    color: Color(0xFF3B82F6),
    description: 'Framework multiplataforma para móvil',
    category: 'frontend',
  ),

  // ========== BACKEND ==========
  TechItem(
    name: 'FastAPI',
    icon: Icons.bolt,
    color: Color(0xFF10B981),
    description: 'API REST asíncrona con Python',
    category: 'backend',
  ),
  TechItem(
    name: 'Supabase',
    icon: Icons.cloud,
    color: Color(0xFF10B981),
    description: 'Backend como servicio con PostgreSQL',
    category: 'backend',
  ),
  TechItem(
    name: 'PostgreSQL',
    icon: Icons.storage,
    color: Color(0xFF3B82F6),
    description: 'Base de datos relacional robusta',
    category: 'backend',
  ),
  TechItem(
    name: 'SQLAlchemy',
    icon: Icons.inventory,
    color: Color(0xFF3B82F6),
    description: 'ORM para Python',
    category: 'backend',
  ),
  TechItem(
    name: 'Pydantic',
    icon: Icons.check_circle,
    color: Color(0xFF10B981),
    description: 'Validación de datos y modelos',
    category: 'backend',
  ),
  TechItem(
    name: 'Uvicorn',
    icon: Icons.bolt,
    color: Color(0xFFEAB308),
    description: 'Servidor ASGI de alto rendimiento',
    category: 'backend',
  ),

  // ========== SEGURIDAD ==========
  TechItem(
    name: 'WebAuthn',
    icon: Icons.fingerprint,
    color: Color(0xFF8B5CF6),
    description: 'Passkeys: huella digital, Face ID, Windows Hello',
    category: 'security',
  ),
  TechItem(
    name: 'TOTP 2FA',
    icon: Icons.qr_code,
    color: Color(0xFF8B5CF6),
    description: 'Google Authenticator, Authy, Microsoft Authenticator',
    category: 'security',
  ),
  TechItem(
    name: 'QR Code',
    icon: Icons.qr_code_scanner,
    color: Color(0xFF8B5CF6),
    description: 'Generación de códigos QR para 2FA',
    category: 'security',
  ),
  TechItem(
    name: 'OTP Email',
    icon: Icons.email,
    color: Color(0xFF3B82F6),
    description: 'Verificación por código de 6 dígitos',
    category: 'security',
  ),
  TechItem(
    name: 'SendGrid',
    icon: Icons.send,
    color: Color(0xFFEF4444),
    description: '100 emails/día gratis + respaldo SMTP',
    category: 'security',
  ),
  TechItem(
    name: 'JWT Tokens',
    icon: Icons.key,
    color: Color(0xFFF97316),
    description: 'HS256 + ES256 para autenticación dual',
    category: 'security',
  ),
  TechItem(
    name: 'Password History',
    icon: Icons.history,
    color: Color(0xFFF59E0B),
    description: 'Últimas 5 contraseñas, sin reutilización',
    category: 'security',
  ),
  TechItem(
    name: 'Session Invalidation',
    icon: Icons.logout,
    color: Color(0xFFF59E0B),
    description: 'Cierre de sesiones al cambiar contraseña',
    category: 'security',
  ),
  TechItem(
    name: 'RLS Policies',
    icon: Icons.shield,
    color: Color(0xFF8B5CF6),
    description: 'Seguridad a nivel de filas en Supabase',
    category: 'security',
  ),

  // ========== BACKUPS ==========
  TechItem(
    name: 'Cloud Backup',
    icon: Icons.cloud_upload,
    color: Color(0xFF6366F1),
    description: 'Backup en Supabase con compresión',
    category: 'backup',
  ),
  TechItem(
    name: 'GZIP Compression',
    icon: Icons.compress,
    color: Color(0xFF14B8A6),
    description: 'Ahorro 65-80% de espacio',
    category: 'backup',
  ),
  TechItem(
    name: 'Auto Backup',
    icon: Icons.refresh,
    color: Color(0xFF10B981),
    description: 'Detección automática con debounce 30s',
    category: 'backup',
  ),
  TechItem(
    name: 'Selective Backup',
    icon: Icons.filter_list,
    color: Color(0xFFF97316),
    description: 'Elegir qué notas respaldar',
    category: 'backup',
  ),
  TechItem(
    name: 'Scheduled Backup',
    icon: Icons.schedule,
    color: Color(0xFFF59E0B),
    description: 'Automático diario/semanal',
    category: 'backup',
  ),
  TechItem(
    name: 'Multiple Selection',
    icon: Icons.check_box,
    color: Color(0xFF3B82F6),
    description: 'Eliminación masiva de backups',
    category: 'backup',
  ),
  TechItem(
    name: 'Bidirectional Sync',
    icon: Icons.sync,
    color: Color(0xFF06B6D4),
    description: 'Sincronización local ↔ nube',
    category: 'backup',
  ),
  TechItem(
    name: 'Backup Notifications',
    icon: Icons.notifications,
    color: Color(0xFFEC4899),
    description: 'Alertas de límite y estado',
    category: 'backup',
  ),

  // ========== EXPORTACIÓN ==========
  TechItem(
    name: 'Export PDF',
    icon: Icons.picture_as_pdf,
    color: Color(0xFFEF4444),
    description: 'Documentos profesionales con diseño',
    category: 'export',
  ),
  TechItem(
    name: 'Export Markdown',
    icon: Icons.description,
    color: Color(0xFF3B82F6),
    description: 'Formato texto plano compatible',
    category: 'export',
  ),
  TechItem(
    name: 'Export JSON',
    icon: Icons.data_object,
    color: Color(0xFF10B981),
    description: 'Backup completo de datos',
    category: 'export',
  ),
  TechItem(
    name: 'Share Social',
    icon: Icons.share,
    color: Color(0xFF3B82F6),
    description: 'Twitter, Facebook, LinkedIn, WhatsApp',
    category: 'export',
  ),
  TechItem(
    name: 'Copy to Clipboard',
    icon: Icons.content_copy,
    color: Color(0xFF6B7280),
    description: 'Copiar título + contenido',
    category: 'export',
  ),
  TechItem(
    name: 'Print Note',
    icon: Icons.print,
    color: Color(0xFF6B7280),
    description: 'Vista optimizada para impresión',
    category: 'export',
  ),

  // ========== CARACTERÍSTICAS ==========
  TechItem(
    name: 'Grid/List View',
    icon: Icons.grid_view,
    color: Color(0xFF06B6D4),
    description: 'Alternancia entre vistas',
    category: 'features',
  ),
  TechItem(
    name: 'Favorites',
    icon: Icons.star,
    color: Color(0xFFF59E0B),
    description: 'Marcar notas importantes',
    category: 'features',
  ),
  TechItem(
    name: 'Archive',
    icon: Icons.archive,
    color: Color(0xFF6B7280),
    description: 'Archivar notas sin eliminar',
    category: 'features',
  ),
  TechItem(
    name: 'Tags System',
    icon: Icons.tag,
    color: Color(0xFF8B5CF6),
    description: 'Organización por etiquetas',
    category: 'features',
  ),
  TechItem(
    name: 'Custom Colors',
    icon: Icons.palette,
    color: Color(0xFFEC4899),
    description: 'Personalización visual de notas',
    category: 'features',
  ),
  TechItem(
    name: 'Rich Text',
    icon: Icons.format_align_left,
    color: Color(0xFF3B82F6),
    description: 'Formato de texto enriquecido',
    category: 'features',
  ),
  TechItem(
    name: 'Trash Bin',
    icon: Icons.delete,
    color: Color(0xFFEF4444),
    description: 'Recuperación de notas eliminadas',
    category: 'features',
  ),

  // ========== DISEÑO ==========
  TechItem(
    name: 'Dark Mode',
    icon: Icons.dark_mode,
    color: Color(0xFF6B7280),
    description: 'Tema oscuro/claro automático',
    category: 'design',
  ),
  TechItem(
    name: 'Responsive Design',
    icon: Icons.smartphone,
    color: Color(0xFF10B981),
    description: 'Adaptación a todos los dispositivos',
    category: 'design',
  ),
  TechItem(
    name: 'Glassmorphism',
    icon: Icons.blur_on,
    color: Color(0xFF06B6D4),
    description: 'Efectos de vidrio y blur',
    category: 'design',
  ),
  TechItem(
    name: 'Figma',
    icon: Icons.design_services,
    color: Color(0xFF8B5CF6),
    description: 'Diseño UI/UX profesional',
    category: 'design',
  ),
  TechItem(
    name: 'Animations',
    icon: Icons.animation,
    color: Color(0xFFEC4899),
    description: 'Transiciones suaves y micro-interacciones',
    category: 'design',
  ),
  TechItem(
    name: 'Accessibility',
    icon: Icons.accessibility,
    color: Color(0xFF3B82F6),
    description: 'ARIA labels, keyboard navigation',
    category: 'design',
  ),

  // ========== HOSTING ==========
  TechItem(
    name: 'Render',
    icon: Icons.cloud,
    color: Color(0xFF3B82F6),
    description: 'Hosting API FastAPI',
    category: 'hosting',
  ),
  TechItem(
    name: 'Vercel',
    icon: Icons.public,
    color: Color(0xFF000000),
    description: 'Hosting frontend React',
    category: 'hosting',
  ),
  TechItem(
    name: 'GitHub Actions',
    icon: Icons.account_tree,
    color: Color(0xFF6B7280),
    description: 'CI/CD automatizado',
    category: 'hosting',
  ),
];

// ============================================
// CATEGORÍAS PARA FILTRO
// ============================================

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

final List<Category> categories = [
  const Category(id: 'all', name: 'Todas', icon: Icons.category, color: Color(0xFF6B7280)),
  const Category(id: 'frontend', name: 'Frontend', icon: Icons.web, color: Color(0xFF3B82F6)),
  const Category(id: 'backend', name: 'Backend', icon: Icons.dns, color: Color(0xFF10B981)),
  const Category(id: 'security', name: 'Seguridad', icon: Icons.shield, color: Color(0xFF8B5CF6)),
  const Category(id: 'backup', name: 'Backups', icon: Icons.cloud_upload, color: Color(0xFF6366F1)),
  const Category(id: 'export', name: 'Exportación', icon: Icons.download, color: Color(0xFF10B981)),
  const Category(id: 'features', name: 'Características', icon: Icons.star, color: Color(0xFFF59E0B)),
  const Category(id: 'design', name: 'Diseño', icon: Icons.palette, color: Color(0xFFEC4899)),
  const Category(id: 'hosting', name: 'Hosting', icon: Icons.public, color: Color(0xFF06B6D4)),
];

// ============================================
// PAINTER PARA PATRÓN DE PUNTOS
// ============================================

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    const radius = 1.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================
// PANTALLA PRINCIPAL
// ============================================

class DeveloperScreen extends ConsumerStatefulWidget {
  const DeveloperScreen({super.key});

  @override
  ConsumerState<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends ConsumerState<DeveloperScreen> {
  bool _avatarError = false;
  bool _isNavigating = false;
  String _selectedCategory = 'all';

  void _goBack() {
    if (_isNavigating) return;
    _isNavigating = true;
    
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      try {
        context.go('/settings');
      } finally {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _isNavigating = false;
        });
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ToastMessage.error(context, 'No se pudo abrir el enlace');
      }
    }
  }

  void _showTechDescription(TechItem tech) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tech.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(tech.icon, size: 48, color: tech.color),
                ),
                const SizedBox(height: 16),
                Text(
                  tech.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: tech.color,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 50,
                  height: 3,
                  decoration: BoxDecoration(
                    color: tech.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tech.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tech.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int getCategoryCount(String categoryId) {
    if (categoryId == 'all') return allTechnologies.length;
    return allTechnologies.where((t) => t.category == categoryId).length;
  }

  List<TechItem> get filteredTechnologies {
    if (_selectedCategory == 'all') return allTechnologies;
    return allTechnologies.where((t) => t.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;
    final crossAxisCount = screenWidth < 400 ? 2 : (screenWidth < 800 ? 3 : 4);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.code, size: 20),
            SizedBox(width: 8),
            Text('Desarrollador'),
          ],
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _goBack,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Banner principal con gradiente de QuickNote
            _buildBanner(isDesktop),
            
            // Avatar sobrepuesto
            _buildAvatarOverlay(isDark),
            
            // Nombre del desarrollador con nuevos colores
            _buildDeveloperName(isDark),
            
            const SizedBox(height: 20),
            
            // Sobre el desarrollador
            _buildAboutCard(isDark),
            
            const SizedBox(height: 16),
            
            // Estadísticas rápidas - NUEVA VERSIÓN SIN OVERFLOW
            _buildStatsSectionHorizontal(isDark),
            
            const SizedBox(height: 16),
            
            // Stack Tecnológico con filtro
            _buildTechSection(isDark, crossAxisCount, screenWidth),
            
            const SizedBox(height: 16),
            
            // Características destacadas
            _buildHighlightedFeatures(isDark),
            
            const SizedBox(height: 16),
            
            // Conectar
            _buildContactSection(isDark),
            
            const SizedBox(height: 16),
            
            // Footer horizontal
            _buildFooterHorizontal(isDark),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BANNER PRINCIPAL CON GRADIENTE DE QUICKNOTE
  // ==========================================

  Widget _buildBanner(bool isDesktop) {
    return Container(
      width: double.infinity,
      height: isDesktop ? 200 : 170,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Patrón de puntos decorativo
          Positioned.fill(
            child: CustomPaint(
              painter: _DotPatternPainter(),
            ),
          ),
          // Contenido central
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFA7F3D0)],
                    ).createShader(bounds),
                    child: Text(
                      'QuickNote',
                      style: TextStyle(
                        fontSize: isDesktop ? 40 : 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        shadows: const [
                          Shadow(
                            blurRadius: 20,
                            color: Colors.black26,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.rocket_launch, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Versión 2.8.0',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // AVATAR SOBREPUESTO
  // ==========================================

  Widget _buildAvatarOverlay(bool isDark) {
    return Transform.translate(
      offset: const Offset(0, -45),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sombra exterior
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          // Borde
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                width: 3,
              ),
            ),
          ),
          // Avatar
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipOval(
              child: _avatarError
                  ? const Icon(Icons.auto_awesome, size: 40, color: Colors.white)
                  : Image.asset(
                      'assets/images/1766699641613.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        _avatarError = true;
                        return const Icon(Icons.auto_awesome, size: 40, color: Colors.white);
                      },
                    ),
            ),
          ),
          // Badge de verificación
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(Icons.verified, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // NOMBRE DEL DESARROLLADOR - CON NUEVOS COLORES
  // ==========================================

  Widget _buildDeveloperName(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Transform.translate(
        offset: const Offset(0, -30),
        child: Column(
          children: [
            // Nombre con gradiente violeta-rosa
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFC084FC), Color(0xFFF472B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                developerName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            // Badge rol con color rosa
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC084FC), Color(0xFFF472B6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.code, size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    developerRole,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SOBRE EL DESARROLLADOR
  // ==========================================

  Widget _buildAboutCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _sectionHeader(Icons.info_outline_rounded, 'Sobre el desarrollador'),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC084FC), Color(0xFFF472B6)],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            developerBio,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ESTADÍSTICAS HORIZONTAL - SIN OVERFLOW
  // ==========================================

  Widget _buildStatsSectionHorizontal(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.code,
            value: '55+',
            label: 'Tecnologías',
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
          _buildStatItem(
            icon: Icons.commit,
            value: '200+',
            label: 'Commits',
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          _buildStatItem(
            icon: Icons.data_usage,
            value: '15K+',
            label: 'Líneas',
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
          _buildStatItem(
            icon: Icons.star,
            value: 'v2.6.0',
            label: 'Versión',
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STACK TECNOLÓGICO CON FILTRO
  // ==========================================

  Widget _buildTechSection(bool isDark, int crossAxisCount, double screenWidth) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _sectionHeader(Icons.memory_rounded, 'Stack Tecnológico'),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC084FC), Color(0xFFF472B6)],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 18),
          
          // Filtro de categorías
          _buildCategoryFilter(isDark, screenWidth),
          
          const SizedBox(height: 20),
          
          // Grid de tecnologías filtradas
          if (filteredTechnologies.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: filteredTechnologies.length,
              itemBuilder: (context, index) {
                final tech = filteredTechnologies[index];
                return _buildTechCard(tech, isDark);
              },
            )
          else
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No hay tecnologías en esta categoría',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Contador de tecnologías
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFC084FC).withOpacity(0.08),
                  const Color(0xFFF472B6).withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFC084FC).withOpacity(0.15),
              ),
            ),
            child: Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${filteredTechnologies.length} ',
                      style: const TextStyle(
                        color: Color(0xFFC084FC),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: _selectedCategory == 'all' 
                          ? 'tecnologías utilizadas'
                          : 'tecnologías en ${categories.firstWhere((c) => c.id == _selectedCategory).name.toLowerCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark, double screenWidth) {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category.id;
          final count = getCategoryCount(category.id);
          
          return FilterChip(
            selected: isSelected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(category.icon, size: 14, color: isSelected ? Colors.white : category.color),
                const SizedBox(width: 6),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white.withOpacity(0.2) 
                        : category.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : category.color,
                    ),
                  ),
                ),
              ],
            ),
            selectedColor: category.color,
            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            checkmarkColor: Colors.white,
            showCheckmark: false,
            onSelected: (_) {
              setState(() {
                _selectedCategory = category.id;
              });
            },
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: isSelected 
                  ? BorderSide.none 
                  : BorderSide(color: category.color.withOpacity(0.3)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTechCard(TechItem tech, bool isDark) {
    return GestureDetector(
      onTap: () => _showTechDescription(tech),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: tech.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: tech.color.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: tech.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(tech.icon, size: 22, color: tech.color),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                tech.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CARACTERÍSTICAS DESTACADAS
  // ==========================================

  Widget _buildHighlightedFeatures(bool isDark) {
    final features = [
      {'icon': Icons.fingerprint, 'text': 'Autenticación biométrica con WebAuthn', 'color': const Color(0xFF8B5CF6)},
      {'icon': Icons.qr_code, 'text': '2FA con Google Authenticator', 'color': const Color(0xFF3B82F6)},
      {'icon': Icons.cloud_upload, 'text': 'Backup automático en la nube', 'color': const Color(0xFF06B6D4)},
      {'icon': Icons.picture_as_pdf, 'text': 'Exportación a PDF, MD y JSON', 'color': const Color(0xFF10B981)},
      {'icon': Icons.share, 'text': 'Compartir en redes sociales', 'color': const Color(0xFFEC4899)},
      {'icon': Icons.smartphone, 'text': 'Diseño totalmente responsivo', 'color': const Color(0xFFF97316)},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFC084FC).withOpacity(0.05),
            const Color(0xFFF472B6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC084FC).withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          _sectionHeader(Icons.star_rounded, 'Características Destacadas'),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC084FC), Color(0xFFF472B6)],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (feature['color'] as Color).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(feature['icon'] as IconData, size: 16, color: feature['color'] as Color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature['text'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CONECTAR CONMIGO
  // ==========================================

  Widget _buildContactSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _sectionHeader(Icons.connect_without_contact_rounded, 'Conectar conmigo'),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC084FC), Color(0xFFF472B6)],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 16),
          
          // GitHub
          _socialButton(
            icon: Icons.code,
            label: 'GitHub',
            username: '@JosePablo1996',
            color: Colors.grey.shade800,
            url: 'https://github.com/JosePablo1996',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          
          // LinkedIn
          _socialButton(
            icon: Icons.business,
            label: 'LinkedIn',
            username: '/in/josepablo',
            color: Colors.blue.shade700,
            url: 'https://linkedin.com/in/josepablo',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          
          // Twitter
          _socialButton(
            icon: Icons.alternate_email,
            label: 'Twitter',
            username: '@josepablo',
            color: Colors.cyan,
            url: 'https://twitter.com/josepablo',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          
          // Email
          _socialButton(
            icon: Icons.email_rounded,
            label: 'Email',
            username: 'pabloquintanilla988@gmail.com',
            color: Colors.red,
            url: 'mailto:pabloquintanilla988@gmail.com',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FOOTER HORIZONTAL
  // ==========================================

  Widget _buildFooterHorizontal(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Badge versión
          Row(
            children: [
              const Icon(Icons.rocket_launch, size: 14, color: Color(0xFFC084FC)),
              const SizedBox(width: 4),
              const Text(
                'v2.8.0',
                style: TextStyle(
                  color: Color(0xFFC084FC),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          // Separador
          Container(
            width: 1,
            height: 20,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          // Nombre de la app
          Text(
            'QuickNote',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          // Separador
          Container(
            width: 1,
            height: 20,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          // Copyright
          const Text(
            '© 2026',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGETS REUTILIZABLES
  // ==========================================

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFC084FC), Color(0xFFF472B6)],
            ),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
    required String username,
    required Color color,
    required String url,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}