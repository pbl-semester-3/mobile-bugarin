/// Item workout plan dari `weekly_plans.workout_plan`.
class WorkoutPlanItem {
  final String hari;
  final String jam;
  final String jenis;
  final String lokasi;

  const WorkoutPlanItem({
    required this.hari,
    required this.jam,
    required this.jenis,
    required this.lokasi,
  });

  factory WorkoutPlanItem.fromJson(Map<String, dynamic> json) => WorkoutPlanItem(
        hari: json['hari'] as String? ?? '',
        jam: json['jam'] as String? ?? '',
        jenis: json['jenis'] as String? ?? '',
        lokasi: json['lokasi'] as String? ?? '',
      );
}

/// Item meal plan dari `weekly_plans.meal_plan`.
class MealPlanItem {
  final String waktu;
  final String menu;
  final int estimasiKalori;

  const MealPlanItem({
    required this.waktu,
    required this.menu,
    required this.estimasiKalori,
  });

  factory MealPlanItem.fromJson(Map<String, dynamic> json) => MealPlanItem(
        waktu: json['waktu'] as String? ?? '',
        menu: json['menu'] as String? ?? '',
        estimasiKalori: (json['estimasiKalori'] as num?)?.toInt() ?? 0,
      );
}

/// `GET /klien/weekly-plan/current` → data bisa `null` bila belum ada plan disetujui.
class WeeklyPlan {
  final int id;
  final String mingguMulai;
  final String status;
  final List<WorkoutPlanItem> workoutPlan;
  final List<MealPlanItem> mealPlan;

  const WeeklyPlan({
    required this.id,
    required this.mingguMulai,
    required this.status,
    required this.workoutPlan,
    required this.mealPlan,
  });

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) {
    final rawWorkout = json['workoutPlan'];
    final rawMeal = json['mealPlan'];
    return WeeklyPlan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      mingguMulai: json['mingguMulai'] as String? ?? '',
      status: json['status'] as String? ?? '',
      workoutPlan: rawWorkout is List
          ? rawWorkout
              .whereType<Map>()
              .map((e) => WorkoutPlanItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      mealPlan: rawMeal is List
          ? rawMeal
              .whereType<Map>()
              .map((e) => MealPlanItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

/// Respons `POST /klien/activity-logs` (kalori dihitung backend).
class CreatedActivityLog {
  final int id;
  final int olahragaId;
  final int durasiMenit;
  final double? jarakMeter;
  final int kaloriTerbakar;
  final String tanggal;

  const CreatedActivityLog({
    required this.id,
    required this.olahragaId,
    required this.durasiMenit,
    required this.jarakMeter,
    required this.kaloriTerbakar,
    required this.tanggal,
  });

  factory CreatedActivityLog.fromJson(Map<String, dynamic> json) => CreatedActivityLog(
        id: (json['id'] as num?)?.toInt() ?? 0,
        olahragaId: (json['olahragaId'] as num?)?.toInt() ?? 0,
        durasiMenit: (json['durasiMenit'] as num?)?.toInt() ?? 0,
        jarakMeter: (json['jarakMeter'] as num?)?.toDouble(),
        kaloriTerbakar: (json['kaloriTerbakar'] as num?)?.toInt() ?? 0,
        tanggal: json['tanggal'] as String? ?? '',
      );
}

/// Respons `POST /klien/meal-logs`.
class CreatedMealLog {
  final int id;
  final int makananId;
  final String namaMakanan;
  final double porsiGram;
  final int kaloriMasuk;
  final String tanggal;

  const CreatedMealLog({
    required this.id,
    required this.makananId,
    required this.namaMakanan,
    required this.porsiGram,
    required this.kaloriMasuk,
    required this.tanggal,
  });

  factory CreatedMealLog.fromJson(Map<String, dynamic> json) => CreatedMealLog(
        id: (json['id'] as num?)?.toInt() ?? 0,
        makananId: (json['makananId'] as num?)?.toInt() ?? 0,
        namaMakanan: json['namaMakanan'] as String? ?? '',
        porsiGram: (json['porsiGram'] as num?)?.toDouble() ?? 0,
        kaloriMasuk: (json['kaloriMasuk'] as num?)?.toInt() ?? 0,
        tanggal: json['tanggal'] as String? ?? '',
      );
}
