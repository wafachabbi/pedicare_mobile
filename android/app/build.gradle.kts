plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pedicare.ai"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.pedicare.ai"
        minSdk = 23
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ── Signature release ────────────────────────────────────────────────────
    signingConfigs {
        create("release") {
            storeFile     = file("pedicare-release.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "pedicare2024"
            keyAlias      = System.getenv("KEY_ALIAS")         ?: "pedicare"
            keyPassword   = System.getenv("KEY_PASSWORD")      ?: "pedicare2024"
        }
    }

    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".debug"
            versionNameSuffix   = "-debug"
        }
        getByName("release") {
            signingConfig     = signingConfigs.getByName("release")
            isMinifyEnabled   = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // ── APK split par architecture ────────────────────────────────────────────
    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a", "armeabi-v7a", "x86_64")
            isUniversalApk = true
        }
    }
}

// Forcer le chemin CMake pour tous les sous-projets (fix plugin jni)
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            val android = ext as? com.android.build.gradle.BaseExtension ?: return@let
            android.compileSdkVersion(36)
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
