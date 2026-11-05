import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/date_utils.dart';
import '../providers/routine_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widgets.dart';
import 'routine_form_screen.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();
    final routines = provider.all;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mes routines', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        routines.isEmpty
                            ? 'Crée ta première routine skincare'
                            : '${routines.length} routine${routines.length > 1 ? 's' : ''} au total',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: routines.isEmpty
                ? _EmptyRoutines(
                    onCreate: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoutineFormScreen()),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
                    itemCount: routines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final routine = routines[i];
                      Color seedColor;
                      try {
                        seedColor = Color(int.parse('FF${routine.colorSeed}', radix: 16));
                      } catch (_) {
                        seedColor = AppColors.primary;
                      }
                      return Dismissible(
                        key: ValueKey(routine.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          await provider.deleteRoutine(routine.id);
                          return true;
                        },
                        child: LoadingOverlay(
                          isLoading: provider.isDeleting(routine.id),
                          child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => RoutineFormScreen(existing: routine)),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textPrimary.withOpacity(0.05),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    color: seedColor,
                                    borderRadius: const BorderRadius.horizontal(
                                        left: Radius.circular(20)),
                                  ),
                                ),
                                Expanded(
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
                                                colors: [seedColor, seedColor.withOpacity(0.6)]),
                                          ),
                                          child: const Icon(Icons.spa_outlined, color: Colors.white),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(routine.name,
                                                  style: Theme.of(context).textTheme.titleMedium),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${routine.steps.length} produit${routine.steps.length > 1 ? 's' : ''}',
                                                style: const TextStyle(
                                                    color: AppColors.textSecondary, fontSize: 12),
                                              ),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 4,
                                                children: List.generate(7, (i) {
                                                  final day = i + 1;
                                                  final active = routine.activeDays.contains(day);
                                                  return Container(
                                                    width: 20,
                                                    height: 20,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: active
                                                          ? seedColor
                                                          : AppColors.surfaceMuted,
                                                    ),
                                                    child: Text(
                                                      weekdayShortLabels[day]!.substring(0, 1),
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        color: active
                                                            ? Colors.white
                                                            : AppColors.textSecondary,
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (routine.remindersEnabled)
                                          const Icon(Icons.notifications_active_outlined,
                                              color: AppColors.secondary, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRoutines extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyRoutines({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.list_alt_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 18),
            const Text(
              'Aucune routine créée',
              style: TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Crée ta première routine skincare et choisis les jours où tu veux la suivre.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Créer ma première routine'),
            ),
          ],
        ),
      ),
    );
  }
}
