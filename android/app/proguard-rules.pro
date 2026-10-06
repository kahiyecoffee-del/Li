# ML Kit text recognition: the plugin references the optional Chinese,
# Devanagari, Japanese and Korean recognizers. LifeOS only bundles the Latin
# model, so those classes are intentionally absent.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
