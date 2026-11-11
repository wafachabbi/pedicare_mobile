# ── Flutter ──────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# ── SQLite (sqflite) ──────────────────────────────────────────────────────────
-keep class com.tekartik.sqflite.** { *; }

# ── Notifications ─────────────────────────────────────────────────────────────
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# ── Tesseract OCR ─────────────────────────────────────────────────────────────
-keep class com.googlecode.tesseract.** { *; }

# ── Shared Preferences ───────────────────────────────────────────────────────
-keep class androidx.datastore.** { *; }

# ── Image Picker ──────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.imagepicker.** { *; }

# ── JNI (flutter_tesseract_ocr natif) ────────────────────────────────────────
-keep class dev.dart.jni.** { *; }

# ── Google Generative AI ──────────────────────────────────────────────────────
-keep class com.google.ai.** { *; }
-dontwarn com.google.ai.**

# ── Général Kotlin / Coroutines ───────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlin.**
