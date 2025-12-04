# MindScribe ProGuard Rules for Production

# Keep Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Play Core (for app bundles)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Keep notification classes
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

# Keep speech recognition
-keep class com.google.android.gms.** { *; }

# Keep model classes (for database)
-keep class com.mindscribe.diary.** { *; }

# Keep Gson (if used)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Remove logging in production
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}