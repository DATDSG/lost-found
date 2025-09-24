plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after Android and Kotlin plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.lostfound"

    // Use versions provided by the Flutter plugin
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.lostfound"
        // Ensure minSdk ≥ 21 for notifications + desugaring
        minSdk = maxOf(21, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // Keep debug signing for quick runs; replace with your release config when signing
            signingConfig = signingConfigs.getByName("debug")
            // isMinifyEnabled = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Kotlin DSL uses parentheses, not spaces/quotes like Groovy
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.core:core-splashscreen:1.0.1")
    // add any other deps here using implementation("group:artifact:version")
}
