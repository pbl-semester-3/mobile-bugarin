import 'package:bugarin_mobile/db/cache_repository.dart';
import 'package:bugarin_mobile/features/progres/data/master_repository.dart';
import 'package:bugarin_mobile/features/progres/models/master_data.dart';
import 'package:bugarin_mobile/services/api_error.dart';

class FakeMasterRepository implements MasterRepository {
  List<MasterOlahraga> olahraga = const [];
  List<MasterMakanan> makanan = const [];
  ApiException? error;

  @override
  Future<List<MasterOlahraga>> getOlahraga() async {
    if (error != null) throw error!;
    return olahraga;
  }

  @override
  Future<List<MasterMakanan>> getMakanan({String? q}) async {
    if (error != null) throw error!;
    return makanan;
  }
}

class FakeCacheRepository implements CacheRepository {
  List<MasterOlahraga> cachedOlahraga = const [];
  List<MasterMakanan> cachedMakanan = const [];

  bool cacheOlahragaWritten = false;
  bool cacheMakananWritten = false;

  @override
  Future<void> cacheMasterOlahraga(List<MasterOlahraga> list) async {
    cachedOlahraga = list;
    cacheOlahragaWritten = true;
  }

  @override
  Future<List<MasterOlahraga>> getCachedMasterOlahraga() async => cachedOlahraga;

  @override
  Future<void> cacheMasterMakanan(List<MasterMakanan> list) async {
    cachedMakanan = list;
    cacheMakananWritten = true;
  }

  @override
  Future<List<MasterMakanan>> getCachedMasterMakanan({String? q}) async {
    if (q == null || q.isEmpty) return cachedMakanan;
    final query = q.toLowerCase();
    return cachedMakanan.where((m) => m.nama.toLowerCase().contains(query)).toList();
  }
}
