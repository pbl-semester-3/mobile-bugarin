# Bugarin Mobile

Flutter + Riverpod + GoRouter + Dio + Drift — Mobile App Klien.

**Sebelum mulai**: baca `Bugarin_PRD_Mobile.md` dan skill di folder `skill/` (`flutter-riverpod-patterns`, `dio-jwt-networking`, `drift-offline-cache`, `gorouter-navigation-bugarin`, `flutter-form-validation`).

> ⚠️ **Catatan jujur**: scaffold ini ditulis manual tanpa Flutter SDK tersedia di sisi saya (nggak bisa `flutter pub get`/`flutter analyze` buat verifikasi otomatis, beda dari scaffold Backend & Frontend yang sudah saya build & typecheck). Jalankan `flutter analyze` sebagai langkah pertama sebelum lanjut ngoding, buat nangkep kalau ada typo/error yang kelewat.

## Setup

Lihat `docs/SETUP.md` untuk panduan lengkap (konfigurasi API URL, dst). Ringkas:

```bash
flutter pub get

# WAJIB — provider (@riverpod) dan tabel Drift (@DriftDatabase) di scaffold ini
# butuh file *.g.dart yang di-generate, bukan opsional:
dart run build_runner build --delete-conflicting-outputs

flutter analyze          # cek dulu sebelum run, lihat catatan di atas

flutter run --dart-define=API_URL=http://10.0.2.2:4000   # 10.0.2.2 = alias localhost dari Android emulator
```

Selama development, jalankan build_runner dalam mode watch supaya `*.g.dart` auto-update tiap provider/tabel baru ditambah:
```bash
dart run build_runner watch -d
```

## Struktur

```
lib/
 ├─ config/env.dart        # API_URL via --dart-define
 ├─ services/               # TokenStorage (flutter_secure_storage), ApiClient (Dio + interceptor)
 ├─ providers/              # authStateNotifierProvider (sealed class), apiClientProvider
 ├─ router/app_router.dart  # GoRouter + auth guard reaktif (refreshListenable)
 ├─ shell/main_shell.dart   # bottom navigation 5 tab, Profil via ikon terpisah
 ├─ db/local_database.dart  # Drift — cache master data & weekly plan
 └─ features/               # 1 folder per screen (auth, onboarding, dashboard, pt_ku,
                             #   progres, riwayat, feedback, profil) — semua masih STUB,
                             #   isi sesuai Bugarin_PRD_Mobile.md bab 3
```

## Yang Sudah Ada vs Yang Masih TODO

**Sudah ada (kerangka kerja, bukan UI final):**
- Auth guard reaktif di GoRouter (redirect otomatis berdasar state, bukan cek sekali di awal)
- Dio + secure storage + interceptor 401 → auto logout
- Sealed class `AuthState` (Unauthenticated/Authenticated) sebagai pola state auth
- Contoh 1 provider data server penuh (`dashboardSummaryProvider`) sebagai referensi pola untuk provider lain

**Masih TODO (tiap screen ada komentar TODO merujuk ke bab PRD terkait):**
- Semua form (Login, Register, Onboarding, Profil) — lihat skill `flutter-form-validation`
- Provider untuk PT ku, Progres, Riwayat, Feedback — ikuti pola `dashboardSummaryProvider` yang sudah ada
- Sinkronisasi cache Drift (`syncOlahraga`, `syncMakanan`, cache weekly plan) — lihat skill `drift-offline-cache`
- `_restoreSession()` di `auth_provider.dart` masih placeholder (return role dummy) — ganti dengan panggilan nyata ke `GET /klien/profile`
