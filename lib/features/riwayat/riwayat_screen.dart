import 'package:flutter/material.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/bugarin_header.dart';

class CycleHistory {
  final String id;
  final String title;
  final String cycleNumber;
  final DateTime startDate;
  final DateTime? endDate;
  final double targetWeight;
  final int consistencyScore;
  final int avgCalories;
  final int sessionCount;
  final bool isActive;
  final List<DailyLog> logs;
  final String? subtitle;
  final int? avgCalIn;
  final int? avgCalOut;

  CycleHistory({
    required this.id,
    required this.title,
    required this.cycleNumber,
    required this.startDate,
    this.endDate,
    required this.targetWeight,
    required this.consistencyScore,
    required this.avgCalories,
    required this.sessionCount,
    required this.isActive,
    required this.logs,
    this.subtitle,
    this.avgCalIn,
    this.avgCalOut,
  });
}

class DailyLog {
  final DateTime date;
  final int caloriesIn;
  final int caloriesOut;
  final String activity;
  final bool isRestDay;

  DailyLog({
    required this.date,
    required this.caloriesIn,
    required this.caloriesOut,
    required this.activity,
    this.isRestDay = false,
  });

  int get deficit => caloriesIn - caloriesOut;
}

// ============================================================================
// 2. MAIN SCREEN WIDGET
// ============================================================================
class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  static const Color primaryOrange = Color(0xFFFF5520);

  String _selectedFilter = 'Semua Siklus';
  bool _isLoading = true;
  List<CycleHistory> _historyData = [];

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  Future<void> _fetchHistoryData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      _historyData = [
        CycleHistory(
          id: 'c3',
          cycleNumber: 'Siklus #03',
          title: 'Hypertrophy & Core Definition',
          startDate: DateTime(2027, 1, 15),
          targetWeight: 68.0,
          consistencyScore: 94,
          avgCalories: 1840,
          sessionCount: 22,
          isActive: true,
          logs: [],
        ),
        CycleHistory(
          id: 'c2',
          cycleNumber: 'Siklus #02',
          title: 'Cutting & Fat Loss Intensive',
          startDate: DateTime(2026, 11, 15),
          endDate: DateTime(2027, 1, 12),
          targetWeight: 65.0,
          consistencyScore: 88,
          avgCalories: 1650,
          sessionCount: 45,
          isActive: false,
          logs: [
            DailyLog(date: DateTime(2027, 1, 12), caloriesIn: 1620, caloriesOut: 2150, activity: 'Leg Day & Cardio'),
            DailyLog(date: DateTime(2027, 1, 11), caloriesIn: 1680, caloriesOut: 2050, activity: 'Push & Triceps'),
            DailyLog(date: DateTime(2027, 1, 10), caloriesIn: 1590, caloriesOut: 2210, activity: 'HIIT & Pull Session'),
            DailyLog(date: DateTime(2027, 1, 9), caloriesIn: 1750, caloriesOut: 1980, activity: 'Jalan Kaki 8.000 langkah', isRestDay: true),
          ],
        ),
        CycleHistory(
          id: 'c1',
          cycleNumber: 'Siklus #01',
          title: 'Adaptasi Dasar & Ketahanan Kardio',
          subtitle: '45 Hari • Capaian: Pembentukan Kebiasaan & Mobilitas Sendi',
          startDate: DateTime(2026, 9, 20),
          endDate: DateTime(2026, 11, 10),
          targetWeight: 70.0,
          consistencyScore: 80,
          avgCalories: 1920,
          sessionCount: 30,
          isActive: false,
          avgCalIn: 1920,
          avgCalOut: 2100,
          logs: [],
        ),
      ];
      _isLoading = false;
    });
  }

  List<CycleHistory> get _filteredData {
    if (_selectedFilter == 'Selesai') {
      return _historyData.where((c) => !c.isActive).toList();
    } else if (_selectedFilter == 'Sedang Berjalan') {
      return _historyData.where((c) => c.isActive).toList();
    }
    return _historyData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryOrange))
            : RefreshIndicator(
                color: primaryOrange,
                backgroundColor: context.card,
                onRefresh: _fetchHistoryData,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 12),
                    // Header dipanggil langsung di dalam body
                    const BugarinHeader(subtitle: 'Riwayat'),
                    const SizedBox(height: 20),
                    _buildHeaderTexts(context),
                    const SizedBox(height: 24),
                    _buildFilters(context),
                    const SizedBox(height: 24),
                    ..._filteredData.map((cycle) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _CycleExpandableCard(cycle: cycle),
                        )),
                    const SizedBox(height: 120), // Memberikan ruang agar konten bawah tidak tertutup Bottom Navigation Bar
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderTexts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Siklus',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Arsip target, capaian metabolisme, dan rincian log harian secara menyeluruh.',
          style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    final filters = [
      {'label': 'Semua Siklus', 'count': _historyData.length},
      {'label': 'Selesai', 'count': _historyData.where((c) => !c.isActive).length},
      {'label': 'Sedang Berjalan', 'count': _historyData.where((c) => c.isActive).length},
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
                color: isSelected ? primaryOrange.withValues(alpha: 0.15) : context.surfaceInner,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? primaryOrange.withValues(alpha: 0.5) : context.border,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    f['label'] as String,
                    style: TextStyle(
                      color: isSelected ? primaryOrange : context.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryOrange : context.border,
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
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// 3. EXPANDABLE CYCLE CARD
// ============================================================================
class _CycleExpandableCard extends StatefulWidget {
  final CycleHistory cycle;

  const _CycleExpandableCard({required this.cycle});

  @override
  State<_CycleExpandableCard> createState() => _CycleExpandableCardState();
}

class _CycleExpandableCardState extends State<_CycleExpandableCard> {
  static const Color primaryOrange = Color(0xFFFF5520);
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.cycle.logs.isNotEmpty;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasExpandableContent = widget.cycle.logs.isNotEmpty || widget.cycle.subtitle != null;

    return GestureDetector(
      onTap: () {
        if (hasExpandableContent) {
          setState(() => _isExpanded = !_isExpanded);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
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
              )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.cycle.isActive)
                  Text(
                    widget.cycle.cycleNumber,
                    style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
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
                        Text(
                          'Selesai: ${_formatDate(widget.cycle.endDate!)}',
                          style: TextStyle(color: context.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                if (!widget.cycle.isActive)
                  Text(
                    widget.cycle.cycleNumber,
                    style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                if (hasExpandableContent)
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: context.surfaceInner, shape: BoxShape.circle),
                      child: Icon(Icons.keyboard_arrow_down, color: context.textPrimary, size: 18),
                    ),
                  )
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.cycle.title,
              style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (widget.cycle.subtitle != null)
              Text(
                widget.cycle.subtitle!,
                style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.5),
              )
            else
              Text(
                'Mulai: ${_formatDate(widget.cycle.startDate)} • Target BB: ${widget.cycle.targetWeight} kg',
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),

            if (widget.cycle.isActive) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Sisa 18 Hari',
                  style: TextStyle(color: primaryOrange, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],

            const SizedBox(height: 16),

            if (widget.cycle.avgCalIn != null)
              Column(
                children: [
                  _buildStatRow(Icons.restaurant, 'Rata2 Masuk:', '${widget.cycle.avgCalIn} kkal', primaryOrange),
                  const SizedBox(height: 8),
                  _buildStatRow(Icons.local_fire_department, 'Rata2 Keluar:', '${widget.cycle.avgCalOut} kkal', Colors.redAccent),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatPill('Konsistensi', '${widget.cycle.consistencyScore}%', primaryOrange),
                  _buildStatPill('Rata-rata', '${widget.cycle.avgCalories} kkal', context.textPrimary),
                  _buildStatPill('Latihan', '${widget.cycle.sessionCount} Sesi', context.textSecondary),
                ],
              ),

            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isExpanded && widget.cycle.logs.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Divider(color: context.border, height: 1, thickness: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'LOG HARIAN SIKLUS',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 11,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryOrange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Defisit Konsisten',
                                style: TextStyle(color: primaryOrange, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        ...widget.cycle.logs.asMap().entries.map((entry) {
                          return _buildTimelineItem(entry.value, isLast: entry.key == widget.cycle.logs.length - 1);
                        }),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: context.surfaceInner,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {},
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Lihat Seluruh Log Harian',
                                  style: TextStyle(color: primaryOrange, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: primaryOrange, size: 16),
                              ],
                            ),
                          ),
                        )
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 12)),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTimelineItem(DailyLog log, {required bool isLast}) {
    final dotColor = log.isRestDay ? context.textSecondary : primaryOrange;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    boxShadow: [
                      BoxShadow(color: dotColor.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: primaryOrange.withValues(alpha: 0.3),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatDate(log.date), style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Masuk: ${log.caloriesIn} kkal', style: const TextStyle(color: primaryOrange, fontSize: 12)),
                      Text('  •  ', style: TextStyle(color: context.textSecondary)),
                      Text('Keluar: ${log.caloriesOut} kkal', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: log.isRestDay ? context.surfaceInner : primaryOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          log.isRestDay ? 'Rest Day' : 'Defisit ${log.deficit} kkal',
                          style: TextStyle(color: log.isRestDay ? context.textSecondary : primaryOrange, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          log.isRestDay ? log.activity : 'Latihan: ${log.activity}',
                          style: TextStyle(color: context.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}