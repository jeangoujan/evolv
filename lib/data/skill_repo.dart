import 'package:flutter/material.dart';
import 'hive_boxes.dart';
import 'models/skill.dart';
import 'models/session.dart';

class SkillRepo {
  static final _box = HiveBoxes.skillBox();

  static List<Skill> getAll() => _box.values.toList();

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

  static Future<void> deleteSkill(int id) async => _box.delete(id);

  static Future<void> addSession({
    required int skillId,
    required int durationSeconds,
    String note = '',
  }) async {
    final skill = _box.get(skillId);
    if (skill == null) return;

    final sessionId = DateTime.now().microsecondsSinceEpoch;
    final session = Session(
      id: sessionId,
      date: DateTime.now(),
      durationSeconds: durationSeconds,
      note: note,
    );

    final updatedSessions = [...skill.sessions, session];
    final addedHours = durationSeconds / 3600.0;

    final updated = Skill(
      id: skill.id,
      name: skill.name,
      goalHours: skill.goalHours,
      totalHours: (skill.totalHours + addedHours),
      colorValue: skill.colorValue,
      iconCode: skill.iconCode,
      sessions: updatedSessions,
    );

    await _box.put(skillId, updated);
  }

  static Future<void> deleteSession({
    required int skillId,
    required int sessionId,
  }) async {
    final skill = _box.get(skillId);
    if (skill == null) return;
    final session = skill.sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => Session(id: -1, date: DateTime.now(), durationSeconds: 0),
    );
    if (session.id == -1) return;

    final reducedHours = session.durationSeconds / 3600.0;
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