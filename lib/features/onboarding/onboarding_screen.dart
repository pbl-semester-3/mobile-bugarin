import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _storage = const FlutterSecureStorage();

  // State Profil Dasar
  bool _isMale = true;
  int _age = 24;
  int _height = 175;

  final List<String> _activityLevels = [
    'Jarang',
    'Sedang',
    'Berat',
    'Ekstrem',
    'Atlet',
  ];
  int _selectedActivityIndex = 1;

  // 0: Turun BB, 1: Jaga BB, 2: Tambah Otot
  int _targetGoalIndex = 0;
  double _currentWeight = 72.5;
  double _targetWeight = 67.0;

  final List<int> _durationOptions = [30, 60, 90];
  int _selectedDuration = 60;

  bool _isSaving = false;

  // Controller agar kolom bisa diketik langsung
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _currentWeightController;
  late final TextEditingController _targetWeightController;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: '$_age');
    _heightController = TextEditingController(text: '$_height');
    _currentWeightController = TextEditingController(text: '$_currentWeight');
    _targetWeightController = TextEditingController(text: '$_targetWeight');
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  // Rumus Mifflin-St Jeor
  int get _calculatedCalories {
    double bmr;
    if (_isMale) {
      bmr = (10 * _currentWeight) + (6.25 * _height) - (5 * _age) + 5;
    } else {
      bmr = (10 * _currentWeight) + (6.25 * _height) - (5 * _age) - 161;
    }

    const multipliers = [1.2, 1.375, 1.55, 1.725, 1.9];
    final tdee = bmr * multipliers[_selectedActivityIndex];

    if (_targetGoalIndex == 0) {
      return (tdee - 450).round().clamp(1200, 4500);
    } else if (_targetGoalIndex == 2) {
      return (tdee + 350).round().clamp(1500, 5000);
    } else {
      return tdee.round();
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Future<void> _handleSaveProfile() async {
    setState(() => _isSaving = true);

    try {
      await _storage.write(key: 'has_completed_profile', value: 'true');
      await _storage.write(key: 'user_gender', value: _isMale ? 'male' : 'female');
      await _storage.write(key: 'user_age', value: '$_age');
      await _storage.write(key: 'user_height', value: '$_height');
      await _storage.write(key: 'user_weight', value: '$_currentWeight');
      await _storage.write(key: 'user_target_weight', value: '$_targetWeight');
      await _storage.write(key: 'daily_calorie_target', value: '$_calculatedCalories');

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        context.go('/');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan saat menyimpan data.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyKcal = _calculatedCalories;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161920),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2C3240)),
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: Color(0xFFFF5520),
                      size: 18,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161920),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2C3240)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFFFF5520)),
                        SizedBox(width: 6),
                        Text(
                          'LANGKAH 1 DARI 1',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161920),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF2C3240)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target & Profil Fisik',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Kalkulasi presisi untuk target komposisi tubuh & ritme performa harianmu.',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // SECTION 1: PROFIL DASAR
                    _buildSectionTitle('Profil Dasar Fisik'),
                    const SizedBox(height: 12),

                    // Gender Selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161920),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2C3240)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildGenderOption(
                              label: 'Pria',
                              icon: Icons.male_rounded,
                              isSelected: _isMale,
                              onTap: () => setState(() => _isMale = true),
                            ),
                          ),
                          Expanded(
                            child: _buildGenderOption(
                              label: 'Wanita',
                              icon: Icons.female_rounded,
                              isSelected: !_isMale,
                              onTap: () => setState(() => _isMale = false),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Usia & Tinggi (Bisa Diketik & Tombol +/-)
                    Row(
                      children: [
                        Expanded(
                          child: _buildEditableCounterCard(
                            label: 'Usia',
                            controller: _ageController,
                            unit: 'Tahun',
                            onChanged: (val) {
                              final parsed = int.tryParse(val);
                              if (parsed != null && parsed >= 10 && parsed <= 100) {
                                setState(() => _age = parsed);
                              }
                            },
                            onDecrement: () {
                              if (_age > 14) {
                                setState(() {
                                  _age--;
                                  _ageController.text = '$_age';
                                });
                              }
                            },
                            onIncrement: () {
                              if (_age < 85) {
                                setState(() {
                                  _age++;
                                  _ageController.text = '$_age';
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildEditableCounterCard(
                            label: 'Tinggi',
                            controller: _heightController,
                            unit: 'cm',
                            onChanged: (val) {
                              final parsed = int.tryParse(val);
                              if (parsed != null && parsed >= 80 && parsed <= 250) {
                                setState(() => _height = parsed);
                              }
                            },
                            onDecrement: () {
                              if (_height > 120) {
                                setState(() {
                                  _height--;
                                  _heightController.text = '$_height';
                                });
                              }
                            },
                            onIncrement: () {
                              if (_height < 230) {
                                setState(() {
                                  _height++;
                                  _heightController.text = '$_height';
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Aktivitas
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161920),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF2C3240)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tingkat Aktivitas Fisik',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(_activityLevels.length, (index) {
                              final isSelected = _selectedActivityIndex == index;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedActivityIndex = index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFF5520)
                                        : const Color(0xFF1E222B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFFF5520)
                                          : const Color(0xFF2C3240),
                                    ),
                                  ),
                                  child: Text(
                                    _activityLevels[index],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SECTION 2: METRIK & TARGET
                    _buildSectionTitle('Metrik & Target Progres'),
                    const SizedBox(height: 12),

                    // Goal Selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161920),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2C3240)),
                      ),
                      child: Row(
                        children: [
                          _buildGoalPill('Turun BB', 0),
                          _buildGoalPill('Jaga BB', 1),
                          _buildGoalPill('Tambah Otot', 2),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Berat Saat Ini (Bisa Diketik & Tombol +/-)
                    _buildEditableWeightCard(
                      title: 'Berat Badan Saat Ini',
                      subtitle: 'Kondisi fisik dasar saat ini',
                      controller: _currentWeightController,
                      onChanged: (val) {
                        final parsed = double.tryParse(val.replaceAll(',', '.'));
                        if (parsed != null && parsed >= 30 && parsed <= 250) {
                          setState(() => _currentWeight = parsed);
                        }
                      },
                      onDecrement: () {
                        if (_currentWeight > 35) {
                          setState(() {
                            _currentWeight = (_currentWeight - 0.5);
                            _currentWeightController.text = _currentWeight.toStringAsFixed(1);
                          });
                        }
                      },
                      onIncrement: () {
                        if (_currentWeight < 200) {
                          setState(() {
                            _currentWeight = (_currentWeight + 0.5);
                            _currentWeightController.text = _currentWeight.toStringAsFixed(1);
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    // Target Berat Badan (Bisa Diketik & Tombol +/-)
                    _buildEditableWeightCard(
                      title: 'Target Berat Badan',
                      subtitle: 'Sasaran komposisi akhir',
                      controller: _targetWeightController,
                      highlightColor: const Color(0xFFFF5520),
                      onChanged: (val) {
                        final parsed = double.tryParse(val.replaceAll(',', '.'));
                        if (parsed != null && parsed >= 30 && parsed <= 250) {
                          setState(() => _targetWeight = parsed);
                        }
                      },
                      onDecrement: () {
                        if (_targetWeight > 35) {
                          setState(() {
                            _targetWeight = (_targetWeight - 0.5);
                            _targetWeightController.text = _targetWeight.toStringAsFixed(1);
                          });
                        }
                      },
                      onIncrement: () {
                        if (_targetWeight < 200) {
                          setState(() {
                            _targetWeight = (_targetWeight + 0.5);
                            _targetWeightController.text = _targetWeight.toStringAsFixed(1);
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    // Durasi Hari
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161920),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF2C3240)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Durasi Waktu Target',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: _durationOptions.map((days) {
                              final isSelected = _selectedDuration == days;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedDuration = days),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFF5520)
                                          : const Color(0xFF1E222B),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFFF5520)
                                            : const Color(0xFF2C3240),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$days Hari',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SECTION 3: GEMINI AI & BMR CALIBRATION ENGINE CARD
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12141A),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF1F242F)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Gemini AI & Status Live Est.[cite: 6]
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF113230),
                                  border: Border.all(
                                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFF2DD4BF),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Gemini AI & BMR Calibration\nEngine',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF162524),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Column(
                                  children: [
                                    Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: Color(0xFF2DD4BF),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Text(
                                      'EST.',
                                      style: TextStyle(
                                        color: Color(0xFF2DD4BF),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Target Kalori Harian[cite: 6]
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF181B22),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Target Kalori\nHarian:',
                                      style: TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        height: 1.25,
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          '~${_formatNumber(dailyKcal)}',
                                          style: const TextStyle(
                                            color: Color(0xFF2DD4BF),
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'kkal /\nhari',
                                          style: TextStyle(
                                            color: Color(0xFF9CA3AF),
                                            fontSize: 11,
                                            height: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Progress Bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Row(
                                    children: const [
                                      Expanded(
                                        flex: 40,
                                        child: SizedBox(
                                          height: 7,
                                          child: ColoredBox(color: Color(0xFF2DD4BF)),
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Expanded(
                                        flex: 30,
                                        child: SizedBox(
                                          height: 7,
                                          child: ColoredBox(color: Color(0xFFC084FC)),
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Expanded(
                                        flex: 30,
                                        child: SizedBox(
                                          height: 7,
                                          child: ColoredBox(color: Color(0xFF60A5FA)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Legend Nutrisi[cite: 6]
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    _NutritionLegend(color: Color(0xFF2DD4BF), label: 'Karbo 40%'),
                                    _NutritionLegend(color: Color(0xFFC084FC), label: 'Protein 30%'),
                                    _NutritionLegend(color: Color(0xFF60A5FA), label: 'Lemak 30%'),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Catatan AI[cite: 6]
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.verified_outlined,
                                  color: Color(0xFF2DD4BF),
                                  size: 18,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Siklus baru akan otomatis berstatus ',
                                    style: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 12,
                                      height: 1.45,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Aktif',
                                        style: TextStyle(
                                          color: Color(0xFF2DD4BF),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '. Begitu disimpan, AI langsung meracik 7 hari perdana Weekly Plan (menu makanan lokal Indonesia & jadwal latihan tubuh).',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tombol Submit
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSaveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5520),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Simpan & Mulai Evolusi Fisikmu',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Data profil dapat diperbarui kapan saja di menu Pengaturan Akun.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildGenderOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF5520) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableCounterCard({
    required String label,
    required TextEditingController controller,
    required String unit,
    required ValueChanged<String> onChanged,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161920),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2C3240)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              IntrinsicWidth(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniStepBtn(icon: Icons.remove, onTap: onDecrement),
              const SizedBox(width: 14),
              _buildMiniStepBtn(icon: Icons.add, onTap: onIncrement),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableWeightCard({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    Color? highlightColor,
    required ValueChanged<String> onChanged,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161920),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2C3240)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildMiniStepBtn(icon: Icons.remove, onTap: onDecrement),
              const SizedBox(width: 10),
              IntrinsicWidth(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: highlightColor ?? Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 3),
              const Text(
                'kg',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
              const SizedBox(width: 10),
              _buildMiniStepBtn(icon: Icons.add, onTap: onIncrement),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalPill(String label, int index) {
    final isSelected = _targetGoalIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _targetGoalIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF5520) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStepBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF1E222B),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF2C3240)),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

class _NutritionLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _NutritionLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}