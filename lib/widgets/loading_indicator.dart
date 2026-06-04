// lib/widgets/loading_indicator.dart
// Indicador de carga - CON MÚLTIPLES VARIANTES Y DISEÑO COMPLETO
// Similar a la versión de React de QuickNote

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================
// TIPOS DE INDICADOR DE CARGA
// ============================================

enum LoadingVariant {
  spinner,   // Círculo giratorio
  dots,      // Puntos animados
  pulse,     // Pulso circular
  progress,  // Barra de progreso
  skeleton,  // Skeleton screen
}

enum LoadingSize {
  small,
  medium,
  large,
  extraLarge,
}

extension LoadingSizeExtension on LoadingSize {
  double get size {
    switch (this) {
      case LoadingSize.small:
        return 24;
      case LoadingSize.medium:
        return 40;
      case LoadingSize.large:
        return 56;
      case LoadingSize.extraLarge:
        return 80;
    }
  }

  double get fontSize {
    switch (this) {
      case LoadingSize.small:
        return 11;
      case LoadingSize.medium:
        return 13;
      case LoadingSize.large:
        return 15;
      case LoadingSize.extraLarge:
        return 17;
    }
  }

  double get strokeWidth {
    switch (this) {
      case LoadingSize.small:
        return 2;
      case LoadingSize.medium:
        return 3;
      case LoadingSize.large:
        return 4;
      case LoadingSize.extraLarge:
        return 5;
    }
  }
}

enum LoadingColor {
  blue,
  purple,
  green,
  red,
  yellow,
  white,
  gray,
}

extension LoadingColorExtension on LoadingColor {
  Color get color {
    switch (this) {
      case LoadingColor.blue:
        return const Color(0xFF3B82F6);
      case LoadingColor.purple:
        return const Color(0xFF8B5CF6);
      case LoadingColor.green:
        return const Color(0xFF10B981);
      case LoadingColor.red:
        return const Color(0xFFEF4444);
      case LoadingColor.yellow:
        return const Color(0xFFF59E0B);
      case LoadingColor.white:
        return Colors.white;
      case LoadingColor.gray:
        return Colors.grey;
    }
  }

  List<Color> get gradient {
    switch (this) {
      case LoadingColor.blue:
        return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
      case LoadingColor.purple:
        return [const Color(0xFF8B5CF6), const Color(0xFF6366F1)];
      case LoadingColor.green:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case LoadingColor.red:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case LoadingColor.yellow:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      default:
        return [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)];
    }
  }
}

// ============================================
// INDICADOR DE CARGA PRINCIPAL
// ============================================

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool fullScreen;
  final LoadingSize size;
  final LoadingColor color;
  final LoadingVariant variant;
  final double? progress;
  final Widget? customChild;

  const LoadingIndicator({
    super.key,
    this.message,
    this.fullScreen = false,
    this.size = LoadingSize.medium,
    this.color = LoadingColor.purple,
    this.variant = LoadingVariant.spinner,
    this.progress,
    this.customChild,
  });

  // Fábricas para uso rápido
  factory LoadingIndicator.small({String? message}) {
    return LoadingIndicator(
      message: message,
      size: LoadingSize.small,
    );
  }

  factory LoadingIndicator.large({String? message}) {
    return LoadingIndicator(
      message: message,
      size: LoadingSize.large,
    );
  }

  factory LoadingIndicator.fullScreen({String? message}) {
    return LoadingIndicator(
      message: message,
      fullScreen: true,
      size: LoadingSize.large,
    );
  }

  factory LoadingIndicator.progress(double progress, {String? message}) {
    return LoadingIndicator(
      progress: progress,
      message: message,
      variant: LoadingVariant.progress,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    
    if (fullScreen) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: content),
      );
    }
    
    return Center(child: content);
  }

  Widget _buildContent(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLoader(context, isDarkMode),
        if (message != null && message!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: GoogleFonts.poppins(
              fontSize: size.fontSize,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildLoader(BuildContext context, bool isDarkMode) {
    switch (variant) {
      case LoadingVariant.spinner:
        return _buildSpinner(isDarkMode);
      case LoadingVariant.dots:
        return _buildDots(isDarkMode);
      case LoadingVariant.pulse:
        return _buildPulse(isDarkMode);
      case LoadingVariant.progress:
        return _buildProgressBar(isDarkMode);
      case LoadingVariant.skeleton:
        return _buildSkeleton();
    }
  }

  // ============================================
  // VARIANTES DE LOADER
  // ============================================

  Widget _buildSpinner(bool isDarkMode) {
    final colors = color.gradient;
    
    return SizedBox(
      width: size.size,
      height: size.size,
      child: CircularProgressIndicator(
        strokeWidth: size.strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color.color),
        backgroundColor: isDarkMode ? Colors.white24 : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildDots(bool isDarkMode) {
    final dotColor = color.color;
    final dotSize = size.size / 4;
    
    return SizedBox(
      width: size.size,
      height: size.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: AlwaysStoppedAnimation(0),
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.5, end: 1.0),
                  duration: Duration(milliseconds: 600 + (index * 200)),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                  onEnd: () {},
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildPulse(bool isDarkMode) {
    final colors = color.gradient;
    
    return SizedBox(
      width: size.size,
      height: size.size,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.8, end: 1.2),
        duration: const Duration(milliseconds: 1000),
        builder: (context, value, child) {
          return Container(
            width: size.size * value,
            height: size.size * value,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.color.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.edit_note, color: Colors.white, size: 28),
          );
        },
        onEnd: () {},
      ),
    );
  }

  Widget _buildProgressBar(bool isDarkMode) {
    final progressValue = progress?.clamp(0.0, 1.0) ?? 0.0;
    final colors = color.gradient;
    
    return Column(
      children: [
        Container(
          width: 200,
          height: 8,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.transparent,
              color: color.color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(progressValue * 100).toInt()}%',
          style: GoogleFonts.poppins(
            fontSize: size.fontSize,
            fontWeight: FontWeight.w600,
            color: color.color,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        // Avatar skeleton
        Container(
          width: size.size,
          height: size.size,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 12),
        // Title skeleton
        Container(
          width: size.size * 1.5,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        // Line skeletons
        Container(
          width: size.size * 2,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: size.size * 1.8,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

// ============================================
// OVERLAY DE CARGA (PARA MODALES)
// ============================================

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final LoadingVariant variant;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.variant = LoadingVariant.spinner,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade900
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LoadingIndicator(
                  message: message,
                  variant: variant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================
// SKELETON SCREENS
// ============================================

class SkeletonScreen extends StatelessWidget {
  final int itemCount;
  final bool isGrid;

  const SkeletonScreen({
    super.key,
    this.itemCount = 6,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildSkeletonCard(),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// INDICADOR DE CARGA INLINE
// ============================================

class LoadingInline extends StatelessWidget {
  final String? message;
  final LoadingSize size;

  const LoadingInline({
    super.key,
    this.message,
    this.size = LoadingSize.small,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size.size,
          height: size.size,
          child: CircularProgressIndicator(
            strokeWidth: size.strokeWidth,
          ),
        ),
        if (message != null) ...[
          const SizedBox(width: 12),
          Text(
            message!,
            style: GoogleFonts.poppins(
              fontSize: size.fontSize,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }
}