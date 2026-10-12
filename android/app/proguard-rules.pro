# Firebase/ML Kit/CameraX ship their own consumer rules, so this file only
# covers what R8 cannot see on its own.

# flutter_local_notifications deserializes its scheduled-notification models
# with Gson reflection; R8 otherwise strips the fields.
-keep class com.dexterous.** { *; }

# The notification tap callback is reached from a background isolate.
-keep class io.flutter.plugins.** { *; }
