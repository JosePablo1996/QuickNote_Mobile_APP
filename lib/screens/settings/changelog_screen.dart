// lib/screens/settings/changelog_screen.dart
// Pantalla de registro de cambios (Changelog) - v2.8.0
// Con animaciones suaves, banner decorativo y navegación corregida

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ============================================
// MODELOS DE DATOS
// ============================================

class VersionChange {
  final String description;
  final List<String>? details;

  const VersionChange({required this.description, this.details});
}

class VersionCategory {
  final String category;
  final IconData icon;
  final Color color;
  final List<VersionChange> items;

  const VersionCategory({
    required this.category,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class AppVersion {
  final String version;
  final String date;
  final String title;
  final List<Color> gradientColors;
  final bool isLatest;
  final List<VersionCategory> changes;

  const AppVersion({
    required this.version,
    required this.date,
    required this.title,
    required this.gradientColors,
    this.isLatest = false,
    required this.changes,
  });
}

// ============================================
// PANTALLA PRINCIPAL
// ============================================

class ChangelogScreen extends ConsumerStatefulWidget {
  const ChangelogScreen({super.key});

  @override
  ConsumerState<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends ConsumerState<ChangelogScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _expandedVersions = {'2.8.0'};

  // Datos de versiones (0.5.0 a 2.8.0)
  final List<AppVersion> _versions = const [
    // ==================== VERSIÓN 2.8.0 ====================
    AppVersion(
      version: '2.8.0',
      date: '03 Jun 2026',
      title: '🔐 Seguridad Avanzada, Modo Offline y Experiencia Premium Completa',
      gradientColors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      isLatest: true,
      changes: [
        VersionCategory(
          category: '📱 Modo Offline Completo',
          icon: Icons.offline_bolt,
          color: Color(0xFF3B82F6),
          items: [
            VersionChange(
              description: '💾 Almacenamiento local con Hive',
              details: [
                'Base de datos local para notas en modo offline',
                'Sincronización automática al recuperar conexión',
                'Indicador visual de estado de conexión en UI',
                'Cola de operaciones pendientes para sincronización',
              ],
            ),
            VersionChange(
              description: '🔄 Sincronización bidireccional',
              details: [
                'Merge inteligente de cambios entre local y nube',
                'Resolución de conflictos con timestamp',
                'Sincronización en segundo plano sin interrupciones',
                'Progreso visual durante la sincronización',
              ],
            ),
          ],
        ),
        VersionCategory(
          category: '🔐 Passkeys (WebAuthn)',
          icon: Icons.fingerprint,
          color: Color(0xFF10B981),
          items: [
            VersionChange(
              description: '🔑 Autenticación biométrica universal',
              details: [
                'Soporte para Face ID, Huella dactilar y Windows Hello',
                'Registro de múltiples dispositivos por usuario',
                'Flujo completo de registro e inicio de sesión',
                'Gestión de passkeys desde configuración',
              ],
            ),
            VersionChange(
              description: '📡 Endpoints consumidos',
              details: [
                'POST /passkeys/register/start - Iniciar registro',
                'POST /passkeys/register/complete - Completar registro',
                'POST /passkeys/login/start - Iniciar login',
                'POST /passkeys/login/complete - Completar login',
                'GET /passkeys/list/{user_id} - Listar passkeys',
                'DELETE /passkeys/{credential_id} - Eliminar passkey',
              ],
            ),
          ],
        ),
        VersionCategory(
          category: '🚪 Gestión de Sesiones',
          icon: Icons.devices,
          color: Color(0xFFF59E0B),
          items: [
            VersionChange(
              description: '📱 Cierre de sesión en todos los dispositivos',
              details: [
                'Endpoint /auth/logout-all-sessions implementado',
                'Visualización de sesiones activas por dispositivo',
                'Cierre remoto de sesiones específicas',
                'Notificación al usuario al cerrar sesión remota',
              ],
            ),
          ],
        ),
        VersionCategory(
          category: '📥 Importación y Exportación Avanzada',
          icon: Icons.import_export,
          color: Color(0xFFEC4899),
          items: [
            VersionChange(
              description: '📤 Exportación mejorada',
              details: [
                'Exportación de notas seleccionadas (múltiples)',
                'Formatos soportados: PDF, Markdown, JSON, ZIP',
                'Compartir archivos exportados directamente',
              ],
            ),
            VersionChange(
              description: '📥 Importación desde archivos',
              details: [
                'Importar notas desde JSON exportado',
                'Importar desde ZIP (MD + JSON)',
                'Modos de importación: Reemplazar/Fusionar/Agregar',
              ],
            ),
          ],
        ),
        VersionCategory(
          category: '⏰ Backup Programado',
          icon: Icons.schedule,
          color: Color(0xFF6366F1),
          items: [
            VersionChange(
              description: '🔄 Backup automático programado',
              details: [
                'Backup diario a las 2:00 AM',
                'Backup semanal los lunes a las 2:00 AM',
                'Configuración desde Settings',
                'Notificaciones al completar backup',
              ],
            ),
          ],
        ),
        VersionCategory(
          category: '🔍 Búsqueda Avanzada',
          icon: Icons.search,
          color: Color(0xFF14B8A6),
          items: [
            VersionChange(
              description: '🎯 Filtros inteligentes',
              details: [
                'Búsqueda por título y contenido',
                'Filtro por etiquetas múltiples',
                'Filtro por rango de fechas',
              ],
            ),
          ],
        ),
        VersionCategory(
          category: '⚡ Optimización de Rendimiento',
          icon: Icons.speed,
          color: Color(0xFF8B5CF6),
          items: [
            VersionChange(
              description: '🚀 Mejoras de velocidad',
              details: [
                'Lazy loading de notas (paginación)',
                'Caché de imágenes con optimización',
                'Reducción del tamaño de build',
              ],
            ),
          ],
        ),
      ],
    ),
    // ==================== VERSIÓN 2.7.0 ====================
    AppVersion(
      version: '2.7.0',
      date: '28 May 2026',
      title: '💾 Exportación Avanzada, Backups Mejorados y Estabilidad Total',
      gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
      changes: [
        VersionCategory(
          category: '📄 Exportación Avanzada',
          icon: Icons.file_download,
          color: Color(0xFF10B981),
          items: [
            VersionChange(
              description: '📑 Exportación a múltiples formatos',
              details: [
                'Exportar a PDF con formato profesional',
                'Exportar a Markdown para documentación',
                'Exportar a JSON para interoperabilidad',
                'Exportar a ZIP (incluye MD + JSON)',
              ],
            ),
          ],
        ),
        VersionCategory(
          category: '🤖 Auto-Backup Inteligente',
          icon: Icons.auto_awesome,
          color: Color(0xFFF59E0B),
          items: [
            VersionChange(
              description: '⏱️ Detección automática de cambios',
              details: [
                'Hash de notas para detectar cambios reales',
                'Debounce inteligente de 30 segundos',
                'Backup automático cuando hay cambios pendientes',
                'Indicador visual AutoBackupIndicator',
              ],
            ),
          ],
        ),
        VersionCategory(
          category: '☁️ Backup en la Nube Mejorado',
          icon: Icons.cloud,
          color: Color(0xFF3B82F6),
          items: [
            VersionChange(
              description: '📤 Funcionalidades cloud mejoradas',
              details: [
                'Backup selectivo (elegir qué notas respaldar)',
                'Límite ampliado a 20 backups por usuario',
                'Sincronización bidireccional con /cloud/sync',
              ],
            ),
          ],
        ),
        VersionCategory(
          category: '🎨 Rediseño de Menús Laterales',
          icon: Icons.menu,
          color: Color(0xFF8B5CF6),
          items: [
            VersionChange(
              description: '✨ Left Menu y Right Menu rediseñados',
              details: [
                'Banner decorativo con gradiente dinámico',
                'Badge "Cuenta verificada" y "Administrador"',
                'Título "Opciones rápidas" en Right Menu',
              ],
            ),
          ],
        ),
      ],
    ),
    // ==================== VERSIÓN 2.6.0 ====================
    AppVersion(
      version: '2.6.0',
      date: '16 May 2026',
      title: '💾 Sistema Completo de Copias de Seguridad',
      gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
      changes: [
        VersionCategory(
          category: '💾 Backups Locales Completos',
          icon: Icons.backup,
          color: Color(0xFF10B981),
          items: [
            VersionChange(
              description: '📁 Gestión completa de backups locales',
              details: [
                'Crear, restaurar, eliminar y descargar backups',
                'Selección múltiple para eliminación masiva',
                'Límite aumentado de 10 a 20 backups por usuario',
              ],
            ),
          ],
        ),
        VersionCategory(
          category: '📄 Página de Ayuda Rediseñada',
          icon: Icons.help,
          color: Color(0xFFEC4899),
          items: [
            VersionChange(
              description: '🎨 Nuevo diseño y funcionalidades',
              details: [
                'Banner decorativo con gradiente',
                'Sistema de tabs: FAQ, Contacto, Acerca de',
                'Buscador para filtrar preguntas',
              ],
            ),
          ],
        ),
      ],
    ),
    // ==================== VERSIÓN 2.5.0 ====================
    AppVersion(
      version: '2.5.0',
      date: '15 May 2026',
      title: '🔐 Seguridad Avanzada, 2FA Completo y Recuperación por OTP',
      gradientColors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      changes: [
        VersionCategory(
          category: '🔐 Seguridad Avanzada',
          icon: Icons.lock,
          color: Color(0xFF10B981),
          items: [
            VersionChange(
              description: '📜 Historial de contraseñas',
              details: ['Almacena las últimas 5 contraseñas', 'Prevención de reutilización'],
            ),
            VersionChange(
              description: '⏰ Expiración de contraseñas',
              details: ['Expiran automáticamente después de 90 días', 'Forzar cambio al expirar'],
            ),
          ],
        ),
        VersionCategory(
          category: '🔢 Autenticación 2FA (TOTP)',
          icon: Icons.qr_code,
          color: Color(0xFFF59E0B),
          items: [
            VersionChange(
              description: '📱 Integración con Google Authenticator',
              details: ['Generación de código QR', 'Verificación de código TOTP', '8 códigos de respaldo'],
            ),
          ],
        ),
      ],
    ),
    // ==================== VERSIÓN 2.4.0 ====================
    AppVersion(
      version: '2.4.0',
      date: '12 May 2026',
      title: '🧹 Estabilización, limpieza y preparación para producción',
      gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
      changes: [
        VersionCategory(
          category: '🧹 Mejoras generales',
          icon: Icons.settings,
          color: Color(0xFFF59E0B),
          items: [
            VersionChange(
              description: '🔧 CORS configurado con orígenes explícitos',
              details: ['Configuración segura de CORS', 'Lista blanca de dominios'],
            ),
          ],
        ),
      ],
    ),
    // ==================== VERSIÓN 2.3.0 ====================
    AppVersion(
      version: '2.3.0',
      date: '09 May 2026',
      title: '☁️ Backup en la nube (Cloud Backup)',
      gradientColors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
      changes: [
        VersionCategory(
          category: '☁️ Backup en la nube',
          icon: Icons.cloud,
          color: Color(0xFF3B82F6),
          items: [
            VersionChange(
              description: '🗄️ Nuevas tablas en Supabase',
              details: ['cloud_backups - Metadatos', 'backup_data - Datos comprimidos'],
            ),
          ],
        ),
      ],
    ),
    // ==================== VERSIÓN 2.2.0 ====================
    AppVersion(
      version: '2.2.0',
      date: '07 May 2026',
      title: '🔄 Flujo OTP por email y mejoras en login',
      gradientColors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
      changes: [
        VersionCategory(
          category: '📧 Sistema de emails OTP',
          icon: Icons.email,
          color: Color(0xFF3B82F6),
          items: [
            VersionChange(
              description: '📨 Envío real con SendGrid',
              details: ['SendGrid como método primario', 'Respaldo automático con SMTP Gmail'],
            ),
          ],
        ),
      ],
    ),
    // ==================== VERSIÓN 2.1.0 ====================
    AppVersion(
      version: '2.1.0',
      date: '05 May 2026',
      title: '🔐 Soporte inicial de 2FA (TOTP)',
      gradientColors: [Color(0xFF10B981), Color(0xFF3B82F6)],
      changes: [
        VersionCategory(
          category: '🔐 2FA con Google Authenticator',
          icon: Icons.qr_code_scanner,
          color: Color(0xFF10B981),
          items: [
            VersionChange(
              description: '🔢 TOTP (Time-based One-Time Password)',
              details: ['Códigos de 6 dígitos cada 30 segundos', 'Compatibilidad con Google Authenticator, Authy'],
            ),
          ],
        ),
      ],
    ),
    // ==================== VERSIÓN 2.0.0 ====================
    AppVersion(
      version: '2.0.0',
      date: '11 Mar 2026',
      title: '🚀 Rediseño Completo y Autenticación Biométrica Mejorada',
      gradientColors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      changes: [
        VersionCategory(
          category: '✨ Rediseño de UI/UX',
          icon: Icons.design_services,
          color: Color(0xFF8B5CF6),
          items: [
            VersionChange(
              description: '🎨 Interfaz completamente rediseñada',
              details: ['Glassmorphism mejorado', 'Animaciones suaves', 'Modo oscuro/claro mejorado'],
            ),
          ],
        ),
        VersionCategory(
          category: '🔐 Autenticación Biométrica',
          icon: Icons.fingerprint,
          color: Color(0xFF3B82F6),
          items: [
            VersionChange(
              description: '🔑 Soporte para huella y Face ID',
              details: ['Login con biometría', 'Guardado de credenciales seguras'],
            ),
          ],
        ),
      ],
    ),
    // ==================== VERSIÓN 1.0.0 ====================
    AppVersion(
      version: '1.0.0',
      date: '04 Mar 2026',
      title: '🎉 Lanzamiento Inicial - QuickNote',
      gradientColors: [Color(0xFF3B82F6), Color(0xFF10B981)],
      changes: [
        VersionCategory(
          category: '🚀 Funcionalidades Principales',
          icon: Icons.rocket,
          color: Color(0xFF4CAF50),
          items: [
            VersionChange(
              description: '📝 Gestión básica de notas',
              details: ['CRUD completo de notas', 'Vista grid y lista', 'Modo oscuro/claro'],
            ),
          ],
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      appBar: _buildAppBar(isDark, context),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _versions.length + 2, // +2 para banner y footer
        itemBuilder: (context, index) {
          // Banner decorativo al inicio
          if (index == 0) {
            return _buildHeroBanner(isDark);
          }
          
          // Footer al final
          if (index == _versions.length + 1) {
            return _buildFooter(isDark);
          }

          final versionIndex = index - 1;
          final version = _versions[versionIndex];
          final isExpanded = _expandedVersions.contains(version.version);

          return _buildVersionCard(version, isExpanded, isDark);
        },
      ),
    );
  }

  // ============================================
  // APPBAR
  // ============================================

  PreferredSizeWidget _buildAppBar(bool isDark, BuildContext context) {
    return AppBar(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, size: 20),
          SizedBox(width: 8),
          Text('Historial de Cambios'),
        ],
      ),
      centerTitle: true,
      backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // ✅ CORRECCIÓN: Navegar a Settings en lugar de Login
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/settings');
          }
        },
      ),
    );
  }

  // ============================================
  // BANNER DECORATIVO
  // ============================================

  Widget _buildHeroBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icono decorativo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Título principal
          const Text(
            'CHANGELOG',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // Subtítulo
          Text(
            'Registro de versiones y novedades',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          // Badge de versión actual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.new_releases, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Última versión: v2.8.0',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // FOOTER CON ESTADÍSTICAS
  // ============================================

  Widget _buildFooter(bool isDark) {
    final totalVersionesCount = _versions.length;
    final latestVersion = _versions.firstWhere((v) => v.isLatest, orElse: () => _versions.first);
    final latestDate = latestVersion.date;
    final latestVersionNumber = latestVersion.version;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            const Color(0xFFEC4899).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Icono central
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),

          // Título
          Text(
            'Registro de Versiones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Estadísticas en cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.history,
                  value: totalVersionesCount.toString(),
                  label: 'Versiones\nTotales',
                  color: const Color(0xFF3B82F6),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.new_releases,
                  value: 'v$latestVersionNumber',
                  label: 'Última\nVersión',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fecha de última actualización
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.update,
                  size: 16,
                  color: const Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Última actualización: $latestDate',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Mensaje final
          const Text(
            '✨ ¡Gracias por usar QuickNote! ✨',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF8B5CF6),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================
  // TARJETA DE ESTADÍSTICA
  // ============================================

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================
  // TARJETA DE VERSIÓN
  // ============================================

  Widget _buildVersionCard(AppVersion version, bool isExpanded, bool isDark) {
    final gradientStart = version.gradientColors[0];
    final gradientEnd = version.gradientColors[1];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade200,
        ),
        boxShadow: version.isLatest
            ? [
                BoxShadow(
                  color: gradientStart.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          // HEADER DE VERSIÓN
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedVersions.remove(version.version);
                  } else {
                    _expandedVersions.add(version.version);
                  }
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Badge de versión
                    Hero(
                      tag: 'version_${version.version}',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [gradientStart, gradientEnd],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'v${version.version}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Título y fecha
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            version.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                version.date,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              if (version.isLatest) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: gradientStart.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Última',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: gradientStart,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Icono expandir con animación
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CONTENIDO EXPANDIDO
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(version, isDark),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  // ============================================
  // CONTENIDO EXPANDIDO
  // ============================================

  Widget _buildExpandedContent(AppVersion version, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: version.changes.map((category) {
          return _buildCategory(category, isDark);
        }).toList(),
      ),
    );
  }

  // ============================================
  // CATEGORÍA DE CAMBIOS
  // ============================================

  Widget _buildCategory(VersionCategory category, bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de categoría
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(category.icon, size: 16, color: category.color),
                ),
                const SizedBox(width: 8),
                Text(
                  category.category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Items
            ...category.items.asMap().entries.map((entry) {
              final itemIndex = entry.key;
              final item = entry.value;
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + (itemIndex * 50)),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8, left: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: category.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.details != null && item.details!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...item.details!.map((detail) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 22, bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: BoxDecoration(
                                    color: category.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    detail,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}