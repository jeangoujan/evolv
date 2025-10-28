import 'package:hive/hive.dart';

part 'session.g.dart';

@HiveType(typeId: 1) // НЕ МЕНЯТЬ после релиза
class Session extends HiveObject {
  @HiveField(0)
  int id; // локальный id сессии

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  int durationSeconds; // длительность в секундах

  @HiveField(3)
  String note;

  Session({
    required this.id,
    required this.date,
    required this.durationSeconds,
    this.note = '',
  });
}