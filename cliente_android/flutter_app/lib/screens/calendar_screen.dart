import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/reservation_panel.dart';
import '../widgets/my_reservations.dart';

class MonthInfo {
  final String name;
  final int days;
  MonthInfo({required this.name, required this.days});
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final List<MonthInfo> months = [
    MonthInfo(name: "Enero", days: 31),
    MonthInfo(name: "Febrero", days: 28),
    MonthInfo(name: "Marzo", days: 31),
    MonthInfo(name: "Abril", days: 30),
    MonthInfo(name: "Mayo", days: 31),
    MonthInfo(name: "Junio", days: 30),
    MonthInfo(name: "Julio", days: 31),
    MonthInfo(name: "Agosto", days: 31),
    MonthInfo(name: "Septiembre", days: 30),
    MonthInfo(name: "Octubre", days: 31),
    MonthInfo(name: "Noviembre", days: 30),
    MonthInfo(name: "Diciembre", days: 31),
  ];

  String? _selectedDate;
  int? _selectedDay;
  int _currentMonthIndex = DateTime.now().month - 1; // Mes actual

  final List<String> _weekDays = ["LU", "MA", "MI", "JU", "VI", "SA", "DO"];

  String _getFormattedDate(String? dateStr) {
    if (dateStr == null) return "";
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) return dateStr;
      final year = parts[0];
      final monthIndex = int.parse(parts[1]) - 1;
      final day = int.parse(parts[2]);
      return "$day de ${months[monthIndex].name} $year";
    } catch (e) {
      return dateStr;
    }
  }

  void _handleDayClick(int day) {
    setState(() {
      _selectedDay = day;
      // Formato YYYY-MM-DD para la base de datos
      _selectedDate = "2026-${(_currentMonthIndex + 1).toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
    });
  }

  void _handlePrevMonth() {
    setState(() {
      _currentMonthIndex = (_currentMonthIndex - 1 + 12) % 12;
      _selectedDay = null;
      _selectedDate = null;
    });
  }

  void _handleNextMonth() {
    setState(() {
      _currentMonthIndex = (_currentMonthIndex + 1) % 12;
      _selectedDay = null;
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = months[_currentMonthIndex];
    final daysInMonth = List.generate(currentMonth.days, (i) => i + 1);

    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 124),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    // Calendario Container
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6750A4).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(27),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
                                onPressed: _handlePrevMonth,
                              ),
                              Text(
                                "${currentMonth.name} 2026",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 24),
                                onPressed: _handleNextMonth,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // WeekDays
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: _weekDays.map((day) => Expanded(
                              child: Container(
                                height: 28,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6750A4).withOpacity(0.21),
                                  borderRadius: BorderRadius.circular(4.7),
                                ),
                                child: Text(
                                  day,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 8),
                          // Days Grid
                          Builder(
                            builder: (context) {
                              final now = DateTime.now();
                              // Calcular en qué día de la semana cae el 1 del mes
                              final firstDayOfMonth = DateTime(2026, _currentMonthIndex + 1, 1);
                              final startOffset = firstDayOfMonth.weekday - 1;
                              final totalCells = startOffset + currentMonth.days;

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisSpacing: 4,
                                  crossAxisSpacing: 4,
                                ),
                                itemCount: totalCells,
                                itemBuilder: (context, index) {
                                  if (index < startOffset) {
                                    return const SizedBox();
                                  }
                                  final day = index - startOffset + 1;
                                  final cellDate = DateTime(2026, _currentMonthIndex + 1, day);
                                  final today = DateTime(now.year, now.month, now.day);
                                  final isPast = cellDate.isBefore(today);
                                  final isToday = cellDate.isAtSameMomentAs(today);
                                  final isSelected = _selectedDay == day;

                                  return GestureDetector(
                                    onTap: isPast ? null : () => _handleDayClick(day),
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isPast
                                            ? const Color(0xFF6750A4).withOpacity(0.08)
                                            : isSelected
                                                ? const Color(0xFF6750A4)
                                                : const Color(0xFF6750A4).withOpacity(0.21),
                                        borderRadius: BorderRadius.circular(4.7),
                                        border: isToday
                                            ? Border.all(color: Colors.white54, width: 1.5)
                                            : null,
                                      ),
                                      child: Text(
                                        "$day",
                                        style: TextStyle(
                                          color: isPast ? Colors.white24 : Colors.white,
                                          fontSize: 9.4,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Panel de reserva
                    ReservationPanel(
                      selectedDate: _selectedDate,
                      formattedDate: _getFormattedDate(_selectedDate),
                    ),
                    // Mis reservas
                    const MyReservations(),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(),
          ),
        ],
      ),
    );
  }
}
