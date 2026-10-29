import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_provider.dart';
import '../../services/api_error.dart';
import '../../shared/widgets/bugarin_header.dart';
import '../dashboard/dashboard_screen.dart' show dashboardSummaryProvider;
import 'data/progres_providers.dart';
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
  final TextEditingController _beratBebanController = TextEditingController();
  final TextEditingController _setController = TextEditingController();
  final TextEditingController _repetisiController = TextEditingController();
  final TextEditingController _istirahatController = TextEditingController();

  MasterOlahraga? _selectedOlahraga;
  final List<_DraftMeal> _draftMeals = [];
  final List<CreatedActivityLog> _submittedActivities = [];

  bool _menyimpanAktivitas = false;
  bool _menyimpanMeal = false;
  bool _mengestimasi = false;

  @override
  void initState() {
    super.initState();
    _muatRiwayatHariIni();
  }

  @override
  void dispose() {
    _customMenuController.dispose();
    _customGramController.dispose();
    _durasiController.dispose();
    _jarakController.dispose();
    _beratBebanController.dispose();
    _setController.dispose();
    _repetisiController.dispose();
    _istirahatController.dispose();
    super.dispose();
  }

  Future<void> _muatRiwayatHariIni() async {
    try {
      final list = await ref.read(progresRepositoryProvider).getActivityLogs();
      if (!mounted) return;
      setState(() {
        _submittedActivities
          ..clear()
          ..addAll(list);
      });
    } catch (_) {
      // Gagal memuat riwayat (mis. offline) — biarkan kosong, tidak mengganggu.
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

  int get _totalKaloriTerbakar =>
      _submittedActivities.fold(0, (sum, a) => sum + a.kaloriTerbakar);

  String _detailAktivitas(CreatedActivityLog act) {
    final bagian = <String>['${act.durasiMenit} menit'];
    if (act.beratBebanKg != null && act.repetisi != null && act.jumlahSet != null) {
      final berat = act.beratBebanKg!;
      final beratTeks = berat % 1 == 0 ? berat.toStringAsFixed(0) : berat.toStringAsFixed(1);
      bagian.add('$beratTeks kg × ${act.repetisi} rep × ${act.jumlahSet} set');
      if (act.waktuIstirahatDetik != null) {
        bagian.add('jeda ${act.waktuIstirahatDetik} dtk');
      }
    } else if (act.jarakMeter != null) {
      bagian.add('${act.jarakMeter!.toStringAsFixed(0)} meter');
    }
    return bagian.join(' • ');
  }

  Future<void> _submitActivity(MasterOlahraga? olahraga) async {
    if (olahraga == null) {
      _toast('Pilih jenis olahraga dulu.', error: true);
      return;
    }

    int? durasi;
    double? jarak;
    double? beratBeban;
    int? jumlahSet;
    int? repetisi;
    int? istirahat;

    if (olahraga.butuhBeban) {
      beratBeban = double.tryParse(_beratBebanController.text.trim().replaceAll(',', '.'));
      jumlahSet = int.tryParse(_setController.text.trim());
      repetisi = int.tryParse(_repetisiController.text.trim());
      istirahat = int.tryParse(_istirahatController.text.trim());

      if (beratBeban == null || beratBeban <= 0) {
        _toast('Berat beban (kg) wajib diisi.', error: true);
        return;
      }
      if (jumlahSet == null || jumlahSet <= 0) {
        _toast('Jumlah set wajib diisi.', error: true);
        return;
      }
      if (repetisi == null || repetisi <= 0) {
        _toast('Repetisi wajib diisi.', error: true);
        return;
      }
      if (istirahat == null || istirahat <= 0) {
        _toast('Jeda istirahat (detik) wajib diisi dan lebih dari 0.', error: true);
        return;
      }
    } else {
      durasi = int.tryParse(_durasiController.text.trim());
      if (durasi == null || durasi <= 0) {
        _toast('Durasi olahraga (menit) wajib diisi.', error: true);
        return;
      }

      if (olahraga.butuhJarak) {
        jarak = double.tryParse(_jarakController.text.trim().replaceAll(',', '.'));
        if (jarak == null || jarak <= 0) {
          _toast('Olahraga ini mewajibkan input jarak (meter).', error: true);
          return;
        }
      }
    }

    setState(() => _menyimpanAktivitas = true);
    try {
      final log = await ref.read(progresRepositoryProvider).createActivityLog(
            olahragaId: olahraga.id,
            durasiMenit: durasi,
            jarakMeter: jarak,
            beratBebanKg: beratBeban,
            jumlahSet: jumlahSet,
            repetisi: repetisi,
            waktuIstirahatDetik: istirahat,
          );
      if (!mounted) return;
      setState(() {
        _submittedActivities.insert(0, log);
        _durasiController.clear();
        _jarakController.clear();
        _beratBebanController.clear();
        _setController.clear();
        _repetisiController.clear();
        _istirahatController.clear();
      });
      ref.invalidate(dashboardSummaryProvider);
      _toast('Aktivitas tersimpan. Terbakar ${log.kaloriTerbakar} kkal.');
    } catch (e) {
      _toast(e is ApiException ? e.message : 'Gagal menyimpan aktivitas.', error: true);
    } finally {
      if (mounted) setState(() => _menyimpanAktivitas = false);
    }
  }

  int get _totalKaloriMasukDraft =>
      _draftMeals.fold(0, (sum, m) => sum + m.kalori);

  Future<void> _tambahMenu() async {
    final nama = _customMenuController.text.trim();
    final gram = double.tryParse(_customGramController.text.trim().replaceAll(',', '.'));

    if (nama.isEmpty) {
      _toast('Ketik nama menu terlebih dahulu.', error: true);
      return;
    }
    if (gram == null || gram <= 0) {
      _toast('Porsi (gram) wajib diisi dan lebih dari 0.', error: true);
      return;
    }

    setState(() => _mengestimasi = true);
    try {
      final est = await ref.read(progresRepositoryProvider).estimateMakanan(nama);
      final kalori = (est.kaloriPer100g * (gram / 100)).round();
      if (!mounted) return;
      setState(() {
        _draftMeals.add(_DraftMeal(
          makananId: est.makananId,
          nama: est.namaMakanan,
          porsiGram: gram,
          kalori: kalori,
        ));
        _customMenuController.clear();
        _customGramController.clear();
      });
    } catch (e) {
      _toast(e is ApiException ? e.message : 'Gagal mengestimasi kalori makanan.', error: true);
    } finally {
      if (mounted) setState(() => _mengestimasi = false);
    }
  }

  Future<void> _simpanMeals() async {
    if (_draftMeals.isEmpty) {
      _toast('Belum ada makanan untuk disimpan.', error: true);
      return;
    }

    final repo = ref.read(progresRepositoryProvider);
    final drafts = List<_DraftMeal>.from(_draftMeals);
    setState(() => _menyimpanMeal = true);
    try {
      int total = 0;
      for (final m in drafts) {
        final log = await repo.createMealLog(makananId: m.makananId, porsiGram: m.porsiGram);
        total += log.kaloriMasuk;
      }
      if (!mounted) return;
      setState(() => _draftMeals.clear());
      ref.invalidate(dashboardSummaryProvider);
      _toast('$total kkal tercatat ke riwayat kalori hari ini.');
    } catch (e) {
      _toast(e is ApiException ? e.message : 'Gagal menyimpan makanan.', error: true);
    } finally {
      if (mounted) setState(() => _menyimpanMeal = false);
    }
  }

  Future<void> _resetMeals() async {
    if (_draftMeals.isEmpty) {
      _customMenuController.clear();
      _customGramController.clear();
      return;
    }

    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: ctx.border),
        ),
        title: Text('Reset Daftar',
            style: TextStyle(color: ctx.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Kosongkan semua makanan yang belum disimpan hari ini?',
            style: TextStyle(color: ctx.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: ctx.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5C39),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (yakin != true || !mounted) return;
    setState(() {
      _draftMeals.clear();
      _customMenuController.clear();
      _customGramController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final masterAsync = ref.watch(masterDataProvider);
    final plan = ref.watch(weeklyPlanProvider).value;

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: masterAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF5C39))),
          error: (err, _) => _buildError(
            err is ApiException ? err.message : 'Gagal memuat data.',
          ),
          data: (data) {
            final selected = _selectedOlahraga ??
                (data.olahraga.isNotEmpty ? data.olahraga.first : null);

            return SingleChildScrollView(
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
                  if (data.fromCache) ...[
                    const SizedBox(height: 10),
                    _offlineNote(),
                  ],
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
                  if (_isMealTab)
                    _buildMealSection(plan)
                  else
                    _buildOlahragaSection(data.olahraga, selected, plan),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _offlineNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceInner,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 16, color: context.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Menampilkan data offline (cache).',
                style: TextStyle(color: context.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: context.textMuted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(masterDataProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5C39),
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
            color: active ? const Color(0xFFFF5C39) : Colors.transparent,
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

  Widget _buildWeeklyPlanCard(WeeklyPlan? plan, {required bool meal}) {
    final title = meal ? 'Rencana Menu Minggu Ini' : 'Rencana Latihan Minggu Ini';
    final subtitle = plan == null
        ? 'Belum ada weekly plan yang disetujui PT.'
        : (meal ? '${plan.mealPlan.length} menu referensi' : '${plan.workoutPlan.length} sesi referensi');

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

  Widget _buildMealSection(WeeklyPlan? plan) {
    final total = _totalKaloriMasukDraft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeeklyPlanCard(plan, meal: true),
        const SizedBox(height: 22),
        Text('Meal Hari Ini',
            style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_draftMeals.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.border),
            ),
            child: Text('Belum ada makanan ditambahkan hari ini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary, fontSize: 12)),
          )
        else
          ...List.generate(_draftMeals.length, (i) {
            final m = _draftMeals[i];
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
                        Text(m.nama,
                            style: TextStyle(
                                color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text('${m.kalori} kkal',
                            style: TextStyle(color: context.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.surfaceInner,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.border),
                    ),
                    child: Text('${m.porsiGram.toStringAsFixed(0)} gr',
                        style: TextStyle(
                            color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() => _draftMeals.removeAt(i)),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: context.surfaceInner,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.border),
                      ),
                      child: Center(
                        child: Icon(Icons.remove_rounded, size: 18, color: context.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 20),
        Text('Catat Meal',
            style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Jika makanan belum terdaftar, sistem mengestimasi kalori via AI.',
            style: TextStyle(color: context.textSecondary, fontSize: 11)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _inputBox(controller: _customMenuController, hint: 'Ketik Menu Anda'),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _inputBox(
                controller: _customGramController,
                hint: 'Porsi',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                suffixText: 'gram',
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              height: 48,
              child: ElevatedButton(
                onPressed: _mengestimasi ? null : _tambahMenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5C39),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                child: _mengestimasi
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.add_rounded, size: 24),
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
                        onPressed: _menyimpanMeal ? null : _simpanMeals,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5C39),
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

  Widget _buildOlahragaSection(
      List<MasterOlahraga> olahragaList, MasterOlahraga? selected, WeeklyPlan? plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeeklyPlanCard(plan, meal: false),
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
              value: selected,
              isExpanded: true,
              dropdownColor: context.card,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFF5C39)),
              items: olahragaList
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
        if (selected?.butuhBeban == true) ...[
          _inputBox(
            controller: _beratBebanController,
            hint: 'Berat Beban',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            suffixText: 'Kg',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _inputBox(
                  controller: _repetisiController,
                  hint: 'Repetisi',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _inputBox(
                  controller: _setController,
                  hint: 'Set',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _inputBox(
            controller: _istirahatController,
            hint: 'Jeda Istirahat',
            keyboardType: TextInputType.number,
            suffixText: 'detik',
          ),
        ] else ...[
          _inputBox(
            controller: _durasiController,
            hint: 'Durasi Latihan',
            keyboardType: TextInputType.number,
            suffixText: 'menit',
          ),
          if (selected != null && selected.butuhJarak) ...[
            const SizedBox(height: 12),
            _inputBox(
              controller: _jarakController,
              hint: 'Jarak Tempuh',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffixText: 'meter',
            ),
          ],
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _menyimpanAktivitas ? null : () => _submitActivity(selected),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5C39),
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
                style: const TextStyle(color: Color(0xFFFF5C39), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        if (_submittedActivities.isEmpty)
          Text('Belum ada aktivitas tercatat hari ini.',
              style: TextStyle(color: context.textSecondary, fontSize: 12))
        else
          ..._submittedActivities.map((act) {
            final matches = olahragaList.where((o) => o.id == act.olahragaId);
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
                          _detailAktivitas(act),
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
                            color: Color(0xFFFF5C39), fontSize: 11, fontWeight: FontWeight.bold)),
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
    String? suffixText,
  }) {
    final field = TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: context.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.surfaceInner,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: suffixText == null
          ? field
          : Row(
              children: [
                Expanded(child: field),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Text(
                    suffixText,
                    style: TextStyle(
                      color: context.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Item makanan yang belum disimpan (staging) di tab Meal.
class _DraftMeal {
  final int makananId;
  final String nama;
  final double porsiGram;
  final int kalori;

  const _DraftMeal({
    required this.makananId,
    required this.nama,
    required this.porsiGram,
    required this.kalori,
  });
}
