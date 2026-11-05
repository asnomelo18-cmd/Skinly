import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Écran de chargement initial de l'app, affiché pendant que les providers
/// se chargent depuis le stockage local. Remplace un simple spinner nu par
/// quelque chose de cohérent avec l'identité de l'app.
class SkinlyLoadingScreen extends StatelessWidget {
  const SkinlyLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                gradient: AppColors.gradientPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.spa_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'Skinly',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 18),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloc rectangulaire "pulsant" utilisé comme brique de base pour les
/// squelettes de chargement (skeleton loaders).
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _opacity =
      Tween<double>(begin: 0.5, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: child,
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }
}

/// Squelette d'une carte de routine, utilisé le temps que les données
/// se chargent (écrans Aujourd'hui / Routines).
class RoutineCardSkeleton extends StatelessWidget {
  const RoutineCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const ShimmerBox(
            width: 44,
            height: 44,
            borderRadius: BorderRadius.all(Radius.circular(22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(height: 14, width: 140),
                SizedBox(height: 10),
                ShimmerBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grille de vignettes fantômes pour le journal photo pendant le chargement.
class PhotoGridSkeleton extends StatelessWidget {
  final int count;
  const PhotoGridSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, i) => ShimmerBox(
        height: double.infinity,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

/// Bouton plein-largeur qui affiche un spinner à la place de son label
/// pendant une action asynchrone (ex: enregistrer une routine, ajouter une
/// photo), pour éviter les double-taps et donner un retour visuel immédiat.
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: foregroundColor ?? Colors.white,
        disabledBackgroundColor: (backgroundColor ?? AppColors.primary).withOpacity(0.7),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: isLoading ? null : onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: isLoading
            ? const SizedBox(
                key: ValueKey('loading'),
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : KeyedSubtree(key: const ValueKey('label'), child: child),
      ),
    );
  }
}

/// Petit voile semi-transparent avec spinner, à poser au-dessus d'un
/// contenu (ex: une grille de photos) pendant une action de fond.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }
}
