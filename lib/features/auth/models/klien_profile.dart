import 'progress_cycle.dart';

/// Model profil klien — hasil `GET /klien/profile`.
///
/// Menggabungkan kolom `klien_profiles` + relasi `users` (email/username/tema),
/// flag `profileComplete`, dan `activeCycle` (null bila belum ada siklus aktif).
class KlienProfile {
  final int id;
  final int userId;
  final String nama;
  final int? usia;
  final String? jenisKelamin; // 'pria' | 'wanita'
  final String? alergiMakanan;
  final double? tinggiBadanCm;
  final int? ptId;

  // Dari relasi `users`
  final String? email;
  final String? username;
  final String? tema; // 'siang' | 'malam'
  final String? role; // 'klien' | 'pt' | 'admin'

  final bool profileComplete;
  final ProgressCycle? activeCycle;

  const KlienProfile({
    required this.id,
    required this.userId,
    required this.nama,
    this.usia,
    this.jenisKelamin,
    this.alergiMakanan,
    this.tinggiBadanCm,
    this.ptId,
    this.email,
    this.username,
    this.tema,
    this.role,
    required this.profileComplete,
    this.activeCycle,
  });

  bool get hasPt => ptId != null;

  factory KlienProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : const <String, dynamic>{};
    final active = json['activeCycle'];

    return KlienProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      nama: json['nama'] as String? ?? '',
      usia: (json['usia'] as num?)?.toInt(),
      jenisKelamin: json['jenisKelamin'] as String?,
      alergiMakanan: json['alergiMakanan'] as String?,
      tinggiBadanCm: (json['tinggiBadanCm'] as num?)?.toDouble(),
      ptId: (json['ptId'] as num?)?.toInt(),
      email: userMap['email'] as String?,
      username: userMap['username'] as String?,
      tema: userMap['tema'] as String?,
      role: userMap['role'] as String?,
      profileComplete: json['profileComplete'] as bool? ?? false,
      activeCycle:
          active is Map ? ProgressCycle.fromJson(Map<String, dynamic>.from(active)) : null,
    );
  }
}
