# Aturan ProGuard/R8 untuk Bugarin.
# 1) flutter_secure_storage memakai Tink untuk enkripsi.
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# 2) Plugin Flutter & kode Pigeon (generated): dipanggil via method channel /
#    nama method, sehingga tidak boleh dihapus/di-obfuscate. Tanpa ini,
#    mis. shared_preferences gagal dengan NoSuchMethodError("getAll") dan
#    aplikasi black screen saat startup di build release.
-keep class io.flutter.plugins.** { *; }
-keep class dev.flutter.pigeon.** { *; }

# 3) Tipe parameter suspend function (Continuation) dipakai di signature
#    Pigeon; jangan di-rename agar signature tetap cocok saat runtime.
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.CoroutineContext { *; }
