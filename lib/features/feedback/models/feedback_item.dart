class FeedbackPt {
  final int id;
  final String nama;

  const FeedbackPt({required this.id, required this.nama});

  factory FeedbackPt.fromJson(Map<String, dynamic> json) => FeedbackPt(
        id: (json['id'] as num?)?.toInt() ?? 0,
        nama: json['nama'] as String? ?? '',
      );
}

/// Satu item feedback (`GET /klien/feedbacks`).
class FeedbackItem {
  final int id;
  final String source; // 'ai' | 'pt'
  final String pesan;
  final String? balasanKlien;
  final bool dibaca;
  final String createdAt; // ISO 8601
  final FeedbackPt? pt; // null bila dari AI

  const FeedbackItem({
    required this.id,
    required this.source,
    required this.pesan,
    this.balasanKlien,
    required this.dibaca,
    required this.createdAt,
    this.pt,
  });

  bool get isAi => source == 'ai';
  bool get isPt => source == 'pt';
  bool get sudahDibalas => balasanKlien != null && balasanKlien!.isNotEmpty;

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    final rawPt = json['pt'];
    return FeedbackItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      source: json['source'] as String? ?? 'ai',
      pesan: json['pesan'] as String? ?? '',
      balasanKlien: json['balasanKlien'] as String?,
      dibaca: json['dibaca'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      pt: rawPt is Map ? FeedbackPt.fromJson(Map<String, dynamic>.from(rawPt)) : null,
    );
  }
}
