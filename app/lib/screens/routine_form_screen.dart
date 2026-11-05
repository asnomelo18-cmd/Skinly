import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/routine.dart';
import '../providers/routine_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/day_selector.dart';
import '../widgets/loading_widgets.dart';

class RoutineFormScreen extends StatefulWidget {
  final Routine? existing;
  const RoutineFormScreen({super.key, this.existing});

  @override
  State<RoutineFormScreen> createState() => _RoutineFormScreenState();
}

class _RoutineFormScreenState extends State<RoutineFormScreen> {
  final _nameCtrl = TextEditingController();
  late List<RoutineStep> _steps;
  late Set<int> _activeDays;
  late int _hour;
  late int _minute;
  late bool _remindersEnabled;
  String _colorSeed = 'E8927C';
  bool _isSaving = false;

  static const _palette = ['E8927C', '8FA998', 'E0B589', 'D98878', 'A78BFA', '7EC4CF'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _steps = e.steps.map((s) => RoutineStep(id: s.id, name: s.name, category: s.category, notes: s.notes)).toList();
      _activeDays = Set.from(e.activeDays);
      _hour = e.reminderHour;
      _minute = e.reminderMinute;
      _remindersEnabled = e.remindersEnabled;
      _colorSeed = e.colorSeed;
    } else {
      _steps = [];
      _activeDays = {1, 2, 3, 4, 5, 6, 7};
      _hour = 8;
      _minute = 0;
      _remindersEnabled = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addStepDialog() async {
    final nameCtrl = TextEditingController();
    String category = stepCategories.first;
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Ajouter un produit', style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'ex: Nettoyant moussant CeraVe',
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: stepCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Notes (optionnel)',
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  _steps.add(RoutineStep(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim(),
                    category: category,
                    notes: notesCtrl.text.trim(),
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute un nom et au moins un produit')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final provider = context.read<RoutineProvider>();
    try {
      if (widget.existing == null) {
        await provider.addRoutine(Routine(
          id: provider.newId(),
          name: _nameCtrl.text.trim(),
          colorSeed: _colorSeed,
          steps: _steps,
          activeDays: _activeDays,
          reminderHour: _hour,
          reminderMinute: _minute,
          remindersEnabled: _remindersEnabled,
        ));
      } else {
        final r = widget.existing!;
        r.name = _nameCtrl.text.trim();
        r.colorSeed = _colorSeed;
        r.steps = _steps;
        r.activeDays = _activeDays;
        r.reminderHour = _hour;
        r.reminderMinute = _minute;
        r.remindersEnabled = _remindersEnabled;
        await provider.updateRoutine(r);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Nouvelle routine' : 'Modifier la routine'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Nom de la routine (ex: Routine du matin)',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Couleur', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: _palette.map((hex) {
                final color = Color(int.parse('FF$hex', radix: 16));
                final selected = _colorSeed == hex;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _colorSeed = hex),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? AppColors.textPrimary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Jours de la semaine', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            DaySelector(
              selectedDays: _activeDays,
              onChanged: (days) => setState(() => _activeDays = days),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Rappel notification',
                        style: TextStyle(color: AppColors.textPrimary)),
                    subtitle: const Text('Reçois une notification les jours sélectionnés',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    value: _remindersEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _remindersEnabled = v),
                  ),
                  if (_remindersEnabled)
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Heure du rappel',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(hour: _hour, minute: _minute),
                            );
                            if (picked != null) {
                              setState(() {
                                _hour = picked.hour;
                                _minute = picked.minute;
                              });
                            }
                          },
                          child: Text(
                            '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Produits (${_steps.length})', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: _addStepDialog,
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: const Text('Ajouter', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_steps.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('Aucun produit. Ajoute au moins une étape.',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _steps.removeAt(oldIndex);
                    _steps.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, i) {
                  final step = _steps[i];
                  return Container(
                    key: ValueKey(step.id),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.surfaceMuted,
                        child: Text('${i + 1}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                      ),
                      title: Text(step.name, style: const TextStyle(color: AppColors.textPrimary)),
                      subtitle: Text(step.category, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () => setState(() => _steps.removeAt(i)),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            LoadingButton(
              isLoading: _isSaving,
              onPressed: _save,
              child: Text(widget.existing == null ? 'Créer la routine' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
