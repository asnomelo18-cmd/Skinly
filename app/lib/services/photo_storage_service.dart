import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Gère la copie des photos choisies par l'utilisateur vers un dossier
/// stable de l'application (les fichiers temporaires du picker peuvent être
/// nettoyés par l'OS, donc on ne garde jamais que notre propre copie).
class PhotoStorageService {
  static const _subfolder = 'skin_journal';
  final ImagePicker _picker = ImagePicker();

  Future<Directory> _journalDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, _subfolder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Ouvre la caméra ou la galerie, puis copie l'image choisie dans le
  /// dossier de l'app. Retourne le chemin final, ou `null` si l'utilisateur
  /// a annulé.
  Future<String?> pickAndStoreImage({required ImageSource source}) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 88,
    );
    if (picked == null) return null;

    final dir = await _journalDirectory();
    final ext = p.extension(picked.path).isNotEmpty ? p.extension(picked.path) : '.jpg';
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$ext';
    final destPath = p.join(dir.path, fileName);

    final bytes = await picked.readAsBytes();
    final destFile = File(destPath);
    await destFile.writeAsBytes(bytes, flush: true);

    return destPath;
  }

  Future<void> deleteImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Si le fichier est déjà absent, on ignore silencieusement.
    }
  }
}
