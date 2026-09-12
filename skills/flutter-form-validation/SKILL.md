---
name: flutter-form-validation
description: Pola validasi form Flutter (Form + TextFormField + validator) untuk Mobile Klien Bugarin, selaras dengan Zod validation di backend dan menangani error per-field dari API. Gunakan saat membangun form baru (Onboarding, Profil, Catat Progres).
metadata:
  origin: bugarin-project
---

# Flutter Form Validation (Bugarin Mobile)

Sama seperti prinsip di `form-validation-patterns` (Web): validasi frontend untuk UX cepat, validasi backend (Zod) tetap wajib sebagai lapisan sesungguhnya. Skill ini fokus ke implementasi di Flutter memakai `Form` + `GlobalKey<FormState>` bawaan, tanpa dependency tambahan (cukup untuk kompleksitas form Bugarin — tidak perlu `reactive_forms` kecuali form makin kompleks nanti).

## Activation

- Membangun form Onboarding, Profil (4 section), Catat Progres (olahraga/makanan).
- Menangani error validasi dari response API di form.

## Pola Dasar

```dart
class ProfilInfoForm extends ConsumerStatefulWidget {
  const ProfilInfoForm({super.key});
  @override
  ConsumerState<ProfilInfoForm> createState() => _ProfilInfoFormState();
}

class _ProfilInfoFormState extends ConsumerState<ProfilInfoForm> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _alergiController = TextEditingController();
  String? _serverError;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return; // stop kalau validator lokal gagal

    try {
      await ref.read(klienProfileProvider.notifier).update(
        nama: _namaController.text,
        alergiMakanan: _alergiController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tersimpan')));
    } on ApiValidationError catch (e) {
      // pasang error per-field dari backend, bukan cuma toast generic
      setState(() => _serverError = e.fieldErrors['nama']?.first);
      _formKey.currentState!.validate(); // trigger ulang tampilan error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _namaController,
            decoration: const InputDecoration(labelText: 'Nama'),
            validator: (value) {
              if (_serverError != null) return _serverError; // prioritas: error dari server
              if (value == null || value.trim().length < 2) return 'Nama minimal 2 karakter';
              return null;
            },
          ),
          TextFormField(
            controller: _alergiController,
            decoration: const InputDecoration(labelText: 'Alergi Makanan (opsional)'),
          ),
          ElevatedButton(onPressed: _submit, child: const Text('Simpan')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alergiController.dispose();
    super.dispose();
  }
}
```

## Validator Reusable (samakan aturan dengan Zod backend)

```dart
// utils/validators.dart
class Validators {
  static String? required(String? value, {String field = 'Field ini'}) {
    if (value == null || value.trim().isEmpty) return '$field wajib diisi';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email wajib diisi';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value)) return 'Format email tidak valid';
    return null;
  }

  static String? minLength(String? value, int min, {String field = 'Field ini'}) {
    if (value == null || value.length < min) return '$field minimal $min karakter';
    return null;
  }

  static String? positiveNumber(String? value, {String field = 'Nilai'}) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) return '$field harus angka lebih dari 0';
    return null;
  }
}
```

Aturan angka `min(8)` untuk password, format email, dsb — **samakan persis** dengan schema Zod di `modules/*/[nama].schema.ts` backend. Kalau backend ubah aturan (skill `api-contract-bugarin`, protokol perubahan kontrak), update juga validator di sini.

## Kondisional Field (Jarak muncul hanya jika `butuhJarak`)

```dart
Column(
  children: [
    DropdownButtonFormField<MasterOlahraga>(
      items: olahragaList.map((o) => DropdownMenuItem(value: o, child: Text(o.nama))).toList(),
      onChanged: (value) => setState(() => _selectedOlahraga = value),
      validator: (value) => value == null ? 'Pilih jenis olahraga' : null,
    ),
    TextFormField(
      decoration: const InputDecoration(labelText: 'Durasi (menit)'),
      keyboardType: TextInputType.number,
      validator: (v) => Validators.positiveNumber(v, field: 'Durasi'),
    ),
    if (_selectedOlahraga?.butuhJarak == true) // field kondisional dari data master
      TextFormField(
        decoration: const InputDecoration(labelText: 'Jarak (meter)'),
        keyboardType: TextInputType.number,
        validator: (v) => Validators.positiveNumber(v, field: 'Jarak'),
      ),
  ],
)
```

## Form Multi-Section dengan Submit Independen (Profil)

Sama seperti pola di `form-validation-patterns` (Web): **satu `GlobalKey<FormState>` per section** (Informasi Diri, Detail Penting, Password, Tema), bukan satu form besar — supaya submit section "Password" tidak ikut memvalidasi field "Alergi Makanan" yang mungkin sedang kosong/belum diisi ulang.

## Anti-Patterns

| Anti-Pattern | Risiko | Perbaikan |
|---|---|---|
| Satu `GlobalKey<FormState>` untuk seluruh halaman Profil (4 section) | Submit section Password ikut trigger validasi field section lain | Satu `Form`/`GlobalKey` per section, sesuai tombol Simpan masing-masing |
| Validator lokal tidak disamakan dengan aturan backend | User lolos di app tapi ditolak API, atau sebaliknya, bikin bingung | Selaraskan manual — lihat protokol perubahan kontrak di `api-contract-bugarin` |
| Error dari backend cuma ditampilkan sebagai `SnackBar` generic | User tidak tahu field mana yang salah | Pasang ke `validator` field terkait via `_serverError` + `formKey.currentState!.validate()` |
| Field kondisional (Jarak) selalu ditampilkan lalu disembunyikan pakai `Visibility` | Space kosong aneh atau validator tetap jalan walau field disembunyikan | Render kondisional dengan `if` di widget tree (field beneran tidak ada di tree saat tidak butuh) |

## Related

- Skill: `dio-jwt-networking` — `ApiValidationError` yang ditangkap di `_submit()`
- Skill: `flutter-riverpod-patterns` — notifier (`klienProfileProvider`, dst) yang dipanggil dari form
- Skill: `form-validation-patterns` (Frontend Web) — pola setara di sisi Next.js, jaga konsistensi pesan error lintas platform
