import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/skin_photo.dart';
import '../providers/photo_provider.dart';
import '../theme/app_theme.dart';

class PhotoCompareScreen extends StatefulWidget {
  const PhotoCompareScreen({super.key});

  @override
  State<PhotoCompareScreen> createState() => _PhotoCompareScreenState();
}

class _PhotoCompareScreenState extends State<PhotoCompareScreen> {
  SkinPhoto? _before;
  SkinPhoto? _after;

  @override
  Widget build(BuildContext context) {
    final photos = context.watch<PhotoProvider>().all; // récent -> ancien
    if (_before == null || _after == null) {
      _after = photos.first;
      _before = photos.last;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Avant / Après'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _CompareSlider(before: _before!, after: _after!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _PhotoPickerRow(
              label: 'Avant',
              photos: photos,
              selected: _before!,
              onSelect: (p) => setState(() => _before = p),
            ),
            const SizedBox(height: 12),
            _PhotoPickerRow(
              label: 'Après',
              photos: photos,
              selected: _after!,
              onSelect: (p) => setState(() => _after = p),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PhotoPickerRow extends StatelessWidget {
  final String label;
  final List<SkinPhoto> photos;
  final SkinPhoto selected;
  final ValueChanged<SkinPhoto> onSelect;

  const _PhotoPickerRow({
    required this.label,
    required this.photos,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final photo = photos[i];
              final isSelected = photo.id == selected.id;
              return GestureDetector(
                onTap: () => onSelect(photo),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.file(File(photo.filePath), fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Comparateur avant/après avec un curseur vertical qu'on glisse pour
/// révéler progressivement la photo "avant" par-dessus la photo "après".
class _CompareSlider extends StatefulWidget {
  final SkinPhoto before;
  final SkinPhoto after;

  const _CompareSlider({required this.before, required this.after});

  @override
  State<_CompareSlider> createState() => _CompareSliderState();
}

class _CompareSliderState extends State<_CompareSlider> {
  double _position = 0.5; // 0 = tout "après", 1 = tout "avant"

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _position = (details.localPosition.dx / width).clamp(0.0, 1.0);
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(widget.after.filePath), fit: BoxFit.cover),
              ClipRect(
                clipper: _LeftClipper(fraction: _position),
                child: Image.file(File(widget.before.filePath), fit: BoxFit.cover),
              ),
              Positioned(
                left: (width * _position - 1).clamp(0.0, width - 2),
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: Colors.white),
              ),
              Positioned(
                left: (width * _position - 18).clamp(0.0, width - 36),
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6),
                      ],
                    ),
                    child: const Icon(Icons.drag_handle, color: AppColors.primary, size: 18),
                  ),
                ),
              ),
              const Positioned(
                top: 10,
                left: 10,
                child: _Badge(text: 'Avant'),
              ),
              const Positioned(
                top: 10,
                right: 10,
                child: _Badge(text: 'Après'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  final double fraction;
  _LeftClipper({required this.fraction});

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(covariant _LeftClipper oldClipper) => oldClipper.fraction != fraction;
}
