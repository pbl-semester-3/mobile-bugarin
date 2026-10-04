import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_provider.dart';
import '../../services/api_error.dart';
import '../../shared/widgets/bugarin_header.dart';
import 'data/pt_repository_provider.dart';
import 'models/pt_models.dart';

const Color _accent = Color(0xFFFF5520);

class PtKuScreen extends ConsumerStatefulWidget {
  const PtKuScreen({super.key});

  @override
  ConsumerState<PtKuScreen> createState() => _PtKuScreenState();
}

class _PtKuScreenState extends ConsumerState<PtKuScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<PtRecommendation> _rekomendasi = [];
  PairingRequest? _request;

  bool _memuat = true;
  String? _errorMuat;
  bool _profilBelumLengkap = false;
  bool _mengirim = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    setState(() {
      _memuat = true;
      _errorMuat = null;
      _profilBelumLengkap = false;
    });
    try {
      final repo = ref.read(ptRepositoryProvider);
      final request = await repo.getCurrentRequest();
      final rekomendasi = await repo.getRecommendations();
      if (!mounted) return;
      setState(() {
        _request = request;
        _rekomendasi = rekomendasi;
        _memuat = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      final belumLengkap = e.message.toLowerCase().contains('lengkapi profil');
      setState(() {
        _profilBelumLengkap = belumLengkap;
        _errorMuat = belumLengkap ? null : e.message;
        _memuat = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMuat = 'Gagal memuat data PT.';
        _memuat = false;
      });
    }
  }

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

  Future<void> _kirimPairingRequest(PtRecommendation pt) async {
    setState(() => _mengirim = true);
    try {
      await ref.read(ptRepositoryProvider).sendPairingRequest(pt.id);
      final request = await ref.read(ptRepositoryProvider).getCurrentRequest();
      if (!mounted) return;
      setState(() => _request = request);
      _toast('Request terkirim. Menunggu konfirmasi Coach ${pt.nama}.');
    } on ApiException catch (e) {
      _toast(e.message, error: true);
      await _muat();
    } catch (_) {
      _toast('Gagal mengirim request.', error: true);
    } finally {
      if (mounted) setState(() => _mengirim = false);
    }
  }

  void _showConfirmationDialog(PtRecommendation pt) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: context.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: context.surfaceInner, shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded, size: 18, color: context.textSecondary),
                  ),
                ),
              ),
              _Avatar(nama: pt.nama, size: 80),
              const SizedBox(height: 16),
              Text('Coach ${pt.nama}',
                  style: const TextStyle(color: _accent, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('${_labelSpesialisasi(pt.spesialisasi)} • ${pt.tempatGym}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.textSecondary, fontSize: 12)),
              const SizedBox(height: 32),
              Text('Yakin Ingin Memilih PT Ini?',
                  style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'Anda akan terhubung langsung dengan Coach ${pt.nama} untuk menyusun program latihan dan panduan transformasi kebugaran Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.surfaceInner,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.border),
                ),
                child: Column(
                  children: const [
                    _FeatureRow(icon: Icons.calendar_today_rounded, text: 'Jadwal latihan mingguan'),
                    SizedBox(height: 16),
                    _FeatureRow(icon: Icons.schedule_rounded, text: 'Jadwal fleksibel & booking mandiri'),
                    SizedBox(height: 16),
                    _FeatureRow(icon: Icons.check_circle_outline_rounded, text: 'Konsultasi nutrisi & pola makan'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _mengirim
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _kirimPairingRequest(pt);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text('YA, PILIH COACH ${pt.nama.split(' ').first.toUpperCase()}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Batal',
                      style: TextStyle(color: context.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _accent,
          onRefresh: _muat,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
            children: [
              const BugarinHeader(subtitle: 'PT ku'),
              const SizedBox(height: 18),
              if (_memuat)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator(color: _accent)),
                )
              else if (_errorMuat != null)
                _buildError()
              else if (_profilBelumLengkap)
                _buildBelumLengkap()
              else
                ..._buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    final req = _request;
    if (req != null && req.isPending) {
      return [_buildWaitingCard(req)];
    }
    if (req != null && req.isDiterima) {
      return [_buildActiveCard(req)];
    }

    return [
      if (req != null && req.isDitolak) ...[
        _buildRejectedCard(req),
        const SizedBox(height: 18),
      ],
      Text('Pilih Personal Trainer',
          style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text('Coach terakreditasi untuk siklus targetmu',
          style: TextStyle(color: context.textSecondary, fontSize: 12)),
      const SizedBox(height: 18),
      _buildSearchBar(),
      const SizedBox(height: 18),
      ..._buildList(),
    ];
  }

  List<Widget> _buildList() {
    final query = _searchController.text.trim().toLowerCase();
    final list = query.isEmpty
        ? _rekomendasi
        : _rekomendasi
            .where((p) =>
                p.nama.toLowerCase().contains(query) ||
                p.spesialisasi.toLowerCase().contains(query) ||
                p.tempatGym.toLowerCase().contains(query))
            .toList();

    if (list.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Center(
            child: Text('Tidak ada PT yang cocok.',
                style: TextStyle(color: context.textSecondary, fontSize: 13)),
          ),
        ),
      ];
    }

    return [
      Text('Tersedia ${list.length} Personal Trainer',
          style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      ...list.map(_buildTrainerCard),
    ];
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: context.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: context.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari nama, spesialisasi, atau gym...',
                hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerCard(PtRecommendation trainer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          _Avatar(nama: trainer.nama, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trainer.nama,
                    style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text('${_labelSpesialisasi(trainer.spesialisasi)} • ${trainer.tempatGym}',
                    style: TextStyle(color: context.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _mengirim ? null : () => _showConfirmationDialog(trainer),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Pilih', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 14, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingCard(PairingRequest req) {
    return _statusCard(
      icon: Icons.hourglass_top_rounded,
      title: 'Menunggu Konfirmasi PT',
      subtitle: req.pt == null
          ? 'Requestmu sedang ditinjau oleh Personal Trainer.'
          : 'Request ke Coach ${req.pt!.nama} sedang ditinjau.',
      color: _accent,
    );
  }

  Widget _buildActiveCard(PairingRequest req) {
    return _statusCard(
      icon: Icons.verified_rounded,
      title: 'PT Aktif',
      subtitle: req.pt == null
          ? 'Kamu sudah terhubung dengan Personal Trainer.'
          : 'Kamu dibimbing oleh Coach ${req.pt!.nama} (${_labelSpesialisasi(req.pt!.spesialisasi)}).',
      color: const Color(0xFF2E7D32),
    );
  }

  Widget _buildRejectedCard(PairingRequest req) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_outlined, color: Color(0xFFE53935), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Request Ditolak',
                    style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  req.alasanPenolakan?.isNotEmpty == true
                      ? req.alasanPenolakan!
                      : 'PT tidak dapat menerima requestmu saat ini. Silakan pilih PT lain.',
                  style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border, width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildBelumLengkap() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.assignment_late_outlined, size: 48, color: context.textMuted),
          const SizedBox(height: 14),
          Text('Lengkapi profil dulu',
              style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Isi data fisik dan mulai siklus target di Onboarding sebelum memilih Personal Trainer.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: context.textMuted),
          const SizedBox(height: 12),
          Text(_errorMuat!, textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _muat,
            style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

String _labelSpesialisasi(String spesialisasi) {
  switch (spesialisasi) {
    case 'turun_bb':
      return 'Turun BB';
    case 'naik_bb':
      return 'Naik BB';
    default:
      return 'Personal Trainer';
  }
}

class _Avatar extends StatelessWidget {
  final String nama;
  final double size;

  const _Avatar({required this.nama, required this.size});

  @override
  Widget build(BuildContext context) {
    final inisial = nama.trim().isEmpty ? '?' : nama.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.surfaceInner,
        border: Border.all(color: _accent, width: 1.5),
      ),
      child: Center(
        child: Text(
          inisial,
          style: TextStyle(
            color: _accent,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _accent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: TextStyle(color: context.textPrimary, fontSize: 13)),
        ),
      ],
    );
  }
}
