/// Item jadwal latihan dari `weekly_plans.workout_plan` (backend).
class WorkoutPlanItem {
  final String hari;
  final String jam;
  final String jenis;
  final String lokasi;

  const WorkoutPlanItem({
    required this.hari,
    required this.jam,
    required this.jenis,
    required this.lokasi,
  });

  factory WorkoutPlanItem.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanItem(
      hari: json['hari'] as String? ?? '',
      jam: json['jam'] as String? ?? '',
      jenis: json['jenis'] as String? ?? '',
      lokasi: json['lokasi'] as String? ?? '',
    );
  }
}

/// PT aktif klien (`pt` pada dashboard-summary).
class PtSummary {
  final int id;
  final String nama;
  final String? spesialisasi;

  const PtSummary({required this.id, required this.nama, this.spesialisasi});

  factory PtSummary.fromJson(Map<String, dynamic> json) {
    return PtSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nama: json['nama'] as String? ?? '',
      spesialisasi: json['spesialisasi'] as String?,
    );
  }
}

/// Respons `GET /klien/dashboard-summary`.
class DashboardSummary {
  final PtSummary? pt;
  final int? targetKaloriHariIni;
  final int streak;
  final List<WorkoutPlanItem> jadwalMingguan;
  final bool isReminderActive;
  final int unreadFeedbackCount;

  const DashboardSummary({
    required this.pt,
    required this.targetKaloriHariIni,
    required this.streak,
    required this.jadwalMingguan,
    required this.isReminderActive,
    required this.unreadFeedbackCount,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final rawPt = json['pt'];
    final rawJadwal = json['jadwalMingguan'];

    return DashboardSummary(
      pt: rawPt is Map ? PtSummary.fromJson(Map<String, dynamic>.from(rawPt)) : null,
      targetKaloriHariIni: (json['targetKaloriHariIni'] as num?)?.toInt(),
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      jadwalMingguan: rawJadwal is List
          ? rawJadwal
              .whereType<Map>()
              .map((e) => WorkoutPlanItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      isReminderActive: json['isReminderActive'] as bool? ?? false,
      unreadFeedbackCount: (json['unreadFeedbackCount'] as num?)?.toInt() ?? 0,
    );
  }
}
