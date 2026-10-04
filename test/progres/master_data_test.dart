import 'package:bugarin_mobile/features/progres/data/progres_providers.dart';
import 'package:bugarin_mobile/features/progres/models/master_data.dart';
import 'package:bugarin_mobile/services/api_error.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

const _olahraga = MasterOlahraga(
  id: 1,
  nama: 'Jogging',
  metValue: 7,
  kategori: 'kardio',
  butuhJarak: true,
);
const _makanan = MasterMakanan(
  id: 1,
  nama: 'Nasi',
  kaloriPer100g: 150,
  kategori: 'karbohidrat',
  sumber: 'seed',
);

void main() {
  test('sukses API -> data fresh & ditulis ke cache', () async {
    final master = FakeMasterRepository()
      ..olahraga = [_olahraga]
      ..makanan = [_makanan];
    final cache = FakeCacheRepository();

    final data = await loadMasterData(master: master, cache: cache);

    expect(data.fromCache, isFalse);
    expect(data.olahraga.single.nama, 'Jogging');
    expect(data.makanan.single.nama, 'Nasi');
    expect(cache.cacheOlahragaWritten, isTrue);
    expect(cache.cacheMakananWritten, isTrue);
  });

  test('API gagal -> fallback cache (fromCache true)', () async {
    final master = FakeMasterRepository()..error = const ApiException('offline');
    final cache = FakeCacheRepository()
      ..cachedOlahraga = [_olahraga]
      ..cachedMakanan = [_makanan];

    final data = await loadMasterData(master: master, cache: cache);

    expect(data.fromCache, isTrue);
    expect(data.olahraga.single.nama, 'Jogging');
    expect(cache.cacheOlahragaWritten, isFalse);
  });

  test('API gagal & cache kosong -> melempar error', () async {
    final master = FakeMasterRepository()..error = const ApiException('offline');
    final cache = FakeCacheRepository();

    expect(
      () => loadMasterData(master: master, cache: cache),
      throwsA(isA<ApiException>()),
    );
  });
}
