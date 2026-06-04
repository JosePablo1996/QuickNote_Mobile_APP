// lib/app.dart
// Aplicación principal de QuickNote - VERSIÓN CORREGIDA CON REDIRECT INTELIGENTE
// ✅ ORDEN DE RUTAS CORREGIDO: Rutas específicas ANTES que rutas con parámetros
// ✅ Agregado redirect para manejar deep links del widget de Android
// ✅ Eliminadas rutas duplicadas que causaban conflictos
// ✅ Rutas unificadas: usar /notes/archived y /notes/favorites
// ✅ Manejo de noteId inválidos desde el widget
// ✅ Integrado apiNavigatorKey para manejo global de 401
// ✅ BackupSchedulerScreen eliminado temporalmente por problemas con WorkManager

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicknote/core/api/api_client.dart';
import 'package:quicknote/core/constants/app_theme.dart';
import 'package:quicknote/providers/theme_provider.dart';
import 'package:quicknote/screens/splash_screen.dart';
import 'package:quicknote/screens/auth/login_screen.dart';
import 'package:quicknote/screens/auth/register_screen.dart';
import 'package:quicknote/screens/auth/forgot_password_screen.dart';
import 'package:quicknote/screens/auth/otp_verification_screen.dart';
import 'package:quicknote/screens/auth/biometric_login_screen.dart';
import 'package:quicknote/screens/auth/two_factor_screen.dart';
import 'package:quicknote/screens/auth/welcome_screen.dart';
import 'package:quicknote/screens/notes/home_screen.dart';
import 'package:quicknote/screens/notes/note_detail_screen.dart';
import 'package:quicknote/screens/notes/create_note_screen.dart';
import 'package:quicknote/screens/notes/note_editor_screen.dart';
import 'package:quicknote/screens/notes/note_customizer_screen.dart';
import 'package:quicknote/screens/notes/archived_screen.dart';
import 'package:quicknote/screens/notes/favorites_screen.dart';
import 'package:quicknote/screens/notes/trash_screen.dart';
import 'package:quicknote/screens/calendar/calendar_screen.dart';
import 'package:quicknote/screens/tags/tags_screen.dart';
import 'package:quicknote/screens/tags/tag_notes_screen.dart';
import 'package:quicknote/screens/backup/backup_screen.dart';
import 'package:quicknote/screens/settings/settings_screen.dart';
import 'package:quicknote/screens/settings/profile_screen.dart';
import 'package:quicknote/screens/settings/change_password_screen.dart';
import 'package:quicknote/screens/settings/developer_screen.dart';
import 'package:quicknote/screens/settings/help_screen.dart';
import 'package:quicknote/screens/settings/changelog_screen.dart';
import 'package:quicknote/screens/settings/two_factor_setup_screen.dart';
// import 'package:quicknote/screens/settings/backup_scheduler_screen.dart'; // ELIMINADO - WorkManager desactivado

// ============================================
// LOGGER DEL ROUTER
// ============================================

class _RouterLogger {
  static void info(String message) {
    debugPrint('🔍 [Router] $message');
  }
  static void success(String message) {
    debugPrint('✅ [Router] $message');
  }
  static void warning(String message) {
    debugPrint('⚠️ [Router] $message');
  }
  static void error(String message) {
    debugPrint('❌ [Router] $message');
  }
  static void deepLink(String message) {
    debugPrint('🔗 [Router DeepLink] $message');
  }
}

// ============================================
// CONFIGURACIÓN DE RUTAS CON REDIRECT INTELIGENTE
// ============================================

final GoRouter _router = GoRouter(
  initialLocation: '/',
  
  // ✅ Usar el navigatorKey global para manejar 401
  navigatorKey: apiNavigatorKey,
  
  // 🔥 REDIRECT INTELIGENTE - Maneja deep links del widget
  redirect: (BuildContext context, GoRouterState state) {
    final uri = state.uri;
    final path = state.matchedLocation;
    final queryParams = uri.queryParameters;
    
    _RouterLogger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _RouterLogger.info('📍 Redirect evaluando: $path');
    _RouterLogger.info('📋 Full URI: ${uri.toString()}');
    _RouterLogger.info('📋 Query params: $queryParams');
    _RouterLogger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // ============================================
    // CASO 0: RUTAS ESPECÍFICAS VÁLIDAS - PERMITIR PASAR
    // ============================================
    
    // Estas rutas son válidas y deben manejarse por sus builders específicos
    const validSpecificRoutes = [
      '/', '/login', '/register', '/forgot-password', '/otp-login',
      '/biometric-login', '/verify-2fa', '/welcome', '/notes',
      '/notes/archived', '/notes/favorites', '/notes/new',
      '/trash', '/settings', '/calendar', '/tags', '/backup',
      '/profile', '/change-password', '/two-factor-setup',
      '/developer', '/help', '/changelog'
    ];
    
    if (validSpecificRoutes.contains(path)) {
      _RouterLogger.info('✅ Ruta específica válida: $path');
      return null;
    }
    
    // ============================================
    // CASO 1: DEEP LINK DEL WIDGET DE ANDROID
    // El widget puede enviar: noteId, target, o tab
    // ============================================
    
    if (queryParams.containsKey('noteId')) {
      final noteId = queryParams['noteId'];
      final targetTab = queryParams['target'];
      
      _RouterLogger.deepLink('🎯 Deep link detectado!');
      _RouterLogger.deepLink('   noteId: $noteId');
      _RouterLogger.deepLink('   target: $targetTab');
      
      // 🎯 Sub-caso 1A: Widget quiere ir a FAVORITOS
      if (targetTab == 'favorites') {
        _RouterLogger.success('⭐ Redirigiendo a favoritos (ignorando noteId)');
        return '/notes/favorites';
      }
      
      // 🎯 Sub-caso 1B: Widget quiere ir a ARCHIVADOS
      if (targetTab == 'archived') {
        _RouterLogger.success('📦 Redirigiendo a archivados (ignorando noteId)');
        return '/notes/archived';
      }
      
      // 🎯 Sub-caso 1C: Widget quiere ir a TRASH
      if (targetTab == 'trash') {
        _RouterLogger.success('🗑️ Redirigiendo a papelera (ignorando noteId)');
        return '/trash';
      }
      
      // 🎯 Sub-caso 1D: Widget quiere ir a una NOTA ESPECÍFICA
      if (noteId != null && noteId.isNotEmpty && 
          noteId != 'archived' && noteId != 'favorites' && noteId != 'new') {
        _RouterLogger.info('📝 Deep link a nota específica: $noteId');
        // Dejar que pase, la validación se hará en NoteDetailScreen
        return null;
      }
      
      // Si el noteId es inválido (archived, favorites, new)
      if (noteId == 'archived' || noteId == 'favorites' || noteId == 'new') {
        _RouterLogger.warning('⚠️ noteId inválido detectado: $noteId → redirigiendo a /notes');
        return '/notes';
      }
    }
    
    // ============================================
    // CASO 2: RUTAS CORTAS DEL WIDGET (sin noteId)
    // El widget puede enviar solo ?tab=favorites
    // ============================================
    
    if (queryParams.containsKey('tab')) {
      final tab = queryParams['tab'];
      _RouterLogger.info('📱 Widget tab detectado: $tab');
      
      switch (tab) {
        case 'favorites':
          _RouterLogger.success('⭐ Redirigiendo a favoritos');
          return '/notes/favorites';
        case 'archived':
          _RouterLogger.success('📦 Redirigiendo a archivados');
          return '/notes/archived';
        case 'trash':
          _RouterLogger.success('🗑️ Redirigiendo a papelera');
          return '/trash';
        case 'settings':
          _RouterLogger.success('⚙️ Redirigiendo a ajustes');
          return '/settings';
        default:
          _RouterLogger.warning('⚠️ Tab desconocida: $tab');
          return null;
      }
    }
    
    // ============================================
    // CASO 3: RUTAS ANTIGUAS - REDIRIGIR
    // ============================================
    
    if (path == '/favorites' || path == '/favorite-notes') {
      _RouterLogger.warning('🔄 Ruta antigua detectada: $path → redirigiendo a /notes/favorites');
      return '/notes/favorites';
    }
    
    if (path == '/archived' || path == '/archived-notes') {
      _RouterLogger.warning('🔄 Ruta antigua detectada: $path → redirigiendo a /notes/archived');
      return '/notes/archived';
    }
    
    // ============================================
    // CASO 4: PREVENIR NAVEGACIÓN CON ID INVÁLIDO
    // Si la ruta es /notes/:id pero el ID es una palabra reservada
    // ============================================
    
    if (path.startsWith('/notes/') && 
        !path.startsWith('/notes/archived') && 
        !path.startsWith('/notes/favorites') &&
        !path.startsWith('/notes/new')) {
      
      final potentialId = path.replaceFirst('/notes/', '');
      
      // Validar que no sea una palabra reservada
      if (potentialId == 'archived' || potentialId == 'favorites' || potentialId == 'new') {
        _RouterLogger.warning('⚠️ ID de nota inválido detectado: "$potentialId" → redirigiendo a /notes');
        return '/notes';
      }
    }
    
    // ============================================
    // Sin redirección
    // ============================================
    return null;
  },
  
  routes: <RouteBase>[
    // ============================================
    // RUTAS PÚBLICAS
    // ============================================
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (BuildContext context, GoRouterState state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (BuildContext context, GoRouterState state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/otp-login',
      name: 'otp-login',
      builder: (BuildContext context, GoRouterState state) => const OtpVerificationScreen(),
    ),
    GoRoute(
      path: '/biometric-login',
      name: 'biometric-login',
      builder: (BuildContext context, GoRouterState state) => const BiometricLoginScreen(),
    ),
    GoRoute(
      path: '/verify-2fa',
      name: 'verify-2fa',
      builder: (BuildContext context, GoRouterState state) {
        final tempToken = state.uri.queryParameters['token'] ?? '';
        final email = state.uri.queryParameters['email'] ?? '';
        final password = state.uri.queryParameters['password'] ?? '';
        final userFullName = state.uri.queryParameters['name'];
        final userAvatar = state.uri.queryParameters['avatar'];
        final userBanner = state.uri.queryParameters['banner'];
        
        final decodedName = userFullName != null ? Uri.decodeComponent(userFullName) : null;
        final decodedAvatar = userAvatar != null ? Uri.decodeComponent(userAvatar) : null;
        final decodedBanner = userBanner != null ? Uri.decodeComponent(userBanner) : null;
        
        return TwoFactorScreen(
          tempToken: tempToken,
          email: email,
          password: password,
          userFullName: decodedName,
          userAvatar: decodedAvatar,
          userBanner: decodedBanner,
        );
      },
    ),
    
    // ============================================
    // RUTAS PRINCIPALES (NOTAS)
    // ============================================
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (BuildContext context, GoRouterState state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/notes',
      name: 'notes',
      builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
    ),
    
    // ============================================
    // ⚠️ IMPORTANTE: PRIMERO LAS RUTAS ESPECÍFICAS
    // ANTES que las rutas con parámetros
    // ============================================
    
    // 📌 RUTAS PARA APP_BOTTOM_NAV - RUTAS ESPECÍFICAS
    GoRoute(
      path: '/notes/archived',
      name: 'archived-notes',
      builder: (BuildContext context, GoRouterState state) {
        _RouterLogger.success('📦 Cargando pantalla de archivados');
        return const ArchivedScreen();
      },
    ),
    GoRoute(
      path: '/notes/favorites',
      name: 'favorite-notes',
      builder: (BuildContext context, GoRouterState state) {
        _RouterLogger.success('⭐ Cargando pantalla de favoritos');
        return const FavoritesScreen();
      },
    ),
    
    // 📌 RUTA DE CREACIÓN
    GoRoute(
      path: '/notes/new',
      name: 'create-note',
      builder: (BuildContext context, GoRouterState state) {
        _RouterLogger.success('➕ Cargando pantalla de creación');
        return const CreateNoteScreen();
      },
    ),
    
    // 📌 RUTA DE PAPELERA
    GoRoute(
      path: '/trash',
      name: 'trash',
      builder: (BuildContext context, GoRouterState state) => const TrashScreen(),
    ),
    
    // 📌 RUTA DE CONFIGURACIÓN
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (BuildContext context, GoRouterState state) => const SettingsScreen(),
    ),
    
    // ============================================
    // RUTAS CON PARÁMETROS - VAN DESPUÉS DE LAS ESPECÍFICAS
    // ============================================
    
    // 📌 EDICIÓN DE NOTA
    GoRoute(
      path: '/notes/:id/edit',
      name: 'edit-note',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id']!;
        _RouterLogger.info('✏️ Navegando a edición de nota: $id');
        return NoteEditorScreen(noteId: id);
      },
    ),
    
    // 📌 PERSONALIZACIÓN DE NOTA
    GoRoute(
      path: '/notes/:id/customize',
      name: 'note-customize',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id']!;
        _RouterLogger.info('🎨 Navegando a personalización de nota: $id');
        return NoteCustomizerScreen(noteId: id);
      },
    ),
    
    // 📌 DETALLE DE NOTA - RUTA GENÉRICA (DEBE IR AL FINAL)
    GoRoute(
      path: '/notes/:id',
      name: 'note-detail',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id']!;
        
        // Validación de seguridad: no debería llegar aquí con IDs reservados
        if (id == 'archived' || id == 'favorites' || id == 'new') {
          _RouterLogger.error('❌ Error: ID reservado "$id" llegó a note-detail');
          // Redirigir silenciosamente a home
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/notes');
          });
          return const SizedBox.shrink();
        }
        
        _RouterLogger.info('📝 Navegando a detalle de nota: $id');
        return NoteDetailScreen(noteId: id);
      },
    ),
    
    // ============================================
    // RUTAS DE CALENDARIO
    // ============================================
    GoRoute(
      path: '/calendar',
      name: 'calendar',
      builder: (BuildContext context, GoRouterState state) => const CalendarScreen(),
    ),
    
    // ============================================
    // RUTAS DE ETIQUETAS
    // ============================================
    GoRoute(
      path: '/tags',
      name: 'tags',
      builder: (BuildContext context, GoRouterState state) => const TagsScreen(),
    ),
    GoRoute(
      path: '/tags/:tag',
      name: 'tag-notes',
      builder: (BuildContext context, GoRouterState state) {
        final tag = state.pathParameters['tag']!;
        _RouterLogger.info('# Navegando a etiqueta: $tag');
        return TagNotesScreen(tagName: tag);
      },
    ),
    
    // ============================================
    // RUTAS DE BACKUP
    // ============================================
    GoRoute(
      path: '/backup',
      name: 'backup',
      builder: (BuildContext context, GoRouterState state) => const BackupScreen(),
    ),
    
    // ============================================
    // RUTAS DE CONFIGURACIÓN Y PERFIL
    // ============================================
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (BuildContext context, GoRouterState state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/change-password',
      name: 'change-password',
      builder: (BuildContext context, GoRouterState state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/two-factor-setup',
      name: 'two-factor-setup',
      builder: (BuildContext context, GoRouterState state) => const TwoFactorSetupScreen(),
    ),
    GoRoute(
      path: '/developer',
      name: 'developer',
      builder: (BuildContext context, GoRouterState state) => const DeveloperScreen(),
    ),
    GoRoute(
      path: '/help',
      name: 'help',
      builder: (BuildContext context, GoRouterState state) => const HelpScreen(),
    ),
    GoRoute(
      path: '/changelog',
      name: 'changelog',
      builder: (BuildContext context, GoRouterState state) => const ChangelogScreen(),
    ),
    
    // ✅ BackupSchedulerScreen ELIMINADO temporalmente
    // GoRoute(
    //   path: '/backup-scheduler',
    //   name: 'backup-scheduler',
    //   builder: (BuildContext context, GoRouterState state) => const BackupSchedulerScreen(),
    // ),
    
    // ============================================
    // REDIRECCIÓN PARA RUTAS NO ENCONTRADAS
    // ============================================
    GoRoute(
      path: '/:any',
      name: 'not-found',
      redirect: (BuildContext context, GoRouterState state) {
        _RouterLogger.warning('❌ Ruta no encontrada: ${state.matchedLocation} → redirigiendo a /notes');
        return '/notes';
      },
    ),
  ],
);

// ============================================
// WIDGET PRINCIPAL DE LA APLICACIÓN
// ============================================

class QuickNoteApp extends ConsumerWidget {
  const QuickNoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    _RouterLogger.success('🚀 Iniciando QuickNoteApp');
    
    return MaterialApp.router(
      title: 'QuickNote',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}