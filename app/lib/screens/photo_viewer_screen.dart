import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/date_utils.dart';
import '../models/skin_photo.dart';
import '../providers/photo_provider.dart';
import '../theme/app_theme.dart';

class PhotoViewerScreen extends StatefulWidget {
  final SkinPhoto photo;
  const PhotoViewerScreen({super.key, required this.photo});

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final TextEditingController _noteController =
      TextEditingController(text: widget.photo.note);
  bool _savingNote = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() => _savingNote = true);
    await context.read<PhotoProvider>().updateNote(widget.photo.id, _noteController.text.trim());
    if (mounted) setState(() => _savingNote = false);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Supprimer cette photo ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<PhotoProvider>().deletePhoto(widget.photo.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoProvider>();
    final deleting = provider.isDeleting(widget.photo.id);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(formatFullDate(widget.photo.takenAt)),
        actions: [
          IconButton(
            onPressed: deleting ? null : _confirmDelete,
            icon: deleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Image.file(File(widget.photo.filePath), fit: BoxFit.contain),
            ),
          ),
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Ajouter une note (ex: J15 - rétinol)',
                    ),
                    onSubmitted: (_) => _saveNote(),
                  ),
                ),
                const SizedBox(width: 8),
                _savingNote
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary),
                      )
                    : IconButton(
                        onPressed: _saveNote,
                        icon: const Icon(Icons.check_circle_outline, color: AppColors.primary),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
