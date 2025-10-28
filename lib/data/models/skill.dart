import 'package:hive/hive.dart';
import 'session.dart';

part 'skill.g.dart';

@HiveType(typeId: 0)
class Skill extends HiveObject {
  @HiveField(0)
  int id; // уникальный идентификатор

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
  int iconCode; // <-- вместо iconCodePoint / iconFontFamily

  @HiveField(7)
  List<Session> sessions;



  Skill({
    required this.id,
    required this.name,
    required this.goalHours,
    this.totalHours = 0,
    this.currentStreak = 0,
    required this.colorValue,
    required this.iconCode,
    this.sessions = const [],
  });
}