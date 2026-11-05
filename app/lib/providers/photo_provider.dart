import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/skin_photo.dart';
import '../services/photo_storage_service.dart';

/// Fournit la liste des photos du journal de peau, avec des indicateurs de
/// chargement séparés pour que l'UI puisse afficher le bon état :
/// - [isLoading] : chargement initial de la liste depuis le disque
/// - [isSaving] : une photo est en train d'être choisie/copiée/enregistrée
/// - [deletingIds] : quelles photos sont en cours de suppression
class PhotoProvider extends ChangeNotifier {
  static const _photosKey = 'skin_journal_photos_v1';

  final _uuid = const Uuid();
  final _storage = PhotoStorageService();

  List<SkinPhoto> _photos = [];
  bool _isLoading = true;
  bool _isSaving = false;
  final Set<String> _deletingIds = {};

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool isDeleting(String id) => _deletingIds.contains(id);

  /// Photos triées de la plus récente à la plus ancienne.
  List<SkinPhoto> get all {
    final sorted = List<SkinPhoto>.from(_photos);
    sorted.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return List.unmodifiable(sorted);
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_photosKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        _photos = decoded
            .map((item) => SkinPhoto.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _photos = [];
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_photos.map((p) => p.toMap()).toList());
    await prefs.setString(_photosKey, encoded);
  }

  /// Ouvre l'appareil photo ou la galerie, copie l'image et l'ajoute au
  /// journal. Retourne `true` si une photo a bien été ajoutée.
  Future<bool> addPhoto({required ImageSource source, String note = ''}) async {
    _isSaving = true;
    notifyListeners();
    try {
      final path = await _storage.pickAndStoreImage(source: source);
      if (path == null) {
        return false;
      }
      final photo = SkinPhoto(
        id: _uuid.v4(),
        filePath: path,
        takenAt: DateTime.now(),
        note: note,
      );
      _photos.add(photo);
      await _persist();
      return true;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateNote(String id, String note) async {
    final photo = _photos.where((p) => p.id == id).firstOrNull;
    if (photo == null) return;
    photo.note = note;
    notifyListeners();
    await _persist();
  }

  Future<void> deletePhoto(String id) async {
    _deletingIds.add(id);
    notifyListeners();
    try {
      final photo = _photos.where((p) => p.id == id).firstOrNull;
      if (photo != null) {
        await _storage.deleteImage(photo.filePath);
      }
      _photos.removeWhere((p) => p.id == id);
      await _persist();
    } finally {
      _deletingIds.remove(id);
      notifyListeners();
    }
  }

  String newId() => _uuid.v4();
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
