import 'package:hive/hive.dart';

part 'session.g.dart';

@HiveType(typeId: 1)
class Session extends HiveObject {
  @HiveField(0)
  int id; // уникальный ID (timestamp)

  @HiveField(1)
  int skillId; // к какому навыку относится

  @HiveField(2)
  double durationMinutes; // длительность в минутах

  @HiveField(3)
  DateTime date; // дата завершения

  @HiveField(4)
  String? note; // заметка пользователя (опционально)

  Session({
    required this.id,
    required this.skillId,
    required this.durationMinutes,
    required this.date,
    this.note,
  });

  String get formattedDuration {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}min';
    if (h > 0) return '${h}h';
    return '${m}min';
  }
}