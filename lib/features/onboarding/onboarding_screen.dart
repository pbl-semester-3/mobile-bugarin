import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_provider.dart';

class OnboardingScreen extends StatefulWidget {
  final String mode;
  const OnboardingScreen({this.mode = 'first-time', super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _storage = const FlutterSecureStorage();

  bool _isMale = true;
  int _age = 26;
  int _height = 175;

  final List<String> _allergyOptions = ['Kacang', 'Laktosa', 'Gluten', 'Seafood', 'Tidak Ada (Bebas)'];
  final List<String> _selectedAllergies = ['Tidak Ada (Bebas)'];

  int _targetGoalIndex = 0; // 0: Turun BB, 1: Naik BB Massa Otot
  double _currentWeight = 72.5;
  double _targetWeight = 67.0;

  bool _isSaving = false;

  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _currentWeightController;
  late final TextEditingController _targetWeightController;
  late final TextEditingController _otherAllergyController;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: '$_age');
    _heightController = TextEditingController(text: '$_height');
    _currentWeightController = TextEditingController(text: '$_currentWeight');
    _targetWeightController = TextEditingController(text: '$_targetWeight');
    _otherAllergyController = TextEditingController();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final weight = await _storage.read(key: 'current_weight');
    final height = await _storage.read(key: 'user_height');
    final age = await _storage.read(key: 'user_age');
    final gender = await _storage.read(key: 'user_gender');

    if (mounted) {
      setState(() {
        if (weight != null) {
          final p = double.tryParse(weight);
          if (p != null) {
            _currentWeight = p;
            _currentWeightController.text = p.toStringAsFixed(1);
          }
        }
        if (height != null) {
          final p = int.tryParse(height);
          if (p != null) {
            _height = p;
            _heightController.text = '$p';
          }
        }
        if (age != null) {
          final p = int.tryParse(age);
          if (p != null) {
            _age = p;
            _ageController.text = '$p';
          }
        }
        if (gender != null) _isMale = gender == 'male';
      });
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    _otherAllergyController.dispose();
    super.dispose();
  }

  void _toggleAllergy(String allergy) {
    setState(() {
      if (allergy == 'Tidak Ada (Bebas)') {
        _selectedAllergies.clear();
        _selectedAllergies.add('Tidak Ada (Bebas)');
      } else {
        _selectedAllergies.remove('Tidak Ada (Bebas)');
        if (_selectedAllergies.contains(allergy)) {
          _selectedAllergies.remove(allergy);
          if (_selectedAllergies.isEmpty) _selectedAllergies.add('Tidak Ada (Bebas)');
        } else {
          _selectedAllergies.add(allergy);
        }
      }
    });
  }

  int get _calculatedCalories {
    double bmr = _isMale
        ? (10 * _currentWeight) + (6.25 * _height) - (5 * _age) + 5
        : (10 * _currentWeight) + (6.25 * _height) - (5 * _age) - 161;
    final tdee = bmr * 1.55; // Default Sedang
    if (_targetGoalIndex == 0) return (tdee - 450).round().clamp(1200, 4500); // Turun
    return (tdee + 350).round().clamp(1500, 5000); // Naik
  }

  Future<void> _submitData() async {
    setState(() => _isSaving = true);
    try {
      await _storage.write(key: 'has_completed_profile', value: 'true');
      await _storage.write(key: 'user_gender', value: _isMale ? 'male' : 'female');
      await _storage.write(key: 'user_age', value: '$_age');
      await _storage.write(key: 'user_height', value: '$_height');
      await _storage.write(key: 'current_weight', value: '$_currentWeight');
      await _storage.write(key: 'user_target_weight', value: '$_targetWeight');
      await _storage.write(key: 'daily_calorie_target', value: '$_calculatedCalories');
      
      final allergyStr = _selectedAllergies.join(', ') + (_otherAllergyController.text.isNotEmpty ? ', ${_otherAllergyController.text}' : '');
      await _storage.write(key: 'user_allergies', value: allergyStr);

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      if (widget.mode == 'new-cycle') {
        context.pop();
      } else {
        context.go('/');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF5520);

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.border)),
                    child: GestureDetector(
                      onTap: () => context.canPop() ? context.pop() : null,
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: context.textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: context.surfaceInner, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.border)),
                    child: Text(widget.mode == 'new-cycle' ? 'SIKLUS BARU' : 'LANGKAH 1 DARI 1', style: TextStyle(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Target & Profil Fisik', style: TextStyle(color: context.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('Data esensial untuk perhitungan target kalori cerdas AI & generate Weekly Plan personal yang adaptif.', style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.4)),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Profil Dasar Klien', style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('KLIEN_PROFILES', style: TextStyle(color: context.textMuted, fontSize: 10, letterSpacing: 1.0)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jenis Kelamin Biologis • Wajib', style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildGenderBtn('Pria', Icons.male_rounded, _isMale, () => setState(() => _isMale = true))),
                              const SizedBox(width: 10),
                              Expanded(child: _buildGenderBtn('Wanita', Icons.female_rounded, !_isMale, () => setState(() => _isMale = false))),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: _buildCounterField('USIA', 'tahun', _ageController, () => setState(() => _age > 14 ? _age-- : null), () => setState(() => _age < 85 ? _age++ : null), (v) => setState(() => _age = int.parse(v)))),
                              Container(width: 1, height: 50, color: context.border, margin: const EdgeInsets.symmetric(horizontal: 16)),
                              Expanded(child: _buildCounterField('TINGGI', 'cm', _heightController, () => setState(() => _height > 120 ? _height-- : null), () => setState(() => _height < 230 ? _height++ : null), (v) => setState(() => _height = int.parse(v)))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Alergi & Preferensi Diet', style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('Pilih multi', style: TextStyle(color: context.textMuted, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            children: _allergyOptions.map((opt) {
                              final active = _selectedAllergies.contains(opt);
                              return GestureDetector(
                                onTap: () => _toggleAllergy(opt),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: active ? (opt.contains('Tidak') ? const Color(0xFFE0F2F1) : const Color(0xFFFFECE5)) : context.surfaceInner,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: active ? (opt.contains('Tidak') ? Colors.teal : accent) : context.border),
                                  ),
                                  child: Text(opt, style: TextStyle(color: active ? (opt.contains('Tidak') ? Colors.teal[700] : accent) : context.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 42,
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.border))),
                            child: TextField(
                              controller: _otherAllergyController,
                              style: TextStyle(color: context.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Ada batasan lain? (cth: Vegan, Halal)',
                                hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
                                border: InputBorder.none,
                                suffixIcon: Icon(Icons.edit_note_rounded, color: context.textMuted, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Siklus & Target Progres', style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('PROGRESS_CYCLES', style: TextStyle(color: context.textMuted, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Arah Sasaran Siklus Ini', style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildGoalBtn('Turun BB', 'DEFISIT KALORI', 0)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildGoalBtn('Naik BB', 'MASSA OTOT', 1)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildWeightRow('Berat Badan Awal', 'Masuk ke log berat perdana', _currentWeightController, () => setState(() => _currentWeight -= 0.5), () => setState(() => _currentWeight += 0.5), (v) => setState(() => _currentWeight = double.parse(v))),
                          Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Divider(color: context.border)),
                          _buildWeightRow('Berat Badan Tujuan', 'Target akhir siklus', _targetWeightController, () => setState(() => _targetWeight -= 0.5), () => setState(() => _targetWeight += 0.5), (v) => setState(() => _targetWeight = double.parse(v)), isTarget: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submitData,
                        style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                        child: _isSaving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                            : const Text('MULAI GENERATE AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
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

  Widget _buildGenderBtn(String label, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF5520) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? const Color(0xFFFF5520) : context.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : context.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: active ? Colors.white : context.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterField(String label, String unit, TextEditingController ctrl, VoidCallback onDec, VoidCallback onInc, Function(String) onChanged) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            IntrinsicWidth(child: TextField(controller: ctrl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], textAlign: TextAlign.center, style: TextStyle(color: context.textPrimary, fontSize: 24, fontWeight: FontWeight.bold), decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none), onChanged: onChanged)),
            const SizedBox(width: 4),
            Text(unit, style: TextStyle(color: context.textMuted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBtn(Icons.remove, onDec),
            const SizedBox(width: 16),
            _buildBtn(Icons.add, onInc),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalBtn(String title, String sub, int index) {
    final active = _targetGoalIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _targetGoalIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: active ? const Color(0xFFFF5520) : context.surfaceInner, borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? const Color(0xFFFF5520) : context.border)),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: active ? Colors.white : context.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: active ? Colors.white70 : context.textMuted, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightRow(String title, String sub, TextEditingController ctrl, VoidCallback onDec, VoidCallback onInc, Function(String) onChanged, {bool isTarget = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(color: context.textMuted, fontSize: 11)),
            ],
          ),
        ),
        Row(
          children: [
            _buildBtn(Icons.remove, onDec),
            const SizedBox(width: 12),
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    IntrinsicWidth(child: TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), textAlign: TextAlign.center, style: TextStyle(color: context.textPrimary, fontSize: 22, fontWeight: FontWeight.bold), decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none), onChanged: onChanged)),
                    const SizedBox(width: 2),
                    Text('kg', style: TextStyle(color: context.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 12),
            _buildBtn(Icons.add, onInc),
          ],
        ),
      ],
    );
  }

  Widget _buildBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 28, height: 28, decoration: BoxDecoration(color: context.surfaceInner, shape: BoxShape.circle, border: Border.all(color: context.border)), child: Icon(icon, size: 14, color: context.textPrimary)),
    );
  }
}