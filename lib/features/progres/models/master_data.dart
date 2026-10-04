/// Master data olahraga (`GET /master/olahraga`).
class MasterOlahraga {
  final int id;
  final String nama;
  final double metValue;
  final String kategori;
  final bool butuhJarak;

  const MasterOlahraga({
    required this.id,
    required this.nama,
    required this.metValue,
    required this.kategori,
    required this.butuhJarak,
  });

  factory MasterOlahraga.fromJson(Map<String, dynamic> json) {
    return MasterOlahraga(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nama: json['nama'] as String? ?? '',
      metValue: (json['metValue'] as num?)?.toDouble() ?? 0,
      kategori: json['kategori'] as String? ?? '',
      butuhJarak: json['butuhJarak'] as bool? ?? false,
    );
  }
}

/// Master data makanan (`GET /master/makanan?q=`).
class MasterMakanan {
  final int id;
  final String nama;
  final double kaloriPer100g;
  final String kategori;
  final String sumber; // 'seed' | 'ai_generated'

  const MasterMakanan({
    required this.id,
    required this.nama,
    required this.kaloriPer100g,
    required this.kategori,
    required this.sumber,
  });

  factory MasterMakanan.fromJson(Map<String, dynamic> json) {
    return MasterMakanan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nama: json['nama'] as String? ?? '',
      kaloriPer100g: (json['kaloriPer100g'] as num?)?.toDouble() ?? 0,
      kategori: json['kategori'] as String? ?? '',
      sumber: json['sumber'] as String? ?? 'seed',
    );
  }
}
