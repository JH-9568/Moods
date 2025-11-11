plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val env: MutableMap<String, String> = mutableMapOf<String, String>().apply {
    val envFile = rootProject.file(".env")
    if (envFile.exists()) {
        envFile.readLines().forEach { rawLine ->
            val line = rawLine.trim()
            if (line.isEmpty() || line.startsWith("#")) return@forEach
            val idx = line.indexOf("=")
            if (idx <= 0) return@forEach
            val key = line.substring(0, idx).trim()
            val value = line.substring(idx + 1).trim()
            if (key.isNotEmpty()) {
                this[key] = value
            }
        }
    }
}

android {
    namespace = "com.moodsapp.moods"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.moodsapp.moods"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        val mapsKey =
            env["MAPS_API_KEY_ANDROID"] ?: env["MAPS_API_KEY"] ?: (project.findProperty("MAPS_API_KEY") as String?) ?: ""
        val kakaoKey = env["KAKAO_NATIVE_APP_KEY"] ?: (project.findProperty("KAKAO_NATIVE_APP_KEY") as String?)

        manifestPlaceholders.putAll(
            mapOf(
                "MAPS_API_KEY" to mapsKey,
                "KAKAO_SCHEME" to (kakaoKey?.let { "kakao$it" } ?: "kakao"),
            ),
        )
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
