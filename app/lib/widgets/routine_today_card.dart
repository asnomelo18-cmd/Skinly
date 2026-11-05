import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/routine.dart';
import '../providers/routine_provider.dart';
import '../theme/app_theme.dart';

class RoutineTodayCard extends StatefulWidget {
  final Routine routine;
  final DateTime date;
  final VoidCallback onEdit;

  const RoutineTodayCard({
    super.key,
    required this.routine,
    required this.date,
    required this.onEdit,
  });

  @override
  State<RoutineTodayCard> createState() => _RoutineTodayCardState();
}

class _RoutineTodayCardState extends State<RoutineTodayCard> {
  bool _expanded = true;

  Color get _seedColor {
    try {
      return Color(int.parse('FF${widget.routine.colorSeed}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();
    final routine = widget.routine;
    final completed = provider.completedSteps(routine.id, widget.date);
    final progress = provider.progressFor(routine.id, widget.date, routine.steps.length);
    final isDone = routine.steps.isNotEmpty && completed.length >= routine.steps.length;

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.gradientCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _seedColor.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [_seedColor, _seedColor.withOpacity(0.6)]),
                    ),
                    child: Icon(
                      isDone ? Icons.check : Icons.spa_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(routine.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress.toDouble(),
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceMuted,
                            valueColor: AlwaysStoppedAnimation(_seedColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${completed.length}/${routine.steps.length}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  IconButton(
                    icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textSecondary),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                children: [
                  ...routine.steps.map((step) {
                    final done = completed.contains(step.id);
                    return CheckboxListTile(
                      value: done,
                      onChanged: (_) => context
                          .read<RoutineProvider>()
                          .toggleStep(routine.id, step.id, widget.date),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        step.name,
                        style: TextStyle(
                          color: done ? AppColors.textSecondary : AppColors.textPrimary,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(step.category,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      activeColor: AppColors.success,
                    );
                  }),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit, size: 16, color: AppColors.textSecondary),
                      label: const Text('Modifier',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
