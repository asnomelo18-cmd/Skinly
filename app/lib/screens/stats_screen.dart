import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/routine_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_pill.dart';
import 'photo_journal_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();
    final routines = provider.all;
    final streak = provider.currentStreak();
    final weeklyPercent = (provider.weeklyCompletionPercentage() * 100).round();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          Text('Suivi', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text('Ton évolution, en un coup d\'œil',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          if (routines.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: EmptyState(
                icon: Icons.bar_chart_rounded,
                message: 'Crée une routine pour voir tes statistiques ici.',
              ),
            )
          else ...[
            Row(
              children: [
                StatPill(
                  icon: Icons.local_fire_department_rounded,
                  value: '$streak',
                  label: 'Jours de suite',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                StatPill(
                  icon: Icons.trending_up_rounded,
                  value: '$weeklyPercent%',
                  label: 'Cette semaine',
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                StatPill(
                  icon: Icons.spa_outlined,
                  value: '${routines.length}',
                  label: routines.length > 1 ? 'Routines' : 'Routine',
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PhotoJournalScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.accentGold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.compare_rounded, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Voir ton évolution en photos',
                        style: TextStyle(
                            color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Détail par routine',
                style: TextStyle(
                    color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12.5)),
            const SizedBox(height: 10),
            ...routines.map((r) {
              Color seedColor;
              try {
                seedColor = Color(int.parse('FF${r.colorSeed}', radix: 16));
              } catch (_) {
                seedColor = AppColors.primary;
              }
              final rate = provider.completionRate(r, days: 7);
              final percent = (rate * 100).round();
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: seedColor.withOpacity(0.15), shape: BoxShape.circle),
                          child: Icon(Icons.spa_outlined, size: 16, color: seedColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(r.name, style: Theme.of(context).textTheme.titleMedium),
                        ),
                        Text('$percent%',
                            style: TextStyle(
                                color: seedColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: rate),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 10,
                          backgroundColor: AppColors.surfaceMuted,
                          valueColor: AlwaysStoppedAnimation(seedColor),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
