# Aturan ProGuard/R8 untuk Bugarin.
# flutter_secure_storage memakai Tink untuk enkripsi; tanpa keep rules,
# R8 menghapus class Tink di build release sehingga secure storage gagal
# (menyebabkan aplikasi crash/black screen saat startup).
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
