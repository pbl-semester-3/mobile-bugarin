import 'package:flutter/material.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/bugarin_header.dart';

class MasterOlahraga {
  final int id;
  final String nama;
  final bool butuhJarak;
  final double met;

  const MasterOlahraga({
    required this.id,
    required this.nama,
    required this.butuhJarak,
    required this.met,
  });
}

class MealItem {
  final int id;
  final String nama;
  final int kaloriPer100g;
  int gram;
  bool isSelected;
  final bool isCustom;

  MealItem({
    required this.id,
    required this.nama,
    required this.kaloriPer100g,
    required this.gram,
    this.isSelected = true,
    this.isCustom = false,
  });

  int get totalKalori => ((gram / 100) * kaloriPer100g).round();
}

class ActivityLogItem {
  final String namaOlahraga;
  final int durasiMenit;
  final int? jarakMeter;
  final int kaloriTerbakar;

  ActivityLogItem({
    required this.namaOlahraga,
    required this.durasiMenit,
    this.jarakMeter,
    required this.kaloriTerbakar,
  });
}

class ProgresScreen extends StatefulWidget {
  const ProgresScreen({super.key});

  @override
  State<ProgresScreen> createState() => _ProgresScreenState();
}

class _ProgresScreenState extends State<ProgresScreen> {
  bool _isMealTab = true;

  final TextEditingController _customMenuController = TextEditingController();
  final TextEditingController _customGramController = TextEditingController();
  final TextEditingController _durasiController = TextEditingController();
  final TextEditingController _jarakController = TextEditingController();

  final List<MealItem> _meals = [
    MealItem(id: 1, nama: 'Nasi Merah', kaloriPer100g: 150, gram: 150),
    MealItem(id: 2, nama: 'Dada Ayam', kaloriPer100g: 165, gram: 150),
    MealItem(id: 3, nama: 'Ikan Tuna Panggang', kaloriPer100g: 130, gram: 100),
    MealItem(id: 4, nama: 'Sayur Bayam & Wortel', kaloriPer100g: 35, gram: 100),
  ];

  final List<MasterOlahraga> _masterOlahragaList = const [
    MasterOlahraga(id: 1, nama: 'Lari Santai (Jogging)', butuhJarak: true, met: 7.0),
    MasterOlahraga(id: 2, nama: 'Bersepeda Luar Ruangan', butuhJarak: true, met: 6.8),
    MasterOlahraga(id: 3, nama: 'Renang Gaya Bebas', butuhJarak: true, met: 8.0),
    MasterOlahraga(id: 4, nama: 'Latihan Beban (Hypertrophy)', butuhJarak: false, met: 5.0),
    MasterOlahraga(id: 5, nama: 'Kalistenik & Core', butuhJarak: false, met: 4.5),
    MasterOlahraga(id: 6, nama: 'HIIT Circuit', butuhJarak: false, met: 8.5),
  ];

  late MasterOlahraga _selectedOlahraga;

  final List<ActivityLogItem> _submittedActivities = [
    ActivityLogItem(
      namaOlahraga: 'Latihan Beban (Hypertrophy)',
      durasiMenit: 45,
      kaloriTerbakar: 260,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedOlahraga = _masterOlahragaList.first;
  }

  @override
  void dispose() {
    _customMenuController.dispose();
    _customGramController.dispose();
    _durasiController.dispose();
    _jarakController.dispose();
    super.dispose();
  }

  int get _totalKaloriMasuk {
    int total = 0;
    for (var m in _meals) {
      if (m.isSelected) {
        total += m.totalKalori;
      }
    }
    return total;
  }

  int get _totalKaloriTerbakar {
    int total = 0;
    for (var act in _submittedActivities) {
      total += act.kaloriTerbakar;
    }
    return total;
  }

  void _addCustomMeal() {
    final name = _customMenuController.text.trim();
    final gram = int.tryParse(_customGramController.text.trim());

    if (name.isEmpty || gram == null || gram <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Nama makanan dan porsi gram wajib diisi dengan benar.'),
        ),
      );
      return;
    }

    setState(() {
      _meals.add(
        MealItem(
          id: DateTime.now().millisecondsSinceEpoch,
          nama: name,
          kaloriPer100g: 135,
          gram: gram,
          isSelected: true,
          isCustom: true,
        ),
      );
      _customMenuController.clear();
      _customGramController.clear();
    });
  }

  void _editPortionDialog(MealItem meal) {
    final controller = TextEditingController(text: meal.gram.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.border),
        ),
        title: Text(
          'Ubah Porsi ${meal.nama}',
          style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
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
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                setState(() {
                  meal.gram = val;
                });
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

  void _resetMeals() {
    setState(() {
      for (var meal in _meals) {
        meal.isSelected = false;
      }
      _meals.removeWhere((item) => item.isCustom);
    });
  }

  void _submitActivity() {
    final durasi = int.tryParse(_durasiController.text.trim());
    if (durasi == null || durasi <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Durasi olahraga (menit) wajib diisi.'),
        ),
      );
      return;
    }

    int? jarak;
    if (_selectedOlahraga.butuhJarak) {
      jarak = int.tryParse(_jarakController.text.trim());
      if (jarak == null || jarak <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text('Olahraga ini mewajibkan input jarak tempuh (meter).'),
          ),
        );
        return;
      }
    }

    final double beratBadanKg = 70.0;
    final int kaloriEstimasi = ((_selectedOlahraga.met * 3.5 * beratBadanKg / 200) * durasi).round();

    setState(() {
      _submittedActivities.insert(
        0,
        ActivityLogItem(
          namaOlahraga: _selectedOlahraga.nama,
          durasiMenit: durasi,
          jarakMeter: jarak,
          kaloriTerbakar: kaloriEstimasi,
        ),
      );
      _durasiController.clear();
      _jarakController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('Aktivitas tersimpan. Estimasi terbakar: $kaloriEstimasi kkal.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BugarinHeader(subtitle: 'Progres'),
              const SizedBox(height: 22),
              Text(
                'Progres Harian',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pantau asupan nutrisi dan aktivitas latihan terpadu.',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12,
                ),
              ),
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
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isMealTab = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isMealTab ? const Color(0xFFFF5520) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'Meal (Nutrisi)',
                              style: TextStyle(
                                color: _isMealTab ? Colors.white : context.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isMealTab = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isMealTab ? const Color(0xFFFF5520) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'Olahraga',
                              style: TextStyle(
                                color: !_isMealTab ? Colors.white : context.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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

  Widget _buildMealSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                child: const Text(
                  'WEEKLY PLAN • MEAL',
                  style: TextStyle(
                    color: Color(0xFFFF5520),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Rencana Menu Hari Ini',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Prioritaskan sumber protein bebas lemak jenuh dan karbohidrat kompleks terukur.',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Preset Makanan Hari Ini',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._meals.map((meal) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: meal.isSelected
                    ? const Color(0xFFFF5520).withValues(alpha: 0.4)
                    : context.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              meal.nama,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (meal.isCustom) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.surfaceInner,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'AI',
                                style: TextStyle(
                                  color: Color(0xFFFF5520),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${meal.totalKalori} kkal (${meal.kaloriPer100g} kkal/100g)',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _editPortionDialog(meal),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.surfaceInner,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.border),
                    ),
                    child: Text(
                      '${meal.gram} g',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      meal.isSelected = !meal.isSelected;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: meal.isSelected ? const Color(0xFFFF5520) : context.surfaceInner,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: meal.isSelected ? Colors.transparent : context.border,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: meal.isSelected ? Colors.white : context.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),
        Text(
          'Tambah Menu Khusus (Custom Entry)',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Jika makanan belum terdaftar, sistem akan mengestimasi kalori otomatis.',
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: context.surfaceInner,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.border),
                ),
                child: TextField(
                  controller: _customMenuController,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ketik Menu Anda',
                    hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: context.surfaceInner,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.border),
                ),
                child: TextField(
                  controller: _customGramController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Porsi (g)',
                    hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addCustomMeal,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5520),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 24),
                ),
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
                      Text(
                        'TOTAL KALORI MASUK',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_totalKaloriMasuk kkal',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Reset',
                          style: TextStyle(color: context.textSecondary, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              content: Text(
                                'Terkirim ke backend: $_totalKaloriMasuk kkal tercatat.',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5520),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                child: const Text(
                  'WEEKLY PLAN • WORKOUT',
                  style: TextStyle(
                    color: Color(0xFFFF5520),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Upper Body Hypertrophy & Core Power',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Fokus hipertrofi dada, bahu samping, dan aktivasi akselerasi core mingguan.',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Catat Aktivitas Latihan',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
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
              value: _selectedOlahraga,
              isExpanded: true,
              dropdownColor: context.card,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFF5520)),
              items: _masterOlahragaList.map((item) {
                return DropdownMenuItem<MasterOlahraga>(
                  value: item,
                  child: Text(
                    item.nama,
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedOlahraga = val;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: context.surfaceInner,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.border),
          ),
          child: TextField(
            controller: _durasiController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: context.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Durasi Latihan (menit)',
              hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (_selectedOlahraga.butuhJarak) ...[
          const SizedBox(height: 12),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: context.surfaceInner,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFF5520).withValues(alpha: 0.6)),
            ),
            child: TextField(
              controller: _jarakController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Jarak Tempuh (meter) *Wajib',
                hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _submitActivity,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5520),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Catat Latihan Ini', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Hari Ini',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Total: $_totalKaloriTerbakar kkal',
              style: const TextStyle(
                color: Color(0xFFFF5520),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._submittedActivities.map((act) {
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
                      Text(
                        act.namaOlahraga,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        act.jarakMeter != null
                            ? '${act.durasiMenit} menit • ${act.jarakMeter} meter'
                            : '${act.durasiMenit} menit',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 11,
                        ),
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
                  child: Text(
                    '${act.kaloriTerbakar} kkal',
                    style: const TextStyle(
                      color: Color(0xFFFF5520),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}