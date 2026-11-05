import 'dart:convert';

/// Catégories de produits proposées par défaut (l'utilisateur peut aussi
/// choisir "Autre" et préciser dans les notes).
const List<String> stepCategories = [
  'Nettoyant',
  'Tonique',
  'Sérum',
  'Hydratant',
  'Protection solaire',
  'Exfoliant',
  'Contour des yeux',
  'Masque',
  'Autre',
];

/// Un produit / une étape dans une routine, précisé par l'utilisateur.
class RoutineStep {
  final String id;
  String name;
  String category;
  String notes;

  RoutineStep({
    required this.id,
    required this.name,
    this.category = 'Autre',
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'notes': notes,
      };

  factory RoutineStep.fromMap(Map<String, dynamic> map) => RoutineStep(
        id: map['id'],
        name: map['name'] ?? '',
        category: map['category'] ?? 'Autre',
        notes: map['notes'] ?? '',
      );
}

/// Une routine skincare définie par l'utilisateur : un nom, une liste de
/// produits dans l'ordre d'application, et les jours de la semaine où elle
/// doit être faite (1 = Lundi ... 7 = Dimanche, convention DateTime.weekday).
class Routine {
  final String id;
  String name;
  String colorSeed;
  List<RoutineStep> steps;
  Set<int> activeDays;
  int reminderHour;
  int reminderMinute;
  bool remindersEnabled;
  DateTime updatedAt;

  Routine({
    required this.id,
    required this.name,
    this.colorSeed = 'E8927C',
    List<RoutineStep>? steps,
    Set<int>? activeDays,
    this.reminderHour = 8,
    this.reminderMinute = 0,
    this.remindersEnabled = true,
    DateTime? updatedAt,
  })  : steps = steps ?? [],
        activeDays = activeDays ?? {1, 2, 3, 4, 5, 6, 7},
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'colorSeed': colorSeed,
        'steps': steps.map((s) => s.toMap()).toList(),
        'activeDays': activeDays.toList(),
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'remindersEnabled': remindersEnabled,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Routine.fromMap(Map<String, dynamic> map) => Routine(
        id: map['id'],
        name: map['name'] ?? '',
        colorSeed: map['colorSeed'] ?? 'E8927C',
        steps: (map['steps'] as List?)
                ?.map((s) => RoutineStep.fromMap(s as Map<String, dynamic>))
                .toList() ??
            [],
        activeDays: ((map['activeDays'] as List?)?.map((d) => d as int).toSet()) ??
            {1, 2, 3, 4, 5, 6, 7},
        reminderHour: map['reminderHour'] ?? 8,
        reminderMinute: map['reminderMinute'] ?? 0,
        remindersEnabled: map['remindersEnabled'] ?? true,
        updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      );

  static String encodeList(List<Routine> list) =>
      jsonEncode(list.map((r) => r.toMap()).toList());

  static List<Routine> decodeList(String source) {
    final decoded = jsonDecode(source) as List;
    return decoded
        .map((item) => Routine.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
