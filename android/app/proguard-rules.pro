# Aturan ProGuard/R8 untuk Bugarin.
# 1) flutter_secure_storage memakai Tink untuk enkripsi.
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# 2) Plugin Flutter & kode Pigeon (generated): dipanggil via method channel /
#    nama method, sehingga tidak boleh dihapus/di-obfuscate. Tanpa ini,
#    mis. shared_preferences gagal dengan NoSuchMethodError("getAll").
-keep class io.flutter.plugins.** { *; }
-keep class dev.flutter.pigeon.** { *; }

# 3) Kotlin coroutines (dipakai suspend function Pigeon/plugin). R8 cenderung
#    menghapus kelas internal seperti CoroutineSingletons -> ClassNotFoundException.
-keep class kotlin.coroutines.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**
