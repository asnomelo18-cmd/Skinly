import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../models/routine.dart';
import '../models/date_utils.dart';
import '../services/notification_service.dart';

/// Statut de complétion d'une journée, utilisé par l'écran Calendrier.
enum DayStatus { none, empty, partial, full }

class RoutineProvider extends ChangeNotifier {
  static const _routinesKey = 'skincare_routines_v1';
  static const _completionsKey = 'skincare_completions_v1';

  final _uuid = const Uuid();
  final _notifications = NotificationService();

  List<Routine> _routines = [];
  // clé = "routineId|yyyy-MM-dd" -> set des id d'étapes cochées
  Map<String, Set<String>> _completions = {};

  bool _loaded = false;
  bool _isSaving = false;
  final Set<String> _deletingIds = {};

  bool get isLoaded => _loaded;
  bool get isSaving => _isSaving;
  bool isDeleting(String id) => _deletingIds.contains(id);
  List<Routine> get all => List.unmodifiable(_routines);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawRoutines = prefs.getString(_routinesKey);
    if (rawRoutines != null && rawRoutines.isNotEmpty) {
      try {
        _routines = Routine.decodeList(rawRoutines);
      } catch (_) {
        _routines = [];
      }
    }
    final rawCompletions = prefs.getString(_completionsKey);
    if (rawCompletions != null && rawCompletions.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawCompletions) as Map<String, dynamic>;
        _completions = decoded.map(
          (key, value) => MapEntry(key, (value as List).map((e) => e.toString()).toSet()),
        );
      } catch (_) {
        _completions = {};
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persistRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_routinesKey, Routine.encodeList(_routines));
  }

  Future<void> _persistCompletions() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_completions.map((k, v) => MapEntry(k, v.toList())));
    await prefs.setString(_completionsKey, encoded);
  }

  // ---------- Routines CRUD ----------

  Future<void> addRoutine(Routine routine) async {
    _isSaving = true;
    notifyListeners();
    try {
      _routines.add(routine);
      await _persistRoutines();
      await _syncReminders(routine);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateRoutine(Routine routine) async {
    final index = _routines.indexWhere((r) => r.id == routine.id);
    if (index == -1) return;
    _isSaving = true;
    notifyListeners();
    try {
      routine.updatedAt = DateTime.now();
      _routines[index] = routine;
      await _persistRoutines();
      await _syncReminders(routine);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteRoutine(String id) async {
    _deletingIds.add(id);
    notifyListeners();
    try {
      await _notifications.cancelRoutineReminders(id);
      _routines.removeWhere((r) => r.id == id);
      _completions.removeWhere((key, _) => key.startsWith('$id|'));
      await _persistRoutines();
      await _persistCompletions();
    } finally {
      _deletingIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> _syncReminders(Routine routine) async {
    if (routine.remindersEnabled && routine.activeDays.isNotEmpty) {
      await _notifications.scheduleRoutineReminders(
        routineId: routine.id,
        routineName: routine.name,
        days: routine.activeDays,
        hour: routine.reminderHour,
        minute: routine.reminderMinute,
      );
    } else {
      await _notifications.cancelRoutineReminders(routine.id);
    }
  }

  Future<void> rescheduleAllReminders() async {
    for (final routine in _routines) {
      await _syncReminders(routine);
    }
  }

  Routine? findById(String id) {
    try {
      return _routines.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  // ---------- Routines actives pour un jour donné ----------

  List<Routine> routinesForWeekday(int weekday) =>
      _routines.where((r) => r.activeDays.contains(weekday)).toList();

  List<Routine> get todaysRoutines => routinesForWeekday(DateTime.now().weekday);

  // ---------- Progression quotidienne ----------

  String _key(String routineId, DateTime date) => '$routineId|${formatDateKey(date)}';

  Set<String> completedSteps(String routineId, DateTime date) =>
      _completions[_key(routineId, date)] ?? {};

  bool isStepDone(String routineId, String stepId, DateTime date) =>
      completedSteps(routineId, date).contains(stepId);

  double progressFor(String routineId, DateTime date, int totalSteps) {
    if (totalSteps == 0) return 0;
    final done = completedSteps(routineId, date).length;
    return (done / totalSteps).clamp(0, 1);
  }

  Future<void> toggleStep(String routineId, String stepId, DateTime date) async {
    final key = _key(routineId, date);
    final current = Set<String>.from(_completions[key] ?? {});
    if (current.contains(stepId)) {
      current.remove(stepId);
    } else {
      current.add(stepId);
    }
    _completions[key] = current;
    notifyListeners();
    await _persistCompletions();
  }

  /// Taux de complétion sur les [days] derniers jours pour une routine,
  /// en ne comptant que les jours où elle était programmée.
  double completionRate(Routine routine, {int days = 7}) {
    int scheduled = 0;
    int fullyDone = 0;
    final now = DateTime.now();
    for (var i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      if (!routine.activeDays.contains(date.weekday)) continue;
      scheduled++;
      final done = completedSteps(routine.id, date).length;
      if (routine.steps.isNotEmpty && done >= routine.steps.length) {
        fullyDone++;
      }
    }
    if (scheduled == 0) return 0;
    return fullyDone / scheduled;
  }

  /// Nombre de jours consécutifs (en partant d'aujourd'hui ou d'hier si rien
  /// n'est encore fait aujourd'hui) où toutes les routines programmées ce
  /// jour-là ont été complétées à 100 %. Les jours sans routine programmée
  /// ne cassent pas la série, ils sont simplement ignorés.
  int currentStreak() {
    var streak = 0;
    var date = DateTime.now();
    // Si rien n'est prévu ou fait aujourd'hui, on commence à compter depuis hier
    // pour ne pas casser la série avant même la fin de la journée.
    final todaysScheduled = routinesForWeekday(date.weekday);
    if (todaysScheduled.isNotEmpty && !_isDayFullyDone(todaysScheduled, date)) {
      date = date.subtract(const Duration(days: 1));
    }
    for (var i = 0; i < 365; i++) {
      final scheduled = routinesForWeekday(date.weekday);
      if (scheduled.isEmpty) {
        date = date.subtract(const Duration(days: 1));
        continue;
      }
      if (_isDayFullyDone(scheduled, date)) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  bool _isDayFullyDone(List<Routine> scheduled, DateTime date) {
    for (final r in scheduled) {
      if (r.steps.isEmpty) continue;
      final done = completedSteps(r.id, date).length;
      if (done < r.steps.length) return false;
    }
    return true;
  }

  /// Pourcentage global de complétion (toutes routines confondues) sur les
  /// [days] derniers jours, basé sur le nombre d'étapes cochées par rapport
  /// au nombre d'étapes prévues.
  double weeklyCompletionPercentage({int days = 7}) {
    int totalScheduledSteps = 0;
    int totalDoneSteps = 0;
    final now = DateTime.now();
    for (var i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      for (final r in routinesForWeekday(date.weekday)) {
        if (r.steps.isEmpty) continue;
        totalScheduledSteps += r.steps.length;
        totalDoneSteps += completedSteps(r.id, date).length;
      }
    }
    if (totalScheduledSteps == 0) return 0;
    return totalDoneSteps / totalScheduledSteps;
  }

  /// Statut de complétion d'une date donnée, pour l'affichage dans le calendrier.
  DayStatus statusForDate(DateTime date) {
    final scheduled = routinesForWeekday(date.weekday);
    if (scheduled.isEmpty) return DayStatus.none;
    var total = 0;
    var done = 0;
    for (final r in scheduled) {
      if (r.steps.isEmpty) continue;
      total += r.steps.length;
      done += completedSteps(r.id, date).length;
    }
    if (total == 0) return DayStatus.none;
    if (done == 0) return DayStatus.empty;
    if (done >= total) return DayStatus.full;
    return DayStatus.partial;
  }

  String newId() => _uuid.v4();
}
