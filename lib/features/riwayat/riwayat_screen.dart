import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/bugarin_header.dart';
import '../auth/models/progress_cycle.dart';
import 'data/riwayat_providers.dart';
import 'models/daily_log.dart';

const Color _primaryOrange = Color(0xFFFF5520);

class RiwayatScreen extends ConsumerStatefulWidget {
  const RiwayatScreen({super.key});

  @override
  ConsumerState<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends ConsumerState<RiwayatScreen> {
  String _selectedFilter = 'Semua Siklus';

  @override
  Widget build(BuildContext context) {
    final cyclesAsync = ref.watch(progressCyclesProvider);

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: cyclesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: _primaryOrange)),
          error: (err, _) => _buildError('Gagal memuat riwayat.'),
          data: (cycles) {
            final filtered = _filter(cycles);
            return RefreshIndicator(
              color: _primaryOrange,
              onRefresh: () async => ref.invalidate(progressCyclesProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 12),
                  const BugarinHeader(subtitle: 'Riwayat'),
                  const SizedBox(height: 20),
                  Text('Riwayat Siklus',
                      style: TextStyle(color: context.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Arsip target, capaian metabolisme, dan rincian log harian secara menyeluruh.',
                    style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  _buildFilters(cycles),
                  const SizedBox(height: 24),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text('Belum ada siklus.',
                            style: TextStyle(color: context.textSecondary, fontSize: 13)),
                      ),
                    )
                  else
                    ...filtered.map((cycle) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _CycleCard(cycle: cycle),
                        )),
                  const SizedBox(height: 120),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<ProgressCycle> _filter(List<ProgressCycle> cycles) {
    if (_selectedFilter == 'Selesai') return cycles.where((c) => !c.isActive).toList();
    if (_selectedFilter == 'Sedang Berjalan') return cycles.where((c) => c.isActive).toList();
    return cycles;
  }

  Widget _buildFilters(List<ProgressCycle> cycles) {
    final filters = [
      {'label': 'Semua Siklus', 'count': cycles.length},
      {'label': 'Selesai', 'count': cycles.where((c) => !c.isActive).length},
      {'label': 'Sedang Berjalan', 'count': cycles.where((c) => c.isActive).length},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['label'];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f['label'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _primaryOrange.withValues(alpha: 0.15) : context.surfaceInner,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? _primaryOrange.withValues(alpha: 0.5) : context.border,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    f['label'] as String,
                    style: TextStyle(
                      color: isSelected ? _primaryOrange : context.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? _primaryOrange : context.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${f['count']}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : context.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
              onPressed: () => ref.invalidate(progressCyclesProvider),
              style: ElevatedButton.styleFrom(backgroundColor: _primaryOrange, foregroundColor: Colors.white),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTanggal(String tanggal) {
  final date = DateTime.tryParse(tanggal);
  if (date == null) return tanggal;
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

String _labelTujuan(String tujuan) {
  switch (tujuan) {
    case 'turun_bb':
      return 'Turun BB';
    case 'naik_bb':
      return 'Naik BB';
    default:
      return 'Siklus';
  }
}

class _CycleCard extends StatefulWidget {
  final ProgressCycle cycle;

  const _CycleCard({required this.cycle});

  @override
  State<_CycleCard> createState() => _CycleCardState();
}

class _CycleCardState extends State<_CycleCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cycle = widget.cycle;
    final sisaHari = _sisaHari(cycle);

    return Container(
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border),
        boxShadow: [
          if (_isExpanded)
            BoxShadow(
              color: context.isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Siklus #${cycle.id}',
                          style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                      if (cycle.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primaryOrange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Berjalan',
                              style: TextStyle(color: _primaryOrange, fontSize: 11, fontWeight: FontWeight.w600)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.surfaceInner,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: context.textSecondary, size: 14),
                              const SizedBox(width: 6),
                              Text('Selesai: ${_formatTanggal(cycle.tanggalSelesai ?? '')}',
                                  style: TextStyle(color: context.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_labelTujuan(cycle.tujuan),
                      style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Mulai: ${_formatTanggal(cycle.tanggalMulai)} • Target BB: ${cycle.bbTujuanKg.toStringAsFixed(1)} kg',
                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                  ),
                  if (cycle.isActive && sisaHari != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Sisa $sisaHari Hari',
                          style: const TextStyle(color: _primaryOrange, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _stat('Streak', '${cycle.streak} hari', _primaryOrange),
                      _stat('Target Kalori', '${cycle.targetKaloriPerHari} kkal', context.textPrimary),
                      _stat('Durasi', '${cycle.durasiHari} hari', context.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Icon(
                      _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: context.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) _LogSection(cycleId: cycle.id),
        ],
      ),
    );
  }

  int? _sisaHari(ProgressCycle cycle) {
    final start = DateTime.tryParse(cycle.tanggalMulai);
    if (start == null) return null;
    final elapsed = DateTime.now().difference(start).inDays;
    final sisa = cycle.durasiHari - elapsed;
    return sisa < 0 ? 0 : sisa;
  }

  Widget _stat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _LogSection extends ConsumerWidget {
  final int cycleId;

  const _LogSection({required this.cycleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(cycleLogsProvider(cycleId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: context.border, height: 1, thickness: 1),
          const SizedBox(height: 16),
          Text('LOG HARIAN SIKLUS',
              style: TextStyle(
                  color: context.textSecondary, fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          logsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: _primaryOrange, strokeWidth: 2.2)),
            ),
            error: (err, _) => Text('Gagal memuat log harian.',
                style: TextStyle(color: context.textSecondary, fontSize: 12)),
            data: (logs) {
              if (logs.isEmpty) {
                return Text('Belum ada log pada siklus ini.',
                    style: TextStyle(color: context.textSecondary, fontSize: 12));
              }
              return Column(
                children: logs
                    .map((log) => _buildLogItem(context, log))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, DailyLogItem log) {
    final defisit = log.kaloriMasuk - log.kaloriKeluar;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_formatTanggal(log.tanggal),
              style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Masuk: ${log.kaloriMasuk} kkal', style: const TextStyle(color: _primaryOrange, fontSize: 12)),
              Text('  •  ', style: TextStyle(color: context.textSecondary)),
              Text('Keluar: ${log.kaloriKeluar} kkal',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _primaryOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Selisih ${defisit >= 0 ? '+' : ''}$defisit kkal',
                style: const TextStyle(color: _primaryOrange, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
