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
    );
    await _box.put(id, skill);
  }

  /// Удалить навык
  static Future<void> deleteSkill(int id) async {
    await _box.delete(id);

    // Также удалить все сессии, связанные с этим навыком
    final sessionsToDelete =
        _sessionBox.values.where((s) => s.skillId == id).toList();
    for (final s in sessionsToDelete) {
      await _sessionBox.delete(s.id);
    }
  }
static int _calculateStreak(List<Session> sessions) {
  if (sessions.isEmpty) return 0;

  sessions.sort((a, b) => b.date.compareTo(a.date));
  final today = DateTime.now();
  int streak = 0;

  for (int i = 0; i < sessions.length; i++) {
    final diff = today.difference(sessions[i].date).inDays;
    if (diff == streak) {
      streak++;
    } else if (diff > streak) {
      break;
    }
  }
  return streak;
}


  /// Добавить сессию (через SessionTimerScreen)
static Future<void> addSession({
  required int skillId,
  required double durationMinutes,
  String note = '',
}) async {
  final skill = _box.get(skillId);
  if (skill == null) return;

  final sessionId = DateTime.now().millisecondsSinceEpoch;
  final session = Session(
    id: sessionId,
    skillId: skillId,
    durationMinutes: durationMinutes,
    date: DateTime.now(),
    note: note.trim().isEmpty ? null : note.trim(),
  );

  // Сохраняем в отдельный Hive box "sessions"
  await _sessionBox.put(sessionId, session);

  // === Пересчёт streak ===
  final allSessions = _sessionBox.values
      .where((s) => s.skillId == skillId)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  final streak = _calculateStreak(allSessions);

  // === Обновляем навык ===
  final addedHours = durationMinutes / 60.0;
  final updated = Skill(
    id: skill.id,
    name: skill.name,
    goalHours: skill.goalHours,
    totalHours: (skill.totalHours + addedHours),
    colorValue: skill.colorValue,
    iconCode: skill.iconCode,
    sessions: [...skill.sessions, session],
    currentStreak: streak, // 👈 добавили поле streak
  );

  await _box.put(skillId, updated);
}

  /// Удалить одну сессию (по долгому тапу в SkillDetailScreen)
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

    // Обновляем totalHours у навыка
    final updated = Skill(
      id: skill.id,
      name: skill.name,
      goalHours: skill.goalHours,
      totalHours: (skill.totalHours - reducedHours).clamp(0, double.infinity),
      colorValue: skill.colorValue,
      iconCode: skill.iconCode,
      sessions: skill.sessions.where((s) => s.id != sessionId).toList(),
    );

    await _box.put(skillId, updated);
  }
}

