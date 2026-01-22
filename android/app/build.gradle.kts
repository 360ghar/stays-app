plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Apply Google Services plugin here (only once, not at bottom)
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.stays_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.stays_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 🔹 Flavor setup
    flavorDimensions += listOf("env")

    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "360ghar stays (Dev)")
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".staging"
            resValue("string", "app_name", "360ghar stays (Staging)")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "360ghar stays")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // 🔹 Automatically pick correct google-services.json based on flavor
    sourceSets {
        getByName("dev") {
            res.srcDirs("src/dev/res")
            // Place your dev google-services.json here:
            // android/app/src/dev/google-services.json
        }
        getByName("staging") {
            res.srcDirs("src/staging/res")
            // Place staging google-services.json here:
            // android/app/src/staging/google-services.json
        }
        getByName("prod") {
            res.srcDirs("src/prod/res")
            // Place prod google-services.json here:
            // android/app/src/prod/google-services.json
        }
    }
}

flutter {
    source = "../.."
}
