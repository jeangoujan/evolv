import 'package:flutter/material.dart';
import 'hive_boxes.dart';
import 'models/skill.dart';
import 'models/session.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SkillRepo {
  static final _box = HiveBoxes.skillBox();
  static final _sessionBox = Hive.box<Session>('sessions');

  /// Получить все навыки
  static List<Skill> getAll() => _box.values.toList();

  /// Добавить новый навык
  static Future<void> addSkill({
    required String name,
    required double goalHours,
    required Color color,
    required IconData icon,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    final skill = Skill(
      id: id,
      name: name,
      goalHours: goalHours,
      colorValue: color.value,
      iconCode: icon.codePoint,
      totalHours: 0,
      sessions: [],
      currentStreak: 1, // ✅ начинаем с 1 по умолчанию
    );
    await _box.put(id, skill);
  }

  /// Удалить навык и связанные сессии
  static Future<void> deleteSkill(int id) async {
    await _box.delete(id);
    final sessionsToDelete =
        _sessionBox.values.where((s) => s.skillId == id).toList();
    for (final s in sessionsToDelete) {
      await _sessionBox.delete(s.id);
    }
  }

  /// Добавить сессию (через SessionTimerScreen)
static Future<void> addSession({
  required int skillId,
  required double durationMinutes,
  String note = '',
}) async {
  // 1) Находим реальный KEY бокса по id навыка
  final key = _box.keys.firstWhere(
    (k) => _box.get(k)?.id == skillId,
    orElse: () => null,
  );
  if (key == null) {
    debugPrint('⚠️ SkillRepo.addSession: skillId=$skillId not found in Hive');
    return;
  }

  final skill = _box.get(key)!;

  // 2) Создаём и сохраняем сессию в sessions-box
  final now = DateTime.now();
  final sessionId = now.microsecondsSinceEpoch & 0x7fffffff; // безопасный int
  final session = Session(
    id: sessionId,
    skillId: skillId,
    durationMinutes: durationMinutes,
    date: now,
    note: note.trim().isEmpty ? null : note.trim(),
  );
  await _sessionBox.put(sessionId, session);

  // 3) Готовим новый список сессий для навыка (локальная денормализация)
  final newSessions = [...skill.sessions, session]..sort((a, b) => a.date.compareTo(b.date));

  // 4) Пересчитываем totalHours
  final addedHours = durationMinutes / 60.0;
  final newTotal = (skill.totalHours + addedHours);

  // 5) Пересчитываем streak (минимум 1, если была хотя бы одна сессия)
  final newStreak = _calculateStreak(newSessions);

  // 6) Сохраняем обновлённый навык по НАЙДЕННОМУ ключу
  final updated = Skill(
    id: skill.id,
    name: skill.name,
    goalHours: skill.goalHours,
    totalHours: newTotal,
    currentStreak: newStreak,
    colorValue: skill.colorValue,
    iconCode: skill.iconCode,
    sessions: newSessions,
  );

  await _box.put(key, updated);

  debugPrint('✅ addSession: "${skill.name}" +${durationMinutes.toStringAsFixed(2)} min '
      '→ total=${updated.totalHours.toStringAsFixed(2)} h, streak=${updated.currentStreak}');
}

  /// Удалить одну сессию (по долгому тапу)
  static Future<void> deleteSession({
    required int skillId,
    required int sessionId,
  }) async {
    final skill = _box.get(skillId);
    if (skill == null) return;

    final session = skill.sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => Session(
        id: -1,
        skillId: skillId,
        durationMinutes: 0,
        date: DateTime.now(),
      ),
    );
    if (session.id == -1) return;

    // Удаляем из бокса сессий
    await _sessionBox.delete(sessionId);

    final reducedHours = session.durationMinutes / 60.0;

    // Оставшиеся сессии
    final remainingSessions =
        skill.sessions.where((s) => s.id != sessionId).toList();

    // Пересчитываем streak заново
    final newStreak = _calculateStreak(remainingSessions);

    // Обновляем данные навыка
    final updated = Skill(
      id: skill.id,
      name: skill.name,
      goalHours: skill.goalHours,
      totalHours: (skill.totalHours - reducedHours).clamp(0, double.infinity),
      colorValue: skill.colorValue,
      iconCode: skill.iconCode,
      sessions: remainingSessions,
      currentStreak: newStreak,
    );

    await _box.put(skillId, updated);
  }

  /// ===============================
  /// 🧮 Логика вычисления streak
  /// ===============================
  static int _calculateStreak(List<Session> sessions) {
    if (sessions.isEmpty) return 1; // ✅ минимум 1 день

    // Уникальные дни (чтобы несколько сессий за день не влияли)
    final uniqueDays = <DateTime>{};
    for (final s in sessions) {
      final d = DateTime(s.date.year, s.date.month, s.date.day);
      uniqueDays.add(d);
    }

    // Считаем streak от сегодняшнего дня
    int streak = 0;
    DateTime cursor = DateTime.now();

    while (true) {
      final day = DateTime(cursor.year, cursor.month, cursor.day);
      if (uniqueDays.contains(day)) {
        streak++;
        cursor = day.subtract(const Duration(days: 1));
        continue;
      }
      break;
    }

    // ✅ Минимум 1 день (если хотя бы одна сессия была)
    if (streak == 0) return 1;
    return streak;
  }
}