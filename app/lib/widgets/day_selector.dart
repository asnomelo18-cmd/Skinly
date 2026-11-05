import 'package:flutter/material.dart';
import '../models/date_utils.dart';
import '../theme/app_theme.dart';

class DaySelector extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<Set<int>> onChanged;

  const DaySelector({super.key, required this.selectedDays, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = i + 1;
        final selected = selectedDays.contains(day);
        return GestureDetector(
          onTap: () {
            final updated = Set<int>.from(selectedDays);
            if (selected) {
              updated.remove(day);
            } else {
              updated.add(day);
            }
            onChanged(updated);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.primary : AppColors.surfaceMuted,
            ),
            alignment: Alignment.center,
            child: Text(
              weekdayShortLabels[day]!.substring(0, 1),
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }
}
