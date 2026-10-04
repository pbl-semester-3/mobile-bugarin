import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_provider.dart';
import '../../services/api_error.dart';
import '../../shared/widgets/bugarin_header.dart';
import '../dashboard/dashboard_screen.dart' show dashboardSummaryProvider;
import 'data/feedback_providers.dart';
import 'models/feedback_item.dart';

const Color _accent = Color(0xFFFF5520);

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  int _selectedFilter = 0; // 0 Semua, 1 AI, 2 Coach
  bool _sudahTandaiBaca = false;
  int? _sendingId;
  final Map<int, TextEditingController> _replyControllers = {};

  @override
  void dispose() {
    for (final c in _replyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _replyController(int id) =>
      _replyControllers.putIfAbsent(id, () => TextEditingController());

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

  Future<void> _tandaiBaca(List<FeedbackItem> unread) async {
    if (_sudahTandaiBaca) return;
    _sudahTandaiBaca = true;
    try {
      final repo = ref.read(feedbackRepositoryProvider);
      for (final f in unread) {
        await repo.markRead(f.id);
      }
      ref.invalidate(dashboardSummaryProvider); // badge unread di bottom nav
    } catch (_) {
      // Diamkan; badge akan tersinkron saat dashboard di-refresh.
    }
  }

  Future<void> _kirimBalasan(FeedbackItem item) async {
    final controller = _replyController(item.id);
    final teks = controller.text.trim();
    if (teks.isEmpty) {
      _toast('Balasan tidak boleh kosong.', error: true);
      return;
    }
    setState(() => _sendingId = item.id);
    try {
      await ref.read(feedbackRepositoryProvider).replyFeedback(item.id, teks);
      controller.clear();
      ref.invalidate(feedbackListProvider);
      _toast('Balasan terkirim.');
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Gagal mengirim balasan.', error: true);
    } finally {
      if (mounted) setState(() => _sendingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(feedbackListProvider, (_, next) {
      next.whenData((list) {
        final unread = list.where((f) => !f.dibaca).toList();
        if (unread.isNotEmpty) _tandaiBaca(unread);
      });
    });

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Evaluasi & Saran',
                      style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Umpan balik personalisasi AI & arahan Coach',
                      style: TextStyle(color: context.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: feedbackAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _accent)),
                error: (err, _) => _buildError(),
                data: (feedbacks) {
                  final filtered = feedbacks.where((f) {
                    if (_selectedFilter == 1) return f.isAi;
                    if (_selectedFilter == 2) return f.isPt;
                    return true;
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilters(feedbacks),
                      const SizedBox(height: 20),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text('Belum ada feedback.',
                                    style: TextStyle(color: context.textSecondary, fontSize: 13)),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                                physics: const BouncingScrollPhysics(),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return item.isAi ? _buildAiCard(item) : _buildCoachCard(item);
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
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
            Text('Gagal memuat feedback.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(feedbackListProvider),
              style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(List<FeedbackItem> feedbacks) {
    final aiCount = feedbacks.where((f) => f.isAi).length;
    final ptCount = feedbacks.where((f) => f.isPt).length;
    String? coachName;
    for (final f in feedbacks) {
      if (f.isPt && f.pt != null && f.pt!.nama.isNotEmpty) {
        coachName = f.pt!.nama;
        break;
      }
    }

    final labels = [
      'Semua (${feedbacks.length})',
      'AI Insight ($aiCount)',
      coachName == null ? 'Coach ($ptCount)' : 'Coach $coachName ($ptCount)',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSelected = _selectedFilter == i;
          return Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _accent : context.surfaceInner,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? _accent : context.border),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: isSelected ? Colors.white : context.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAiCard(FeedbackItem item) {
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
                    decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BUGARIN AI',
                          style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Evaluasi Mingguan',
                          style: TextStyle(color: context.textSecondary, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Text(_formatWaktu(item.createdAt),
                  style: TextStyle(color: context.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          Text(item.pesan, style: TextStyle(color: context.textPrimary, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildCoachCard(FeedbackItem item) {
    final nama = item.pt?.nama ?? 'Coach';
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
                      color: context.surfaceInner,
                      border: Border.all(color: _accent, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        nama.trim().isEmpty ? '?' : nama.trim()[0].toUpperCase(),
                        style: const TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nama,
                          style: TextStyle(
                              color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 14, height: 1.2)),
                      Text('Coach', style: TextStyle(color: context.textSecondary, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Text(_formatWaktu(item.createdAt),
                  style: TextStyle(color: context.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          Text(item.pesan, style: TextStyle(color: context.textPrimary, fontSize: 14, height: 1.5)),

          if (item.sudahDibalas) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: context.surfaceInner, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Balasan Anda',
                      style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(item.balasanKlien!,
                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: context.bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController(item.id),
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
                    onPressed: _sendingId == item.id ? null : () => _kirimBalasan(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      elevation: 0,
                    ),
                    child: _sendingId == item.id
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Balas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

String _formatWaktu(String iso) {
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) return '';
  const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '${date.day} ${bulan[date.month - 1]}, $hh:$mm';
}
