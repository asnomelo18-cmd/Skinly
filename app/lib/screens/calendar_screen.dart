import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/date_utils.dart';
import '../providers/routine_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/routine_today_card.dart';
import 'routine_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Text('Calendrier', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text('Ton historique de suivi, jour par jour',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildMonthHeader(),
                const SizedBox(height: 12),
                _buildWeekdayHeader(),
                const SizedBox(height: 6),
                _buildMonthGrid(provider),
                const SizedBox(height: 8),
                _buildLegend(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(_capitalizedFullDate(_selectedDate),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildSelectedDayDetail(provider),
        ],
      ),
    );
  }

  String _capitalizedFullDate(DateTime date) {
    final formatted = formatFullDate(date);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  Widget _buildMonthHeader() {
    final label = monthLabels[_focusedMonth.month - 1];
    final capitalized = label[0].toUpperCase() + label.substring(1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
        ),
        Text('$capitalized ${_focusedMonth.year}',
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    return Row(
      children: List.generate(7, (i) {
        final day = i + 1;
        return Expanded(
          child: Center(
            child: Text(
              weekdayShortLabels[day]!,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMonthGrid(RoutineProvider provider) {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final leadingEmpty = firstOfMonth.weekday - 1; // 0 si le mois commence un lundi
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows * 7,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final dayNumber = index - leadingEmpty + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox();

        final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
        final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;
        final isFuture = date.isAfter(DateTime(today.year, today.month, today.day));
        final status = isFuture ? DayStatus.none : provider.statusForDate(date);

        return GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primary : Colors.transparent,
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.primary, width: 1.4)
                  : null,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$dayNumber',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                _statusDot(status, isSelected),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusDot(DayStatus status, bool isSelected) {
    if (status == DayStatus.none) return const SizedBox(width: 6, height: 6);
    Color color;
    switch (status) {
      case DayStatus.full:
        color = AppColors.success;
        break;
      case DayStatus.partial:
        color = AppColors.accentGold;
        break;
      case DayStatus.empty:
        color = AppColors.danger;
        break;
      case DayStatus.none:
        color = Colors.transparent;
        break;
    }
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? Colors.white : color,
      ),
    );
  }

  Widget _buildLegend() {
    Widget item(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        );

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        item(AppColors.success, 'Complété'),
        item(AppColors.accentGold, 'Partiel'),
        item(AppColors.danger, 'Manqué'),
      ],
    );
  }

  Widget _buildSelectedDayDetail(RoutineProvider provider) {
    final scheduled = provider.routinesForWeekday(_selectedDate.weekday);
    if (scheduled.isEmpty) {
      return const EmptyState(
        icon: Icons.spa_outlined,
        message: 'Aucune routine programmée ce jour-là.',
      );
    }
    return Column(
      children: scheduled
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: RoutineTodayCard(
                  routine: r,
                  date: _selectedDate,
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RoutineFormScreen(existing: r)),
                  ),
                ),
              ))
          .toList(),
    );
  }
}
