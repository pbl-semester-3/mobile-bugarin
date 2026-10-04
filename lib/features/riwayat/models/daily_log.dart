/// Satu baris daily log siklus (`GET /klien/progress-cycles/:id/logs`).
class DailyLogItem {
  final String tanggal; // yyyy-MM-dd
  final int kaloriMasuk;
  final int kaloriKeluar;

  const DailyLogItem({
    required this.tanggal,
    required this.kaloriMasuk,
    required this.kaloriKeluar,
  });

  factory DailyLogItem.fromJson(Map<String, dynamic> json) => DailyLogItem(
        tanggal: json['tanggal'] as String? ?? '',
        kaloriMasuk: (json['kaloriMasuk'] as num?)?.toInt() ?? 0,
        kaloriKeluar: (json['kaloriKeluar'] as num?)?.toInt() ?? 0,
      );
}
