# Evita que se eliminen las clases necesarias para las peticiones HTTP y JSON
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-keep class com.google.gson.** { *; }
-keep class io.flutter.plugin.** { *; }

# Mantiene las firmas de funciones y anotaciones
-keepattributes Signature
-keepattributes *Annotation*

# No mostrar warnings de esas librerías
-dontwarn okhttp3.**
-dontwarn retrofit2.**
-dontwarn com.google.gson.**
