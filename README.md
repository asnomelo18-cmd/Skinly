<p align="center">
  <img src="docs/logo.png" width="120" alt="Skinly">
</p>

<h1 align="center">Skinly</h1>
<p align="center">Ta routine skincare, tes rappels, ton évolution. Tout reste sur ton téléphone.</p>

---

## Fonctionnalités

- **Routines illimitées** : crée tes propres routines (matin, soir, masque…) avec tes produits, dans l'ordre d'application
- **Produits personnalisés** : nom, catégorie (nettoyant, sérum, hydratant, SPF, exfoliant…) et notes
- **Jours au choix** : chaque routine a ses jours de la semaine et son heure
- **Vrais rappels** : notifications hebdomadaires récurrentes, même application fermée
- **Aujourd'hui** : uniquement les routines du jour, avec une case à cocher par produit
- **Série et statistiques** : jours consécutifs, pourcentage de la semaine, détail par routine
- **Calendrier** : vue mensuelle (complété, partiel, manqué), avec cases modifiables rétroactivement
- **Journal photo avant / après** : photos datées avec notes, comparateur à curseur
- **Diagnostic notifications** : permissions, alarmes exactes, test en 5 secondes
- **100 % local** : aucun compte, aucun serveur

## Structure du dépôt

```
skinly/
├── app/      Application mobile Flutter (Android)
└── docs/     Logo, captures d'écran
```

## Architecture de l'app

```
app/lib/
├── models/       Routine, étapes, photos, dates
├── providers/    État (routines, photos) + sauvegarde locale
├── services/     Notifications, stockage des photos
├── screens/      Aujourd'hui, Routines, Photos, Calendrier, Suivi
├── widgets/      Barre de navigation flottante, chargements, cartes
└── theme/        Palette crème, corail, sauge
```

## Développement

**App mobile** (Flutter 3.x)
```bash
cd app
flutter pub get
dart run flutter_launcher_icons   # génère l'icône à partir de assets/icon/icon.png
flutter run                       # téléphone branché en débogage USB
flutter build apk --release       # APK de distribution
```

**Notifications (Android)** : les permissions et le *core library desugaring* sont déjà configurés
dans `app/android`. Sur certains téléphones (Xiaomi, Huawei, Oppo, Vivo, Samsung), désactive
l'optimisation de batterie pour Skinly. L'écran **Diagnostic notifications** (icône cloche sur
l'écran Aujourd'hui) t'indique quoi vérifier.

## Technologies

Flutter · Dart · Provider · flutter_local_notifications · timezone · image_picker · shared_preferences

## Auteur

Christ-Roland — étudiant en Informatique et Développement d'Applications, Abidjan
