# Bugarin Mobile — Aplikasi Klien

Aplikasi mobile **Bugarin** untuk **klien**: platform kebugaran personal yang menghubungkan klien dengan **Personal Trainer (PT)** dan **asisten AI** untuk menyusun program latihan, rencana makan, serta memantau progres harian.

Dibangun dengan **Flutter** (Riverpod, GoRouter, Dio, Drift) dan terintegrasi dengan REST API Bugarin.

![Flutter](https://img.shields.io/badge/Flutter-3.47.5-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-%3E%3D3.5-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![CI](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)

---

## Daftar Isi

- [Tentang](#tentang)
- [Fitur Utama](#fitur-utama)
- [Alur Penggunaan Klien](#alur-penggunaan-klien)
- [Arsitektur Aplikasi](#arsitektur-aplikasi)
- [Struktur Direktori](#struktur-direktori)
- [Teknologi & Dependensi](#teknologi--dependensi)
- [Prasyarat](#prasyarat)
- [Memulai](#memulai)
- [Konfigurasi API & Menjalankan](#konfigurasi-api--menjalankan)
- [Build & Rilis APK](#build--rilis-apk)
- [Penyimpanan & Keamanan](#penyimpanan--keamanan)
- [Pengujian & Kualitas](#pengujian--kualitas)
- [Integrasi API](#integrasi-api)
- [Alur Kontribusi](#alur-kontribusi)

---

## Tentang

Bugarin adalah sistem monitoring kebugaran dengan dua peran utama:

- **Klien** — memantau progres, mencatat asupan makan & aktivitas, memilih PT, dan menerima arahan.
- **Personal Trainer (PT)** — mengirim feedback dan menyusun/menyetujui program klien melalui platform web.

Aplikasi ini adalah **sisi klien** (Android). PT dan Admin menggunakan platform web terpisah. Backend & AI berjalan di layanan terpusat (`https://api.bugarin.my.id`).

**Nilai utama aplikasi bagi klien:**

- Target kalori & siklus progres personal yang dihitung backend/AI.
- Pencatatan makan dan olahraga yang cepat, termasuk **latihan beban** (beban, set, repetisi, jeda) dengan estimasi kalori berbasis AI.
- Umpan balik dari **Coach (PT)** dan **AI** dalam satu feed.
- Riwayat progres per siklus yang transparan.
- Tetap nyaman dipakai saat jaringan tidak stabil (cache lokal).

---

## Fitur Utama

### Autentikasi & Sesi
- Login dengan **email atau username** + password.
- Registrasi klien baru.
- Login via **Google (OAuth)**.
- **Lupa kata sandi** (reset via email).
- Token JWT disimpan aman dan otomatis dipakai di setiap request; sesi dipulihkan saat app dibuka.

### Onboarding & Siklus Target
- Form profil awal: usia, jenis kelamin, alergi makanan, tinggi badan, berat awal.
- Menentukan **tujuan** (turun BB / naik BB), **berat target**, dan **durasi siklus**.
- Backend menghitung target kalori harian dan menyiapkan **Weekly Plan** awal.
- Form yang sama dipakai ulang untuk **memulai siklus baru** setelah target tercapai.

### Beranda (Dashboard)
- Kartu **PT aktif** dengan foto, nama, dan spesialisasi.
- **Target kalori** harian dan **streak** progres.
- **Jadwal latihan** bersama PT (hari, jam, jenis, lokasi).
- Pengingat bila durasi siklus berakhir namun target belum tercapai.
- Badge **feedback belum dibaca**.

### PT ku
- Rekomendasi PT sesuai tujuan klien (foto, nama, spesialisasi, gym).
- Dialog detail/conﬁrmasi sebelum memilih PT.
- Pengiriman permintaan pairing dan pemantauan status (menunggu/diterima/ditolak beserta alasan).

### Progres Harian
Dua tab: **Meal (Nutrisi)** dan **Olahraga**.

**Meal:**
- Referensi **Rencana Menu Minggu Ini** dari PT/AI.
- **Meal Hari Ini** — daftar makanan yang sedang disusun (nama, kalori, porsi gram).
- **Catat Meal** — input nama menu + porsi (gram); kalori diestimasi backend (AI) untuk makanan baru.
- Total kalori otomatis, **Reset** (dengan konfirmasi), dan **Simpan Perubahan**.

**Olahraga:**
- Referensi **Rencana Latihan Minggu Ini**.
- Pilih jenis olahraga dari master data.
- **Kardio**: durasi (menit) + jarak (meter, bila diwajibkan).
- **Latihan beban** (Upper/Lower Body): berat beban (kg), repetisi, set, jeda istirahat (detik). Durasi dihitung otomatis, kalori diestimasi AI.
- **Riwayat Hari Ini** — daftar aktivitas hari ini (dimuat dari server; tetap tampil setelah app dibuka ulang).

### Riwayat
- Daftar **siklus progres** (berjalan/selesai).
- Detail per siklus: log harian berisi **kalori masuk**, **kalori keluar**, dan selisih.

### Feedback
- Feed gabungan **AI** (mingguan) dan **Coach/PT**.
- Penanda sudah dibaca dan badge jumlah yang belum dibaca.

### Profil
- **Foto profil** (unggah/hapus) yang juga tampil di header aplikasi.
- **Informasi diri**: nama, email, username, usia, jenis kelamin, alergi.
- **Detail penting**: tinggi badan, catat berat badan terbaru, progress bar menuju target.
- Banner **target tercapai** untuk memulai siklus baru.
- **Keamanan**: ubah kata sandi.
- **Tampilan**: mode terang/gelap (persisten).
- Logout.

---

## Alur Penggunaan Klien

Alur lengkap dari pertama kali membuka aplikasi sampai keluar akun:

### 1. Instalasi & Pembukaan Pertama
1. Pasang APK Bugarin, buka aplikasi.
2. Muncul **Splash** lalu **Welcome** (logo & ajakan geser untuk mulai).
3. Welcome hanya tampil sekali; setelah itu app langsung mengarah ke Login.

### 2. Registrasi / Login
1. Buat akun baru (nama, email, username, password) **atau** login dengan email/username.
2. Bisa juga **Masuk dengan Google**.
3. Lupa password? Gunakan **Lupa Kata Sandi** untuk reset via email.

### 3. Onboarding (Pertama Kali / Siklus Baru)
Jika profil belum lengkap atau belum punya siklus aktif, klien diarahkan ke **Onboarding**:
1. Isi usia, jenis kelamin, alergi makanan.
2. Isi tinggi badan dan berat badan awal.
3. Pilih tujuan (Turun BB / Naik BB), berat target, dan durasi siklus.
4. Simpan → backend menghitung **target kalori** dan menyiapkan **Weekly Plan**.

### 4. Beranda
Setelah profil lengkap, klien masuk ke aplikasi utama (navigasi bawah):
- Lihat kartu **PT aktif** (bila sudah terhubung), target kalori, streak, dan jadwal latihan.
- Bila belum punya PT, diarahkan ke tab **PT ku**.

### 5. Memilih PT (PT ku)
1. Buka tab **PT ku** → lihat rekomendasi PT sesuai tujuan.
2. Ketuk PT → muncul detail (foto, nama, spesialisasi, gym).
3. Tekan **Pilih PT** → permintaan dikirim.
4. Tunggu konfirmasi PT; status ditampilkan di halaman yang sama.

### 6. Mencatat Makan (Progres → Meal)
1. Buka **Progres → Meal (Nutrisi)**.
2. Ketik nama menu + porsi (gram), tekan **+** untuk menambah ke **Meal Hari Ini**.
3. Ulangi untuk makanan lain; total kalori ikut bertambah otomatis.
4. Gunakan **Reset** bila ingin mengosongkan, atau **Simpan Perubahan** untuk menyimpan ke riwayat kalori hari ini.

### 7. Mencatat Olahraga (Progres → Olahraga)
1. Buka **Progres → Olahraga**.
2. Pilih jenis olahraga.
3. **Kardio** → isi durasi (dan jarak bila diwajibkan).
   **Latihan beban** → isi berat beban, repetisi, set, dan jeda istirahat.
4. Tekan **Catat Latihan Ini** → kalori terbakar dihitung (AI untuk latihan beban).
5. Aktivitas muncul di **Riwayat Hari Ini**.

### 8. Melihat Riwayat
1. Buka tab **Riwayat**.
2. Pilih siklus → perluas untuk melihat log harian (kalori masuk/keluar dan selisih).

### 9. Menerima Feedback
1. Tab **Feedback** menampilkan umpan balik AI dan Coach.
2. Badge di navigasi menunjukkan jumlah feedback yang belum dibaca; membuka tab akan menandainya sudah dibaca.

### 10. Mengelola Profil
1. Ketuk avatar di kanan atas → **Profil**.
2. Unggah/ganti foto profil.
3. Perbarui informasi diri, tinggi badan, dan catat berat badan terbaru.
4. Jika target tercapai, muncul ajakan **mulai siklus baru** (membuka kembali Onboarding).
5. Ubah kata sandi, ganti tema terang/gelap, atau **logout**.

---

## Arsitektur Aplikasi

Aplikasi mengikuti pemisahan berbasis fitur (*feature-first*) dengan lapisan pendukung:

```
Presentation (Screen/Widget)
        │  (Riverpod providers)
        ▼
State & Orchestration (providers / notifiers)
        │
        ▼
Repository (kontrak + implementasi Dio)
        │
        ├─► ApiClient (Dio + interceptor JWT, 401 → logout)
        ├─► CacheRepository (Drift / No-op di web)
        └─► Secure storage (token) & SharedPreferences (setting)
```

**Prinsip kunci:**

- **Riverpod** sebagai state management; provider di-generate (`@riverpod`) dan file `*.g.dart` dibuat oleh `build_runner`.
- **GoRouter** dengan **auth guard reaktif**: redirect berdasar status sesi (welcome → login → onboarding → beranda).
- **Dio** + interceptor: menyisipkan `Authorization: Bearer <token>`; `401` memicu logout otomatis.
- **Repository pattern**: UI tidak memanggil Dio langsung; error dipetakan ke pesan ramah (`ApiException`).
- **Offline-friendly**: master data, weekly plan, dan ringkasan dashboard di-cache via **Drift** (stale-while-revalidate). Di web, cache di-bypass.
- **Keamanan**: token di **flutter_secure_storage**; setting non-rahasia (tema) di **shared_preferences**.

---

## Struktur Direktori

```
lib/
├─ main.dart                 # Bootstrap: SettingsStore init, ProviderScope, router
├─ config/
│  ├─ env.dart               # API_URL & GOOGLE_CLIENT_ID via --dart-define
│  └─ app_colors.dart
├─ core/
│  └─ theme/theme_provider.dart   # Tema terang/gelap + palet warna
├─ services/
│  ├─ api_client.dart        # Dio + interceptor JWT
│  ├─ api_error.dart         # Pemetaan error API
│  ├─ token_storage.dart     # Token JWT (secure storage)
│  └─ settings_store.dart    # Setting non-rahasia (shared_preferences) + migrasi
├─ providers/                # Provider global (auth, api client, token, welcome)
├─ router/
│  ├─ app_router.dart        # GoRouter
│  └─ auth_redirect.dart     # Logika guard (fungsi murni, mudah diuji)
├─ shell/main_shell.dart     # Bottom navigation + badge feedback
├─ db/
│  ├─ local_database.dart    # Tabel Drift (cache)
│  ├─ drift_cache_repository.dart
│  ├─ cache_repository.dart  # Kontrak cache
│  ├─ cache_backend_io.dart  # Implementasi native
│  ├─ cache_backend_stub.dart# Fallback web (no-op)
│  └─ noop_cache_repository.dart
├─ shared/widgets/           # Header, logo, widget bersama
└─ features/
   ├─ auth/                  # Login, registrasi, OAuth Google, lupa sandi, model
   ├─ onboarding/            # Profil awal & siklus target
   ├─ welcome/               # Layar sambutan
   ├─ splash/                # Splash
   ├─ dashboard/             # Beranda (PT card, kalori, streak, jadwal)
   ├─ pt_ku/                 # Rekomendasi & pairing PT
   ├─ progres/               # Meal & Olahraga (+ riwayat hari ini)
   ├─ riwayat/               # Riwayat per siklus
   ├─ feedback/              # Feed AI + Coach
   └─ profil/                # Profil, foto, keamanan, tampilan, logout
```

> **Catatan:** file `*.g.dart` (hasil `riverpod_generator` & `drift_dev`) **tidak di-commit** (lihat `.gitignore`). Wajib di-generate setelah clone/ubah provider/tabel.

---

## Teknologi & Dependensi

| Kategori | Paket | Kegunaan |
|---|---|---|
| Framework | `flutter` | UI Android |
| State | `flutter_riverpod`, `riverpod_annotation` | State management & DI |
| Routing | `go_router` | Navigasi + guard |
| HTTP | `dio` | Klien REST + interceptor |
| Cache lokal | `drift`, `sqlite3_flutter_libs` | Cache offline (SQLite) |
| Path | `path_provider`, `path` | Lokasi file database |
| Keamanan | `flutter_secure_storage` | Menyimpan token JWT |
| Setting | `shared_preferences` | Preferensi non-rahasia (tema, flag) |
| Media | `image_picker` | Unggah foto profil |
| Auth | `google_sign_in` | Login Google |
| UI | `google_fonts`, `intl` | Font & format tanggal/angka |
| Codegen | `build_runner`, `riverpod_generator`, `drift_dev` | Generate kode |
| Aset | `flutter_launcher_icons` | Ikon aplikasi |

**Versi minimum:** Dart `>=3.5.0`, Flutter `>=3.24.0`. CI memakai Flutter **3.47.5 (stable)**, Java **17**.

---

## Prasyarat

- **Flutter SDK** 3.24+ (disarankan 3.47.5) dan **Dart**.
- **Android SDK** + perangkat/emulator (untuk Android).
- **Java 17** (untuk build Gradle).
- Akses ke backend Bugarin (produksi `https://api.bugarin.my.id`, atau backend lokal).

---

## Memulai

```bash
git clone https://github.com/pbl-semester-3/mobile-bugarin.git
cd mobile-bugarin

# 1) Ambil dependensi
flutter pub get

# 2) WAJIB: generate kode (provider Riverpod & tabel Drift)
dart run build_runner build --delete-conflicting-outputs

# 3) Cek statis
flutter analyze

# 4) Jalankan test
flutter test
```

Selama pengembangan, jalankan generator dalam mode watch agar `*.g.dart` ikut ter-update:

```bash
dart run build_runner watch -d
```

---

## Konfigurasi API & Menjalankan

Flutter tidak memakai `.env`; konfigurasi diberikan lewat `--dart-define`.

| Parameter | Contoh | Wajib |
|---|---|---|
| `API_URL` | `https://api.bugarin.my.id` | Ya (default: `http://10.0.2.2:4000`) |
| `GOOGLE_CLIENT_ID` | `<web-client-id>.apps.googleusercontent.com` | Untuk login Google |

### Emulator Android (backend lokal)
```bash
flutter run --dart-define=API_URL=http://10.0.2.2:4000
```
> `10.0.2.2` adalah alias `localhost` di emulator Android (bukan untuk HP fisik).

### HP fisik (USB, backend produksi)
```bash
flutter run -d <device-id> \
  --dart-define=API_URL=https://api.bugarin.my.id \
  --dart-define=GOOGLE_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

### HP fisik dengan backend lokal (satu WiFi)
```bash
flutter run -d <device-id> --dart-define=API_URL=http://192.168.x.x:4000
```

> Pastikan `API_URL` diisi saat menjalankan di HP fisik. Tanpa itu, app memakai default `10.0.2.2` yang tidak dapat dijangkau dari perangkat nyata.

---

## Build & Rilis APK

Rilis APK dibangun otomatis melalui **GitHub Actions** (`.github/workflows/ci-build-apk.yml`):

- **Pull Request ke `main`** → menjalankan **Analyze & Test** (tanpa build/secret).
- **Push ke `main`** → **Analyze & Test** + **Build Release APK** → unggah **artifact** dan perbarui **GitHub Release `latest`**.
- **Manual (`workflow_dispatch`)** → build APK + artifact; menimpa `latest` hanya jika `publish_release = true` **dan** dijalankan dari `main`.

**Konfigurasi yang dibutuhkan (repository-level, Settings → Secrets and variables → Actions):**

- **Variables:** `API_URL`, `GOOGLE_CLIENT_ID`
- **Secrets:** `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`

**Signing:**

- `android/app/build.gradle.kts` memakai keystore release bila `android/key.properties` tersedia; jika tidak, fallback ke **debug signing** (untuk build lokal).
- File keystore & `key.properties` **tidak boleh** masuk repo (sudah di `.gitignore`).
- `versionCode` otomatis naik dari `github.run_number`, sehingga APK baru dapat menimpa instalasi sebelumnya tanpa uninstall.
- APK release pertama tidak dapat menimpa instalasi **debug** (signature berbeda) → uninstall sekali.

**Build lokal:**
```bash
flutter build apk --release \
  --dart-define=API_URL=https://api.bugarin.my.id \
  --dart-define=GOOGLE_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
# hasil: build/app/outputs/flutter-apk/app-release.apk
```

---

## Penyimpanan & Keamanan

| Data | Media | Catatan |
|---|---|---|
| Token JWT | `flutter_secure_storage` | Terenkripsi (Keystore/Keychain) |
| Tema & flag welcome | `shared_preferences` | Non-rahasia; migrasi otomatis dari secure storage versi lama |
| Master data, weekly plan, ringkasan dashboard | **Drift** (SQLite) | Cache offline; stale-while-revalidate |
| Foto profil | Cloudinary (backend) | URL disimpan di profil |

**Praktik keamanan:**
- Token tidak pernah disimpan di plaintext.
- `401` otomatis menghapus token dan mengarahkan ke login.
- `.env`, `key.properties`, dan `*.jks` di-`.gitignore`.

---

## Pengujian & Kualitas

- **Unit test** untuk repository, provider, dan fungsi murni (mis. logika auth guard, cache SWR, pemetaan error).
- Sebelum push, jalankan:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  flutter analyze     # target: 0 issue
  flutter test        # target: semua lulus
  flutter build apk --debug
  ```

---

## Integrasi API

Ringkasan endpoint utama yang dipakai aplikasi:

| Area | Endpoint |
|---|---|
| Auth | `POST /auth/login`, `POST /auth/register`, `POST /auth/oauth/google`, `POST /auth/logout` |
| Profil | `GET/PUT /klien/profile`, `PUT /klien/password`, `PUT /klien/theme`, `POST/DELETE /klien/profile/photo` |
| Siklus & BB | `GET/POST /klien/progress-cycles`, `GET /klien/progress-cycles/:id/logs`, `POST /klien/weight-logs` |
| Dashboard | `GET /klien/dashboard-summary` |
| Weekly Plan | `GET /klien/weekly-plan/current` |
| Master data | `GET /master/olahraga`, `GET /master/makanan?q=` |
| Aktivitas | `POST /klien/activity-logs`, `GET /klien/activity-logs` |
| Meal | `POST /klien/meal-logs`, `POST /klien/meal-logs/estimate` |
| PT | `GET /pt/recommendations`, `POST /klien/pairing-requests`, `GET /klien/pairing-requests/current` |
| Feedback | `GET /klien/feedbacks`, `PUT /klien/feedbacks/:id/read` |

Semua endpoint klien memerlukan header `Authorization: Bearer <token>` dan tanggal/waktu mengikuti konvensi **ISO 8601 UTC** dari backend.

---

## Alur Kontribusi

1. Buat branch dari `dev` dengan prefix: `feat/`, `fix/`, `chore/`, `docs/`, `refactor/`.
2. Tulis **Implementation Plan** sebelum coding (lihat `docs/WORKFLOW.md`).
3. Jalankan `build_runner` bila mengubah provider/tabel.
4. Verifikasi: `flutter analyze` (0 issue), `flutter test`, `flutter build apk --debug`.
5. Commit dengan **Conventional Commits** (Bahasa Indonesia), 1 commit = 1 perubahan logis.
6. Push branch → buka **Pull Request ke `dev`**.
7. Setelah lolos review & CI, merge ke `dev`. Rilis ke `main` memicu build APK otomatis.

---

## Lisensi

Proyek akademik **PBL Semester 3 — Tim Bugarin**. Hak cipta milik tim pengembang.
