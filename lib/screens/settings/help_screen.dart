// lib/screens/settings/help_screen.dart
// Pantalla de ayuda y soporte - VERSIÓN CORREGIDA v2.8.0
// ✅ CORREGIDA navegación - Sin PopScope, usando solo AppBar
// ✅ Navegación directa a Settings
// ✅ Actualizado a v2.8.0 con nuevas funcionalidades

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicknote/widgets/toast_message.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  int _activeTab = 0;
  String? _expandedFaq;
  bool _isNavigating = false;

  // Categorías visuales
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Todos', 'icon': Icons.grid_view, 'color': const Color(0xFF6B7280), 'description': 'Ver todas las preguntas'},
    {'name': 'General', 'icon': Icons.info_outline, 'color': const Color(0xFF3B82F6), 'description': 'Información general de QuickNote'},
    {'name': 'Notas', 'icon': Icons.edit_note, 'color': const Color(0xFF10B981), 'description': 'Crear y gestionar notas'},
    {'name': 'Etiquetas', 'icon': Icons.sell, 'color': const Color(0xFFEC4899), 'description': 'Organización por etiquetas'},
    {'name': 'Organización', 'icon': Icons.folder, 'color': const Color(0xFF14B8A6), 'description': 'Archivar y organizar notas'},
    {'name': 'Backups', 'icon': Icons.cloud_upload, 'color': const Color(0xFF6366F1), 'description': 'Copias de seguridad'},
    {'name': 'Seguridad', 'icon': Icons.security, 'color': const Color(0xFFEF4444), 'description': '2FA y datos biométricos'},
    {'name': 'Exportación', 'icon': Icons.download, 'color': const Color(0xFFF59E0B), 'description': 'Exportar a PDF, MD, JSON'},
    {'name': 'Offline', 'icon': Icons.offline_bolt, 'color': const Color(0xFF06B6D4), 'description': 'Modo offline y sincronización'},
    {'name': 'Passkeys', 'icon': Icons.fingerprint, 'color': const Color(0xFFA855F7), 'description': 'Autenticación biométrica WebAuthn'},
  ];

  // FAQs
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': '✨ ¿Qué es QuickNote?',
      'answer': 'QuickNote es una aplicación moderna de gestión de notas que combina simplicidad con características avanzadas. Ofrece sincronización en la nube, autenticación biométrica, 2FA, backups automáticos, exportación a múltiples formatos, modo offline completo y soporte para Passkeys/WebAuthn.',
      'category': 'General',
      'icon': Icons.rocket_launch,
    },
    {
      'question': '🔄 ¿Cómo funciona la sincronización?',
      'answer': 'Tus notas se sincronizan automáticamente con Supabase en la nube. Puedes ver el estado de sincronización en el menú lateral y forzar una sincronización manual. Con el modo offline (v2.8.0), los cambios se guardan localmente y se sincronizan automáticamente cuando recuperas conexión.',
      'category': 'General',
      'icon': Icons.sync,
    },
    {
      'question': '📝 ¿Cómo crear una nota?',
      'answer': 'Para crear una nota, haz clic en el botón "+" en la esquina inferior derecha de la pantalla principal. Luego, completa el título y el contenido, selecciona un color, elige una forma y guarda.',
      'category': 'Notas',
      'icon': Icons.note_add,
    },
    {
      'question': '🎨 ¿Cómo personalizar una nota?',
      'answer': 'Puedes personalizar el color de fondo, la forma, el icono y el tamaño de la nota. También puedes ajustar la intensidad del color.',
      'category': 'Notas',
      'icon': Icons.palette,
    },
    {
      'question': '🏷️ ¿Cómo funcionan las etiquetas?',
      'answer': 'Las etiquetas te ayudan a organizar tus notas por categorías. Puedes agregar múltiples etiquetas a cada nota (máximo 10) y filtrar por ellas.',
      'category': 'Etiquetas',
      'icon': Icons.tag,
    },
    {
      'question': '💾 ¿Cómo crear un backup de mis notas?',
      'answer': 'En "Configuración" > "Copias de Seguridad", puedes crear copias de seguridad. Puedes hacer backups locales o en la nube, usar backup selectivo y programar backups automáticos.',
      'category': 'Backups',
      'icon': Icons.backup,
    },
    {
      'question': '☁️ ¿Límite de backups en la nube?',
      'answer': 'QuickNote permite un máximo de 20 backups por usuario. Los backups están comprimidos con GZIP para ahorrar espacio.',
      'category': 'Backups',
      'icon': Icons.cloud,
    },
    {
      'question': '⏰ ¿Cómo funciona el backup programado?',
      'answer': 'Desde la versión 2.8.0, puedes programar backups automáticos diarios (2:00 AM) o semanales (lunes 2:00 AM).',
      'category': 'Backups',
      'icon': Icons.schedule,
    },
    {
      'question': '🔐 ¿Cómo activar la autenticación de dos factores (2FA)?',
      'answer': 'Ve a Configuración > Seguridad, haz clic en "Configurar 2FA", escanea el código QR con Google Authenticator y guarda tus códigos de respaldo.',
      'category': 'Seguridad',
      'icon': Icons.qr_code,
    },
    {
      'question': '👆 ¿Qué es la autenticación biométrica?',
      'answer': 'La autenticación biométrica te permite iniciar sesión con tu huella digital o Face ID. Puedes activarla desde Configuración > Seguridad.',
      'category': 'Seguridad',
      'icon': Icons.fingerprint,
    },
    {
      'question': '📱 ¿Cómo funciona el modo offline?',
      'answer': 'QuickNote v2.8.0 incluye modo offline completo. Tus notas se almacenan localmente y se sincronizan automáticamente cuando recuperas conexión.',
      'category': 'Offline',
      'icon': Icons.offline_bolt,
    },
    {
      'question': '🔑 ¿Qué son los Passkeys (WebAuthn)?',
      'answer': 'Passkeys permite iniciar sesión usando Face ID, Huella dactilar sin contraseña. Puedes registrar múltiples dispositivos desde Configuración > Seguridad.',
      'category': 'Passkeys',
      'icon': Icons.fingerprint,
    },
    {
      'question': '📤 ¿Cómo exportar una nota?',
      'answer': 'Puedes exportar notas individuales o múltiples a PDF, Markdown, JSON o ZIP desde el detalle de la nota o usando el botón de exportación.',
      'category': 'Exportación',
      'icon': Icons.download,
    },
    {
      'question': '📥 ¿Cómo importar notas desde un backup?',
      'answer': 'Desde v2.8.0, puedes importar notas desde archivos JSON o ZIP. Ve a "Configuración" > "Copias de Seguridad" > "Importar".',
      'category': 'Exportación',
      'icon': Icons.upload,
    },
  ];

  // Características principales
  final List<Map<String, dynamic>> _features = [
    {'icon': Icons.edit_note, 'title': 'Gestión de Notas', 'description': 'Crea, edita y organiza', 'color': const Color(0xFF3B82F6)},
    {'icon': Icons.cloud_sync, 'title': 'Sincronización', 'description': 'Nube en tiempo real', 'color': const Color(0xFF8B5CF6)},
    {'icon': Icons.fingerprint, 'title': 'Passkeys/WebAuthn', 'description': 'Biometría sin contraseña', 'color': const Color(0xFFA855F7)},
    {'icon': Icons.backup, 'title': 'Backups', 'description': 'Automáticos y selectivos', 'color': const Color(0xFFF59E0B)},
    {'icon': Icons.offline_bolt, 'title': 'Modo Offline', 'description': 'Trabaja sin internet', 'color': const Color(0xFF06B6D4)},
    {'icon': Icons.share, 'title': 'Exportación', 'description': 'PDF, MD o JSON', 'color': const Color(0xFFEC4899)},
    {'icon': Icons.security, 'title': '2FA + Biometría', 'description': 'Seguridad avanzada', 'color': const Color(0xFF10B981)},
    {'icon': Icons.grid_view, 'title': 'Múltiples vistas', 'description': 'Grid o lista', 'color': const Color(0xFF6366F1)},
    {'icon': Icons.calendar_month, 'title': 'Calendario', 'description': 'Visualización por fechas', 'color': const Color(0xFF14B8A6)},
    {'icon': Icons.palette, 'title': 'Personalización', 'description': 'Colores y formas', 'color': const Color(0xFFEC4899)},
  ];

  // ✅ CORRECCIÓN: Navegación simple y segura
  void _goBack() {
    if (_isNavigating) return;
    _isNavigating = true;
    
    debugPrint('🔙 [HelpScreen] Navegando de vuelta a Settings');
    
    // Pequeña pausa para evitar conflictos
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) {
        _isNavigating = false;
        return;
      }
      try {
        // Navegar directamente a Settings
        context.go('/settings');
        debugPrint('✅ [HelpScreen] Navegación exitosa a Settings');
      } catch (e) {
        debugPrint('❌ [HelpScreen] Error: $e');
        // Fallback
        context.go('/settings');
      } finally {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _isNavigating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 800;
    final isTablet = screenSize.width >= 600 && screenSize.width < 800;
    final filteredFaqs = _getFilteredFaqs();

    // ✅ SIN PopScope - navegación solo desde AppBar
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(isDarkMode, isDesktop),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildBanner(isDarkMode, isDesktop),
            Padding(
              padding: EdgeInsets.all(isDesktop ? 32 : 16),
              child: Column(
                children: [
                  _buildSearchBar(isDarkMode, isDesktop),
                  const SizedBox(height: 24),
                  _buildTabs(isDarkMode, isDesktop),
                  const SizedBox(height: 24),
                  _activeTab == 0 ? _buildFaqContent(isDarkMode, filteredFaqs, isDesktop) : const SizedBox.shrink(),
                  _activeTab == 1 ? _buildContactContent(isDarkMode, isDesktop, isTablet) : const SizedBox.shrink(),
                  _activeTab == 2 ? _buildAboutContent(isDarkMode, isDesktop, isTablet) : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode, bool isDesktop) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.help_outline, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Text(
            'Centro de Ayuda',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      centerTitle: false,
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: _goBack,
      ),
    );
  }

  Widget _buildBanner(bool isDarkMode, bool isDesktop) {
    return Container(
      height: isDesktop ? 180 : 140,
      width: double.infinity,
      margin: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF1E3A8A), const Color(0xFF4C1D95), const Color(0xFF831843)]
              : [const Color(0xFF3B82F6), const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 32 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          ...List.generate(3, (index) {
            return Positioned(
              top: -20 + (index * 40),
              right: -20 + (index * 30),
              child: Container(
                width: 80 + (index * 20),
                height: 80 + (index * 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08 - (index * 0.02)),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
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
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFA7F3D0)],
                  ).createShader(bounds),
                  child: Text(
                    'QuickNote',
                    style: TextStyle(
                      fontSize: isDesktop ? 36 : 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Centro de Ayuda y Soporte v2.8.0',
                    style: TextStyle(
                      fontSize: isDesktop ? 13 : 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode, bool isDesktop) {
    return Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Buscar en el centro de ayuda...',
            hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white54 : Colors.grey.shade600),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: isDarkMode ? Colors.white54 : Colors.grey.shade600),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(bool isDarkMode, bool isDesktop) {
    final tabs = [
      {'icon': Icons.quiz, 'label': 'Preguntas Frecuentes'},
      {'icon': Icons.contact_support, 'label': 'Contacto'},
      {'icon': Icons.info, 'label': 'Acerca de'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
        ),
      ),
      child: isDesktop
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(tabs.length, (index) => _buildTabButton(index, tabs[index], isDarkMode, isDesktop)),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(tabs.length, (index) => _buildTabButton(index, tabs[index], isDarkMode, isDesktop)),
              ),
            ),
    );
  }

  Widget _buildTabButton(int index, Map<String, dynamic> tab, bool isDarkMode, bool isDesktop) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: isDesktop ? 14 : 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? Colors.blue.shade800.withValues(alpha: 0.3) : Colors.blue.shade50)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab['icon'], size: isDesktop ? 20 : 18, color: isSelected ? Colors.blue : (isDarkMode ? Colors.white54 : Colors.grey.shade600)),
            const SizedBox(width: 8),
            Text(
              tab['label'],
              style: TextStyle(
                fontSize: isDesktop ? 14 : 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.blue : (isDarkMode ? Colors.white70 : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqContent(bool isDarkMode, List<Map<String, dynamic>> faqs, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryChips(isDarkMode, isDesktop),
        const SizedBox(height: 24),
        if (faqs.isEmpty)
          _buildEmptyState(isDarkMode)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              final faq = faqs[index];
              final isExpanded = _expandedFaq == faq['question'];
              final categoryColor = _getCategoryColor(faq['category']);
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isExpanded
                        ? categoryColor.withValues(alpha: 0.5)
                        : (isDarkMode ? Colors.white24 : Colors.grey.shade200),
                  ),
                  boxShadow: isExpanded
                      ? [
                          BoxShadow(
                            color: categoryColor.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [categoryColor.withValues(alpha: 0.2), categoryColor.withValues(alpha: 0.1)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(faq['icon'], size: 20, color: categoryColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            faq['question'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isDesktop ? 15 : 14,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: categoryColor,
                    ),
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _expandedFaq = expanded ? faq['question'] : null;
                      });
                    },
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: categoryColor.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          faq['answer'],
                          style: TextStyle(
                            fontSize: isDesktop ? 14 : 13,
                            height: 1.6,
                            color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCategoryChips(bool isDarkMode, bool isDesktop) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category['name'];
          final color = category['color'] as Color;
          
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              selected: isSelected,
              label: Text(category['name']),
              avatar: Icon(category['icon'], size: 18, color: isSelected ? Colors.white : color),
              onSelected: (_) => setState(() => _selectedCategory = category['name']),
              backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              selectedColor: color,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : Colors.grey.shade700),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : color.withValues(alpha: 0.3),
                ),
              ),
              tooltip: category['description'],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactContent(bool isDarkMode, bool isDesktop, bool isTablet) {
    final contactOptions = [
      {'icon': Icons.email, 'title': 'Correo electrónico', 'subtitle': 'soporte@quicknote.com', 'color': const Color(0xFFEF4444), 'action': () => _launchUrl('mailto:soporte@quicknote.com')},
      {'icon': Icons.star, 'title': 'Feedback y sugerencias', 'subtitle': 'Comparte tus ideas para mejorar', 'color': const Color(0xFFF59E0B), 'action': () => ToastMessage.info(context, 'Feedback - Próximamente disponible')},
      {'icon': Icons.bug_report, 'title': 'Reportar un problema', 'subtitle': 'Ayúdanos a mejorar QuickNote', 'color': const Color(0xFF8B5CF6), 'action': () => ToastMessage.info(context, 'Reporte - Próximamente disponible')},
    ];

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isDesktop ? 32 : 24),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: isDesktop ? 100 : 80,
                height: isDesktop ? 100 : 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(isDesktop ? 28 : 24),
                ),
                child: Icon(Icons.support_agent, size: isDesktop ? 44 : 36, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                '¿Necesitas ayuda personalizada?',
                style: TextStyle(
                  fontSize: isDesktop ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Estoy aquí para ayudarte. Puedes contactarme por cualquiera de estos medios.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 13,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 28),
              Column(
                children: contactOptions.map((option) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildContactOption(option, isDarkMode),
                )).toList(),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [Colors.blue.shade900.withValues(alpha: 0.3), Colors.purple.shade900.withValues(alpha: 0.3)]
                        : [Colors.blue.shade50, Colors.purple.shade50],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
                  ),
                ),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildResponseTime('Email', '< 24h', const Color(0xFF10B981)),
                    _buildResponseTime('Feedback', '< 48h', const Color(0xFF3B82F6)),
                    if (isDesktop) _buildResponseTime('Urgente', '< 12h', const Color(0xFFEF4444)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactOption(Map<String, dynamic> option, bool isDarkMode) {
    final color = option['color'] as Color;
    return GestureDetector(
      onTap: option['action'] as VoidCallback,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(option['icon'], color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option['subtitle'],
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseTime(String label, String time, Color color) {
    return Column(
      children: [
        Text(
          time,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildAboutContent(bool isDarkMode, bool isDesktop, bool isTablet) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isDesktop ? 32 : 24),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.apps, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu gestor de notas inteligente',
                          style: TextStyle(
                            fontSize: isDesktop ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'QuickNote es una aplicación moderna de gestión de notas diseñada para ayudarte a organizar tus ideas, tareas y recordatorios con la máxima eficiencia. Con soporte offline, passkeys y backups programados.',
                          style: TextStyle(
                            fontSize: isDesktop ? 14 : 13,
                            height: 1.5,
                            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.code, size: 18, color: Color(0xFF8B5CF6)),
                        SizedBox(width: 8),
                        Text(
                          'Tecnologías que lo hacen posible',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildTechBadge('Flutter', const Color(0xFF3B82F6), isDarkMode),
                        _buildTechBadge('Dart', const Color(0xFF06B6D4), isDarkMode),
                        _buildTechBadge('FastAPI', const Color(0xFF10B981), isDarkMode),
                        _buildTechBadge('Supabase', const Color(0xFF8B5CF6), isDarkMode),
                        _buildTechBadge('PostgreSQL', const Color(0xFF3B82F6), isDarkMode),
                        _buildTechBadge('WebAuthn', const Color(0xFF6366F1), isDarkMode),
                        _buildTechBadge('Hive', const Color(0xFFF59E0B), isDarkMode),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Icon(Icons.star, size: 20, color: Color(0xFFF59E0B)),
                  SizedBox(width: 8),
                  Text(
                    'Características principales',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isDesktop ? (isTablet ? 3 : 4) : 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.3,
                children: _features.map((feature) {
                  final color = feature['color'] as Color;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(feature['icon'], color: color, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          feature['title'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature['description'],
                          style: TextStyle(
                            fontSize: 10,
                            color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [Colors.blue.shade900.withValues(alpha: 0.3), Colors.purple.shade900.withValues(alpha: 0.3)]
                        : [Colors.blue.shade50, Colors.purple.shade50],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.info, color: Color(0xFF3B82F6), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Versión actual: v2.8.0',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '✨ NUEVO: Modo offline completo, Passkeys/WebAuthn, Backup programado, Importación de notas, Búsqueda avanzada y optimizaciones de rendimiento.',
                            style: TextStyle(
                              fontSize: isDesktop ? 13 : 12,
                              height: 1.4,
                              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  const Icon(Icons.favorite, size: 16, color: Color(0xFFEC4899)),
                  Text(
                    'Centro de ayuda de QuickNote v2.8.0',
                    style: TextStyle(
                      fontSize: isDesktop ? 13 : 12,
                      color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  const Icon(Icons.favorite, size: 16, color: Color(0xFFEC4899)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '¿No encuentras lo que buscas? Contáctame directamente y te ayudaré a resolver tu consulta.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 12 : 11,
                  color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTechBadge(String name, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 80, color: isDarkMode ? Colors.white24 : Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'No se encontraron resultados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otros términos de búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredFaqs() {
    var faqs = List<Map<String, dynamic>>.from(_faqs);
    
    if (_selectedCategory != 'Todos') {
      faqs = faqs.where((f) => f['category'] == _selectedCategory).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      faqs = faqs.where((f) =>
        f['question'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
        f['answer'].toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return faqs;
  }

  Color _getCategoryColor(String category) {
    final categoryData = _categories.firstWhere(
      (c) => c['name'] == category,
      orElse: () => {'color': const Color(0xFF3B82F6)},
    );
    return categoryData['color'];
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
}