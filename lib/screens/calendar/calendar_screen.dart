// lib/screens/calendar/calendar_screen.dart
// Pantalla de calendario para visualizar notas por fecha - CON PERSONALIZACIÓN COMPLETA
// Similar a la versión de React de QuickNote

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quicknote/models/note.dart';
import 'package:quicknote/providers/notes_provider.dart';
import 'package:quicknote/widgets/loading_indicator.dart';
import 'package:quicknote/widgets/toast_message.dart';
import 'package:intl/intl.dart';

// ============================================
// TARJETA DE NOTA DEL CALENDARIO
// ============================================

class CalendarNoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final Color accentColor;

  const CalendarNoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.accentColor,
  });

  Color get _noteColor => note.colorValue;
  IconConfig get _iconConfig => note.iconConfig;

  Widget _buildIcon(double size) {
    if (_iconConfig.value == NoteIcon.default_) {
      return Icon(Icons.edit_note, size: size, color: accentColor);
    }
    return Text(_iconConfig.iconName, style: TextStyle(fontSize: size, color: accentColor));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final formattedTime = DateFormat('HH:mm').format(note.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Indicador de color
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Icono
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: _buildIcon(20)),
            ),
            const SizedBox(width: 12),
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (note.isFavorite)
                        Icon(Icons.star, color: Colors.amber, size: 14),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.content,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (note.tags.isNotEmpty)
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            children: note.tags.take(2).map((tag) {
                              return Text(
                                '#$tag',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: accentColor,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 10, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text(
                            formattedTime,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// DÍA DEL CALENDARIO
// ============================================

class CalendarDay extends StatelessWidget {
  final DateTime date;
  final List<Note> notes;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  const CalendarDay({
    super.key,
    required this.date,
    required this.notes,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasNotes = notes.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue
              : isToday
                  ? (isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : (isToday ? FontWeight.w600 : FontWeight.normal),
                      color: !isCurrentMonth
                          ? (isDarkMode ? Colors.white38 : Colors.grey.shade400)
                          : isSelected
                              ? Colors.white
                              : isToday
                                  ? Colors.blue
                                  : (isDarkMode ? Colors.white70 : Colors.grey.shade700),
                    ),
                  ),
                  if (hasNotes)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : (isToday ? Colors.blue : Colors.blue.shade400),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
            if (notes.length > 2)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${notes.length - 2}',
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// PANTALLA PRINCIPAL DEL CALENDARIO
// ============================================

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedMonth;
  DateTime _selectedDate = DateTime.now();
  bool _isWeeklyView = false;

  final List<String> _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  final List<String> _weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  final List<String> _fullWeekDays = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  List<Note> _getNotesForDate(DateTime date, List<Note> notes) {
    return notes.where((note) =>
      note.createdAt.year == date.year &&
      note.createdAt.month == date.month &&
      note.createdAt.day == date.day
    ).toList();
  }

  List<DateTime> _getWeekDays(DateTime date) {
    final startOfWeek = DateTime(date.year, date.month, date.day);
    final weekday = date.weekday;
    final daysToSubtract = weekday == 7 ? 0 : weekday;
    final start = startOfWeek.subtract(Duration(days: daysToSubtract));
    
    return List.generate(7, (index) {
      return start.add(Duration(days: index));
    });
  }

  List<DateTime?> _getMonthDays() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    
    final days = <DateTime?>[];
    
    // Días del mes anterior
    final startWeekday = firstDay.weekday == 7 ? 0 : firstDay.weekday;
    for (int i = 0; i < startWeekday; i++) {
      days.add(null);
    }
    
    // Días del mes actual
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_focusedMonth.year, _focusedMonth.month, i));
    }
    
    return days;
  }

  void _changeMonth(int increment) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + increment);
    });
  }

  void _goToToday() {
    setState(() {
      _focusedMonth = DateTime.now();
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final notesState = ref.watch(notesProvider);
    final activeNotes = notesState.activeNotes;

    if (notesState.isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator(message: 'Cargando calendario...')),
      );
    }

    final notesForSelectedDate = _getNotesForDate(_selectedDate, activeNotes);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(isDarkMode),
      body: Column(
        children: [
          // Selector de mes/año
          _buildMonthSelector(isDarkMode),
          
          // Alternador vista mensual/semanal
          _buildViewToggle(isDarkMode),
          
          // Calendario
          Expanded(
            child: _isWeeklyView
                ? _buildWeekView(isDarkMode, activeNotes)
                : _buildMonthView(isDarkMode, activeNotes),
          ),
          
          // Notas del día seleccionado
          _buildNotesForDay(isDarkMode, notesForSelectedDate),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    return AppBar(
      title: const Text('Calendario'),
      centerTitle: true,
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.today),
          onPressed: _goToToday,
          tooltip: 'Hoy',
        ),
      ],
    );
  }

  Widget _buildMonthSelector(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: Icon(Icons.chevron_left, size: 32),
            color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
          ),
          Text(
            '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: Icon(Icons.chevron_right, size: 32),
            color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildToggleButton(
            label: 'Mensual',
            isSelected: !_isWeeklyView,
            onTap: () => setState(() => _isWeeklyView = false),
            isDarkMode: isDarkMode,
          ),
          _buildToggleButton(
            label: 'Semanal',
            isSelected: _isWeeklyView,
            onTap: () => setState(() => _isWeeklyView = true),
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDarkMode ? Colors.blue.shade800 : Colors.blue.shade50)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? (isDarkMode ? Colors.white : Colors.blue.shade700)
                    : (isDarkMode ? Colors.white54 : Colors.grey.shade600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthView(bool isDarkMode, List<Note> notes) {
    final monthDays = _getMonthDays();
    final today = DateTime.now();

    return Column(
      children: [
        // Días de la semana
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekDays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        // Grid de días
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: monthDays.length,
            itemBuilder: (context, index) {
              final date = monthDays[index];
              if (date == null) {
                return Container(margin: const EdgeInsets.all(2));
              }
              
              final notesForDay = _getNotesForDate(date, notes);
              final isCurrentMonth = date.month == _focusedMonth.month;
              final isToday = date.year == today.year &&
                              date.month == today.month &&
                              date.day == today.day;
              final isSelected = date.year == _selectedDate.year &&
                                 date.month == _selectedDate.month &&
                                 date.day == _selectedDate.day;
              
              return CalendarDay(
                date: date,
                notes: notesForDay,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedDate = date),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView(bool isDarkMode, List<Note> notes) {
    final weekDays = _getWeekDays(_selectedDate);
    final today = DateTime.now();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: weekDays.length,
      itemBuilder: (context, index) {
        final date = weekDays[index];
        final notesForDay = _getNotesForDate(date, notes);
        final isToday = date.year == today.year &&
                        date.month == today.month &&
                        date.day == today.day;
        final isSelected = date.year == _selectedDate.year &&
                           date.month == _selectedDate.month &&
                           date.day == _selectedDate.day;
        
        if (!isSelected && notesForDay.isEmpty) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
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
              children: [
                // Header del día
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue
                        : (isToday
                            ? Colors.blue.withValues(alpha: 0.1)
                            : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100)),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _fullWeekDays[date.weekday - 1],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isSelected
                              ? Colors.white
                              : (isDarkMode ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${date.day} de ${_monthNames[date.month - 1]}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isSelected
                              ? Colors.white70
                              : (isDarkMode ? Colors.white54 : Colors.grey.shade600),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${notesForDay.length} nota${notesForDay.length != 1 ? 's' : ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white70
                              : (isDarkMode ? Colors.white54 : Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Lista de notas del día
                if (notesForDay.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: notesForDay.map((note) {
                        final noteColor = _getNoteColor(note.color);
                        return CalendarNoteCard(
                          note: note,
                          onTap: () => _openNote(note.id),
                          accentColor: noteColor,
                        );
                      }).toList(),
                    ),
                  ),
                
                if (notesForDay.isEmpty && isSelected)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('No hay notas para este día'),
                    ),
                  ),
              ],
            ),
          );
        },
      );
  }

  Widget _buildNotesForDay(bool isDarkMode, List<Note> notes) {
    if (notes.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Notas del ${_selectedDate.day} de ${_monthNames[_selectedDate.month - 1]}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  '${notes.length} nota${notes.length != 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de notas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final noteColor = _getNoteColor(note.color);
                return CalendarNoteCard(
                  note: note,
                  onTap: () => _openNote(note.id),
                  accentColor: noteColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // UTILIDADES
  // ============================================

  Color _getNoteColor(String colorHex) {
    try {
      final hex = colorHex.startsWith('#') ? colorHex : '#$colorHex';
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.blue;
    }
  }

  void _openNote(String id) {
    Navigator.pushNamed(context, '/notes/$id');
  }
}