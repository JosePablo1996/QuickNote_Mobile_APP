plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.quicknote.quicknote"
    compileSdk = 36  // ✅ CAMBIADO: 34 → 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // ✅ AGREGADO: Habilitar desugaring para soporte de Java 8+
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.quicknote.quicknote"
        // ✅ CAMBIADO: usar 21 en lugar de flutter.minSdkVersion (requerido para desugaring)
        minSdk = flutter.minSdkVersion
        // ✅ CAMBIADO: usar 34 en lugar de flutter.targetSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // ✅ AGREGADO: Habilitar multidex para evitar límite de métodos
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// ✅ AGREGADO: Dependencia para desugaring (soporte de Java 8+)
// ✅ ACTUALIZADO: 2.0.4 → 2.1.4
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
