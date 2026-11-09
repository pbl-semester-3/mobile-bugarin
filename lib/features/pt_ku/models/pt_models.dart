/// Rekomendasi PT (`GET /pt/recommendations`).
class PtRecommendation {
  final int id;
  final String nama;
  final String spesialisasi; // 'turun_bb' | 'naik_bb'
  final String tempatGym;
  final String? fotoUrl;

  const PtRecommendation({
    required this.id,
    required this.nama,
    required this.spesialisasi,
    required this.tempatGym,
    this.fotoUrl,
  });

  factory PtRecommendation.fromJson(Map<String, dynamic> json) {
    return PtRecommendation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nama: json['nama'] as String? ?? '',
      spesialisasi: json['spesialisasi'] as String? ?? '',
      tempatGym: json['tempatGym'] as String? ?? '',
      fotoUrl: json['fotoUrl'] as String?,
    );
  }
}

class PairingPt {
  final int id;
  final String nama;
  final String spesialisasi;
  final String? tempatGym;
  final String? fotoUrl;

  const PairingPt({
    required this.id,
    required this.nama,
    required this.spesialisasi,
    this.tempatGym,
    this.fotoUrl,
  });

  factory PairingPt.fromJson(Map<String, dynamic> json) {
    return PairingPt(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nama: json['nama'] as String? ?? '',
      spesialisasi: json['spesialisasi'] as String? ?? '',
      tempatGym: json['tempatGym'] as String?,
      fotoUrl: json['fotoUrl'] as String?,
    );
  }
}

/// Status request aktif (`GET /klien/pairing-requests/current`).
class PairingRequest {
  final int id;
  final String status; // 'pending' | 'diterima' | 'ditolak'
  final String? alasanPenolakan;
  final String createdAt;
  final PairingPt? pt;

  const PairingRequest({
    required this.id,
    required this.status,
    this.alasanPenolakan,
    required this.createdAt,
    this.pt,
  });

  bool get isPending => status == 'pending';
  bool get isDiterima => status == 'diterima';
  bool get isDitolak => status == 'ditolak';

  factory PairingRequest.fromJson(Map<String, dynamic> json) {
    final rawPt = json['pt'];
    return PairingRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      alasanPenolakan: json['alasanPenolakan'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      pt: rawPt is Map ? PairingPt.fromJson(Map<String, dynamic>.from(rawPt)) : null,
    );
  }
}
