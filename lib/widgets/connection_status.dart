// lib/widgets/connection_status.dart
// Indicador de estado de conexión - CON DISEÑO COMPLETO Y ANIMACIONES
// Similar a la versión de React de QuickNote

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================
// TIPOS DE ESTADO DE CONEXIÓN
// ============================================

enum ConnectionStatus {
  online,
  offline,
  reconnecting,
  poor,
}

extension ConnectionStatusExtension on ConnectionStatus {
  String get label {
    switch (this) {
      case ConnectionStatus.online:
        return 'Conectado';
      case ConnectionStatus.offline:
        return 'Sin conexión';
      case ConnectionStatus.reconnecting:
        return 'Reconectando...';
      case ConnectionStatus.poor:
        return 'Conexión inestable';
    }
  }

  IconData get icon {
    switch (this) {
      case ConnectionStatus.online:
        return Icons.wifi;
      case ConnectionStatus.offline:
        return Icons.wifi_off;
      case ConnectionStatus.reconnecting:
        return Icons.sync;
      case ConnectionStatus.poor:
        return Icons.signal_wifi_bad;
    }
  }

  Color get color {
    switch (this) {
      case ConnectionStatus.online:
        return const Color(0xFF10B981);
      case ConnectionStatus.offline:
        return const Color(0xFFEF4444);
      case ConnectionStatus.reconnecting:
        return const Color(0xFFF59E0B);
      case ConnectionStatus.poor:
        return const Color(0xFFF59E0B);
    }
  }

  List<Color> get gradient {
    switch (this) {
      case ConnectionStatus.online:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case ConnectionStatus.offline:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case ConnectionStatus.reconnecting:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case ConnectionStatus.poor:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
    }
  }
}

// ============================================
// MODELO DE ESTADO DE CONEXIÓN
// ============================================

class ConnectionStateModel {
  final ConnectionStatus status;
  final int pendingSync;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  const ConnectionStateModel({
    required this.status,
    this.pendingSync = 0,
    this.lastSyncTime,
    this.errorMessage,
  });

  bool get isOnline => status == ConnectionStatus.online;
  bool get isOffline => status == ConnectionStatus.offline;
  bool get isReconnecting => status == ConnectionStatus.reconnecting;
  bool get hasPendingSync => pendingSync > 0;

  String get formattedLastSync {
    if (lastSyncTime == null) return 'Nunca';
    final diff = DateTime.now().difference(lastSyncTime!);
    if (diff.inSeconds < 60) return 'hace ${diff.inSeconds} segundos';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} minutos';
    if (diff.inHours < 24) return 'hace ${diff.inHours} horas';
    return 'hace ${diff.inDays} días';
  }
}

// ============================================
// WIDGET DE ESTADO DE CONEXIÓN
// ============================================

class ConnectionStatusWidget extends StatefulWidget {
  final bool? isOnline;
  final VoidCallback? onRetry;
  final VoidCallback? onSync;
  final int pendingSync;
  final VoidCallback? onRefresh;
  final bool showDetails;
  final Duration autoHideDuration;

  const ConnectionStatusWidget({
    super.key,
    this.isOnline,
    this.onRetry,
    this.onSync,
    this.pendingSync = 0,
    this.onRefresh,
    this.showDetails = true,
    this.autoHideDuration = const Duration(seconds: 5),
  });

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoHideTimer;
  bool _isVisible = true;

  ConnectionStatus _internalStatus = ConnectionStatus.online;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // ✅ CORREGIDO: _slideAnimation debe ser Animation<Offset>
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _animationController.forward();
    _startAutoHideTimer();
    _initNetworkMonitoring();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    if (widget.isOnline == true && widget.pendingSync == 0) {
      _autoHideTimer = Timer(widget.autoHideDuration, () {
        if (mounted) {
          setState(() => _isVisible = false);
          _animationController.reverse();
        }
      });
    }
  }

  void _initNetworkMonitoring() {
    // Monitoreo básico de red
    _internalStatus = (widget.isOnline ?? true) ? ConnectionStatus.online : ConnectionStatus.offline;
  }

  ConnectionStateModel get _state {
    // ✅ CORREGIDO: conversión correcta de bool a ConnectionStatus
    final status = (widget.isOnline ?? true) ? ConnectionStatus.online : ConnectionStatus.offline;
    return ConnectionStateModel(
      status: status,
      pendingSync: widget.pendingSync,
      lastSyncTime: _lastSyncTime,
    );
  }

  @override
  void didUpdateWidget(covariant ConnectionStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline != oldWidget.isOnline ||
        widget.pendingSync != oldWidget.pendingSync) {
      _startAutoHideTimer();
      if (widget.isOnline == true && oldWidget.isOnline == false) {
        _showReconnectedMessage();
      }
    }
  }

  void _showReconnectedMessage() {
    setState(() {
      _isVisible = true;
      _internalStatus = ConnectionStatus.reconnecting;
    });
    _animationController.forward();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _internalStatus = ConnectionStatus.online);
        _startAutoHideTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (!_isVisible && state.isOnline && !state.hasPendingSync) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildContent(state, isDarkMode),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(ConnectionStateModel state, bool isDarkMode) {
    final colors = state.status.gradient;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [Colors.grey.shade800, Colors.grey.shade900]
              : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          left: BorderSide(
            color: state.status.color,
            width: 4,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contenido principal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono animado
                _buildAnimatedIcon(state, isDarkMode),
                const SizedBox(width: 12),
                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.status.label,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: state.status.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getSubtitle(state),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                      if (widget.showDetails && state.hasPendingSync)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${state.pendingSync} cambio${state.pendingSync != 1 ? 's' : ''} pendiente${state.pendingSync != 1 ? 's' : ''}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.amber.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Botones de acción
                _buildActionButtons(state, isDarkMode),
              ],
            ),
          ),
          // Barra de progreso para reconexión
          if (state.isReconnecting)
            _buildReconnectingProgress(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(ConnectionStateModel state, bool isDarkMode) {
    final colors = state.status.gradient;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: state.isReconnecting
          ? TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 1),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 2 * 3.14159,
                  child: Icon(
                    state.status.icon,
                    size: 20,
                    color: Colors.white,
                  ),
                );
              },
              onEnd: () {},
            )
          : Icon(
              state.status.icon,
              size: 20,
              color: Colors.white,
            ),
    );
  }

  Widget _buildActionButtons(ConnectionStateModel state, bool isDarkMode) {
    final colors = state.status.gradient;

    if (state.isOffline) {
      return Row(
        children: [
          if (widget.onRetry != null)
            _buildActionButton(
              icon: Icons.refresh,
              label: 'Reintentar',
              onPressed: widget.onRetry!,
              colors: colors,
              isDarkMode: isDarkMode,
            ),
        ],
      );
    }

    if (state.hasPendingSync && widget.onSync != null) {
      return Row(
        children: [
          _buildActionButton(
            icon: Icons.sync,
            label: 'Sincronizar',
            onPressed: () {
              widget.onSync?.call();
              _lastSyncTime = DateTime.now();
            },
            colors: colors,
            isDarkMode: isDarkMode,
          ),
        ],
      );
    }

    if (widget.onRefresh != null) {
      return Row(
        children: [
          _buildActionButton(
            icon: Icons.refresh,
            label: 'Actualizar',
            onPressed: widget.onRefresh!,
            colors: colors,
            isDarkMode: isDarkMode,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required List<Color> colors,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReconnectingProgress(bool isDarkMode) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(seconds: 3),
      builder: (context, value, child) {
        return LinearProgressIndicator(
          value: value,
          backgroundColor: isDarkMode ? Colors.white24 : Colors.grey.shade200,
          color: const Color(0xFFF59E0B),
          minHeight: 3,
        );
      },
      onEnd: () {},
    );
  }

  String _getSubtitle(ConnectionStateModel state) {
    if (state.isOffline) {
      return 'Los cambios se guardarán localmente';
    }
    if (state.isReconnecting) {
      return 'Restableciendo conexión...';
    }
    if (state.hasPendingSync) {
      return 'Hay cambios pendientes de sincronizar';
    }
    if (widget.showDetails && state.lastSyncTime != null) {
      return 'Última sincronización: ${state.formattedLastSync}';
    }
    return 'Trabajando en línea';
  }
}

// ============================================
// VARIANTES PREDEFINIDAS
// ============================================

/// Barra de estado compacta (solo icono + estado)
class ConnectionStatusCompact extends StatelessWidget {
  final bool isOnline;
  final VoidCallback? onRetry;

  const ConnectionStatusCompact({
    super.key,
    required this.isOnline,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final status = isOnline ? ConnectionStatus.online : ConnectionStatus.offline;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 14,
            color: status.color,
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: status.color,
            ),
          ),
          if (!isOnline && onRetry != null)
            GestureDetector(
              onTap: onRetry,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.refresh,
                  size: 12,
                  color: status.color,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Banner de estado (para pantalla completa)
class ConnectionStatusBanner extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const ConnectionStatusBanner({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final status = ConnectionStatus.offline;

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              status.icon,
              size: 48,
              color: status.color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            customMessage ?? 'Sin conexión a internet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Verifica tu conexión y vuelve a intentarlo',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('REINTENTAR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: status.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}