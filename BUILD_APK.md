# Guide de génération d'APK - PediCare Mobile

## ✅ Code poussé sur GitHub
Le code source est disponible sur : https://github.com/wafachabbi/pedicare_mobile.git

## ⚠️ Problème de build actuel

Le build APK rencontre actuellement une erreur avec le plugin `flutter_local_notifications` et `zipflinger` :
```
Execution failed for task ':flutter_local_notifications:generateReleaseRFile'.
> com/android/zipflinger/Archive
```

Cette erreur est liée à une incompatibilité entre Gradle 9.3.1 et certaines bibliothèques Android.

## 🔧 Solutions possibles

### Solution 1 : Builder depuis Android Studio
1. Ouvrez le projet dans Android Studio
2. Ouvrez le dossier `android`
3. Laissez Gradle se synchroniser
4. Dans le menu : Build > Generate Signed Bundle / APK
5. Sélectionnez APK
6. Utilisez le keystore `pedicare-release.jks` avec le mot de passe `pedicare2024`

### Solution 2 : Utiliser une version différente de Java
Si vous avez Java 17 installé (requis pour une meilleure compatibilité) :
```powershell
flutter config --jdk-dir="C:\Program Files\Java\jdk-17"
flutter clean
flutter build apk --release
```

### Solution 3 : Build sans les plugins problématiques (temporaire)
Commentez temporairement `flutter_local_notifications` dans `pubspec.yaml` :
```yaml
dependencies:
  # flutter_local_notifications: ^18.0.1
```

Puis :
```powershell
flutter pub get
flutter clean
flutter build apk --release
```

### Solution 4 : Utiliser GitHub Actions
Créez un workflow GitHub Actions qui build l'APK dans un environnement contrôlé.

## 📦 Configuration du build

### Package name
- Release: `com.pedicare.ai`
- Debug: `com.pedicare.ai.debug`

### Signature Release
- Keystore: `android/app/pedicare-release.jks`
- Password: `pedicare2024`
- Alias: `pedicare`

### Versions
- compileSdk: 36
- targetSdk: 36
- minSdk: 21 (ou selon flutter.minSdkVersion)
- Gradle: 9.3.1
- Java: 25.0.3 (incompatible avec Gradle < 9.1)

## 📱 Firebase Configuration
Le fichier `google-services.json` a été mis à jour pour supporter :
- Package release: `com.pedicare.ai`
- Package debug: `com.pedicare.ai.debug`

## 🚀 Commandes utiles

### Nettoyer le projet
```powershell
flutter clean
```

### Vérifier l'environnement
```powershell
flutter doctor
```

### Build APK (splitté par architecture)
```powershell
flutter build apk --split-per-abi
```

### Build APK universal
```powershell
flutter build apk --release
```

### Build APK debug
```powershell
flutter build apk --debug
```

## 📝 Modifications effectuées

1. ✅ Mise à jour de `google-services.json` pour les packages `com.pedicare.ai` et `com.pedicare.ai.debug`
2. ✅ Désactivation de la minification dans `build.gradle.kts` (pour éviter les problèmes de build)
3. ✅ Désactivation du buildDir personnalisé dans `android/build.gradle.kts`
4. ✅ Mise à jour du `.gitignore` pour exclure les fichiers de build volumineux
5. ✅ Code poussé sur GitHub

## 🔍 Localisation des APK générés

Une fois le build réussi, les APK seront dans :
- Universal APK: `build/app/outputs/flutter-apk/app-release.apk`
- Split APKs:
  - `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
  - `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
  - `build/app/outputs/flutter-apk/app-x86_64-release.apk`

## 💡 Recommandation

La meilleure solution à court terme est d'utiliser **Android Studio** pour générer l'APK, car il gère mieux les dépendances Gradle et les problèmes de compatibilité.

---
*Dernière mise à jour : 11 janvier 2027*
