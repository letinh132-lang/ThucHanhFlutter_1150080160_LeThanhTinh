// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin phải đứng sau Android & Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.restaurant_review_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Application ID của bạn (phải trùng với package khi thêm app trên Firebase)
        applicationId = "com.example.restaurant_review_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Tạm dùng debug signing để chạy nhanh (đổi sang keystore khi phát hành)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

// ✅ Áp dụng plugin Google Services bằng cú pháp Kotlin DSL
apply(plugin = "com.google.gms.google-services")
