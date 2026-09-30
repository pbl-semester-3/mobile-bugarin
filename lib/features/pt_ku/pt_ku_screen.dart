import 'package:flutter/material.dart';
import '../../core/theme/theme_provider.dart';

class TrainerModel {
  final int id;
  final String nama;
  final int pengalamanTahun;
  final String lokasiGym;
  final String avatarUrl;

  const TrainerModel({
    required this.id,
    required this.nama,
    required this.pengalamanTahun,
    required this.lokasiGym,
    required this.avatarUrl,
  });
}

class PtKuScreen extends StatefulWidget {
  const PtKuScreen({super.key});

  @override
  State<PtKuScreen> createState() => _PtKuScreenState();
}

class _PtKuScreenState extends State<PtKuScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTrainerId = 1;

  final List<TrainerModel> _trainers = const [
    TrainerModel(
      id: 1,
      nama: 'Sarah Jenkins',
      pengalamanTahun: 7,
      lokasiGym: 'Senopati',
      avatarUrl: 'https://images.unsplash.com/photo-1594381898411-846e7d193883?w=150',
    ),
    TrainerModel(
      id: 2,
      nama: 'Elena Vance',
      pengalamanTahun: 5,
      lokasiGym: 'Dharmawangsa',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    ),
    TrainerModel(
      id: 3,
      nama: 'Dian Pratama',
      pengalamanTahun: 6,
      lokasiGym: 'Mega Kuningan',
      avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
    ),
    TrainerModel(
      id: 4,
      nama: 'Alex Sander, CSCS',
      pengalamanTahun: 9,
      lokasiGym: 'Sudirman',
      avatarUrl: 'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?w=150',
    ),
    TrainerModel(
      id: 5,
      nama: 'Marcus Vance',
      pengalamanTahun: 8,
      lokasiGym: 'Kelapa Gading',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                      child: Icon(Icons.arrow_back_rounded, size: 18, color: context.textPrimary),
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
                    Text(
                      '⌘K',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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
              ..._trainers.map((trainer) {
                final isSelected = trainer.id == _selectedTrainerId;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTrainerId = trainer.id;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFF5520) : context.border,
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
                              color: isSelected ? const Color(0xFFFF5520) : context.border,
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
                            color: isSelected ? const Color(0xFFFF5520) : context.surfaceInner,
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