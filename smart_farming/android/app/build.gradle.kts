plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // ✅ Tambahkan baris ini untuk mengaktifkan plugin Firebase Google Services
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.smart_farming"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

   defaultConfig {
    applicationId = "com.example.smart_farming"
    minSdk = flutter.minSdkVersion  // ✅ Set eksplisit (minimal untuk Flutter)
    targetSdk = 33  // ✅ Set eksplisit
    versionCode = flutter.versionCode
    versionName = flutter.versionName
    multiDexEnabled = true  // ✅ Tambahkan ini
}

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}
