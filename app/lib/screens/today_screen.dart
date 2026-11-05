import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/date_utils.dart';
import '../providers/routine_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/routine_today_card.dart';
import '../widgets/stat_pill.dart';
import 'routine_form_screen.dart';
import 'photo_journal_screen.dart';
import 'notifications_debug_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour ☀️';
    if (hour < 18) return 'Bon après-midi 🌤️';
    return 'Bonsoir 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();
    final today = DateTime.now();
    final routines = provider.todaysRoutines;
    final streak = provider.currentStreak();
    final percent = (provider.weeklyCompletionPercentage() * 100).round();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(), style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 4),
                    Text(formatFullDate(today),
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Diagnostic notifications',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsDebugScreen()),
                ),
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (provider.all.isNotEmpty) ...[
            _buildStreakBanner(context, streak, percent),
            const SizedBox(height: 12),
            Row(
              children: [
                StatPill(
                  icon: Icons.local_fire_department_rounded,
                  value: '$streak',
                  label: streak > 1 ? 'Jours de suite' : 'Jour de suite',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                StatPill(
                  icon: Icons.check_circle_outline_rounded,
                  value: '$percent%',
                  label: 'Cette semaine',
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                StatPill(
                  icon: Icons.spa_outlined,
                  value: '${routines.length}',
                  label: routines.length > 1 ? 'Étapes du jour' : 'Étape du jour',
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPhotoTeaser(context),
            const SizedBox(height: 20),
          ],
          if (routines.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: EmptyState(
                icon: Icons.spa_outlined,
                message: 'Rien de prévu aujourd\'hui.\nProfites-en pour te reposer 🌙',
              ),
            )
          else
            ...routines.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: RoutineTodayCard(
                    routine: r,
                    date: today,
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RoutineFormScreen(existing: r)),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildStreakBanner(BuildContext context, int streak, int percent) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🔥', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak > 0
                      ? '$streak jour${streak > 1 ? 's' : ''} consécutif${streak > 1 ? 's' : ''} !'
                      : 'Commence ta série aujourd\'hui !',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.5),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tu as complété $percent% de ta routine cette semaine.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTeaser(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PhotoJournalScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.surfaceMuted),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_camera_back_outlined,
                  size: 18, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Ajoute une photo à ton journal aujourd\'hui',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
