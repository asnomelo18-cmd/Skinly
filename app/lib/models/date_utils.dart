/// Labels français des jours (index = DateTime.weekday, 1 = Lundi ... 7 = Dimanche)
const Map<int, String> weekdayShortLabels = {
  1: 'Lun',
  2: 'Mar',
  3: 'Mer',
  4: 'Jeu',
  5: 'Ven',
  6: 'Sam',
  7: 'Dim',
};

const Map<int, String> weekdayFullLabels = {
  1: 'lundi',
  2: 'mardi',
  3: 'mercredi',
  4: 'jeudi',
  5: 'vendredi',
  6: 'samedi',
  7: 'dimanche',
};

const List<String> monthLabels = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

String formatDateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String formatFullDate(DateTime date) {
  final weekday = weekdayFullLabels[date.weekday] ?? '';
  final month = monthLabels[date.month - 1];
  return '$weekday ${date.day} $month';
}
