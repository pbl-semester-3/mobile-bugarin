# CATATAN — Pekerjaan Auth Mobile Klien

Tanggal: 3 Oktober 2026
Branch: `auth` (diturunkan dari `dev`)
Referensi: `Bugarin_PRD_Mobile.md` bab 2, 3.1, 4 · skill `flutter-riverpod-patterns`, `gorouter-navigation-bugarin`, `dio-jwt-networking` · kontrak `api-contract-bugarin`

---

## 1. Ringkasan

Pekerjaan ini membangun **lapisan auth end-to-end** untuk aplikasi klien (repository, model,
state, auth guard, dan wiring tombol login/register/logout). Sebelumnya semua alur auth masih
memakai token dummy yang ditulis langsung ke secure storage tanpa menyentuh backend.

**Status:** selesai & terverifikasi. Endpoint backend terkait sudah live (diuji manual).
**Belum termasuk:** submit Onboarding dan wiring data fitur (lihat bagian 8).

---

## 2. Cakupan

**Dikerjakan**
- `AuthRepository` (interface + `DioAuthRepository`) untuk `register`, `login`, `logout`, `getProfile`.
- Model `KlienProfile` + `ProgressCycle` (parse response backend).
- `AuthStateNotifier` dengan `login()`, `register()`, `logout()`, dan restore sesi nyata.
- Auth guard reaktif di GoRouter (aturan redirect di bagian 4).
- Wiring tombol: login/register (sheet di Welcome **dan** route `/register`), logout di Profil.
- Layar `/splash` singkat saat sesi masih dipulihkan.
- Welcome hanya tampil pada pembukaan app pertama kali.
- Unit test auth (repository, restore, guard) — total 31 test.

**Ditahan (sesuai keputusan)**
- Submit Onboarding (`PUT /klien/profile` + `POST /klien/progress-cycles`).
- Wiring data fitur (Dashboard, Profil, Progres, PT ku, Riwayat, Feedback) ke API.
- Social auth (Google/Apple) — backend OAuth belum ada; sementara tombol menampilkan pesan "belum tersedia".

---

## 3. File

**Baru**
- `lib/features/auth/data/auth_repository.dart`
- `lib/features/auth/data/auth_repository_provider.dart`
- `lib/features/auth/models/klien_profile.dart`
- `lib/features/auth/models/progress_cycle.dart`
- `lib/router/auth_redirect.dart`
- `lib/features/splash/splash_screen.dart`
- `test/auth/fakes.dart`
- `test/auth/auth_repository_test.dart`
- `test/auth/auth_notifier_test.dart`
- `test/auth/auth_restore_test.dart`
- `test/router/auth_redirect_test.dart`

**Diubah**
- `lib/services/api_client.dart` — default header `X-Client-Type: mobile` + `Accept: application/json`.
- `lib/providers/auth_provider.dart` — `AuthUnknown`, restore nyata, method login/register/logout.
- `lib/router/app_router.dart` — guard + `refreshListenable` + route `/splash`.
- `lib/features/welcome/welcome_screen.dart` — tandai `has_seen_welcome` setelah tampil pertama.
- `lib/features/auth/login_screen.dart` — panggil auth nyata; social auth dinonaktifkan (pesan).
- `lib/features/auth/register_screen.dart` — panggil `register()` nyata.
- `lib/features/profil/profil_screen.dart` — logout via notifier → `/login`.

---

## 4. Alur & Aturan Auth Guard

1. Sesi masih dipulihkan (`AuthUnknown`) → `/splash`.
2. Belum login + belum pernah buka app → `/welcome`.
3. Belum login + sudah pernah buka app → `/login`.
4. Login + `profileComplete == false` → `/onboarding`.
5. Login + `profileComplete == true` → MainShell (`/`).
6. Logout → `/login`.

Catatan: `/onboarding` tetap diizinkan saat profil lengkap (dipakai alur "mulai target baru").

---

## 5. Endpoint yang Dipakai

| Endpoint | Body | Response (mobile) |
|---|---|---|
| `POST /auth/register` | `{ nama, email, username, password }` | `{ data: { token, role } }` |
| `POST /auth/login` | `{ emailOrUsername, password }` | `{ data: { token, role } }` |
| `POST /auth/logout` | — | `{ data: "ok" }` |
| `GET /klien/profile` | Bearer token | `{ data: { ...profil, user, profileComplete, activeCycle } }` |

Header `X-Client-Type: mobile` dikirim agar backend memilih jalur token (bukan cookie web).
Error: AppError → `{ error: "pesan" }`; validasi Zod → `{ error: { fields: { field: [...] } } }`.

---

## 6. Hasil Verifikasi

```
dart run build_runner build   → sukses
flutter analyze               → 0 error (info style lama saja)
flutter test                  → 31/31 lolos
flutter build apk --debug     → sukses
```

**Verifikasi manual ke backend lokal (11 skenario, semua lolos):** register, login, profil dengan
Bearer, profil tanpa token (401), password salah (401), validasi register (400 + `fields`),
register duplikat (409), logout, isi profil, mulai siklus, dan profil setelah onboarding
(`profileComplete: true` + `activeCycle` terisi).

**Akun uji lokal (DB dev, bukan produksi):** username `authtest1914391771` / password `secret123`
— sudah di-onboarding sehingga login langsung ke MainShell.

---

## 7. Temuan (untuk ditindaklanjuti backend)

1. **`GET /klien/profile` mengirim `passwordHash`** pada objek `user` — isu keamanan, harus
   di-strip di backend. Model mobile tidak memakainya.
2. **`activeCycle` di-omit saat kosong**, bukan `null` eksplisit (melanggar aturan
   `api-contract-bugarin`). Model mobile sudah tahan (dianggap null).
3. ID besar (mis. `600000127`) aman di Dart native (64-bit); hanya relevan bila kelak target web.

---

## 8. Yang Belum / Langkah Berikutnya

1. **Wire submit Onboarding** (`PUT /klien/profile` + `POST /klien/progress-cycles`) — prasyarat
   akun baru bisa `profileComplete = true` dan lanjut ke MainShell.
2. **Wire layar fitur** ke provider/API, mengganti data dummy (Dashboard, Profil, Progres,
   PT ku, Riwayat, Feedback).
3. **RegisterScreen (`/register`)** sudah di-wire tetapi belum punya pintu masuk di UI —
   perlu tombol/entry bila ingin diakses.
4. **Social auth** menunggu backend OAuth.

---

## 9. Cara Menjalankan

Backend lokal aktif di port 4000. Untuk perangkat Android fisik (satu WiFi dengan PC):

```bash
flutter run --dart-define=API_URL=http://<IPv4-PC>:4000
```

Android emulator: `--dart-define=API_URL=http://10.0.2.2:4000`.

---

## 10. Git

| Commit | Pesan |
|---|---|
| `f6c824b` | `feat: bangun repository & model auth klien` |
| `d3c208f` | `test: tambah unit test auth repository & notifier` |
| `aea88a7` | `feat: aktifkan auth guard, restore sesi, dan wiring login/register/logout` |
| `784b1f2` | `test: tambah test auth guard & restore sesi` |

Branch `auth` **belum di-merge** ke `dev` (menunggu keputusan aktivasi lanjutan).
Folder `windows/` & `web/` (hanya untuk testing lokal) sengaja tidak di-commit.

---

## 11. Permintaan ke Backend (ditemukan saat Step 2)

Gap yang membuat sebagian fitur Profil/Dashboard belum bisa sepenuhnya nyata:

1. **Berat badan terkini (bb sekarang)** — tidak ada endpoint/field untuk mengambil
   `weight_logs` terakhir klien. `GET /klien/profile` hanya mengembalikan `activeCycle`
   (`bbAwalKg`, `bbTujuanKg`), bukan BB terkini. Dibutuhkan untuk progress bar Profil
   (`bbAwal → bbSekarang → bbTujuan`). Usulan: tambah field `bbSekarangKg` di
   `GET /klien/profile`, atau endpoint `GET /klien/weight-logs`.
2. **Kalori masuk hari ini** — `GET /klien/dashboard-summary` tidak mengembalikan kalori
   yang dikonsumsi hari ini, padahal UI Dashboard menampilkan progres `consumed/target`.
   Usulan: tambah `kaloriMasukHariIni` di `dashboard-summary`.
3. **Foto profil** — tidak ada endpoint/kolom untuk upload/ambil foto profil klien.
   Sementara fitur ganti foto dinonaktifkan di mobile (avatar tampil inisial).
   Usulan: endpoint `POST /klien/profile/photo` (multipart) + kolom `foto_url` + kembalikan
   `fotoUrl` di `GET /klien/profile`.
4. **Update email/username** — `PUT /klien/profile` hanya menerima `nama`, `usia`,
   `jenisKelamin`, `alergiMakanan`, `tinggiBadanCm`. Tidak ada endpoint untuk mengubah
   `email`/`username` (tabel `users`). Sementara field email/username di Profil tidak
   bisa disimpan.
5. **`createdAt` klien** — tidak dipakai mobile saat ini (`memberSince` dikosongkan);
   opsional untuk tampilan "Member Sejak".
