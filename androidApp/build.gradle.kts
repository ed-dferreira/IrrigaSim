plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.compose")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.irrigasim.android"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.irrigasim.android"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.3"
    }
}

dependencies {
    implementation(project(":shared"))
    implementation(platform("androidx.compose:compose-bom:2024.02.02"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.activity:activity-compose:1.8.2")

    // Firebase
    implementation(platform("com.google.firebase:firebase-bom:32.7.2"))
    implementation("com.google.firebase:firebase-auth-ktx")

    // Google Sign-In (Credential Manager)
    implementation("androidx.credentials:credentials:1.3.0-alpha01")
    implementation("androidx.credentials:credentials-play-services-auth:1.3.0-alpha01")
    implementation("com.google.android.libraries.identity.googleid:googleid:1.1.0")

    // Lifecycle
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
}
