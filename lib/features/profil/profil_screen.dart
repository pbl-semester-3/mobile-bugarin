import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/bugarin_header.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  final _storage = const FlutterSecureStorage();

  final TextEditingController _bbHariIniController = TextEditingController();
  final TextEditingController _namaLengkapController = TextEditingController(text: 'Maya Ayuningsih');
  final TextEditingController _usiaController = TextEditingController(text: '26');
  final TextEditingController _tinggiBadanController = TextEditingController(text: '168');
  final TextEditingController _alergiController = TextEditingController(text: 'Laktosa, Kacang Tanah');

  double _bbAwal = 78.5;
  double _bbKini = 72.0;
  double _bbTujuan = 67.0;
  int _hariKe = 42;
  int _totalHariSiklus = 60;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final name = await _storage.read(key: 'user_name');
    final weight = await _storage.read(key: 'current_weight');
    final height = await _storage.read(key: 'user_height');

    if (mounted) {
      setState(() {
        if (name != null && name.isNotEmpty) {
          _namaLengkapController.text = name;
        }
        if (weight != null) {
          final parsedWeight = double.tryParse(weight);
          if (parsedWeight != null) _bbKini = parsedWeight;
        }
        if (height != null) {
          _tinggiBadanController.text = height;
        }
      });
    }
  }

  @override
  void dispose() {
    _bbHariIniController.dispose();
    _namaLengkapController.dispose();
    _usiaController.dispose();
    _tinggiBadanController.dispose();
    _alergiController.dispose();
    super.dispose();
  }

  void _simpanBeratBadan() async {
    final inputVal = double.tryParse(_bbHariIniController.text.trim().replaceAll(',', '.'));
    if (inputVal != null && inputVal > 30 && inputVal < 250) {
      setState(() {
        _bbKini = inputVal;
      });
      await _storage.write(key: 'current_weight', value: inputVal.toString());
      _bbHariIniController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text('Berat badan berhasil diperbarui: $_bbKini kg'),
        ),
      );
    }
  }

  void _simpanInformasiDiri() async {
    await _storage.write(key: 'user_name', value: _namaLengkapController.text.trim());
    await _storage.write(key: 'user_height', value: _tinggiBadanController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Text('Informasi profil berhasil diperbarui.'),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.border),
        ),
        title: Text(
          'Keluar dari Akun',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun dan kembali ke halaman awal?',
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              // 1. Bersihkan seluruh sesi/token yang tersimpan
              await _storage.deleteAll();

              if (!ctx.mounted) return;
              Navigator.pop(ctx); // Tutup pop-up dialog

              // 2. Arahkan kembali ke Landing/Welcome Page
              try {
                // Mencoba navigasi via GoRouter
                context.go('/welcome');
              } catch (_) {
                try {
                  context.go('/');
                } catch (_) {
                  // Fallback Navigator biasa
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final double selisihBB = _bbKini - _bbAwal;
    final double totalJarakBB = (_bbTujuan - _bbAwal).abs();
    final double jarakDitempuh = (_bbKini - _bbAwal).abs();
    final double progressRatio = totalJarakBB > 0 ? (jarakDitempuh / totalJarakBB).clamp(0.0, 1.0) : 0.0;
    final double progressSiklus = (_hariKe / _totalHariSiklus).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan tombol Back aktif dan tanpa avatar ganda
              BugarinHeader(
                subtitle: 'Profile',
                showBackButton: true,
                showProfileAvatar: false,
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: context.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: context.border, width: 1.2),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF5520),
                              width: 2.2,
                            ),
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5520),
                            shape: BoxShape.circle,
                            border: Border.all(color: context.card, width: 2),
                          ),
                          child: const Icon(Icons.check, size: 14, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _namaLengkapController.text,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Color(0xFFFF5520), size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@mayaayu',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.surfaceInner,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 12, color: context.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Member Sejak Jan 2024',
                            style: TextStyle(color: context.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: context.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF5520).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Target tercapai! Mulai target baru?',
                      style: TextStyle(
                        color: Color(0xFFFF5520),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: Color(0xFFFF5520), size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
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
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5520),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'KINI: ${_bbKini.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: context.surfaceInner,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            Container(
                              height: 6,
                              width: constraints.maxWidth * progressRatio,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5520),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            Positioned(
                              left: ((constraints.maxWidth * progressRatio) - 8).clamp(0.0, constraints.maxWidth - 16),
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFFF5520), width: 3),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BB AWAL', style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text('$_bbAwal kg', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text(
                          'PENCAPAIAN ${selisihBB > 0 ? "+${selisihBB.toStringAsFixed(1)}" : selisihBB.toStringAsFixed(1)} KG',
                          style: const TextStyle(
                            color: Color(0xFFFF5520),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('BB TUJUAN', style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text('$_bbTujuan kg', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.surfaceInner,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.local_fire_department_rounded, size: 14, color: Color(0xFFFF5520)),
                                    SizedBox(width: 4),
                                    Text('Target Kalori', style: TextStyle(color: Color(0xFF8A9992), fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('1,980 kcal/hari', style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text('Defisit Terkontrol (-18%)', style: TextStyle(color: context.textMuted, fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.surfaceInner,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 14, color: Color(0xFFFF5520)),
                                    SizedBox(width: 4),
                                    Text('Durasi Siklus', style: TextStyle(color: Color(0xFF8A9992), fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('Hari $_hariKe / $_totalHariSiklus', style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: progressSiklus,
                                    backgroundColor: context.border,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF5520)),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'PERBARUI BERAT BADAN HARI INI',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: context.surfaceInner,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: context.border),
                            ),
                            child: TextField(
                              controller: _bbHariIniController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(color: context.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Ketik BB hari ini (contoh: 71.8)',
                                hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _simpanBeratBadan,
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5520),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Informasi Diri',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: _simpanInformasiDiri,
                          child: const Text(
                            'Simpan',
                            style: TextStyle(
                              color: Color(0xFFFF5520),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('NAMA LENGKAP', style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _buildInputField(_namaLengkapController, 'Nama Lengkap'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('USIA', style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              _buildInputField(_usiaController, 'Usia (thn)', isNumber: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TINGGI BADAN', style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              _buildInputField(_tinggiBadanController, 'Tinggi (cm)', isNumber: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('ALERGI & PANTANGAN MAKANAN', style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _buildInputField(_alergiController, 'Alergi & Pantangan'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
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
                    Text(
                      'Keamanan & Tampilan',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.surfaceInner,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lock_outline_rounded, color: context.textSecondary, size: 18),
                              const SizedBox(width: 10),
                              Text('Ubah Kata Sandi', style: TextStyle(color: context.textPrimary, fontSize: 13)),
                            ],
                          ),
                          Icon(Icons.chevron_right_rounded, color: context.textSecondary, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.surfaceInner,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                                color: context.textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tema Visual',
                                    style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    isDark ? 'Bioluminescent Dark' : 'Fresh Light Mode',
                                    style: TextStyle(color: context.textMuted, fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0A1310) : const Color(0xFFDDE4E0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    ref.read(themeModeProvider.notifier).setLight();
                                  },
                                  child: Container(
                                    width: 34,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: !isDark ? const Color(0xFFFF5520) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.wb_sunny_rounded,
                                      size: 16,
                                      color: !isDark ? Colors.white : context.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                GestureDetector(
                                  onTap: () {
                                    ref.read(themeModeProvider.notifier).setDark();
                                  },
                                  child: Container(
                                    width: 34,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFFFF5520) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.nightlight_round,
                                      size: 16,
                                      color: isDark ? Colors.white : context.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFFE53935), size: 18),
                    label: const Text('Keluar dari Akun', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? const Color(0xFF2E1717) : const Color(0xFFFFCDD2)),
                      backgroundColor: isDark ? const Color(0xFF1A0F0F) : const Color(0xFFFFEBEE),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: context.surfaceInner,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: context.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}