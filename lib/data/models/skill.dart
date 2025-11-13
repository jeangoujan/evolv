import 'package:hive/hive.dart';

part 'skill.g.dart';

@HiveType(typeId: 0)
class Skill extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double goalHours;

  @HiveField(3)
  double totalHours;

  @HiveField(4)
  int currentStreak;

  @HiveField(5)
  int colorValue;

  @HiveField(6)
  int iconCode;

  // 🔥 Новое поле — дата создания
  @HiveField(7)
  DateTime createdAt;

  Skill({
    required this.id,
    required this.name,
    required this.goalHours,
    this.totalHours = 0,
    this.currentStreak = 1,
    required this.colorValue,
    required this.iconCode,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}