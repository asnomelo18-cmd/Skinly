/// Une entrée du journal photo "avant / après" : une photo de peau prise à
/// une date donnée, avec une note optionnelle (ex: "J15 - rétinol").
class SkinPhoto {
  final String id;
  final String filePath;
  final DateTime takenAt;
  String note;

  SkinPhoto({
    required this.id,
    required this.filePath,
    required this.takenAt,
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'filePath': filePath,
        'takenAt': takenAt.toIso8601String(),
        'note': note,
      };

  factory SkinPhoto.fromMap(Map<String, dynamic> map) => SkinPhoto(
        id: map['id'],
        filePath: map['filePath'] ?? '',
        takenAt: DateTime.tryParse(map['takenAt'] ?? '') ?? DateTime.now(),
        note: map['note'] ?? '',
      );
}
