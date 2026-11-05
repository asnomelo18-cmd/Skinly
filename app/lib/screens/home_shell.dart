import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/routine_provider.dart';
import 'today_screen.dart';
import 'routines_screen.dart';
import 'calendar_screen.dart';
import 'stats_screen.dart';
import 'photo_journal_screen.dart';
import 'routine_form_screen.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/loading_widgets.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _remindersInitialized = false;

  final _screens = const [
    TodayScreen(),
    RoutinesScreen(),
    PhotoJournalScreen(),
    CalendarScreen(),
    StatsScreen(),
  ];

  static const _navItems = [
    NavItemData(icon: Icons.wb_sunny_outlined, activeIcon: Icons.wb_sunny_rounded, label: 'Aujourd\'hui'),
    NavItemData(icon: Icons.list_alt_outlined, activeIcon: Icons.list_alt_rounded, label: 'Routines'),
    NavItemData(icon: Icons.photo_camera_back_outlined, activeIcon: Icons.photo_camera_back_rounded, label: 'Photos'),
    NavItemData(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Calendrier'),
    NavItemData(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Suivi'),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<RoutineProvider>(
      builder: (context, provider, _) {
        if (!provider.isLoaded) {
          return const SkinlyLoadingScreen();
        }
        if (!_remindersInitialized) {
          _remindersInitialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.rescheduleAllReminders();
          });
        }
        return Scaffold(
          extendBody: true,
          body: IndexedStack(index: _index, children: _screens),
          floatingActionButton: _index == 1
              ? FloatingActionButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RoutineFormScreen()),
                  ),
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: FloatingNavBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: _navItems,
          ),
        );
      },
    );
  }
}
