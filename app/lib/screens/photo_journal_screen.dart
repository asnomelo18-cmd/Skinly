import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/date_utils.dart';
import '../models/skin_photo.dart';
import '../providers/photo_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_widgets.dart';
import '../widgets/stat_pill.dart';
import 'photo_compare_screen.dart';
import 'photo_viewer_screen.dart';

class PhotoJournalScreen extends StatelessWidget {
  const PhotoJournalScreen({super.key});

  Future<void> _openAddSheet(BuildContext context) async {
    final provider = context.read<PhotoProvider>();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Ajouter une photo',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !context.mounted) return;
    final added = await provider.addPhoto(source: source);
    if (added && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo ajoutée à ton journal ✨')),
      );
    }
  }

  Map<String, List<SkinPhoto>> _groupByMonth(List<SkinPhoto> photos) {
    final Map<String, List<SkinPhoto>> grouped = {};
    for (final photo in photos) {
      final label = '${monthLabels[photo.takenAt.month - 1]} ${photo.takenAt.year}';
      grouped.putIfAbsent(label, () => []).add(photo);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoProvider>();
    final photos = provider.all;
    final grouped = _groupByMonth(photos);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: provider.isSaving,
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
                      Text('Journal photo', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      const Text('Suis l\'évolution de ta peau au fil du temps',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                if (photos.length >= 2)
                  IconButton(
                    tooltip: 'Comparer deux photos',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PhotoCompareScreen()),
                    ),
                    icon: const Icon(Icons.compare_rounded, color: AppColors.primary),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (!provider.isLoading && photos.isNotEmpty)
              Row(
                children: [
                  StatPill(
                    icon: Icons.photo_camera_back_outlined,
                    value: '${photos.length}',
                    label: 'Photos',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  StatPill(
                    icon: Icons.calendar_today_outlined,
                    value: '${DateTime.now().difference(photos.last.takenAt).inDays}j',
                    label: 'Depuis la 1ère',
                    color: AppColors.secondary,
                  ),
                ],
              ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => _openAddSheet(context),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Ajouter une photo',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (provider.isLoading)
              const PhotoGridSkeleton()
            else if (photos.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: EmptyState(
                  icon: Icons.photo_camera_back_outlined,
                  message:
                      'Aucune photo pour l\'instant.\nAjoute ta première photo pour démarrer ton suivi 📸',
                ),
              )
            else
              ...grouped.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key[0].toUpperCase() + entry.key.substring(1),
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: entry.value.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemBuilder: (context, i) {
                            final photo = entry.value[i];
                            return _PhotoThumbnail(photo: photo);
                          },
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final SkinPhoto photo;
  const _PhotoThumbnail({required this.photo});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoProvider>();
    final deleting = provider.isDeleting(photo.id);

    return GestureDetector(
      onTap: deleting
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PhotoViewerScreen(photo: photo)),
              ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: LoadingOverlay(
          isLoading: deleting,
          child: Ink.image(
            image: FileImage(File(photo.filePath)),
            fit: BoxFit.cover,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.45), Colors.transparent],
                  ),
                ),
                child: Text(
                  '${photo.takenAt.day}/${photo.takenAt.month}',
                  style: const TextStyle(color: Colors.white, fontSize: 9.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
