import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/hive_boxes.dart';
import '../data/models/skill.dart';
import '../data/models/session.dart';

class SkillRepo {
  static final _skillBox = HiveBoxes.skillBox();
  static final _sessionBox = Hive.box<Session>('sessions');

  /// ---------------------------------------------------
  /// Получить все навыки
  /// ---------------------------------------------------
  static List<Skill> getAll() => _skillBox.values.toList();

  /// ---------------------------------------------------
  /// Добавить новый навык (+ поддержка initialHours)
  /// ---------------------------------------------------
  static Future<void> addSkill({
    required String name,
    required double goalHours,
    required Color color,
    required IconData icon,
    double initialHours = 0,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch;

    final skill = Skill(
      id: id,
      name: name,
      goalHours: goalHours,
      totalHours: initialHours,
      currentStreak: 1,
      colorValue: color.value,
      iconCode: icon.codePoint,
      createdAt: DateTime.now(),
    );

    await _skillBox.put(id, skill);
  }

  /// ---------------------------------------------------
  /// Удалить навык + связанные сессии
  /// ---------------------------------------------------
  static Future<void> deleteSkill(int id) async {
    await _skillBox.delete(id);

    final sessionsToDelete =
        _sessionBox.values.where((s) => s.skillId == id).toList();

    for (final s in sessionsToDelete) {
      await _sessionBox.delete(s.id);
    }
  }

  /// ---------------------------------------------------
  /// Добавить сессию + пересчитать streak + totalHours
  /// ---------------------------------------------------
  static Future<void> addSession({
    required int skillId,
    required double durationMinutes,
    String note = '',
  }) async {
    // У каждой записи в Hive ключ может отличаться от skill.id
    final key = _skillBox.keys.firstWhere(
      (k) => _skillBox.get(k)?.id == skillId,
      orElse: () => null,
    );

    if (key == null) {
      debugPrint('❌ SkillRepo.addSession → skillId=$skillId not found in Hive');
      return;
    }

    final skill = _skillBox.get(key)!;

    // Создаём сессию
    final now = DateTime.now();
    final sessionId = now.microsecondsSinceEpoch & 0x7FFFFFFF;

    final session = Session(
      id: sessionId,
      skillId: skillId,
      durationMinutes: durationMinutes,
      date: now,
      note: note.trim().isEmpty ? null : note.trim(),
    );

    await _sessionBox.put(sessionId, session);

    // Пересчитать totalHours (double!)
    final double newTotal =
        skill.totalHours + (durationMinutes / 60.0);

    // Пересчитать streak
    final newStreak = _calculateStreak(skill.id);

    final updated = Skill(
      id: skill.id,
      name: skill.name,
      goalHours: skill.goalHours,
      totalHours: newTotal,
      currentStreak: newStreak,
      colorValue: skill.colorValue,
      iconCode: skill.iconCode,
      createdAt: skill.createdAt,
    );

    await _skillBox.put(key, updated);
  }

  /// ---------------------------------------------------
  /// Удалить сессию
  /// ---------------------------------------------------
  static Future<void> deleteSession({
    required int skillId,
    required int sessionId,
  }) async {
    final session = _sessionBox.get(sessionId);
    if (session == null) return;

    // ищем реальный ключ в Hive
    final key = _skillBox.keys.firstWhere(
      (k) => _skillBox.get(k)?.id == skillId,
      orElse: () => null,
    );
    if (key == null) return;

    final skill = _skillBox.get(key)!;

    // удаляем сессию
    await _sessionBox.delete(sessionId);

    // уменьшаем totalHours (double!)
    final reducedHrs = session.durationMinutes / 60.0;
    final double newTotal =
        (skill.totalHours - reducedHrs).clamp(0, double.infinity).toDouble();

    final newStreak = _calculateStreak(skillId);

    final updated = Skill(
      id: skill.id,
      name: skill.name,
      goalHours: skill.goalHours,
      totalHours: newTotal,
      currentStreak: newStreak,
      colorValue: skill.colorValue,
      iconCode: skill.iconCode,
      createdAt: skill.createdAt,
    );

    await _skillBox.put(key, updated);
  }

  /// ===================================================
  /// 🔥 Вычисление streak с учётом всех сессий в Hive
  /// ===================================================
  static int _calculateStreak(int skillId) {
    final sessions = _sessionBox.values
        .where((s) => s.skillId == skillId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sessions.isEmpty) return 1;

    // Уникальные дни занятий
    final uniqueDays = <DateTime>{};
    for (final s in sessions) {
      uniqueDays.add(DateTime(s.date.year, s.date.month, s.date.day));
    }

    int streak = 0;
    DateTime cursor = DateTime.now();

    while (true) {
      final d = DateTime(cursor.year, cursor.month, cursor.day);
      if (uniqueDays.contains(d)) {
        streak++;
        cursor = d.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak == 0 ? 1 : streak;
  }
}