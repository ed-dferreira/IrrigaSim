# Proguard rules for IrrigaSIM

# Keep Kotlin metadata
-keepattributes *Annotation*

# Keep data classes
-keepclassmembers class * {
    @kotlinx.serialization.Serializable <fields>;
}

# Keep Compose
-dontwarn androidx.compose.**
-keep class androidx.compose.** { *; }

# Keep Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep Google Identity / Credential Manager
-keep class com.google.android.libraries.identity.** { *; }
-dontwarn com.google.android.libraries.identity.**
-keep class androidx.credentials.** { *; }
-dontwarn androidx.credentials.**

# Keep domain models
-keep class com.irrigasim.domain.** { *; }
-keep class com.irrigasim.network.models.** { *; }
