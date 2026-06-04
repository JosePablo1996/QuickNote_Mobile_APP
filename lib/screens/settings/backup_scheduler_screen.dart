// lib/screens/settings/backup_scheduler_screen.dart
// Pantalla de configuración de backups programados

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/widgets/backup_scheduler_widget.dart';

class BackupSchedulerScreen extends ConsumerStatefulWidget {
  const BackupSchedulerScreen({super.key});

  @override
  ConsumerState<BackupSchedulerScreen> createState() => _BackupSchedulerScreenState();
}

class _BackupSchedulerScreenState extends ConsumerState<BackupSchedulerScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Backup Programado'),
        centerTitle: true,
        backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Widget principal de configuración
            const BackupSchedulerWidget(),
            
            const SizedBox(height: 24),
            
            // Información adicional
            _buildInfoCard(isDarkMode),
            
            const SizedBox(height: 24),
            
            // Requisitos
            _buildRequirementsCard(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline, size: 18, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Text(
                '¿Cómo funciona?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Los backups se ejecutan en segundo plano automáticamente\n'
            '• Necesitas conexión a internet para guardar en la nube\n'
            '• Recibirás una notificación cuando el backup se complete\n'
            '• Los backups se guardan en Supabase con tus notas\n'
            '• Puedes forzar un backup manual en cualquier momento',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber, size: 18, color: Colors.amber),
              ),
              const SizedBox(width: 12),
              Text(
                'Requisitos',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• El dispositivo debe tener conexión a internet\n'
            '• La batería debe ser suficiente (recomendado)\n'
            '• Permiso de notificaciones activado\n'
            '• La app puede ejecutarse en segundo plano',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: Colors.amber.shade800,
            ),
          ),
        ],
      ),
    );
  }
}