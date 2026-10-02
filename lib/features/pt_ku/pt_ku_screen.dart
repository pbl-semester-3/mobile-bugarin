import 'package:flutter/material.dart';
import '../../core/theme/theme_provider.dart';

// Model Trainer yang siap diintegrasikan dengan API Backend
class TrainerModel {
  final int id;
  final String nama;
  final int pengalamanTahun;
  final String lokasiGym;
  final String avatarUrl;
  final String spesialisasi;

  const TrainerModel({
    required this.id,
    required this.nama,
    required this.pengalamanTahun,
    required this.lokasiGym,
    required this.avatarUrl,
    this.spesialisasi = 'Hipertrofi & Strength',
  });

  factory TrainerModel.fromJson(Map<String, dynamic> json) {
    return TrainerModel(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      pengalamanTahun: json['pengalaman_tahun'] ?? 0,
      lokasiGym: json['lokasi_gym'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      spesialisasi: json['spesialisasi'] ?? 'Hipertrofi & Strength',
    );
  }
}

class PtKuScreen extends StatefulWidget {
  const PtKuScreen({super.key});

  @override
  State<PtKuScreen> createState() => PtKuScreenState();
}

class PtKuScreenState extends State<PtKuScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTrainerId = 0;
  bool _isLoading = false;

  final List<TrainerModel> _trainers = const [
    TrainerModel(
      id: 1,
      nama: 'Sarah Jenkins',
      pengalamanTahun: 7,
      lokasiGym: 'FitZone Senopati',
      avatarUrl: 'https://images.unsplash.com/photo-1594381898411-846e7d193883?w=150',
      spesialisasi: 'Hipertrofi & Strength',
    ),
    TrainerModel(
      id: 2,
      nama: 'Elena Vance',
      pengalamanTahun: 5,
      lokasiGym: 'FitZone Dharmawangsa',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      spesialisasi: 'Pilates & Core Stability',
    ),
    TrainerModel(
      id: 3,
      nama: 'Dian Pratama',
      pengalamanTahun: 6,
      lokasiGym: 'FitZone Kuningan',
      avatarUrl: 'https://images.unsplash.com/photo-1567013127542-490d757e51fc?w=150',
      spesialisasi: 'Strength & Conditioning',
    ),
    TrainerModel(
      id: 4,
      nama: 'Alex Sander',
      pengalamanTahun: 9,
      lokasiGym: 'FitZone Sudirman',
      avatarUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=150',
      spesialisasi: 'Fat Loss & Transformation',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // FUNGSI INTEGRASI BACKEND SESUAI PRD (Bagian 3.4 & 4)
  Future<void> _kirimPairingRequest(TrainerModel trainer) async {
    setState(() => _isLoading = true);
    
    // TODO: Hubungkan dengan Backend Teman Anda
    // Endpoint: POST /klien/pairing-requests
    // Body: { "pt_id": trainer.id }
    // Auth: Bearer Token
    
    await Future.delayed(const Duration(seconds: 1)); // Simulasi API Delay
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context); // Tutup Modal

    // Menampilkan status sesuai PRD
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request terkirim! Menunggu konfirmasi Coach ${trainer.nama}.'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // MODAL KONFIRMASI (Persis seperti gambar referensi, dengan warna tema kita)
  void _showConfirmationDialog(BuildContext context, TrainerModel trainer) {
    const accentColor = Color(0xFFFF5520); // Warna oranye khas kita
    final firstName = trainer.nama.split(' ').first.toUpperCase();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: context.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            width: 420, // Batas lebar agar rapi di desktop/web
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // CLOSE BUTTON (X) DI KANAN ATAS
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.surfaceInner,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, size: 18, color: context.textSecondary),
                    ),
                  ),
                ),
                
                // AVATAR GLOW
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                    border: Border.all(color: accentColor, width: 2.5),
                    image: DecorationImage(
                      image: NetworkImage(trainer.avatarUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // COACH INFO
                Text(
                  'Coach ${trainer.nama}',
                  style: const TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${trainer.spesialisasi} • ${trainer.pengalamanTahun} thn exp • ${trainer.lokasiGym}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 32),

                // TITLE & DESCRIPTION
                Text(
                  'Yakin Ingin Memilih PT Ini?',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Anda akan terhubung langsung dengan Coach ${trainer.nama} untuk menyusun program latihan dan panduan transformasi kebugaran Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // FEATURE BOX
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.surfaceInner,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureRow(
                        Icons.calendar_today_rounded,
                        'Sesi Aktif: ',
                        highlightText: '12 Sesi Pertemuan',
                        accent: accentColor,
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureRow(
                        Icons.schedule_rounded,
                        'Jadwal Fleksibel & Booking Mandiri',
                        accent: accentColor,
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureRow(
                        Icons.check_circle_outline_rounded,
                        'Konsultasi Nutrisi & Panduan Pola Makan',
                        accent: accentColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // MAIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _kirimPairingRequest(trainer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'YA, PILIH COACH $firstName',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // CANCEL BUTTON
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8), // Home indicator spacing
              ],
            ),
          ),
        );
      },
    );
  }

  // WIDGET HELPER UNTUK ROW FITUR DALAM KOTAK
  Widget _buildFeatureRow(IconData icon, String text, {String? highlightText, required Color accent}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: context.textPrimary, fontSize: 13, fontFamily: 'Outfit'), // Sesuaikan font jika ada
              children: [
                TextSpan(text: text),
                if (highlightText != null)
                  TextSpan(
                    text: highlightText,
                    style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFFF5520);

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.surfaceInner,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.border),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Personal Trainer',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Coach terakreditasi untuk siklus targetmu',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // SEARCH BAR
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: context.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: context.textMuted, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: context.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Cari nama, spesialisasi, atau gym...',
                          hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Text(
                'Tersedia ${_trainers.length} Personal Trainer',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // LIST COACH / TRAINER
              ..._trainers.map((trainer) {
                final isSelected = trainer.id == _selectedTrainerId;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTrainerId = trainer.id;
                    });
                    // Buka Modal Konfirmasi Baru
                    _showConfirmationDialog(context, trainer);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? accentColor : context.border,
                        width: isSelected ? 1.6 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? accentColor : context.border,
                              width: 1.5,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(trainer.avatarUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trainer.nama,
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${trainer.pengalamanTahun} thn exp • ${trainer.lokasiGym}',
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor : context.surfaceInner,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : context.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Pilih',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : context.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 14,
                                color: isSelected ? Colors.white : context.textPrimary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}