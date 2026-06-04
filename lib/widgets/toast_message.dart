// lib/widgets/toast_message.dart
// Notificaciones tipo toast - CON DISEÑO COMPLETO Y ANIMACIONES
// CORREGIDO: Acepta BuildContext como parámetro opcional para compatibilidad

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================
// TIPOS DE TOAST
// ============================================

enum ToastType {
  success,
  error,
  warning,
  info,
}

extension ToastTypeExtension on ToastType {
  IconData get icon {
    switch (this) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.warning:
        return Icons.warning_amber;
      case ToastType.info:
        return Icons.info;
    }
  }

  Color get color {
    switch (this) {
      case ToastType.success:
        return const Color(0xFF10B981);
      case ToastType.error:
        return const Color(0xFFEF4444);
      case ToastType.warning:
        return const Color(0xFFF59E0B);
      case ToastType.info:
        return const Color(0xFF3B82F6);
    }
  }

  List<Color> get gradient {
    switch (this) {
      case ToastType.success:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case ToastType.error:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case ToastType.warning:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case ToastType.info:
        return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
    }
  }
}

// ============================================
// MODELO DE TOAST
// ============================================

class ToastModel {
  final String id;
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onAction;

  ToastModel({
    required this.id,
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 3),
    this.onTap,
    this.actionLabel,
    this.onAction,
  });
}

// ============================================
// GESTOR DE TOAST (SINGLETON)
// ============================================

class ToastManager {
  static final ToastManager _instance = ToastManager._internal();
  factory ToastManager() => _instance;
  ToastManager._internal();

  final List<ToastModel> _toasts = [];
  final List<void Function(List<ToastModel>)> _listeners = [];

  void addListener(void Function(List<ToastModel>) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(List<ToastModel>) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_toasts.toList());
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void show(ToastModel toast) {
    _toasts.insert(0, toast);
    _notifyListeners();

    Future.delayed(toast.duration, () {
      _toasts.removeWhere((t) => t.id == toast.id);
      _notifyListeners();
    });
  }

  void showSuccess(String message, {Duration? duration, VoidCallback? onTap}) {
    show(ToastModel(
      id: _generateId(),
      message: message,
      type: ToastType.success,
      duration: duration ?? const Duration(seconds: 3),
      onTap: onTap,
    ));
  }

  void showError(String message, {Duration? duration, VoidCallback? onTap}) {
    show(ToastModel(
      id: _generateId(),
      message: message,
      type: ToastType.error,
      duration: duration ?? const Duration(seconds: 4),
      onTap: onTap,
    ));
  }

  void showWarning(String message, {Duration? duration, VoidCallback? onTap}) {
    show(ToastModel(
      id: _generateId(),
      message: message,
      type: ToastType.warning,
      duration: duration ?? const Duration(seconds: 3),
      onTap: onTap,
    ));
  }

  void showInfo(String message, {Duration? duration, VoidCallback? onTap}) {
    show(ToastModel(
      id: _generateId(),
      message: message,
      type: ToastType.info,
      duration: duration ?? const Duration(seconds: 3),
      onTap: onTap,
    ));
  }

  void clearAll() {
    _toasts.clear();
    _notifyListeners();
  }
}

// ============================================
// WIDGET DE TOAST INDIVIDUAL
// ============================================

class ToastWidget extends StatefulWidget {
  final ToastModel toast;
  final VoidCallback onDismiss;

  const ToastWidget({
    super.key,
    required this.toast,
    required this.onDismiss,
  });

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.linear),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = widget.toast.type.gradient;
    final iconColor = widget.toast.type.color;

    return GestureDetector(
      onTap: () {
        widget.toast.onTap?.call();
        _dismiss();
      },
      child: FadeTransition(
        opacity: _animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(_animation),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Barra de progreso superior
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: Colors.transparent,
                          color: Colors.white.withValues(alpha: 0.5),
                          minHeight: 4,
                        ),
                      );
                    },
                  ),
                ),
                // Contenido del toast
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDarkMode
                          ? [Colors.grey.shade800, Colors.grey.shade900]
                          : [Colors.white, Colors.grey.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icono
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: colors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.toast.type.icon,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Mensaje
                      Expanded(
                        child: Text(
                          widget.toast.message,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      // Botón de acción
                      if (widget.toast.actionLabel != null &&
                          widget.toast.onAction != null)
                        GestureDetector(
                          onTap: () {
                            widget.toast.onAction?.call();
                            _dismiss();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: colors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.toast.actionLabel!,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      // Botón cerrar
                      GestureDetector(
                        onTap: _dismiss,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }
}

// ============================================
// CONTENEDOR DE TOASTS
// ============================================

class ToastContainer extends StatefulWidget {
  final Widget child;
  final Duration animationDuration;
  final Duration defaultDuration;
  final int maxToasts;

  const ToastContainer({
    super.key,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 300),
    this.defaultDuration = const Duration(seconds: 3),
    this.maxToasts = 5,
  });

  @override
  State<ToastContainer> createState() => _ToastContainerState();
}

class _ToastContainerState extends State<ToastContainer> {
  final ToastManager _toastManager = ToastManager();
  List<ToastModel> _toasts = [];

  @override
  void initState() {
    super.initState();
    _toastManager.addListener(_onToastsChanged);
  }

  @override
  void dispose() {
    _toastManager.removeListener(_onToastsChanged);
    super.dispose();
  }

  void _onToastsChanged(List<ToastModel> toasts) {
    setState(() {
      _toasts = toasts.take(widget.maxToasts).toList();
    });
  }

  void _removeToast(String id) {
    // El toast ya se elimina automáticamente por el Timer
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _toasts.map((toast) {
              return ToastWidget(
                toast: toast,
                onDismiss: () => _removeToast(toast.id),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ============================================
// CLASE PRINCIPAL TOAST MESSAGE (API ESTÁTICA)
// CORREGIDA - Versión simplificada que acepta ambos formatos
// ============================================

class ToastMessage {
  static final ToastManager _manager = ToastManager();

  static void show({
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _manager.show(ToastModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      type: type,
      duration: duration,
      onTap: onTap,
      actionLabel: actionLabel,
      onAction: onAction,
    ));
  }

  // ============================================
  // MÉTODOS SIMPLIFICADOS - Soporte para ambos formatos
  // ============================================

  /// Muestra un toast de éxito
  /// Soporta: ToastMessage.success('mensaje') o ToastMessage.success(context, 'mensaje')
  static void success(dynamic first, [String? second, Duration? duration, VoidCallback? onTap]) {
    String message;
    
    if (first is BuildContext) {
      // Formato: ToastMessage.success(context, 'mensaje')
      message = second ?? '';
    } else {
      // Formato: ToastMessage.success('mensaje')
      message = first.toString();
    }
    
    if (message.isNotEmpty) {
      _manager.showSuccess(message, duration: duration, onTap: onTap);
    }
  }

  /// Muestra un toast de error
  static void error(dynamic first, [String? second, Duration? duration, VoidCallback? onTap]) {
    String message;
    
    if (first is BuildContext) {
      message = second ?? '';
    } else {
      message = first.toString();
    }
    
    if (message.isNotEmpty) {
      _manager.showError(message, duration: duration, onTap: onTap);
    }
  }

  /// Muestra un toast de advertencia
  static void warning(dynamic first, [String? second, Duration? duration, VoidCallback? onTap]) {
    String message;
    
    if (first is BuildContext) {
      message = second ?? '';
    } else {
      message = first.toString();
    }
    
    if (message.isNotEmpty) {
      _manager.showWarning(message, duration: duration, onTap: onTap);
    }
  }

  /// Muestra un toast de información
  static void info(dynamic first, [String? second, Duration? duration, VoidCallback? onTap]) {
    String message;
    
    if (first is BuildContext) {
      message = second ?? '';
    } else {
      message = first.toString();
    }
    
    if (message.isNotEmpty) {
      _manager.showInfo(message, duration: duration, onTap: onTap);
    }
  }

  static void clearAll() {
    _manager.clearAll();
  }
}

// ============================================
// HOOK PARA USAR TOAST EN WIDGETS
// ============================================

class ToastHook {
  final BuildContext context;

  ToastHook(this.context);

  void show(String message, {ToastType type = ToastType.info}) {
    ToastMessage.show(message: message, type: type);
  }

  void success(String message) => ToastMessage.success(message);
  void error(String message) => ToastMessage.error(message);
  void warning(String message) => ToastMessage.warning(message);
  void info(String message) => ToastMessage.info(message);
}

extension ToastExtension on BuildContext {
  ToastHook get toast => ToastHook(this);
}