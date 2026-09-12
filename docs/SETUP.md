# Bugarin Mobile — Setup

## Prasyarat
- Flutter SDK (≥ 3.24) + Android Studio (Android) dan/atau Xcode (iOS, khusus macOS) — toolchain per-mesin, wajib install manual sendiri, tidak ikut ter-clone.
- Backend (`be-bugarin`) sudah jalan — lokal ATAU sudah di-deploy ke Render.

## Setup

```bash
git clone https://github.com/pbl-semester-3/mobile-bugarin.git
cd mobile-bugarin

flutter pub get

# WAJIB — provider (@riverpod) dan tabel Drift (@DriftDatabase) butuh file *.g.dart
# yang di-generate, bukan opsional:
dart run build_runner build --delete-conflicting-outputs

flutter analyze
```

## Konfigurasi API URL

Flutter tidak pakai `.env` bawaan — pakai `--dart-define`:

```bash
# Emulator Android + backend lokal:
flutter run --dart-define=API_URL=http://10.0.2.2:4000

# Backend sudah di-deploy ke Render (paling gampang untuk kerja tim, semua orang konsisten):
flutter run --dart-define=API_URL=https://bugarin-backend-xxxx.onrender.com
```

> `localhost` dari dalam Android emulator **tidak** menunjuk ke laptop kamu — pakai `10.0.2.2` untuk emulator, IP lokal (`192.168.x.x`) untuk HP fisik dalam satu WiFi, atau langsung URL backend yang sudah di-deploy supaya semua anggota tim connect ke sumber yang sama.

Selama development, jalankan build_runner mode watch:
```bash
dart run build_runner watch -d
```

## Struktur Project

```
lib/
 ├─ config/env.dart        # API_URL via --dart-define
 ├─ services/               # TokenStorage, ApiClient (Dio + interceptor)
 ├─ providers/              # authStateNotifierProvider, apiClientProvider
 ├─ router/app_router.dart  # GoRouter + auth guard reaktif
 ├─ shell/main_shell.dart   # bottom navigation 5 tab
 ├─ db/local_database.dart  # Drift — cache master data & weekly plan
 └─ features/               # 1 folder per screen — masih STUB
```

## Yang Perlu Dikerjakan Selanjutnya
Lihat `docs/Bugarin_PRD_Mobile.md` bab 3 untuk detail tiap screen. Semua screen di `features/` masih stub dengan komentar TODO merujuk ke bab PRD terkait.

> ⚠️ Scaffold ini ditulis tanpa Flutter SDK tersedia di sisi pembuatnya — jalankan `flutter analyze` sebagai langkah pertama untuk nangkep kalau ada typo/error yang kelewat sebelum lanjut ngoding.
