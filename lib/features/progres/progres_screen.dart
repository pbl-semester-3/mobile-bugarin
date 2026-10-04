import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_provider.dart';
import '../../services/api_error.dart';
import '../../shared/widgets/bugarin_header.dart';
import '../dashboard/dashboard_screen.dart' show dashboardSummaryProvider;
import 'data/master_repository_provider.dart';
import 'data/progres_repository_provider.dart';
import 'models/master_data.dart';
import 'models/weekly_plan.dart';

class ProgresScreen extends ConsumerStatefulWidget {
  const ProgresScreen({super.key});

  @override
  ConsumerState<ProgresScreen> createState() => _ProgresScreenState();
}

class _ProgresScreenState extends ConsumerState<ProgresScreen> {
  bool _isMealTab = true;

  final TextEditingController _customMenuController = TextEditingController();
  final TextEditingController _customGramController = TextEditingController();
  final TextEditingController _durasiController = TextEditingController();
  final TextEditingController _jarakController = TextEditingController();

  List<MasterOlahraga> _olahragaList = [];
  List<MasterMakanan> _makananList = [];
  MasterOlahraga? _selectedOlahraga;

  final Map<int, double> _porsi = {};
  final Set<int> _selectedMealIds = {};

  final List<CreatedActivityLog> _submittedActivities = [];
  WeeklyPlan? _weeklyPlan;

  bool _memuat = true;
  String? _errorMuat;
  bool _menyimpanAktivitas = false;
  bool _menyimpanMeal = false;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  @override
  void dispose() {
    _customMenuController.dispose();
    _customGramController.dispose();
    _durasiController.dispose();
    _jarakController.dispose();
    super.dispose();
  }

  Future<void> _muatData() async {
    setState(() {
      _memuat = true;
      _errorMuat = null;
    });
    try {
      final master = ref.read(masterRepositoryProvider);
      final progres = ref.read(progresRepositoryProvider);
      final hasil = await Future.wait([
        master.getOlahraga(),
        master.getMakanan(),
        progres.getCurrentWeeklyPlan(),
      ]);
      if (!mounted) return;
      final olahraga = hasil[0] as List<MasterOlahraga>;
      final makanan = hasil[1] as List<MasterMakanan>;
      setState(() {
        _olahragaList = olahraga;
        _makananList = makanan;
        _weeklyPlan = hasil[2] as WeeklyPlan?;
        _selectedOlahraga = olahraga.isNotEmpty ? olahraga.first : null;
        for (final m in makanan) {
          _porsi.putIfAbsent(m.id, () => 100);
        }
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMuat = e is ApiException ? e.message : 'Gagal memuat data.';
        _memuat = false;
      });
    }
  }

  void _toast(String pesan, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? const Color(0xFFE53935) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(pesan),
        ),
      );
  }

  double _totalKaloriMasuk() {
    double total = 0;
    for (final id in _selectedMealIds) {
      final makanan = _makananList.firstWhere((m) => m.id == id);
      final gram = _porsi[id] ?? 100;
      total += makanan.kaloriPer100g * (gram / 100);
    }
    return total;
  }

  int get _totalKaloriTerbakar =>
      _submittedActivities.fold(0, (sum, a) => sum + a.kaloriTerbakar);

  Future<void> _submitActivity() async {
    final olahraga = _selectedOlahraga;
    if (olahraga == null) {
      _toast('Pilih jenis olahraga dulu.', error: true);
      return;
    }
    final durasi = int.tryParse(_durasiController.text.trim());
    if (durasi == null || durasi <= 0) {
      _toast('Durasi olahraga (menit) wajib diisi.', error: true);
      return;
    }

    double? jarak;
    if (olahraga.butuhJarak) {
      jarak = double.tryParse(_jarakController.text.trim().replaceAll(',', '.'));
      if (jarak == null || jarak <= 0) {
        _toast('Olahraga ini mewajibkan input jarak (meter).', error: true);
        return;
      }
    }

    setState(() => _menyimpanAktivitas = true);
    try {
      final log = await ref.read(progresRepositoryProvider).createActivityLog(
            olahragaId: olahraga.id,
            durasiMenit: durasi,
            jarakMeter: jarak,
          );
      if (!mounted) return;
      setState(() {
        _submittedActivities.insert(0, log);
        _durasiController.clear();
        _jarakController.clear();
      });
      ref.invalidate(dashboardSummaryProvider); // streak & kalori berubah
      _toast('Aktivitas tersimpan. Terbakar ${log.kaloriTerbakar} kkal.');
    } catch (e) {
      _toast(e is ApiException ? e.message : 'Gagal menyimpan aktivitas.', error: true);
    } finally {
      if (mounted) setState(() => _menyimpanAktivitas = false);
    }
  }

  Future<void> _submitMeals() async {
    final repo = ref.read(progresRepositoryProvider);
    final namaCustom = _customMenuController.text.trim();
    final gramCustom = double.tryParse(_customGramController.text.trim().replaceAll(',', '.'));

    if (_selectedMealIds.isEmpty && namaCustom.isEmpty) {
      _toast('Pilih minimal satu makanan atau isi menu custom.', error: true);
      return;
    }
    if (namaCustom.isNotEmpty && (gramCustom == null || gramCustom <= 0)) {
      _toast('Porsi menu custom (gram) wajib diisi.', error: true);
      return;
    }

    setState(() => _menyimpanMeal = true);
    try {
      int total = 0;
      for (final id in _selectedMealIds) {
        final log = await repo.createMealLog(makananId: id, porsiGram: _porsi[id] ?? 100);
        total += log.kaloriMasuk;
      }
      if (namaCustom.isNotEmpty) {
        final log = await repo.createMealLog(namaMakanan: namaCustom, porsiGram: gramCustom!);
        total += log.kaloriMasuk;
      }
      if (!mounted) return;
      _customMenuController.clear();
      _customGramController.clear();
      ref.invalidate(dashboardSummaryProvider);
      _toast('$total kkal tercatat ke backend.');
    } catch (e) {
      _toast(e is ApiException ? e.message : 'Gagal menyimpan makanan.', error: true);
    } finally {
      if (mounted) setState(() => _menyimpanMeal = false);
    }
  }

  void _resetMeals() {
    setState(() {
      _selectedMealIds.clear();
      _customMenuController.clear();
      _customGramController.clear();
    });
  }

  void _editPorsi(MasterMakanan makanan) {
    final controller = TextEditingController(text: (_porsi[makanan.id] ?? 100).toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.border),
        ),
        title: Text('Ubah Porsi ${makanan.nama}',
            style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: context.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Porsi (gram)',
            labelStyle: TextStyle(color: context.textSecondary),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.border)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF5520))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim().replaceAll(',', '.'));
              if (val != null && val > 0) {
                setState(() => _porsi[makanan.id] = val);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5520),
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: _memuat
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5520)))
            : _errorMuat != null
                ? _buildError()
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BugarinHeader(subtitle: 'Progres'),
                        const SizedBox(height: 22),
                        Text('Progres Harian',
                            style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2)),
                        const SizedBox(height: 4),
                        Text('Pantau asupan nutrisi dan aktivitas latihan terpadu.',
                            style: TextStyle(color: context.textSecondary, fontSize: 12)),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: context.border),
                          ),
                          child: Row(
                            children: [
                              _buildTab('Meal (Nutrisi)', true),
                              _buildTab('Olahraga', false),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_isMealTab) _buildMealSection() else _buildOlahragaSection(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: context.textMuted),
            const SizedBox(height: 12),
            Text(_errorMuat!, textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _muatData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5520),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool meal) {
    final active = _isMealTab == meal;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isMealTab = meal),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFF5520) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : context.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyPlanCard({required bool meal}) {
    final plan = _weeklyPlan;
    final title = meal ? 'Rencana Menu Minggu Ini' : 'Rencana Latihan Minggu Ini';
    final subtitle = plan == null
        ? 'Belum ada weekly plan yang disetujui PT.'
        : (meal
            ? '${plan.mealPlan.length} menu referensi'
            : '${plan.workoutPlan.length} sesi referensi');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: context.surfaceInner,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.border),
            ),
            child: Text('WEEKLY PLAN',
                style: TextStyle(
                    color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildMealSection() {
    final total = _totalKaloriMasuk().round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeeklyPlanCard(meal: true),
        const SizedBox(height: 22),
        Text('Preset Makanan',
            style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_makananList.isEmpty)
          Text('Master makanan kosong.', style: TextStyle(color: context.textSecondary, fontSize: 12))
        else
          ..._makananList.take(8).map((m) {
            final selected = _selectedMealIds.contains(m.id);
            final gram = _porsi[m.id] ?? 100;
            final kalori = (m.kaloriPer100g * (gram / 100)).round();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? const Color(0xFFFF5520).withValues(alpha: 0.4) : context.border,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.nama,
                            style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text('$kalori kkal (${m.kaloriPer100g.toStringAsFixed(0)} kkal/100g)',
                            style: TextStyle(color: context.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _editPorsi(m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.surfaceInner,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.border),
                      ),
                      child: Text('${gram.toStringAsFixed(0)} g',
                          style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() {
                      if (selected) {
                        _selectedMealIds.remove(m.id);
                      } else {
                        _selectedMealIds.add(m.id);
                      }
                    }),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFFF5520) : context.surfaceInner,
                        shape: BoxShape.circle,
                        border: Border.all(color: selected ? Colors.transparent : context.border),
                      ),
                      child: Center(
                        child: Icon(Icons.check_rounded,
                            size: 18, color: selected ? Colors.white : context.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 20),
        Text('Tambah Menu Khusus (Custom Entry)',
            style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Jika makanan belum terdaftar, sistem mengestimasi kalori via AI.',
            style: TextStyle(color: context.textSecondary, fontSize: 11)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _inputBox(
                controller: _customMenuController,
                hint: 'Ketik Menu Anda',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _inputBox(
                controller: _customGramController,
                hint: 'Porsi (g)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL KALORI MASUK',
                          style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1)),
                      const SizedBox(height: 4),
                      Text('$total kkal',
                          style: TextStyle(
                              color: context.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _resetMeals,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Reset', style: TextStyle(color: context.textSecondary, fontSize: 13)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _menyimpanMeal ? null : _submitMeals,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5520),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _menyimpanMeal
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Simpan Perubahan',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOlahragaSection() {
    final olahraga = _selectedOlahraga;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeeklyPlanCard(meal: false),
        const SizedBox(height: 22),
        Text('Catat Aktivitas Latihan',
            style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.surfaceInner,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MasterOlahraga>(
              value: olahraga,
              isExpanded: true,
              dropdownColor: context.card,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFF5520)),
              items: _olahragaList
                  .map((item) => DropdownMenuItem<MasterOlahraga>(
                        value: item,
                        child: Text(item.nama, style: TextStyle(color: context.textPrimary, fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedOlahraga = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        _inputBox(controller: _durasiController, hint: 'Durasi Latihan (menit)', keyboardType: TextInputType.number),
        if (olahraga != null && olahraga.butuhJarak) ...[
          const SizedBox(height: 12),
          _inputBox(
            controller: _jarakController,
            hint: 'Jarak Tempuh (meter) *Wajib',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _menyimpanAktivitas ? null : _submitActivity,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5520),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _menyimpanAktivitas
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Catat Latihan Ini', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Riwayat Hari Ini',
                style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Total: $_totalKaloriTerbakar kkal',
                style: const TextStyle(color: Color(0xFFFF5520), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        if (_submittedActivities.isEmpty)
          Text('Belum ada aktivitas tercatat hari ini.',
              style: TextStyle(color: context.textSecondary, fontSize: 12))
        else
          ..._submittedActivities.map((act) {
            final matches = _olahragaList.where((o) => o.id == act.olahragaId);
            final nama = matches.isEmpty ? 'Olahraga' : matches.first.nama;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nama,
                            style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          act.jarakMeter != null
                              ? '${act.durasiMenit} menit • ${act.jarakMeter!.toStringAsFixed(0)} meter'
                              : '${act.durasiMenit} menit',
                          style: TextStyle(color: context.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.surfaceInner,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${act.kaloriTerbakar} kkal',
                        style: const TextStyle(
                            color: Color(0xFFFF5520), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _inputBox({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.surfaceInner,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: context.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
