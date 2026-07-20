# Flutter-specific ProGuard rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep http package
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep SharedPreferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# General rules
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
