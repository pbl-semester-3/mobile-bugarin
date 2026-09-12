# Bugarin Mobile — Workflow & Coding Rules

Dokumen ini mengatur cara kerja tim di repo `mobile-bugarin`. Struktur sama dengan `WORKFLOW.md` di `be-bugarin`/`fe-bugarin` (biar konsisten lintas repo), disesuaikan untuk konteks Flutter.

---

## 1. Implementation Plan (Sebelum Coding)

Sama seperti Backend & Frontend — task apa pun (screen baru, provider baru, integrasi endpoint) wajib mulai dari rencana tertulis dulu, direview, baru dieksekusi.

### Format Implementation Plan

```markdown
## Task: <nama task, mis. "Implementasi screen Progres - tab Olahraga">

**Referensi**: Bugarin_PRD_Mobile.md bab 3.5, skill flutter-riverpod-patterns

**Endpoint backend yang dipakai**: GET /master/olahraga, POST /klien/activity-logs
(status endpoint ini di be-bugarin: sudah ada / masih stub — cek dulu sebelum mulai)

**Yang akan dibuat/diubah**:
- `lib/features/progres/progres_screen.dart`
- `lib/providers/olahraga_provider.dart` (list dropdown + submit activity log)

**Provider/state yang dipakai**: `@riverpod` Notifier untuk submit, family provider kalau perlu

**Business logic penting**: field jarak cuma muncul kalau `master_olahraga.butuhJarak == true`

**Risiko/hal yang perlu diperhatikan**:
- Endpoint backend masih stub — pakai data dummy dulu, tandai TODO, jangan nunggu backend selesai
```

### Alur Approval

Sama seperti repo lain: **post plan dulu → approve → baru coding**. Kalau desain Figma berubah dari rencana, update plan dan minta approval ulang.

---

## 2. Branching Strategy

Konvensi sama persis dengan `be-bugarin`/`fe-bugarin`:

```
main    ← selalu stabil, cuma nerima merge dari dev via PR
 └─ dev
     ├─ feat/screen-progres-olahraga
     ├─ feat/onboarding-form
     ├─ fix/auth-guard-redirect-loop
     └─ chore/upgrade-riverpod
```

Prefix (`feat/`, `fix/`, `chore/`, `docs/`, `refactor/`) dan aturan merge — sama seperti repo lain.

---

## 3. Testing Lokal Wajib Sebelum Push

```bash
flutter analyze                                          # harus 0 issue
dart run build_runner build --delete-conflicting-outputs # wajib sukses (ada provider/tabel Drift baru?)
flutter build apk --debug                                 # harus sukses — build asli, bukan cuma analisis
```

**Kenapa 3 langkah ini, bukan cuma `flutter analyze`**: `analyze` cuma cek statis (tipe, unused import) — nggak nangkep error yang muncul pas kompilasi native (config Android/Gradle, plugin conflict, dsb). `flutter build apk --debug` yang jadi bukti "beneran bisa jadi aplikasi", setara `npm run build` di web.

Kalau nambah/ubah provider (`@riverpod`) atau tabel Drift (`@DriftDatabase`), `build_runner` **wajib** dijalankan ulang sebelum `flutter analyze` — kalau nggak, `*.g.dart` basi dan `analyze`/`build` bisa gagal aneh atau malah lolos padahal kodenya salah.

Tambahan khusus Mobile — **cek manual di emulator/device** sebelum push:
- Jalankan `flutter run`, buka screen yang diubah, pastikan nggak crash
- Kalau ubah `app_router.dart` (auth guard), test alur login → onboarding → dashboard, dan logout → balik ke login

---

## 4. Commit Rules

Format sama: **Conventional Commits, Bahasa Indonesia**.

```
feat: tambah screen progres tab olahraga dengan dropdown master data
fix: perbaiki auth guard yang tidak redirect ke onboarding setelah register
chore: upgrade riverpod ke versi terbaru
docs: update Bugarin_PRD_Mobile.md bagian riwayat per siklus
refactor: pindahkan logic kalkulasi progress bar ke provider terpisah
```

Aturan sama: 1 commit = 1 perubahan logis, bukan narasi proses, referensikan issue kalau relevan.

---

## 5. Work Result (Setelah Task Selesai)

```markdown
## Work Result: <nama task>

**Branch**: feat/screen-progres-olahraga
**Implementation Plan**: [link]

**Yang selesai dikerjakan**:
- [x] Screen Progres tab Olahraga — dropdown master_olahraga, field jarak kondisional
- [x] Provider submit activity log + invalidation ke dashboardSummaryProvider

**Yang BELUM selesai / diluar scope**:
- Tab Meal belum diimplementasikan (task terpisah)

**Hasil testing lokal**:
- `flutter analyze` → 0 issue
- `dart run build_runner build` → sukses
- `flutter build apk --debug` → sukses
- Manual test di emulator: [screenshot/rekaman singkat]

**Endpoint backend yang dipakai**: POST /klien/activity-logs — [status: sudah live / masih data dummy]

**Hal yang perlu diperhatikan reviewer**:
- Belum ada empty state kalau master_olahraga kosong dari cache Drift
```

---

## Ringkasan Alur Satu Task

```
1. Terima/ambil task
2. Cek status endpoint backend terkait di be-bugarin (siap / masih stub?)
3. Tulis Implementation Plan → post untuk direview
4. Approved → checkout branch baru dari dev (feat/xxx)
5. Coding (pakai data dummy kalau backend belum siap, tandai TODO)
6. dart run build_runner build --delete-conflicting-outputs (kalau ada provider/tabel baru)
7. flutter analyze && flutter build apk --debug → semua harus lolos
8. Cek manual di emulator/device
9. Commit (Conventional Commits, Bahasa Indonesia)
10. Push branch → buka PR ke dev
11. Tulis Work Result di PR
12. Review → approve → merge ke dev
```
