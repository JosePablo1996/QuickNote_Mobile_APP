// lib/screens/backup/backup_screen.dart
// Pantalla principal de Copias de Seguridad - VERSIÓN CORREGIDA
// ✅ CORREGIDO: Overflow en BackupStatCard
// ✅ CORREGIDO: Navegación con PopScope y go()
// ✅ Diseño responsive mejorado

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/providers/backup_provider.dart';
import 'package:quicknote/providers/notes_provider.dart';
import 'package:quicknote/providers/auth_provider.dart';
import 'package:quicknote/screens/backup/backup_local_screen.dart';
import 'package:quicknote/screens/backup/backup_cloud_screen.dart';
import 'package:quicknote/widgets/loading_indicator.dart';
import 'package:quicknote/widgets/toast_message.dart';

class _BackupScreenLogger {
  static void info(String message) => debugPrint('ℹ️ [BackupScreen] $message');
  static void success(String message) => debugPrint('✅ [BackupScreen] $message');
  static void error(String message) => debugPrint('❌ [BackupScreen] $message');
}

// ============================================
// COMPONENTES REUTILIZABLES CORREGIDOS
// ============================================

/// Tarjeta de estadísticas - CORREGIDA (sin overflow)
class BackupStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;
  final VoidCallback? onTap;

  const BackupStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 9 : 11,
                  color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle!,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 8 : 9,
                    color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de información
class BackupInfoCard extends StatelessWidget {
  final String title;
  final List<BackupInfoItem> items;

  const BackupInfoCard({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Icon(item.icon, size: 12, color: item.color),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.text,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class BackupInfoItem {
  final IconData icon;
  final String text;
  final Color color;

  const BackupInfoItem({
    required this.icon,
    required this.text,
    required this.color,
  });
}

/// Tarjeta de último backup
class LastBackupCard extends StatelessWidget {
  final String fileName;
  final int noteCount;
  final DateTime createdAt;

  const LastBackupCard({
    super.key,
    required this.fileName,
    required this.noteCount,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gradientStart = const Color(0xFF10B981);
    final gradientEnd = const Color(0xFF059669);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [gradientStart.withValues(alpha: 0.2), gradientEnd.withValues(alpha: 0.2)]
              : [gradientStart.withValues(alpha: 0.1), gradientEnd.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradientStart.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.cloud_done, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Último Backup',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: gradientStart,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fileName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$noteCount notas · ${_formatDate(createdAt)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ============================================
// PANTALLA PRINCIPAL - CON NAVEGACIÓN CORREGIDA
// ============================================

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  bool _isNavigating = false;

  void _goBack() {
    if (_isNavigating) return;
    _isNavigating = true;
    
    _BackupScreenLogger.info('🔙 Navegando de vuelta a notas');
    
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      try {
        context.go('/notes');
        _BackupScreenLogger.success('✅ Navegación exitosa');
      } catch (e) {
        _BackupScreenLogger.error('Error: $e');
      } finally {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _isNavigating = false;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _selectedTab = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backupState = ref.watch(backupProvider);
    final notesState = ref.watch(notesProvider);
    final user = ref.watch(currentUserProvider);

    // Calcular estadísticas
    final localBackups = backupState.backups.where((b) => b.source == 'local' || b.source == null).length;
    final cloudBackups = backupState.backups.where((b) => b.source == 'cloud').length;
    final totalSize = backupState.backups.fold<int>(0, (sum, b) => sum + b.fileSize);
    final lastBackup = backupState.backups.isNotEmpty ? backupState.backups.first : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack();
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: _buildAppBar(isDarkMode, user),
        body: Column(
          children: [
            // Banner decorativo
            _buildBanner(isDarkMode),
            const SizedBox(height: 16),
            
            // Tabs
            _buildTabs(isDarkMode),
            
            // Contenido de tabs
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Resumen General
                  _buildOverviewTab(
                    isDarkMode,
                    backupState,
                    notesState,
                    localBackups,
                    cloudBackups,
                    totalSize,
                    lastBackup,
                  ),
                  // Backups Locales
                  const BackupLocalScreen(),
                  // Backups en la Nube
                  const BackupCloudScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode, dynamic user) {
    return AppBar(
      title: const Text('Copias de Seguridad'),
      centerTitle: true,
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _goBack,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(backupProvider.notifier).loadBackups();
            ref.read(notesProvider.notifier).loadNotes();
            ToastMessage.info(context, 'Actualizando backups...');
          },
          tooltip: 'Actualizar',
        ),
        if (user != null)
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              ),
            ),
            child: ClipOval(
              child: user.avatar != null && user.avatar!.isNotEmpty
                  ? Image.network(user.avatar!, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        _getInitials(user.name ?? user.email),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildBanner(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF1E3A8A), const Color(0xFF4C1D95), const Color(0xFF831843)]
              : [const Color(0xFF2563EB), const Color(0xFF7C3AED), const Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Círculos decorativos
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.backup, size: 32, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  'QuickNote',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade300,
                  ),
                ),
                Text(
                  'Sistema de Copias de Seguridad',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'v2.6.0',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: isDarkMode ? Colors.white54 : Colors.grey.shade600,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.bar_chart), text: 'Resumen'),
          Tab(icon: Icon(Icons.storage), text: 'Locales'),
          Tab(icon: Icon(Icons.cloud), text: 'Nube'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    bool isDarkMode,
    BackupState backupState,
    NotesState notesState,
    int localBackups,
    int cloudBackups,
    int totalSize,
    dynamic lastBackup,
  ) {
    if (backupState.isLoading) {
      return const Center(child: LoadingIndicator(message: 'Cargando backups...'));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 500 ? 2 : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grid de estadísticas - CORREGIDO
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              BackupStatCard(
                icon: Icons.note,
                title: 'Notas actuales',
                value: '${notesState.notes.length}',
                color: Colors.blue,
              ),
              BackupStatCard(
                icon: Icons.storage,
                title: 'Backups Locales',
                value: '$localBackups',
                subtitle: backupState.limitInfo != null 
                    ? '${backupState.limitInfo!.current}/${backupState.limitInfo!.max}' 
                    : null,
                color: Colors.teal,
              ),
              BackupStatCard(
                icon: Icons.cloud,
                title: 'Backups en Nube',
                value: '$cloudBackups',
                color: Colors.purple,
              ),
              BackupStatCard(
                icon: Icons.sd_storage,
                title: 'Espacio usado',
                value: _formatFileSize(totalSize),
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Último backup
          if (lastBackup != null)
            LastBackupCard(
              fileName: lastBackup.fileName,
              noteCount: lastBackup.noteCount,
              createdAt: lastBackup.createdAt,
            ),
          
          const SizedBox(height: 24),
          
          // Backup programado
          _buildScheduledBackupCard(isDarkMode),
          
          const SizedBox(height: 24),
          
          // Información
          BackupInfoCard(
            title: 'Información',
            items: const [
              BackupInfoItem(
                icon: Icons.check_circle,
                text: 'Formato JSON compatible',
                color: Color(0xFF10B981),
              ),
              BackupInfoItem(
                icon: Icons.check_circle,
                text: 'Incluye título, contenido, color, etiquetas',
                color: Color(0xFF10B981),
              ),
              BackupInfoItem(
                icon: Icons.check_circle,
                text: 'Las notas importadas se agregan sin eliminar',
                color: Color(0xFF10B981),
              ),
              BackupInfoItem(
                icon: Icons.warning_amber,
                text: 'Al restaurar, las notas actuales serán reemplazadas',
                color: Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledBackupCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.schedule, size: 20, color: Colors.amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Backup Automático Programado',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Switch(
                value: false,
                onChanged: (_) {
                  ToastMessage.info(context, 'Backup programado - Próximamente');
                },
                activeColor: const Color(0xFF8B5CF6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Los backups se ejecutarán automáticamente a las 2:00 AM',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ToastMessage.info(context, 'Backup diario - Próximamente'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Diario',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ToastMessage.info(context, 'Backup semanal - Próximamente'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Semanal',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ToastMessage.info(context, 'Backup programado desactivado'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Nunca',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // UTILIDADES
  // ============================================

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}