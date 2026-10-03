/// Model siklus progres klien.
///
/// Bentuk field menyalin tipe `ProgressCycle` backend (`progress_cycles`),
/// diserialisasi camelCase sesuai skill `api-contract-bugarin`.
class ProgressCycle {
  final int id;
  final int klienId;
  final double bbAwalKg;
  final double bbTujuanKg;
  final String tujuan; // 'turun_bb' | 'naik_bb'
  final int durasiHari;
  final int targetKaloriPerHari;
  final int streak;
  final String status; // 'aktif' | 'selesai'
  final String tanggalMulai; // ISO date 'yyyy-MM-dd'
  final String? tanggalSelesai;

  const ProgressCycle({
    required this.id,
    required this.klienId,
    required this.bbAwalKg,
    required this.bbTujuanKg,
    required this.tujuan,
    required this.durasiHari,
    required this.targetKaloriPerHari,
    required this.streak,
    required this.status,
    required this.tanggalMulai,
    this.tanggalSelesai,
  });

  bool get isActive => status == 'aktif';

  factory ProgressCycle.fromJson(Map<String, dynamic> json) {
    return ProgressCycle(
      id: (json['id'] as num?)?.toInt() ?? 0,
      klienId: (json['klienId'] as num?)?.toInt() ?? 0,
      bbAwalKg: (json['bbAwalKg'] as num?)?.toDouble() ?? 0,
      bbTujuanKg: (json['bbTujuanKg'] as num?)?.toDouble() ?? 0,
      tujuan: json['tujuan'] as String? ?? 'turun_bb',
      durasiHari: (json['durasiHari'] as num?)?.toInt() ?? 0,
      targetKaloriPerHari: (json['targetKaloriPerHari'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'aktif',
      tanggalMulai: json['tanggalMulai'] as String? ?? '',
      tanggalSelesai: json['tanggalSelesai'] as String?,
    );
  }
}
