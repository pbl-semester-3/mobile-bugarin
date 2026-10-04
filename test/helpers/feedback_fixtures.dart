/// Fixture feedback untuk unit test (AI + PT).
const List<Map<String, dynamic>> feedbacksFixture = [
  {
    'id': 1,
    'source': 'ai',
    'pesan': 'Konsistensi proteinmu minggu ini bagus.',
    'balasanKlien': null,
    'dibaca': false,
    'createdAt': '2026-10-04T05:00:00.000Z',
    'pt': null,
  },
  {
    'id': 2,
    'source': 'pt',
    'pesan': 'Tingkatkan asupan air sebelum sesi besok.',
    'balasanKlien': null,
    'dibaca': true,
    'createdAt': '2026-10-04T06:00:00.000Z',
    'pt': {'id': 3, 'nama': 'Sarah'},
  },
];
