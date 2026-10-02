import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/bugarin_header.dart';

part 'feedback_screen.g.dart';

// ============================================================================
// 1. DATA MODEL & ENUMERATION (Backend-Ready)
// ============================================================================
enum SenderType { ai, coach }
enum ReplyStatus { none, replied, waiting }

class FeedbackModel {
  final String id;
  final SenderType senderType;
  final String senderName;
  final String senderRole;
  final String time;
  final String content;
  
  // Spesifik untuk AI
  final String? caloryStat;
  final String? sleepStat;
  
  // Spesifik untuk Coach
  final String? coachTag;
  final ReplyStatus replyStatus;
  final String? userReply;
  final String? replyTime;

  FeedbackModel({
    required this.id,
    required this.senderType,
    required this.senderName,
    required this.senderRole,
    required this.time,
    required this.content,
    this.caloryStat,
    this.sleepStat,
    this.coachTag,
    this.replyStatus = ReplyStatus.none,
    this.userReply,
    this.replyTime,
  });
}

// ============================================================================
// 2. PROVIDER (Simulasi Fetch Data dari API)
// ============================================================================
@riverpod
Future<List<FeedbackModel>> feedbackList(Ref ref) async {
  // TODO: Ganti dengan request HTTP (dio/http) ke endpoint backend Anda
  // await Future.delayed(const Duration(milliseconds: 500)); // Simulasi loading

  return [
    FeedbackModel(
      id: '1',
      senderType: SenderType.ai,
      senderName: 'BUGARIN AI',
      senderRole: 'Evaluasi Siklus',
      time: 'Hari ini, 08:30',
      caloryStat: 'Defisit Kalori: -520 kcal',
      sleepStat: 'Kualitas Istirahat: 88%',
      content: 'Analisis asupan nutrisi 3 hari terakhir menunjukkan konsistensi protein yang sangat baik (rata-rata 115g). Disarankan menambah hidrasi +500ml sebelum sesi intensif besok untuk menjaga regenerasi otot.',
    ),
    FeedbackModel(
      id: '2',
      senderType: SenderType.coach,
      senderName: 'Coach Sarah\nNayarra',
      senderRole: 'Coach',
      time: 'Kemarin, 19:15',
      coachTag: 'Form Check • Romanian Deadlift',
      replyStatus: ReplyStatus.replied,
      content: 'Form deadlift kamu di set ke-3 terlihat jauh lebih stabil di bagian punggung bawah. Pastikan tetap tahan napas di diafragma sebelum mengangkat beban. Pertahankan tempo ini!',
      userReply: '"Terima kasih coach, saya akan perbaiki postur dan fokus pada brace core."',
      replyTime: 'Dibalas 19:40',
    ),
    FeedbackModel(
      id: '3',
      senderType: SenderType.coach,
      senderName: 'Coach Sarah\nNayarra',
      senderRole: 'Coach',
      time: 'Baru saja • 10m lalu',
      replyStatus: ReplyStatus.waiting,
      content: 'Halo User! Berdasarkan catatan peregangan panggul tadi pagi, apakah ada rasa nyeri berlebih di area hamstring kanan? Jika ada, kita sesuaikan intensitas gerakan leg curl besok.',
    ),
  ];
}

// ============================================================================
// 3. MAIN SCREEN WIDGET
// ============================================================================
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  // 0: Semua, 1: AI Insight, 2: Coach
  int _selectedFilter = 0; 
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedbackAsync = ref.watch(feedbackListProvider);

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: const BugarinHeader(subtitle: 'Feedback'),
            ),
            const SizedBox(height: 24),
            
            // TITLE AREA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evaluasi & Saran',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Umpan balik personalisasi AI & arahan Coach',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // FILTER CHIPS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildFilterChip(0, 'Semua (5)'),
                  const SizedBox(width: 10),
                  _buildFilterChip(1, 'AI Insight (2)'),
                  const SizedBox(width: 10),
                  _buildFilterChip(2, 'Coach Sarah (3)'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // LIST FEEDBACK (Menggunakan Riverpod AsyncValue)
            Expanded(
              child: feedbackAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF5520))),
                error: (err, _) => Center(child: Text('Gagal memuat: $err', style: const TextStyle(color: Colors.red))),
                data: (feedbacks) {
                  // Logika Filter
                  final filteredList = feedbacks.where((f) {
                    if (_selectedFilter == 1) return f.senderType == SenderType.ai;
                    if (_selectedFilter == 2) return f.senderType == SenderType.coach;
                    return true;
                  }).toList();

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      if (item.senderType == SenderType.ai) {
                        return _buildAICard(item);
                      } else {
                        return _buildCoachCard(item);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 4. WIDGET BUILDERS
  // ============================================================================
  
  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF5520) : context.surfaceInner,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF5520) : context.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAICard(FeedbackModel item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5520),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.senderName, style: TextStyle(color: const Color(0xFFFF5520), fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(item.senderRole, style: TextStyle(color: context.textSecondary, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Text(item.time, style: TextStyle(color: context.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(Icons.local_fire_department, item.caloryStat ?? '', isRed: true),
              const SizedBox(width: 8),
              _buildStatChip(Icons.dark_mode_outlined, item.sleepStat ?? '', isRed: false),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.content,
            style: TextStyle(color: context.textPrimary, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, {required bool isRed}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isRed ? const Color(0xFF2A1515) : context.surfaceInner,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: isRed ? const Color(0xFFFF4444) : context.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: isRed ? const Color(0xFFFF4444) : context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachCard(FeedbackModel item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFF5520), width: 1.5),
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1594381898411-846e7d193883?w=200'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.senderName, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 14, height: 1.2)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item.time, style: TextStyle(color: context.textSecondary, fontSize: 11)),
                  if (item.replyStatus == ReplyStatus.waiting) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFF5520), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Menunggu\nBalasan', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ]
                ],
              ),
            ],
          ),
          
          if (item.coachTag != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFFF5520), borderRadius: BorderRadius.circular(12)),
              child: Text(item.coachTag!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
          
          const SizedBox(height: 14),
          Text(item.content, style: TextStyle(color: context.textPrimary, fontSize: 14, height: 1.5)),
          
          // Logika Reply Area
          if (item.replyStatus == ReplyStatus.replied && item.userReply != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: context.surfaceInner, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Balasan Anda', style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(item.replyTime ?? '', style: TextStyle(color: context.textSecondary, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(item.userReply!, style: TextStyle(color: context.textPrimary, fontSize: 13, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],

          if (item.replyStatus == ReplyStatus.waiting) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: context.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.border)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      style: TextStyle(color: context.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Ketik balasan Anda...',
                        hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implementasi hit API POST Reply
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5520),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      elevation: 0,
                    ),
                    child: const Text('Balas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}