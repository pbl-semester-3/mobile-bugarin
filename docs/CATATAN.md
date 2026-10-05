# CATATAN — Mobile Klien Bugarin

Terakhir diperbarui: 5 Oktober 2026
Status: seluruh scope PRD Mobile **selesai** (auth, wiring semua layar, cache lokal) **kecuali OAuth**.
Branch utama: `dev` (semua pekerjaan sudah di-merge).

Referensi: `Bugarin_PRD_Mobile.md` · kontrak `api-contract-bugarin` · PRD per fitur di
`bugarin-backend/fitur/klien/*.md`.

---

## 1. Ringkasan

Mobile Klien kini terhubung penuh ke backend (bukan data dummy) untuk: **Auth + guard, Onboarding,
Profil, Dashboard, Progres, PT ku, Riwayat, Feedback**, plus **cache lokal (drift)** untuk master
data, weekly plan, dan dashboard. Verifikasi: `flutter analyze` 0 error · `flutter test` **79/79** ·
`flutter build apk --debug` sukses.

**Belum:** OAuth (Google/Apple), beberapa gap backend (lihat §6), dan uji end-to-end di device
(khususnya perilaku offline/cache).

---

## 2. Yang sudah selesai

- **Auth:** `AuthRepository`, model `KlienProfile`/`ProgressCycle`, `AuthStateNotifier` (login/register/logout/restore), auth guard reaktif (GoRouter), `/splash`, Welcome sekali buka.
- **Onboarding:** submit nyata (`PUT /klien/profile` + `POST /klien/progress-cycles`) + `refreshProfile()`.
- **Step 2 (wiring layar):** Profil, Dashboard, Progres, PT ku, Riwayat, Feedback — masing-masing punya model + repository + provider + unit test.
- **Step 3:** route `/register` yang mati dihapus; pendaftaran satu sumber = toggle "Masuk | Daftar" di Login; validasi klien diselaraskan Zod backend.
- **Cache lokal (drift):** master olahraga/makanan (offline fallback), weekly plan, dashboard stale-while-revalidate.

---

## 3. Yang belum

1. **OAuth Google/Apple** — menunggu backend OAuth + Google client. Tombol social sementara menampilkan "belum tersedia".
2. **Gap backend** — lihat §6.
3. **Uji end-to-end di device** — verifikasi sejauh ini lewat API manual + unit test; perilaku offline/cache perlu dicoba di emulator/HP.

---

## 4. Cara menjalankan & akun uji

Backend lokal di port 4000. Android emulator:

```bash
flutter run --dart-define=API_URL=http://10.0.2.2:4000
```

HP fisik (satu WiFi): `--dart-define=API_URL=http://<IPv4-PC>:4000`.

Akun uji lokal (DB dev, **bukan produksi**): username `authtest1914391771` / password `secret123`
(sudah onboarding → langsung ke MainShell).

> Wajib `dart run build_runner build` setelah clone (file `*.g.dart` di-gitignore).

---

## 5. Endpoint yang dipakai mobile

| Endpoint | Fungsi |
|---|---|
| `POST /auth/register`, `POST /auth/login`, `POST /auth/logout` | Auth (response mobile `{ data: { token, role } }`) |
| `GET /klien/profile`, `PUT /klien/profile` | Profil + `profileComplete` + `activeCycle` |
| `PUT /klien/password`, `PUT /klien/theme` | Ganti password / tema |
| `POST /klien/weight-logs` | Catat berat badan |
| `GET /klien/progress-cycles`, `POST /klien/progress-cycles`, `GET /klien/progress-cycles/:id/logs` | Onboarding & Riwayat |
| `GET /klien/dashboard-summary` | Dashboard (PT, target kalori, streak, jadwal, reminder, `unreadFeedbackCount`) |
| `GET /master/olahraga`, `GET /master/makanan?q=` | Dropdown/search Progres |
| `POST /klien/activity-logs`, `POST /klien/meal-logs`, `GET /klien/weekly-plan/current` | Progres |
| `GET /pt/recommendations`, `POST /klien/pairing-requests`, `GET /klien/pairing-requests/current` | PT ku |
| `GET /klien/feedbacks`, `POST /klien/feedbacks/:id/reply`, `PUT /klien/feedbacks/:id/read` | Feedback |

Header `X-Client-Type: mobile` dikirim agar backend memilih jalur token (bukan cookie web).
Error: AppError → `{ error: "pesan" }`; validasi Zod → `{ error: { fields: { field: [...] } } }`.

---

## 6. Permintaan & Perbaikan Backend

> Bagian ini untuk tim backend. Tiap item: **endpoint**, **gap**, **yang dibutuhkan mobile**,
> **usulan kontrak**, dan **prioritas**. Semua field response camelCase (sesuai `api-contract-bugarin`).

### 6.0 TL;DR prioritas

| # | Item | Prioritas |
|---|---|---|
| 6.1 | `passwordHash` bocor di `GET /klien/profile` | **Tinggi (keamanan)** |
| 6.2 | `kaloriMasukHariIni` di `dashboard-summary` | Sedang |
| 6.3 | BB terkini (`bbSekarangKg`) untuk Profil | Sedang |
| 6.4 | `activeCycle` null eksplisit (bukan key hilang) | Rendah (kontrak) |
| 6.5 | Foto profil (upload + `fotoUrl`) | Opsional |
| 6.6 | Update email/username | **Butuh keputusan produk dulu** |

### 6.1 `passwordHash` bocor — **Tinggi (keamanan)**

- **Endpoint:** `GET /klien/profile`
- **Masalah:** objek `user` menyertakan `passwordHash` (argon2). Terlihat di response nyata.
- **Dampak:** kebocoran hash ke klien; mobile tidak memakainya.
- **Usulan:** strip `passwordHash` (dan kolom internal lain) dari response — eksplisit `select` kolom aman saja.
- **Prioritas:** Tinggi.

### 6.2 `kaloriMasukHariIni` di Dashboard — Sedang

- **Endpoint:** `GET /klien/dashboard-summary`
- **Gap:** tidak ada angka kalori masuk hari ini; UI Dashboard butuh progres `consumed / target`.
  Saat ini mobile hanya menampilkan **target** (arc jadi ring statis).
- **Usulan kontrak:** tambah field
  `kaloriMasukHariIni: number | null`
  = `SUM(meal_logs.kalori_masuk)` untuk klien tsb pada `tanggal = hari ini` (`0` bila tidak ada log;
  `null` bila tidak ada cycle aktif).
- **Prioritas:** Sedang.

### 6.3 BB terkini untuk Profil — Sedang

- **Endpoint:** `GET /klien/profile`
- **Gap:** hanya ada `activeCycle.bbAwalKg` & `bbTujuanKg`; tidak ada berat badan **terkini**.
  UI Profil butuh progress bar `bbAwal → bbSekarang → bbTujuan`.
- **Usulan kontrak (pilih satu):**
  - **Opsi A (disarankan):** tambah `bbSekarangKg: number | null` di `GET /klien/profile`
    (ambil `weight_logs` terbaru: `ORDER BY tanggal DESC, id DESC LIMIT 1`).
  - **Opsi B:** endpoint `GET /klien/weight-logs` → `{ data: [{ id, beratBadanKg, tanggal }] }`.
- **Perilaku mobile saat ini:** fallback ke `bbAwal` (progress 0%) sampai field tersedia.
- **Prioritas:** Sedang.

### 6.4 `activeCycle` null eksplisit — Rendah (kontrak)

- **Endpoint:** `GET /klien/profile`
- **Masalah:** saat tidak ada cycle aktif, key `activeCycle` **dihilangkan**, bukan `null` eksplisit
  (melanggar aturan `api-contract-bugarin` "field null eksplisit").
- **Dampak:** mobile sudah tahan (dianggap null), tapi kontrak tidak konsisten.
- **Usulan:** selalu kirim `activeCycle: null` bila kosong.
- **Prioritas:** Rendah.

### 6.5 Foto profil — Opsional

- **Gap:** tidak ada endpoint/kolom foto profil klien.
- **Dampak mobile:** fitur ganti foto **dinonaktifkan**; avatar menampilkan inisial.
- **Usulan kontrak:**
  - `POST /klien/profile/photo` (multipart, field `foto`) → `{ data: { fotoUrl: string } }`
  - kolom `foto_url` di `klien_profiles`
  - sertakan `fotoUrl: string | null` di `GET /klien/profile`.
- **Prioritas:** Opsional.

### 6.6 Update email/username — **Butuh keputusan produk dulu**

- **Gap:** `PUT /klien/profile` hanya menerima `nama`, `usia`, `jenisKelamin`, `alergiMakanan`,
  `tinggiBadanCm`. Tidak ada cara mengubah `email`/`username` (tabel `users`).
- **Dampak mobile:** field Email & Username di Profil saat ini **tidak tersimpan** (hanya tampil).
- **Catatan:** ini keputusan produk/keamanan (email idealnya lewat verifikasi; username unik).
  Jangan langsung implementasi sebelum disepakati.
- **Opsi bila disetujui:** endpoint `PUT /klien/account` (email/username) + aturan verifikasi/keunikan;
  **atau** mobile jadikan kedua field read-only.
- **Prioritas:** Keputusan dulu.

### 6.7 `createdAt` klien — Rendah/opsional

- **Gap:** mobile tidak punya `createdAt` klien → label "Member Sejak" di Profil dikosongkan.
- **Usulan:** sertakan `createdAt` (ISO 8601, dari `users.created_at`) di `GET /klien/profile`.
- **Prioritas:** Rendah.

---

## 7. Cache lokal (drift) — ringkas

- **Master olahraga & makanan:** fetch API → simpan cache; bila network gagal → fallback cache
  (UI menampilkan catatan "data offline"). Progres.
- **Weekly plan:** fetch → cache; fallback cache bila gagal. Progres.
- **Dashboard:** stale-while-revalidate (tampilkan cache dulu, lalu fetch fresh & simpan).
- Skema lokal versi 2 (tabel: `master_olahraga_cache`, `master_makanan_cache`, `weekly_plan_cache`,
  `dashboard_summary_cache`). Submit log **tidak** di-cache (gagal → error/retry manual).

---

## 8. Git / PR

Semua pekerjaan sudah di-merge ke `dev` via PR:
- PR #2 `auth` → auth + onboarding + wiring seluruh layar (Step 2).
- PR #3 `feat/register-entry` → hapus route `/register` mati + validasi register.
- PR #4 `feat/drift-cache` → cache master data, weekly plan, dashboard SWR.

Sisa: PR untuk OAuth (Step 4) setelah backend/Google client siap.
