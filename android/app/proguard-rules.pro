## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

## Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

## Play Core (required by Flutter plugins, may not be on classpath)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

## Missing class referenced by FlutterPlayStoreSplitApplication
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication

## Suppress all R8 missing class warnings (safe for release builds)
-ignorewarnings
